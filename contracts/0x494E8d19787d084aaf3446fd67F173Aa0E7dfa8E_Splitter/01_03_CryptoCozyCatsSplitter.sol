// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ISplitter {
    function split() external;
}

contract Splitter is ISplitter, Ownable {
    address public ownerAddress;
    address public devAddress;
    address public charityAddress;

    uint256 public ownerPercentage;
    uint256 public devPercentage;
    uint256 public charityPercentage;

    constructor() {
        ownerAddress = msg.sender;
        devAddress = msg.sender;
        charityAddress = msg.sender;

        ownerPercentage = 60;
        devPercentage = 20;
        charityPercentage = 20;
    }

    function setOwnerAddress(address _addr) public onlyOwner {
        ownerAddress = _addr;
    }

    function setDevAddress(address _addr) public onlyOwner {
        devAddress = _addr;
    }

    function setCharityAddress(address _addr) public onlyOwner {
        charityAddress = _addr;
    }

    function setOwnerPercentage(uint256 _perc) public onlyOwner {
        ownerPercentage = _perc;
    }

    function setDevPercentage(uint256 _perc) public onlyOwner {
        devPercentage = _perc;
    }

    function setCharityPercentage(uint256 _perc) public onlyOwner {
        charityPercentage = _perc;
    }

    fallback() external payable {}

    receive() external payable {}

    function split() external onlyOwner {
        uint256 totBalance = address(this).balance;

        (bool hs1, ) = payable(ownerAddress).call{
            value: (totBalance * ownerPercentage) / 100
        }("");
        require(hs1);

        (bool hs2, ) = payable(devAddress).call{
            value: (totBalance * devPercentage) / 100
        }("");
        require(hs2);

        (bool hs3, ) = payable(charityAddress).call{
            value: (totBalance * charityPercentage) / 100
        }("");
        require(hs3);
    }
}