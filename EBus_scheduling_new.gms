OPTIONS LIMROW = 30,limcol = 4, DECIMALS = 4 , Reslim = 1000000000, iterlim = 20000000;
$onecho > cplex.opt
names 0
$offecho

sets
n       terminal node definition /1*4/
*1--University Medical Center
*2--Salt Lake Central Station
*3--This is the Place State Park
*4--North Temple Station

d       depot node definition /0/
*0--depot

i      trip index /1*116/
t      unit time period index /1*1440/
zeta   demand period index with 15 min demand measurment interval  /1*96/
;

alias(i,j);
alias(n,nn,nnn);

sets
Bzeta1(zeta)      demand periods within peak hours
Bzeta2(zeta)      demand periods within off-peak hours Big zeta
Btao(zeta, t)     unit time periods t within demand periods zeta
;

Bzeta1(zeta)$((ord(zeta) ge 32 and ord(zeta) le 40) or (ord(zeta) ge 60 and ord(zeta) le 80))=yes;
Bzeta2(zeta)$(ord(zeta) lt 32 or (ord(zeta) gt 40 and ord(zeta) lt 60) or ord(zeta) gt 80)=yes;
Btao(zeta, t)$(ord(t) le ord(zeta)*15 and ord(t) gt ord(zeta)*15-15 )=Yes;

scalar
p_bus_bar   maximum charging power of buses
mm          a large number
epsilonL    lower bound of battery level /0.2/
epsilonU    upper bound of battery level /0.9/
rho         duration of each time period
gama        duration of each demand period
elecostp    electricity price during peak hours /0.21/
elecosto    electricity price during off peak hours /0.064/
demcostp    demand rate during peak hours /30/
demcosto    demand rate during off peak hours /5/
;

p_bus_bar=350;
mm=100000000000;
rho=1/60;
gama=15/60;

sets
m                 bus index
trips(m,i)        set of service trips of bus m
tripb(m,i,j)      two adjacent service trips serving by bus m
tripF(m,i)        first trip of bus m
tripL(m,i)        last trip of bus m
timei(m,i,n,t)    set of time periods available for charging at terminal n before serving trip i
timed(m,t)        set of time periods available for charging at the depot
tripst(i,n)       the start terminal of trip i
tripet(i,n)       the end terminal of trip i
;

parameters
batt(m)           battery capacity of bus m
energyT(m,i)      energy consumption of bus m serving trip i
energyD(m,i,j)    energy consumption of bus m serving deadhead trip between trip i and trip j
energyDF(m,i)     energy consumption of bus m from its depot to its first trip
energyLD(m,i)     energy consumption of bus m from its last trip to its depot
chastation(n)     whether terminal n is equipped with a charging station
opertime(m)       operating time of bus m 
;
  

$gdxin data.gdx
$load m=m
$load trips=bust
$load tripb=busaj
$load tripF=busf
$load tripL=busl
$load timei=busct
$load timed=busctd
$load tripst=tripst
$load tripet=tripet
$load batt=batt
$load energyT=busen
$load energyD=busea
$load energyDF=busdf
$load energyLD=busld
$load chastation=terch
$load opertime=busst
$gdxin

display m,trips,tripb,tripF,tripL,timei,tripst,tripet;
display batt,energyT,energyD,energyDF,energyLD,chastation,opertime;

parameters
bus_price         bus (without battery) procurement cost
batt_price        battery price ($ per kwh)
salary            drivers salary ($ per hour)
char_fix          fix cost of installing a charging station
char_var          variable cost of a charger ($ per kw)
;

bus_price=(315320/12)/365;
batt_price=(570/6)/365;
salary=16.4;
char_fix=(2000*104/12)/365;
char_var=444/12)/365;
display bus_price,batt_price,salary,char_fix,char_var;


variables
pn(m,i,n,t)       actual charging power of bus m within time period t before serving trip i at terminal n
pd(m,d,t)         actual charging power of bus m at depot within time period t
pavgn(n,zeta)     average charging power at terminal n within demand period zeta
pavgd(d,zeta)     average charging power at depot within demand period zeta
pmaxn(n)          maximum charging power need at a terminal which is the charging power of the charger at the terminal
pmaxd(d)          maximum charging power need at the depot which is the charging power of the charger at the depot
ppeaknp(n)         peak power demand at terminal n during peak hours for calculating demand charges
ppeakno(n)         peak power demand at terminal n during off peak hours for calculating demand charges
ppeakdp(d)         peak power demand at depot during peak hours for calculating demand charges
ppeakdo(d)         peak power demand at depot during off peak hours for calculating demand charges

eni(m,i,n)        energy level of a bus when it finishes a trip i at terminal n
edd(m,d,i)        energy level of a bus when it departs from its depot to serve its first trip i in the morning
ead(m,i,d)        energy level of a bus when it arrives at its depot after finishing its last trip i in the evening
eoi(m,i,n)        energy obtained before it starts a new trip i at terminal n
eod(m,d)          energy obtained at depot

elecost           electricity cost
demcost           demand cost
buscost           bus cost
chacost           charger cost
dricost           drivers cost

objvalue         objective value
;

equations
energydd         energy level when leaves the depot in the morning
energyft         energy level when finishes the first trip
energybt         energy level between two trips
energyad         energy level when arrives the depot in the evening
energysd         energy obtained at the depot should not exceed the maximum value
energymt         maximum energy can be obtained before serving a trip
energymd         maximum energy can be obtained at the depot
energylo1        energy level lower bound constraint 1
energylo2        energy level lower bound constraint 2
energyup1        energy level upper bound constraint 1
energyup2        energy level upper bound constraint 2

powern1          actual charging power at terminal should not exceed the maximum value
powerd1          actual charging power at depot should not exceed the maximum value
powern2          actual charging power equals zero when a bus is not idling at a terminal
powerd2          actual charging power at depot equals zero when a bus is not at the depot
powern3          calculate maximum charging power at a terminal which is the charging power of the charger at the terminal
powerd3          calculate maximum charging power at a depot which is the charging power of the charger at the depot
powern4          charging power should be zero if there is no charger at a terminal
powern5          charging power should be non-negative at a terminal
powerd5          charging power should be non-negative at a depot
demanavgn        calculate average power demand at terminal in each demand period
demanavgd        calculate average power demand at depot in each demand period
demanmaxnp       peak demand at terminal during peak hours
demanmaxno       peak demand at terminal during off peak hours
demanmaxdp       peak demand at depot during peak hours
demanmaxdo       peak demand at depot during off peak hours

elecostc         calculate electricity cost
demcostc         calculate demand cost
buscostc         calculate bus purchase cost
chacostc         calculate charger cost
dricostc         calculate drivers cost

objfun           objective function
;

energydd(m,d,i)$tripF(m,i)..edd(m,d,i) =l= epsilonU*batt(m);
energyft(m,d,i,n)$(tripF(m,i) and tripet(i,n))..eni(m,i,n) =l= edd(m,d,i)-energyDF(m,i)-energyT(m,i);
energybt(m,i,j,n,nn,nnn)$(tripb(m,i,j) and tripet(i,n) and tripet(j,nn) and tripst(j,nnn))..eni(m,j,nn) =l= eni(m,i,n)-energyD(m,i,j)+eoi(m,j,nnn)-energyT(m,j);
energyad(m,j,n,d)$(tripL(m,j) and tripet(j,n))..ead(m,j,d) =l= eni(m,j,n)-energyLD(m,j);
energysd(m,i,j,d)$(tripF(m,i) and tripL(m,j))..ead(m,j,d)+eod(m,d) =g= edd(m,d,i);
energymt(m,i,n)$(trips(m,i) and not tripF(m,i) and tripst(i,n))..eoi(m,i,n) =l= sum(t$timei(m,i,n,t), pn(m,i,n,t)*rho);
energymd(m,d)..eod(m,d) =l= sum(t$timed(m,t), pd(m,d,t)*rho);
energylo1(m,i,n)$(trips(m,i) and (tripet(i,n) or tripst(i,n)))..eni(m,i,n) =g= epsilonL*batt(m);
energylo2(m,i,d)$tripL(m,i)..ead(m,i,d) =g= epsilonL*batt(m);
energyup1(m,i,n)$(trips(m,i) and (tripet(i,n) or tripst(i,n)))..eni(m,i,n) =l= epsilonU*batt(m);
energyup2(m,i,d)$tripL(m,i)..ead(m,i,d) =l= epsilonU*batt(m);     
powern1(m,i,n,t)$timei(m,i,n,t)..pn(m,i,n,t) =l= p_bus_bar;
powerd1(m,d,t)$timed(m,t)..pd(m,d,t)=l= p_bus_bar;
powern2(m,i,n,t)$(not timei(m,i,n,t) and trips(m,i) and tripst(i,n))..pn(m,i,n,t) =e= 0;
powerd2(m,d,t)$(not timed(m,t))..pd(m,d,t) =e= 0;
powern3(n,t)..pmaxn(n) =g= sum(m,sum(i$(trips(m,i) and tripst(i,n)),pn(m,i,n,t)));
powerd3(d,t)..pmaxd(d) =g= sum(m,pd(m,d,t));
powern4(n)..pmaxn(n) =l= chastation(n)*mm;
powern5(m,i,n,t)$timei(m,i,n,t)..pn(m,i,n,t) =g= 0;
powerd5(m,d,t)$timed(m,t)..pd(m,d,t) =g= 0;
demanavgn(n,zeta)..pavgn(n,zeta) =e= sum(t$Btao(zeta, t), sum(m, sum(i$(trips(m,i) and tripst(i,n)),pn(m,i,n,t)*rho)))/gama;
demanavgd(d,zeta)..pavgd(d,zeta) =e= sum(t$Btao(zeta, t), sum(m, pd(m,d,t)*rho))/gama;
demanmaxnp(n,zeta)$Bzeta1(zeta)..ppeaknp(n) =g= pavgn(n,zeta);
demanmaxno(n,zeta)$Bzeta2(zeta)..ppeakno(n) =g= pavgn(n,zeta);
demanmaxdp(d,zeta)$Bzeta1(zeta)..ppeakdp(d) =g= pavgd(d,zeta);
demanmaxdo(d,zeta)$Bzeta2(zeta)..ppeakdo(d) =g= pavgd(d,zeta);

elecostc..elecost =e= sum(zeta$Bzeta1(zeta), sum(t$Btao(zeta, t), sum(n, sum(m, sum(i$(trips(m,i) and tripst(i,n)),pn(m,i,n,t)*rho)))))*elecostp
+ sum(zeta$Bzeta1(zeta), sum(t$Btao(zeta, t), sum(d, sum(m, pd(m,d,t)*rho))))*elecostp
+ sum(zeta$Bzeta2(zeta), sum(t$Btao(zeta, t), sum(n, sum(m, sum(i$(trips(m,i) and tripst(i,n)), pn(m,i,n,t)*rho)))))*elecosto
+ sum(zeta$Bzeta2(zeta), sum(t$Btao(zeta, t), sum(d, sum(m, pd(m,d,t)*rho))))*elecosto;
demcostc..demcost =e= ((sum(n, ppeaknp(n)) + sum(d, ppeakdp(d)))*demcostp + (sum(n, ppeakno(n)) + sum(d, ppeakdo(d)))*demcosto)/30;

buscostc..buscost =e= sum(m,bus_price+batt_price*batt(m));
chacostc..chacost =e= sum(n,chastation(n)*(char_fix+char_var*pmaxn(n)))+char_fix+sum(d,char_var*pmaxd(d));
dricostc..dricost =e= sum(m,opertime(m))/60*salary;


objfun..objvalue =e= elecost + demcost + buscost + chacost + dricost;

model chargingcostmin /energydd,energyft,energybt,energyad,energysd,energymt,energymd,energylo1,energylo2,energyup1,energyup2,powern1
powerd1,powern2,powerd2,powern3,powerd3,powern4,powern5,powerd5,demanavgn,demanavgd,demanmaxnp,demanmaxno,demanmaxdp,demanmaxdo,elecostc,demcostc,buscostc,chacostc,dricostc,objfun/;

solve chargingcostmin using LP minimizing objvalue;




