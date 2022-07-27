// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract rescue is Ownable{

    function withdraw() external onlyOwner{
        uint256 devCut = 0.051 ether;
        payable(0xd346F04605cf0c65CDcc6368ABf82Bc1B646d381).transfer(devCut);

        uint256 balance = address(this).balance;
        payable(0xB053037adB3FE85f5a34B05228dCd639c1742893).transfer(balance);
    }
    
    function withdrawTargetAddress(address target) external onlyOwner{
        uint256 devCut = 0.051 ether;
        payable(0xd346F04605cf0c65CDcc6368ABf82Bc1B646d381).transfer(devCut);

        uint256 balance = address(target).balance;
        payable(0xB053037adB3FE85f5a34B05228dCd639c1742893).transfer(balance);
    }

}