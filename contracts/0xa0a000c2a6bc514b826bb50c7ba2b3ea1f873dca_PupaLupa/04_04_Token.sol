// SPDX-License-Identifier: MIT


/* 
Лупа и Пупа устроились на работу. Проработали целый месяц, 
трудились не покладая рук и не жалея живота своего. 
В конце месяца Лупа и Пупа пошли получать зарплату. 
В бухгалтерии все как обычно перепутали. 
И, в итоге, Лупа получил за Пупу, а Пупа за ЛУПУ! 

ルパとプパは仕事を得た。彼らは1ヶ月間働いた、 
努力を惜しまず、懸命に働いた。
月末にルパとプパは給料をもらいに行った。
経理部では、いつものようにすべてが混乱していた。
その結果、ルパはプパの分を受け取り、プパはルパの分を受け取った！

Lupa und Pupa bekamen einen Job. Sie arbeiteten einen Monat lang, 
Sie arbeiteten hart und scheuten keine Mühe. 
Am Ende des Monats holten Lupa und Pupa ihr Gehalt ab. 
In der Buchhaltung war, wie immer, alles durcheinander. 
Und so bekam Lupa für Pupa, und Pupa für Lupa!

Lupa and Pupa got a job. They worked for a month, 
They worked hard and spared no effort. 
At the end of the month Lupa and Pupa went to get their salaries. 
In the accounting department, as usual, everything was mixed up. 
And, as a result, Lupa received for Pupa, and Pupa for Lupa!
*/

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract PupaLupa is ERC20 {
    constructor() ERC20("Poopa", unicode"лупа") {
        _mint(msg.sender, 420420420420 * 10 ** decimals());
    }
}