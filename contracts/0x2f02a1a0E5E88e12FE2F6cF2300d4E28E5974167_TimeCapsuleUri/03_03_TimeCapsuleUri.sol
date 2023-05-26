// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Author: TOYMAKERSⓒ
// Drop: #1
// Project: TIME CAPSULE
/*
*******************************************************************************
          |                   |                  |                     |
 _________|________________.=""_;=.______________|_____________________|_______
|                   |  ,-"_,=""     `"=.|                  |
|___________________|__"=._o`"-._        `"=.______________|___________________
          |                `"=._o`"=._      _`"=._                     |
 _________|_____________________:=._o "=._."_.-="'"=.__________________|_______
|                   |    __.--" , ; `"=._o." ,-"""-._ ".   |
|___________________|_._"  ,. .` ` `` ,  `"-._"-._   ". '__|___________________
          |           |o`"=._` , "` `; .". ,  "-._"-._; ;              |
 _________|___________| ;`-.o`"=._; ." ` '`."\` . "-._ /_______________|_______
|                   | |o;    `"-.o`"=._``  '` " ,__.--o;   |
|___________________|_| ;     (#) `-.o `"=.`_.--"_o.-; ;___|___________________
____/______/______/___|o;._    "      `".o|o_.--"    ;o;____/______/______/____
/______/______/______/_"=._o--._        ; | ;        ; ;/______/______/______/_
____/______/______/______/__"=._o--._   ;o|o;     _._;o;____/______/______/____
/______/______/______/______/____"=._o._; | ;_.--"o.--"_/______/______/______/_
____/______/______/______/______/_____"=.o|o_.--""___/______/______/______/____
/______/______/______/______/______/______/______/______/______/______/
*/

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

struct TimeLeft {
    string year;
    string day;
    string hour;
    string minute;
    string second;
}

contract TimeCapsuleUri {
    using Strings for uint256;

    function GetUri(TimeLeft memory timeLeft, string memory contractName, string memory buriedTokenId, address burier) public view virtual returns (string memory) {
        return Base64.encode(abi.encodePacked('<svg viewBox="0 0 1658 987" xmlns="http://www.w3.org/2000/svg"><mask id="a" fill="#fff"><path fill-rule="evenodd" clip-rule="evenodd" d="M121.055 154.395c0-85.052 68.948-154 154-154h1132c85.05 0 154 68.948 154 154v84h73c11.05 0 20 8.954 20 20v471c0 11.046-8.95 20-20 20h-73v84c0 85.052-68.95 154-154 154h-1132c-85.052 0-154-68.948-154-154v-84h-98c-11.046 0-20-8.954-20-20v-471c0-11.046 8.954-20 20-20h98v-84Z"/></mask><path fill-rule="evenodd" clip-rule="evenodd" d="M121.665 154.602c0-85.052 68.948-154 154-154h1132c85.05 0 154 68.948 154 154v84h73c11.05 0 20 8.954 20 20v471c0 11.046-8.95 20-20 20h-73v84c0 85.052-68.95 154-154 154h-1132c-85.052 0-154-68.948-154-154v-84h-98c-11.046 0-20-8.954-20-20v-471c0-11.046 8.954-20 20-20h98v-84Z" fill="#F7F0E4"/><path d="M1561.055 238.395h-20v20h20v-20Zm0 511v-20h-20v20h20Zm-1440 0h20v-20h-20v20Zm0-511v20h20v-20h-20Zm154-258c-96.098 0-174 77.902-174 174h40c0-74.006 59.994-134 134-134v-40Zm1132 0h-1132v40h1132v-40Zm174 174c0-96.098-77.9-174-174-174v40c74.01 0 134 59.994 134 134h40Zm0 84v-84h-40v84h40Zm-20 20h73v-40h-73v40Zm73 0 .02.001c.01 0 .01 0 0-.001l-.01-.003c-.01-.002-.01-.004-.02-.005 0-.003-.01-.005 0-.004 0 .002 0 .006.01.012s.01.011.01.014v-.008c0-.004-.01-.008-.01-.013v-.017.024h40c0-22.091-17.91-40-40-40v40Zm0 0v471h40v-471h-40Zm0 471v.024-.017c0-.005.01-.009.01-.013v-.008c0 .003 0 .008-.01.014s-.01.01-.01.012c-.01.001 0-.001 0-.004.01-.001.01-.003.02-.005l.01-.003c.01-.001.01-.001 0-.001l-.02.001v40c22.09 0 40-17.909 40-40h-40Zm0 0h-73v40h73v-40Zm-53 104v-84h-40v84h40Zm-174 174c96.1 0 174-77.902 174-174h-40c0 74.006-59.99 134-134 134v40Zm-1132 0h1132v-40h-1132v40Zm-174-174c0 96.098 77.902 174 174 174v-40c-74.006 0-134-59.994-134-134h-40Zm0-84v84h40v-84h-40Zm-78 20h98v-40h-98v40Zm-40-40c0 22.091 17.909 40 40 40v-40l-.024-.001.003.001.014.003.013.005.008.004-.014-.012-.012-.014.004.008.005.013.003.014.001.003-.001-.024h-40Zm0-471v471h40v-471h-40Zm40-40c-22.091 0-40 17.909-40 40h40l.001-.024-.001.003-.003.014-.005.013-.004.008.012-.014.014-.012-.008.004-.013.005-.014.003-.003.001.024-.001v-40Zm98 0h-98v40h98v-40Zm-20-64v84h40v-84h-40Z" fill="#ECD8BA" mask="url(#a)"/><rect x="466.055" y="471.958" width="61" height="47" rx="3" fill="#D5B290"/><rect x="284.055" y="470.958" width="61" height="47" rx="3" fill="#D5B290"/><rect x="631.985" y="470.958" width="61" height="47" rx="3" fill="#D5B290"/><rect x="829.341" y="470.958" width="61" height="47" rx="3" fill="#D5B290"/><rect x="1056.51" y="468.042" width="61" height="47" rx="3" fill="#D5B290"/><path stroke="#F5E6CE" stroke-width="15" stroke-linecap="round" stroke-dasharray="30 30" d="m137.502 289.948-2.894 409m1410.897-408-2.9 409"/><text style="fill:#333;font-family:&quot;Courier New&quot;;font-size:36.5px;white-space:pre" x="287.121" y="325.129"><tspan x="353.062" y="503.209" style="font-size:36.5px;word-spacing:0">years</tspan></text><text style="fill:#333;font-family:&quot;Courier New&quot;;font-size:36.5px;white-space:pre" x="538.397" y="505.82">days</text><text style="fill:#333;font-family:Courier New;font-size:36.5px;white-space:pre" x="362.821" y="532.652"><tspan x="706.764" y="504.515" style="font-size:36.5px;word-spacing:0">hours</tspan></text><text style="fill:#333;font-family:Courier New;font-size:36.5px;white-space:pre" x="239.694" y="387.778"><tspan x="896.879" y="504.515" style="font-size:36.5px;word-spacing:0">minutes</tspan></text><text style="fill:#333;font-family:Courier New;font-size:36.5px;white-space:pre" x="283.512" y="452.27">Opens in:</text><text style="fill:#333;font-family:&quot;Courier New&quot;;font-size:36.5px;text-anchor:middle;white-space:pre" x="313.212" y="506.895">', timeLeft.year, '</text><text style="fill:#333;font-family:&quot;Courier New&quot;;font-size:36.5px;text-anchor:middle;white-space:pre" x="495.936" y="507.548">', timeLeft.day, '</text><text style="fill:#333;font-family:&quot;Courier New&quot;;font-size:36.5px;text-anchor:middle;white-space:pre" x="661.693" y="507.548">', timeLeft.hour, '</text><text style="fill:#333;font-family:&quot;Courier New&quot;;font-size:36.5px;text-anchor:middle;white-space:pre" x="860.113" y="507.548">', timeLeft.minute, '</text><text style="fill:#333;font-family:&quot;Courier New&quot;;font-size:36.5px;text-anchor:middle;white-space:pre" x="1085.857" y="504.937">', timeLeft.second, '</text><text style="fill:#cbb798;font-family:Courier New;font-size:93px;font-weight:700;white-space:pre;text-anchor:middle" x="829.117" y="173.936">Toymakers Present</text><text style="fill:#333;font-family:Courier New;font-size:97px;font-weight:700;text-anchor:middle;white-space:pre" x="829.117" y="288.634">TIME CAPSULE TICKET</text><text style="fill:#333;font-family:Courier New;font-size:46.2px;white-space:pre" x="272.485" y="735.457">', contractName, ' #', buriedTokenId, '</text><text style="fill:#cbb798;font-family:Courier New;font-size:46.2px;white-space:pre" x="231.984" y="258.085"><tspan x="271.968" y="784.473" style="font-size:46.2px;word-spacing:0">was buried in 2023 by</tspan></text><text style="fill:#333;font-family:Courier New;font-size:46.2px;white-space:pre" x="273.283" y="833.488">', Strings.toHexString(uint256(uint160(burier)), 20), '</text><text style="fill:#333;font-family:Courier New;font-size:36.5px;white-space:pre" x="283.512" y="452.27" transform="translate(843.777 50.745)">seconds<tspan x="283.512" dy="1em"></tspan></text></svg>'));
    }

    function GetMetadata(TimeLeft memory timeLeft, string memory contractName, string memory buriedTokenId, address burier, address buriedTokenAddress, string memory digUpDate, string memory tokenId) external view virtual returns (string memory) {
        string memory metadata = string(abi.encodePacked('data:application/json,{"name": "Time Capsule Ticket #', tokenId, '", "description": "A deposit stub for the 2053 Time Capsule. Made by Toymakers", "attributes": [{"display_type": "date", "trait_type": "Capsule Open", "value":', digUpDate, '}, {"trait_type": "Buried Token Address", "value":"', Strings.toHexString(uint256(uint160(buriedTokenAddress)), 20), '"}, {"trait_type": "Buried Token Id", "value":"', tokenId, '"}, {"trait_type": "Buried Token Name", "value":"', contractName, '"}], "image": "data:image/svg+xml;base64,', GetUri(timeLeft, contractName, buriedTokenId, burier), '"}'));
        return metadata;
    }
}