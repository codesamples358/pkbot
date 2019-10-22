# Pkbot

TODO: Write a gem description

## Installation

D:\pkbot\get.bat

## Usage

pk <command> <arguments>
pk v - показывает текущую версию (время)
pk make <номер> обрабатывает номер целиком (скачивает файлы, закачивает статьи)

## Инструкция

# Пдф, конфиг

когда появилась pdf запустить 

  pk d <номер>

где "d" - обозначает download. для номера 132/П - надо набрать "132p" (p - латинское)

в C:\Users\User\pkbot\issues появится папка 132p
в этой папке написать в config/config.csv статьи в формате

<имя статьи>;<есть ли фотка>;<инфографика1>,<инфографика2>,..

файл конфига надо сохранить как простой текст в формате UTF8 (без BOM - это на самом деле и есть нормальный utf8 :) )
имена всех файлов картинок (инфографика, фотки) - относительно <папка номера>/images - то есть просто имена, если складывать все файлы в эту папку

(в examples записал тот файл что сделал для 132 номера ну и инфографику в 2 последних дописал сейчас для примера просто)

по инфографике пока нет почти никакой логики - только вставит одну широкую в конец и одну "узкую" - примерно в середину. другие случаи и больше одной пока что не вставляет))

по фотке - найдет на коммерсанте самую большую для статьи и вставит шириной 100 после автора.


# проверка конфига, xml

когда появится xml запустить еще раз

  pk d <номер>

и если xml-ка скачалась запустить

  pk c <номер>

где "c" - обозначает config; команда сгенерит файл config/config.yml - это расширенный файл конфигурации, в дальнейшем прога будет работать именно по нему + туда дописывать по ходу всякие промежуточные данные (потом может это переделаю). и заодно будет проверка все ли заголовки из цсв-шки нашлись в xml номера. Надо поискать в yml по строке <<NOT FOUND>>, и если такие элементы есть - их удалить, а их конфиг подставить в правильные элементы (они допишутся в этот yml и у них будет article_id). ИЛИ можно поправить файл цсв и еще раз сделать "pk c"

после того как окончательный config.yml составлен, можно запускать последний этап

  pk make <номер>

который запихнет все в бек-офис по файлу конфига. Важно чтобы в бек-офисе номер уже был переименован так, чтобы совпасть с номером командной строки (в точности если только цифры и '132/П', если в командной строке задан '132p')

командой

  pk p <номер>

можно опубликовать все статьи в номере


# Одновременно

Если делать все сразу, когда уже есть и pdf и xml то можно сначала скачать файлы

  pk d <номер>

потом сегенрить конфиг по xml-ке

  pk c gen_yml <номер>

и пройтись по нему, проставить true где надо у фоток. и потом

  pk make <номер>