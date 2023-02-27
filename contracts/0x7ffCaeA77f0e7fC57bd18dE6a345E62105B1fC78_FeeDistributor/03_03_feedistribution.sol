// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract FeeDistributor is Ownable {
    address payable address1 = payable(0x9a1d70D69Fa9E6B48866f77265E7bc042B0ee862);
    address payable address2 = payable(0xA97Ba1bceF4DD65d69008429f4866c658f175160);
    address payable address3 = payable(0x678a2fc326dEE5d986C48Ee75992F784Ab3a561c);
    address payable address4 = payable(0x8406B19D6e8A39134723F023Cb75a6d21D02F919);
    uint256 percentage1 = 20;
    uint256 percentage2 = 50;
    uint256 percentage3 = 20;

    function setAddress1(address payable _address) public onlyOwner {
        address1 = payable(_address);
    }

    function setAddress2(address payable _address) public onlyOwner {
        address2 = payable(_address);
    }

    function setAddress3(address payable _address) public onlyOwner {
        address3 = payable(_address);
    }

    function setAddress4(address payable _address) public onlyOwner {
        address4 = payable(_address);
    }

    function setPercentage1(uint256 _percentage) public {
        percentage1 = _percentage;
    }

    function setPercentage2(uint256 _percentage) public {
        percentage2 = _percentage;
    }

    function setPercentage3(uint256 _percentage) public {
        percentage3 = _percentage;
    }

    function checkAddress1() public view returns(address, uint256) {
        return (address1, percentage1);
    }

    function checkAddress2() public view returns(address, uint256) {
        return (address2, percentage2);
    }

    function checkAddress3() public view returns(address, uint256) {
        return (address3, percentage3);
    }

    function checkAddress4() public view returns(address, uint256) {
        uint256 _address4Percentage = 100 - (percentage1 + percentage2 + percentage3);
        return (address4, _address4Percentage);
    }
    
    fallback() external payable {
        uint256 _address1Value = msg.value * percentage1 / 100;
        uint256 _address2Value = msg.value * percentage2 / 100;
        uint256 _address3Value = msg.value * percentage3 / 100;
        uint256 _address4Value = msg.value - _address1Value - _address2Value - _address3Value;
        address1.transfer(_address1Value);
        address2.transfer(_address2Value);
        address3.transfer(_address3Value);
        address4.transfer(_address4Value);
    }
    
    receive() external payable {
        uint256 _address1Value = msg.value * percentage1 / 100;
        uint256 _address2Value = msg.value * percentage2 / 100;
        uint256 _address3Value = msg.value * percentage3 / 100;
        uint256 _address4Value = msg.value - _address1Value - _address2Value - _address3Value;
        address1.transfer(_address1Value);
        address2.transfer(_address2Value);
        address3.transfer(_address3Value);
        address4.transfer(_address4Value);
    }
}