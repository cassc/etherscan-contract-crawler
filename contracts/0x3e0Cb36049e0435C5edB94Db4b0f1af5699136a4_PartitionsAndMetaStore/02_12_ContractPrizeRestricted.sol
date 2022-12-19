//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ContractPrizeRestricted is Ownable {
    address private _accessContract;
    address private _accessContractPrize;

    constructor(address accessContract, address accessContractPrize) {
        _setAccessContract(accessContract);
        _setAccessContractPrize(accessContractPrize);
    }

    function getContractAccessAddress() public view returns (address) {
        return _accessContract;
    }

    function getContractPrizeAccessAddress() public view returns (address) {
        return _accessContractPrize;
    }

    modifier onlyContract() {
        require(isContract(), "Storage: caller is not allowed");
        _;
    }

    modifier onlyContractPrize() {
        require(isContract(), "Storage: caller is not allowed");
        _;
    }

    modifier onlyOwnerOrContract() {
        require(
            isContract() || owner() == msg.sender,
            "You are not allowed to perform this opration"
        );
        _;
    }

    modifier onlyOwnerOrContractPrize() {
        require(
            isContract() || owner() == msg.sender,
            "You are not allowed to perform this opration"
        );
        _;
    }

    function isContract() public view returns (bool) {
        return getContractAccessAddress() == _msgSender();
    }

    function isContractPrize() public view returns (bool) {
        return getContractPrizeAccessAddress() == _msgSender();
    }

    function setAccessContract(address accessContract) public onlyOwner {
        _setAccessContract(accessContract);
    }

    function setAccessContractPrize(address accessContract) public onlyOwner {
        _setAccessContractPrize(accessContract);
    }

    function _setAccessContract(address accessContract) private {
        _accessContract = accessContract;
    }

    function _setAccessContractPrize(address accessContract) private {
        _accessContractPrize = accessContract;
    }
}