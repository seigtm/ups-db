# Проектирование аналитической базы данных PostgreSQL

## Постановка задачи

Практическое задание связано с проектированием схемы базы данных для аналитики.

Будем исходить из того, что приложение, для которого была сделана база данных в задании стала очень популярной и по ней каждый день можно собирать большой объем статистической информации.

Результатом данного практического задания являются:

1. скрипты создания базы данных,
2. хранимая процедура (генератор) для ее заполнения,
3. анализ плана выполнения запроса.

## База данных системы доставки UPS

Ниже представлен запрос создания таблицы **Retail center**:

```sql
CREATE TABLE
  public.retail_center (
    id serial,
    type character varying(255) NOT NULL,
    address character varying(255) NOT NULL,
    PRIMARY KEY (id)
  );
```

Ниже представлен запрос создания таблицы **Transportation event**:

```sql
CREATE TABLE
  public.transport_event (
    seq_number serial,
    type character varying(255) NOT NULL,
    delivery_rout character varying(255) NOT NULL,
    PRIMARY KEY (seq_number)
  );
```

Ниже представлен запрос создания таблицы **Shipped item**:

```sql
CREATE TABLE
  public.shipped_item (
    item_num serial,
    retail_center_id integer NOT NULL,
    weight numeric(19, 2) NOT NULL,
    dimension numeric(19, 2) NOT NULL,
    insurance_amt numeric(19, 2) NOT NULL,
    destination character varying(255) NOT NULL,
    final_delivery_date date NOT NULL,
    PRIMARY KEY (item_num),
    CONSTRAINT "Retail Center ID" FOREIGN KEY (retail_center_id)
      REFERENCES public.retail_center (id) MATCH SIMPLE
      ON UPDATE CASCADE
      ON DELETE CASCADE
      NOT VALID
  );
```

Ниже представлен запрос создания таблицы **Item transportation**:

```sql
CREATE TABLE
  IF NOT EXISTS public.item_transportation (
    transportation_event_seq_number integer NOT NULL,
    comment character varying(255) NOT NULL,
    shipped_item_item_num integer NOT NULL,
    CONSTRAINT item_transportation_pkey PRIMARY KEY (
      transportation_event_seq_number,
      shipped_item_item_num
    ),
    CONSTRAINT "Shipped item item num" FOREIGN KEY (shipped_item_item_num) REFERENCES public.shipped_item (item_num) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT "Transportation event seq number" FOREIGN KEY (transportation_event_seq_number) REFERENCES public.transport_event (seq_number) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE
  )
```

## Требования к БД

1. Одна таблица (**Item transportation**) должна содержать не меньше 10 млн. записей.
2. Другая таблица (**Shipped Item**), связанная с первой, должна содержать не меньше 1 млн. записей.
3. Остальные таблицы должны содержать по 5-10 записей.
4. В одной из таблиц с количеством записей 10 млн. (**Item Transportation**) должна быть колонка с текстом, по которой будет необходимо настроить полнотекстовый поиск (**comment**).

## Особенности работы

1. Регистрация/активация расширения **python** в СУБД создается командой `CREATE EXTENSION plpython3u;` автоматически становится доступен **python** объект **plpy** для взаимодействия с таблицами СУБД.
2. Шаблон объявления функции/процедуры в PostgreSQL:

    ```sql
    CREATE FUNCTION имя_функции(аргументы)
        RETURNS возвращаемый_тип
        AS $$

    # Тело функции на PL/Python
    $$
    LANGUAGE plpython3u;
    ```

3. Тело функции содержит просто скрипт на языке Python. Когда вызывается функция, её аргументы передаются в виде элементов списка args; именованные аргументы также передаются скрипту Python как обычные переменные. Примеры методов объекта plpy:

    ```sql
    plpy.execute(query[,предел]);
    plpy.prepare(query [, типы_аргументов]);
    plpy.execute(план [, аргументы [, предел]]);
    plpy.cursor(query);
    plpy.cursor(план [, аргументы]);
    plpy.SPIError;
    ```

4. Нельзя (не нужно) использовать СУБД драйвер python psycopg2.
5. Генерация должна происходить прямо в процедуре/функции. Для оптимизации скорости все ограничения БД (первичные/внешние ключи, ограничения типа) нужно добавлять в таблицы после окончания генерации. Сами строки для вставки генерировать нужно блоками (1000–100000). Если вставлять по одной строке, будет долго из-за поддержки транз. целостности. Если вставлять сразу 1000000 строк, то не хватит памяти сервера БД.

## Практическая часть

Практическая часть включает:

1. Наполнение таблицы, для этого нужно написать хранимую функцию – генератор на языке **plpython3u**. Интерфейс взаимодействия с БД внутри хранимой процедуры через встроенный объект **plpy**.
2. Оценка скорости выполнения запросов. Для этого могут быть использованы механизмы секционирования, наследования и индексов. Необходимо подготовить два запроса:
   - Запрос к одной таблице, содержащий фильтрацию по нескольким полям.
   - Запрос к нескольким связанным таблицам, содержащий фильтрацию по нескольким полям.
3. Оценка скорости полнотекстового поиска (использование функций `to_tsvector`, `to_tsquery`).

Для каждого из запросов необходимо провести следующие шаги:

1. Получить план выполнения запроса без использования индексов (удаление индекса или отключение его использования в плане запроса).
2. Получить статистику выполнения запроса без использования индексов.
3. Создать нужные индексы, позволяющие ускорить запрос.
4. Получить план выполнения запроса с использованием индексов и сравнить с первоначальным планом.
5. Получить статистику выполнения запроса с использованием индексов и сравнить с первоначальной статистикой.
6. Оценить эффективность выполнения оптимизированного запроса. Синтаксис EXPLAIN:

    ```sql
    EXPLAIN [ ( параметр [, ...] ) ] оператор;
    EXPLAIN [ ANALYZE ] [ VERBOSE ] оператор;
    # Здесь допускается параметр:
    ANALYZE [ boolean ];
    VERBOSE [ boolean ];
    COSTS [ boolean ];
    SETTINGS [ boolean ];
    BUFFERS [ boolean ];
    WAL [ boolean ];
    TIMING [ boolean ];
    SUMMARY [ boolean ];
    FORMAT { TEXT | XML | JSON | YAML };
    # В PGAdmin удобно использовать следующий формат команды
    EXPLAIN (ANALYZE, VERBOSE, COSTS, TIMING, FORMAT JSON);
    ```

Также необходимо продемонстрировать полезность индексов для организации полнотекстового поиска.

Для таблицы объёмом 10 млн. записей произвести оптимизацию, позволяющую быстро удалять старые данные, ускорить вставку и чтение записей.
