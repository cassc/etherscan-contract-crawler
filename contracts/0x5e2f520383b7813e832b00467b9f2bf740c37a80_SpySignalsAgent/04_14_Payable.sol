// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Payable
/// @author @MilkyTasteEth MilkyTaste:8662 https://milkytaste.xyz
/// Manage payables

import "@openzeppelin/contracts/access/Ownable.sol";

contract Payable is Ownable {
    address private constant ADDR1 = 0x4c54b734471EF8080C5c252e5588F625D2e5E93E;
    address private constant ADDR2 = 0xE9971063262e10e97Cd778ba85eEbCA656942c59;
    address private constant ADDR3 = 0x686e2dCb4a37D6342ce20F3f8D418f42DbBB5352;
    address private constant ADDR4 = 0x5be495FFE3C171babdDd16AFb8BA816deF29d26c;
    address private constant ADDR5 = 0x390DbD52ac3583ee7F61105F76bf82Fa88fFEf90;
    address private constant ADDR6 = 0x36a23D03faa1A23cAF019C7F9a17d59e3B783A2B;

    /**
     * Withdraw funds
     */
    function withdraw() external onlyOwner {
        uint256 bal = address(this).balance;
        payable(ADDR1).transfer(bal * 10 / 100);
        payable(ADDR2).transfer(bal * 5 / 100);
        payable(ADDR3).transfer(bal * 28 / 100);
        payable(ADDR4).transfer(bal * 28 / 100);
        payable(ADDR5).transfer(bal * 28 / 100);
        payable(ADDR6).transfer(address(this).balance); // The rest
    }
}