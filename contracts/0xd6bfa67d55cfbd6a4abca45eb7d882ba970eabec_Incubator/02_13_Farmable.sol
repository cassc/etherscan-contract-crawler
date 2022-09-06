// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Farmable {
    event NewFarmer(address indexed _farmer);
    event FarmAbandoned(address indexed _farmer);

    address public farmer;

    constructor() {
        _setFarmer(msg.sender);
    }

    function setFarmer(address _farmer) public onlyFarmer {
        require(_farmer != address(0), "abandon your farm");
        _setFarmer(_farmer);
    }

    function abandonFarm() public onlyFarmer {
        farmer = address(0);
        emit FarmAbandoned(msg.sender);
    }

    function _setFarmer(address _farmer) internal {
        farmer = _farmer;
        emit NewFarmer(_farmer);
    }

    modifier onlyFarmer() {
        require(msg.sender == farmer, "you are not the farmer");
        _;
    }

    // for the city folk

    function owner() public view virtual returns (address) {
        return farmer;
    }
}