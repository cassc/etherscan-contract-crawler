pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract UpgradeableHelper is OwnableUpgradeable {
    mapping(address=>bool) public helper;

    modifier onlyHelper() {
        _checkHelper();
        _;
    }

    function __setHelper() internal onlyInitializing {
        helper[msg.sender] = true;
    }

    function _checkHelper() internal view virtual {
        require(helper[msg.sender] == true, "Helper: caller is not the Helper");
    }

    function setHelper(address _address, bool _isHelper) public onlyHelper{
        helper[_address] = _isHelper;
    }

}