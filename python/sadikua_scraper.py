import requests
import csv
from bs4 import BeautifulSoup
from fake_useragent import UserAgent


urls = {'Частные детсады': 'https://sadik.ua/kiev/chastnye-detsady',
        'Раннее развитие': 'https://sadik.ua/kiev/rannee-razvitie',
        'Детские сады Киева': 'https://sadik.ua/kiev',
        'Детские сады Киевской области': 'https://sadik.ua/kiev/oblast'}


class PageParser:

    def __init__(self) -> None:
        super().__init__()
        self.pages_data = []
        self.sections_data = []
        self.domain_name = 'https://sadik.ua'
        self.fieldnames = ('title', 'description', 'address', 'phone', 'specialization', 'section')

    @staticmethod
    def clear_text(text):
        return text.replace('\n', ' ').replace('\r', '').replace('\xa0', '').replace('\t', ' ').strip()

    def save_csv(self, filename):
        with open(filename, 'w', newline='') as csv_file:
            writer = csv.DictWriter(csv_file, fieldnames=self.fieldnames, delimiter='\t')

            writer.writeheader()
            for row in self.sections_data:
                writer.writerow(row)

    def parse_page(self, page_url, section_name=''):
        print('Parsing: ' + section_name + ' (' + page_url + ')')
        _user_agent = UserAgent()
        user_agent = {'User-Agent': _user_agent.random}

        response = requests.get(url=page_url, headers=user_agent)
        found_results = []
        if response.status_code == requests.codes.ok:
            result = response.text

            soup = BeautifulSoup(result, 'html.parser')
            result_block = soup.find_all('div', attrs={'class': 'lsrow row-fluid'})
            for one_result in result_block:
                title = one_result.find('span', attrs={'itemprop': 'name'})
                if title:
                    title = self.clear_text(title.get_text())
                description = one_result.find('p', attrs={'class': 'descr'})
                if description:
                    description = self.clear_text(description.get_text())
                address = one_result.find('p', attrs={'class': 'address'})
                if address:
                    address = self.clear_text(address.get_text())
                data = one_result.find_all('span', attrs={'style': 'font-weight:normal; color:#235829'})
                if data and len(data) == 2:
                    phone = self.clear_text(data[0].get_text())
                    specialization = self.clear_text(data[1].get_text())
                else:
                    phone = ''
                    specialization = ''

                found_results.append({'title': title, 'description': description, 'address': address, 'phone': phone,
                                      'specialization': specialization, 'section': section_name})

            self.pages_data += found_results

            next_page = soup.find('a', attrs={'class': 'pagenav', 'title': 'Вперёд'})
            if next_page:
                self.parse_page(page_url=self.domain_name + next_page['href'], section_name=section_name)

    def parse_section(self, start_url, section_name):
        self.pages_data = []
        self.parse_page(page_url=start_url, section_name=section_name)
        return self.pages_data

    def parse(self, sections):
        self.sections_data = []
        for name, start_url in sections.items():
            section_data = self.parse_section(start_url=start_url, section_name=name)
            if section_data:
                self.sections_data += section_data


def main():
    parser = PageParser()
    parser.parse(sections=urls)
    parser.save_csv(filename='results.csv')


if __name__ == "__main__":
    main()
