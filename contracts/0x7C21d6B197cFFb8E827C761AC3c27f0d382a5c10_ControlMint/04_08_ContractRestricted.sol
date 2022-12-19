//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract ContractRestricted is Ownable {
    address private _accessContract;

    constructor(address accessContract) {
        _setAccessContract(accessContract);
    }

    function getContractAccessAddress() public view returns (address) {
        return _accessContract;
    }

    modifier onlyContract() {
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

    function isContract() public view returns (bool) {
        console.log(
            _msgSender(),
            owner(),
            getContractAccessAddress(),
            getContractAccessAddress() == _msgSender()
        );
        return getContractAccessAddress() == _msgSender();
    }

    function setAccessContract(address accessContract) public onlyOwner {
        _setAccessContract(accessContract);
    }

    function _setAccessContract(address accessContract) private {
        _accessContract = accessContract;
    }
}