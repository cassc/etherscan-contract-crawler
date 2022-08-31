pragma solidity >=0.5.16;

import "./EnumerableSet.sol";
import "./owned.sol";

contract LendingWhiteList is owned {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelist;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    constructor() public {
    }

    modifier onlyWhitelisted {
        require(isWhitelisted(msg.sender), "LendingWhiteList: caller is not in whitelist");
        _;
    }

    function add(address _address) public onlyOwner returns(bool) {
        require(_address != address(0), "LendingWhiteList: _address is the zero address");
        EnumerableSet.add(_whitelist, _address);
        emit AddedToWhitelist(_address);
        return true;
    }

    function remove(address _address) public onlyOwner returns(bool) {
        require(_address != address(0), "LendingWhiteList: _address is the zero address");
        EnumerableSet.remove(_whitelist, _address);
        emit RemovedFromWhitelist(_address);
        return true;
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return EnumerableSet.contains(_whitelist, _address);
    }
}