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
5. ”Split-brain": Одновременно изолировать несколько узлов от сети и дать им возможность
объявить себя новыми мастер-узлами. Проверить, успеет ли Patroni достичь
консенсуса и избежать ситуации "split-brain".
6. Долгосрочная изоляция: Оставить узел изолированным от кластера на длительное время, затем восстановить соединение и наблюдать за процессом синхронизации и
восстановления реплики.
7. Сбои сервисов зависимостей: Изучить поведение кластера Patroni при сбоях в сопутствующих сервисах, например, etcd (которые используются для хранения состояния кластера),
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
### Схема приложения 
![схема приложения](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/mts-teta-hw-chaos.drawio.png?raw=true)
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
Выключаем постоянную нагрузку на генераторе нагрузки на сервере load01 ```apache-jmeter-5.6.2/bin/jmeter -n -t simple-http-request-test-plan5.jmx -l results-2023-12-17_02.log```
Выполняем на узле мастер БД команду ```sudo systemctl shutdown -now ```
###  1.2. Ожидаемые результаты: Описание ожидаемого поведения системы в ответ
При отключении узла система в течении времени, указанного в конфигурации (ttl = 30 секунд)  узел-реплика захватывает лидерство и становиться мастером и сервис восстанавливается. 
Так как у нас сервера реплика БД один, то он и становиться мастером. А так ноды реплики соревнуются, насколько я знаю кто станет мастером зависит от отставания реплик от мастер сервера. Реплики с меньшим оставанием при прочих равных станет мастером. 
"That leader lock has a time-to-live associated with it. If the leader node fails to update the lease of the leader
lock in time, the key will eventually expire from the DCS.
When the leader lock expires, it triggers what Patroni calls a leader race: all nodes start performing checks
to determine if they are the best candidates for taking over the leader role. Some of these checks include calls
to the REST API of all other Patroni members" 
На время недоступности мастер БД транзакции выдают ошибку, которая видна на панели мониторинга http://5eca9364-3899-4021-b861-fd4f64e48c6d.mts-gslb.ru/d/6FYzCvvSz/burdin-4-golden-signals-lt?orgId=1&refresh=5s
При восстановлении отключенного узла мастер-роль возвращается на старый узел если указан fail-back.
###  1.3. Реальные результаты: Что произошло на самом деле в ходе эксперимента.
При отключении узла система в течении времени, указанного в конфигурации делает узел-реплику мастеров и сервис восстанавливается.
![отключение мастер узла](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos1_1.png?raw=true)
На время недоступности мастер БД транзакции выдают ошибку - видно всплеск ошибок на графике.
При отключении мастер-сервера БД он пропадает из конфигурации haproxy, конфигурация перезаписывается на новую.
При восстановлении отключенного узла, он возвращается в кластер, но мастер-роль не возвращается на старый узел  - старый узел становиться репликой.
###  1.4. Анализ результатов: Подробное сравнение ожидаемых и реальных
Было ожидание что роль-мастер сервера БД вернется на старый узел, но похоже это сделано специально чтобы небыло дополнительной недоступности при обратном переключении.
Не ожидал что Patroni перезаписывает конфигурацию haproxy при отключении сервера, ожидал что он будет просто помечен как недоступный...

## 2. Имитация частичной потери сети: Использовать инструменты для имитации потери пакетов
или разрыва TCP-соединений между узлами. Цель — проверить, насколько хорошо система
справляется с временной недоступностью узлов и как быстро восстанавливается репликация
### 2.1 Описание эксперимента: Подробные шаги, которые были предприняты для
Выключаем постоянную нагрузку на генераторе нагрузки на сервере load01 ```apache-jmeter-5.6.2/bin/jmeter -n -t simple-http-request-test-plan5.jmx -l results-2023-12-17_02.log```
Выполняем на узле мастер БД скрипт 1 с частичной потерей и задержкой пакетов на 5 минут
```
#!/bin/bash
sudo tc qdisc del dev ens160 root
sudo tc qdisc add dev ens160 root handle 1: prio
sudo tc filter add dev ens160 parent 1:0 protocol ip pref 55 handle ::55 u32 match ip dst 10.0.10.3 flowid 2:1
sudo tc qdisc add dev ens160 parent 1:1 handle 2: netem delay 1000ms 500ms loss 25.0%
sudo at now + 5 minutes sudo tc qdisc del dev ens160 root

```
Выполняем на узле мастер БД скрипт 1 с полной пакетов  и задержкой пакетов на 10 минут
```
#!/bin/bash
sudo tc qdisc del dev ens160 root
sudo tc qdisc add dev ens160 root handle 1: prio
sudo tc filter add dev ens160 parent 1:0 protocol ip pref 55 handle ::55 u32 match ip dst 10.0.10.3 flowid 2:1
sudo tc qdisc add dev ens160 parent 1:1 handle 2: netem delay 1000ms 500ms loss 100.0%
sudo at now + 5 minutes sudo tc qdisc del dev ens160 root

```
###  2.2. Ожидаемые результаты: Описание ожидаемого поведения системы в ответ
При потери пакетов  и задержке  между узлами postgresql репликация продолжается, так как репликация асинхронная.
При изоляции сети между узлами postgresql репликация останавливается. Приложение работает как обычно, так как репликация ассинхронная. При переподключении сети репликация автоматически восстанавливается.

###  2.3. Реальные результаты: Что произошло на самом деле в ходе эксперимента.
При потери пакетов  и задержке  между узлами postgresql репликация продолжается, так как репликация асинхронная.
При изоляции сети между узлами postgresql репликация останавливается. Приложение работает как обычно, так как репликация ассинхронная. При переподключении сети репликация автоматически восстанавливается.

![ пауза репликации при отключения трафика между узлами БД](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos2_1.png?raw=true)
![ восстановление репликации при отключения трафика между узлами БД](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos2_2.png?raw=true)
###  2.4. Анализ результатов: Подробное сравнение ожидаемых и реальных
Ожидания совпали с результатами

## 3. Высокая нагрузка на CPU или I/O: Запустить процессы, которые создают высокую нагрузку на CPU или дисковую подсистему одного из узлов кластера, чтобы проверить, как это влияет на
производительность кластера в целом и на работу Patroni.
### 3.1 Описание эксперимента: Подробные шаги, которые были предприняты для
Выключаем постоянную нагрузку на генераторе нагрузки на сервере load01 ```apache-jmeter-5.6.2/bin/jmeter -n -t simple-http-request-test-plan5.jmx -l results-2023-12-17_02.log```
Выполняем на узле мастер БД высокую нагрузку на CPU
```
stress-ng --cpu 4 --metrics --timeout 300s
```
Выполняем на узле мастер БД высокую нагрузку  тип 1 на диск 
```
stress-ng --io 4 --timeout 300s --metrics
```
Выполняем на узле мастер БД высокую нагрузку  тип 2 на диск 
```
sudo fio --filename=/tmp/ssd.test.file --size=10GB --direct=1 --rw=randrw --bs=64k --ioengine=libaio --iodepth=64 --runtime=120 --numjobs=4 --time_based --group_reporting --name=throughput-test-job --eta-newline=1
sudo vim ssd-test.fio
sudo fio ssd-test.fio 
```
###  3.2. Ожидаемые результаты: Описание ожидаемого поведения системы в ответ
При высокой нагрузке на СPU мастер узла БД (утилизация 100%) количество RPS снижается и растет API Latency 
При высокой нагрузке на дисковую подсистему мастер узла БД количество RPS  не снижается существенно и не существенно растет API Latency, так как наше приложение не сильно использует диск.

###  3.3. Реальные результаты: Что произошло на самом деле в ходе эксперимента.
При высокой нагрузке на СPU мастер узла БД (утилизация 100%) количество RPS не снижается существенно (10-20%), но существенно растет API Latency -  c 5 мс до значений более 100мс.
При высокой нагрузке на дисковую подсистему мастер узла БД количество RPS не снижается существенно и несущественно растет API Latency - c 5 мс до значений более 4000мс.
При симуляции нагрузки дисковую подсистему мастер узла БД с помощью количество RPS не падает, Latency не растет

небольшая просадка при тесте CPU
![ небольшая просадка при тесте CPU ](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos3_1.png?raw=true)
просадка при тесте ввода-вывода силами stress-ng
![ просадка при тесте ввода-вывода силами stress-ng ](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos3_2.png?raw=true)
просадка при тесте HDD с помощью fio
![ просадка при тесте HDD с помощью fio ](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos3_2.png?raw=true)
###  3.4. Анализ результатов: Подробное сравнение ожидаемых и реальных
При высокой нагрузке на СPU мастер узла БД (утилизация 100%) ожидания в целом совпали с реальностью по задержке, хотя казалось что будет просадка в RPS и больше  ошибок в приложении. Скорее всего наше приложение также сильно нагружает CPU БД, поэтому рост нагрузки CPU не приводит к ошибкам и снижению RPS, а только по latency 
То что при высокой нагрузке на подсистему ввода-вывода с помощью stress-ng существенно растет API Latency, скорее всего объясняется тем что там в тесте идет нагрузка не только на диск но и на ввод-вывод, поэтому и растет latency.  
То что при высокой нагрузке на дисковую подсистемы средствами fio не меняются latency и не возникает ошибки в целом объяснимио, так как приложение не использует активно диск, размер БД ограничен, так что БД закеширована в файловой системе и значительная дисковая нагрузка не оказывает влияние на приложения.

## 4. Тестирование систем мониторинга и оповещения: С помощью chaos engineering можно также
проверить, насколько эффективны системы мониторинга и оповещения. Например, можно
искусственно вызвать отказ, который должен быть зарегистрирован системой мониторинга, и
убедиться, что оповещения доставляются вовремя ?
### 4.1 Описание эксперимента: Подробные шаги, которые были предприняты для
Выключаем постоянную нагрузку на генераторе нагрузки на сервере load01 ```apache-jmeter-5.6.2/bin/jmeter -n -t simple-http-request-test-plan5.jmx -l results-2023-12-17_02.log```
Поочередно выполняем на каждом сервере команду ```sudo systemctl shutdown -now ```, а потом включаем через консоль https://hub.cloud.mts.ru/compute/list
###  4.2. Ожидаемые результаты: Описание ожидаемого поведения системы в ответ
При отключении сервера система мониторинга в течении 2 минут недоступности системы высылает сообщение через телеграмм
###  4.3. Реальные результаты: Что произошло на самом деле в ходе эксперимента.
При отключении сервера система мониторинга в течении 2 минут недоступности системы высылает сообщение через телеграмм
![ сообщение в телеграмм ](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos4_1.png?raw=true)
###  4.4. Анализ результатов: Подробное сравнение ожидаемых и реальных
Все в пределах ожиданий.

## 5. ”Split-brain": Одновременно изолировать несколько узлов от сети и дать им возможность объявить себя новыми мастер-узлами. Проверить, успеет ли Patroni достичь консенсуса и избежать ситуации "split-brain"
### 5.1 Описание эксперимента: Подробные шаги, которые были предприняты для
Выключаем постоянную нагрузку на генераторе нагрузки на сервере load01 ```apache-jmeter-5.6.2/bin/jmeter -n -t simple-http-request-test-plan5.jmx -l results-2023-12-17_02.log```
Так как  у нас всего 3 сервера etcd, то  в этом эксперименте будем изолировать 1 узел. Если изолировать два сразу два, то лидер etcd не изберется и хранилище etcd будет недоступно.
```
sudo ufw allow ssh
sudo ufw deny allow outgoing
sudo ufw default deny incoming
sudo ufw allow 53
sudo ufw enable
nohup ./isolate_network_60s.sh < /dev/null > /dev/null 2>&1
```
###  5.2. Ожидаемые результаты: Описание ожидаемого поведения системы в ответ
При изоляции сервера etcd-02 сервер не видит другие узлы, не может стать лидером, так ему не хватает кворума до 2 узлов. 

###  5.3. Реальные результаты: Что произошло на самом деле в ходе эксперимента.
При изоляции одного сервера на нем не поднимается лидер, тк консенсус не возможен. На других 2 выбирается лидер тк консенсус возможен.
На изолированным узле лидер не поднимается
![ pic1 ](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos5_1.png?raw=true)
На других двух узлах есть лидер
![ pic2 ](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos5_2.png?raw=true)
При отключении изоляции кластер восстанавливается, происходит повторное голосование и лидер сохраняется
![ pic3 ](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos5_3.png?raw=true)
###  5.4. Анализ результатов: Подробное сравнение ожидаемых и реальных
Все в пределах ожиданий.
### 6.  Долгосрочная изоляция: Оставить узел изолированным от кластера на длительное время, затем восстановить соединение и наблюдать за процессом синхронизации и восстановления реплики.
Совдпадает по сути со сценарием 5.
###  7. Сбои сервисов зависимостей: Изучить поведение кластера Patroni при сбоях в сопутствующих сервисах, например, etcd (которые используются для хранения состояния кластера), путем имитации его недоступности или некорректной работы.
### 7.1 Описание эксперимента: Подробные шаги, которые были предприняты для
Выключаем постоянную нагрузку на генераторе нагрузки на сервере load01 ```apache-jmeter-5.6.2/bin/jmeter -n -t simple-http-request-test-plan5.jmx -l results-2023-12-17_02.log```
Так как  у нас всего 3 сервера etcd, то  в этом эксперименте будем изолировать 2 узла, чтобы посмотреть как patroni будет работать при недоступности etcd  для записи. Выполняем следующую команду на узлах etcd-01 и etcd-02
```
nohup ./isolate_network_300s.sh < /dev/null > /dev/null 2>&1
```
### 7.1.1 Повторить эксперимент включив режим DCS Failsafe Mode
```patronictl edit-config -s failsafe_mode=true```
###  7.2. Ожидаемые результаты: Описание ожидаемого поведения системы в ответ
Служба etcd станет недоступна, при отсутствии включенного режима DCS Failsafe Mode приложение станет недоступным, так как подключение настроено через порт master реплики.
Во втором эксперименте служба etcd станет недоступна, приложение должно остаться доступным


###  7.3. Реальные результаты: Что произошло на самом деле в ходе эксперимента.
При изоляции без использования опции failsafe двух сервера на нем не поднимается лидер, тк консенсус не возможен.  БД мастер становиться недоступным. Тк приложение станет недоступным, так как подключение настроено через порт master БД.
![ pic1 ](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos7_1.png?raw=true)
![ pic2 ](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos7_2.png?raw=true)
Во втором эксперименте При изоляции c  опцией failsafe двух сервера на нем не поднимается лидер, тк консенсус не возможен..На других 2 выбирается лидер тк консенсус возможен. БД мастер с опцией failsafe остается работающим если на момент пропадания etcd он был включен . Тк приложение остается доступным, так как подключение настроено через порт master БД.
![ pic1 ](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos7_3.png?raw=true)
![ pic2 ](https://github.com/coolf124-vlab101/mts-teta-chaos/blob/main/chaos7_4.png?raw=true)

###  7.4. Анализ результатов: Подробное сравнение ожидаемых и реальных
Все в пределах ожиданий.