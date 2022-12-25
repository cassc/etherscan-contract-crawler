// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AiFRENSPAYMENT is Ownable, ReentrancyGuard {

    function purchase(address _ownerAddress) payable public nonReentrant {
        uint256 balance = address(this).balance;
        payable(_ownerAddress).transfer((balance*10)/100);
        payable(0xD49b576a94Cef31D8C54251F112B9579Fa29f41C).transfer((balance*90)/100);
    }
}