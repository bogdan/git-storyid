# git-storyid

Helps to attach pivotal story id to git commit

## Installation

``` sh
gem install git-storyid
```

## Usage

``` sh
git storyid -m "Commit message"
# Api token (https://www.pivotaltracker.com/profile): a56f0e9a4fbXXXXXXXXXXXXXX
# Use SSL (y/n): y
# Your pivotal initials (e.g. BG): BG
# Project ID: 494XXX
```

Interactive menu to select an ID of **Started stories**

```
[1] После обновления статуса заказа из 1с на сайте этот заказ снова попадает в результаты апи заказов.
[2] Таблица размеров
[3] Добавить редактирование ProductCategory#size_metric_name в админку
[4] Добавить новую информацию из 1с по карточке товара
[5] все товары с образа в корзину (с выбором размера вместо мэин варианта)
[6] В администраторе, в фотографиях неработает фильтр "ID"

Indexes(csv): 6
[master 6a03823]  [#35311801] Feature: В администраторе, в фотографиях неработает фильтр ID
 1 file changed, 1 insertion(+)
```
