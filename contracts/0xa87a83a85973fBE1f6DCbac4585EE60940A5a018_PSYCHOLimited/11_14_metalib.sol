// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library metalib {
    function moods(
        uint256 mood
    ) internal pure returns (string memory) {
        if (mood == 1) {return "Xanxiety";}
        else if (mood == 2) {return "gotcha";}
        else if (mood == 3) {return "RAMBO";}
        else if (mood == 4) {return "Temper";}
        else if (mood == 5) {return "sensitive";}
        else if (mood == 6) {return "Black Ops";}
        else if (mood == 7) {return "cypherpunk";}
        else if (mood == 8) {return "distant memory";}
        else if (mood == 9) {return "CENSORED";}
        else if (mood == 10) {return "Forgive me i have sinned";}
        else if (mood == 11) {return "Special Ops";}
        else if (mood == 12) {return "Agent of terror";}
        else if (mood == 13) {return "Wonderful";}
        else if (mood == 14) {return "3..2..1..";}
        else if (mood == 15) {return "Bulletproof";}
        else if (mood == 16) {return "Maximum capacitance";}
        else if (mood == 17) {return "Sign of God";}
        else if (mood == 18) {return "run";}
        else if (mood == 19) {return "Don't trend on me";}
        else if (mood == 20) {return "Liberator";}
        else {return "Vril";}
    }

    function grades(
        uint256 grade
    ) internal pure returns (string memory) {
        if (grade == 1) {return "2SS";}
        else if (grade == 2) {return "5";}
        else if (grade == 3) {return "V";}
        else if (grade == 4) {return "M";}
        else if (grade == 5) {return "XXX";}
        else {return "Z";}
    }
}