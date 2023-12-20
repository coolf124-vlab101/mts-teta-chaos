## Проект домашнего задания для МТС Тета - Домашнее задание №4
### Задача:

 1. Отключение узла: Планово остановить один из узлов кластера, чтобы проверить процедуру
переключения ролей (failover). - Анализировать время, необходимое для восстановления и как
система выбирает новый Master узел (и есть ли вообще там стратегия выбора?).
2. Имитация частичной потери сети: Использовать инструменты для имитации потери пакетов
или разрыва TCP-соединений между узлами. Цель — проверить, насколько хорошо система
справляется с временной недоступностью узлов и как быстро восстанавливается репликация.
3. Высокая нагрузка на CPU или I/O: Запустить процессы, которые создают высокую нагрузку на CPU или дисковую подсистему одного из узлов кластера, чтобы проверить, как это влияет на
производительность кластера в целом и на работу Patroni.
4. Тестирование систем мониторинга и оповещения: С помощью chaos engineering можно также
проверить, насколько эффективны системы мониторинга и оповещения. Например, можно
искусственно вызвать отказ, который должен быть зарегистрирован системой мониторинга, и
убедиться, что оповещения доставляются вовремя ?

Если сделали все предыдущие:
1. ”Split-brain": Одновременно изолировать несколько узлов от сети и дать им возможность
объявить себя новыми мастер-узлами. Проверить, успеет ли Patroni достичь
консенсуса и избежать ситуации "split-brain".
2. Долгосрочная изоляция: Оставить узел изолированным от кластера на длительное время, затем восстановить соединение и наблюдать за процессом синхронизации и
восстановления реплики.
3. Сбои сервисов зависимостей: Изучить поведение кластера Patroni при сбоях в сопутствующих сервисах, например, etcd (которые используются для хранения состояния кластера),
путем имитации его недоступности или некорректной работы.

Формат сдачи ДЗ:
Ссылка на репозиторий, где размещен md файлс с описанием экспериментов и результатами
1. Отключение узла: Планово остановить один из узлов кластера, чтобы проверить процедуру
переключения ролей (failover). - Анализировать время, необходимое для восстановления и как
система выбирает новый Master узел (и есть ли вообще там стратегия выбора?).
1.1 Описание эксперимента: Подробные шаги, которые были предприняты для
имитации условий эксперимента. - Инструменты и методы, применяемые в
процессе.
2. Ожидаемые результаты: Описание ожидаемого поведения системы в ответ
на условия эксперимента.
3. Реальные результаты: Что произошло на самом деле в ходе эксперимента.
Логи, метрики и выводы систем мониторинга и логирования.
4. Анализ результатов: Подробное сравнение ожидаемых и реальных
результатов. - Обсуждение возможных причин отклонений.

###  Требования/ Requirements
На НТ на АРМ/Сервере НТ должны быть установлены:
 - openjava11
 - jmeter
### Схема приложения [Ссылка на развернутое Приложение API из Домашного задания по модулю 2 (работает пока не выключено)](http://9f5f69f6-aa8c-4658-abf1-f6deeb4ebbba.mts-gslb.ru/WeatherForecast)
![схема приложения](https://github.com/coolf124-vlab101/mts-teta-hw01/blob/main/mts-teta-hw-01.drawio.png?raw=true)
### Список хостов
```
balancer-01 10.0.10.2 +publicIP
db-01 10.0.10.3
db-01 10.0.10.4
etcd-01 10.0.10.5
etcd-02 10.0.10.6
etcd-03 10.0.10.7
prom-01 10.0.10.8
load-01  10.0.10.9 +publicIP
```
## 1. Отключение узла: Планово остановить один из узлов кластера, чтобы проверить процедуру
переключения ролей (failover). - Анализировать время, необходимое для восстановления и как
система выбирает новый Master узел (и есть ли вообще там стратегия выбора?).
### 1.1 Описание эксперимента: Подробные шаги, которые были предприняты для
Выключаем постоянную нагрузку на генераторе нагрузки.
Выполняем на узле мастер БД команду ```sudo systemctl shutdown -now ```
###  1.2. Ожидаемые результаты: Описание ожидаемого поведения системы в ответ
При отключении узла система в течении времени, указанного в конфигурации (ttl = 30 секунд) делает узел-реплику мастером и сервис восстанавливается. 
Так как у нас сервера реплика БД один, то он и становиться мастером. А так ноды реплики соревнуются, насколько я знаю кто станет мастером зависит от отставания реплик от мастер сервера. Реплики с меньшим оставанием при прочих равных станет мастером. 
"That leader lock has a time-to-live associated with it. If the leader node fails to update the lease of the leader
lock in time, the key will eventually expire from the DCS.
When the leader lock expires, it triggers what Patroni calls a leader race: all nodes start performing checks
to determine if they are the best candidates for taking over the leader role. Some of these checks include calls
to the REST API of all other Patroni members" 
На время недоступности мастер БД транзакции выдают ошибку.
При восстановлении отключенного узла мастер-роль возвращается на старый узел если указан fail-back.
###  1.3. Реальные результаты: Что произошло на самом деле в ходе эксперимента.
При отключении узла система в течении времени, указанного в конфигурации делает узел-реплику мастеров и сервис восстанавливается.
![отключение мастер узла](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos1_1.png?raw=true)
На время недоступности мастер БД транзакции выдают ошибку - видно всплеск ошибок на графике.
При отключении мастер-сервера БД он пропадает из конфигурации haproxy, конфигурация перезаписывается на новую.
При восстановлении отключенного узла, он возвращается в кластер, но мастер-роль не возвращается на старый узел  - старый узел становиться репликой.
###  4. Анализ результатов: Подробное сравнение ожидаемых и реальных
Было ожидание что роль-мастер сервера БД вернется на старый узел, но похоже это сделано специально чтобы небыло дополнительной недоступности при обратном переключении.
Не ожидал что Patroni перезаписывает конфигурацию haproxy при отключении сервера, ожидал что он будет просто помечен как недоступный...
