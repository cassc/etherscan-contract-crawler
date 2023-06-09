// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/tokens/ERC20.sol";

/*
    https://onlyfanseth.xyz
    https://t.me/onlyfanseth

    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⠛⠋⠉⠙⠻⠿⠿⠿⠿⢿⣿⣿⣿⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠄⠄⠄⠄⠄⠄⠄⠄⠹⣿⣿⣶⣶⣦⣬⢹⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠄⠄⠄⣰⣧⡀⠄⠄⠄⠄⠈⢙⡋⣿⣿⣿⢸⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠄⠄⠰⠼⢯⣿⣿⣦⣄⠄⠄⠄⠈⢡⣿⣿⣿⢸⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠄⠄⠸⠤⠕⠛⠙⠷⣿⡆⠄⠄⠄⣸⣿⣿⡏⣼⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⣴⣿⣿⣿⢡⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⡟⠄⠄⠄⠄⠄⣄⠄⢀⠄⠄⢀⣤⣾⣿⣿⣿⢃⣾⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⠿⣛⣡⣄⣀⠄⠠⢴⣿⣿⡿⣄⣴⣿⣿⣿⣿⣿⢃⣾⣿⣿⣿⣿
    ⣿⣿⣿⣿⣿⡏⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣩⡽⡁⢸⣿⣿⣿⣿⣿
    ⣿⣿⣿⣿⣿⢃⣿⣿⢟⣿⣿⣿⣿⣿⣮⢫⣿⣿⣿⣿⣿⣟⢿⠃⠄⢻⣿⣿⣿⣿
    ⣿⣿⣿⣿⡿⣸⠟⣵⣿⣿⣿⣿⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣷⣄⢰⡄⢿⣿⣿⣿
    ⣿⣿⣿⣿⡇⠏⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠹⡎⣿⣿⣿
    ⣭⣍⠛⠿⠄⢰⠋⡉⠹⣿⣿⣿⣿⣿⣿⠙⣿⣿⣿⣿⣿⣿⡟⢁⠙⡆⢡⣿⣿⣿
    ⠻⣿⡆⠄⣤⠈⢣⣈⣠⣿⣿⣿⣿⣿⠏⣄⠻⣿⣿⣿⣿⣿⣆⣈⣴⠃⣿⣿⣿⣿
    ⡀⠈⢿⠄⣿⡇⠄⠙⠿⣿⡿⠿⢋⣥⣾⣿⣷⣌⠻⢿⣿⣿⡿⠟⣡⣾⣿⣿⠿⢋
    ⠛⠳⠄⢠⣿⠇⠄⣷⡑⢶⣶⢿⣿⣿⣿⣽⣿⣿⣿⣶⣶⡐⣶⣿⠿⠛⣩⡄⠄⢸
*/

contract OnlyFans is ERC20 {
    constructor() ERC20("OnlyFans", "ONLYFANS", 18) {
        _mint(msg.sender, 69_420_000_000 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function freeTitties() public pure returns (string memory) {
        return unicode"(｡)(｡)";
    }
}