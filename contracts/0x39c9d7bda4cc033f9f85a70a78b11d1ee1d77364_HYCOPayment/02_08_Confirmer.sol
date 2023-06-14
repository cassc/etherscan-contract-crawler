// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Confirmer is Ownable {

    event AddConfirmer (address account);
    event RemoveConfirmer (address account);
    event Confirmed (address account, uint256 confirmedTime);
    
    struct ConfirmInfo {
        bool confirmed;
        uint256 validTime;
    }
    
    mapping(address => ConfirmInfo) private _confirmInfos;

    address[] public _confirmers;

    constructor() {
    }

    modifier isConfirmed() {
        require(_checkConfirmed(), "Insufficient execution conditions.");
        _;
    }

    modifier isConfirmer(address walletAddress) {
        require(_checkConfirmer(walletAddress), "This address or caller is not the confirmer.");
        _;
    }

    function _checkConfirmed() 
        internal
        view
        returns (bool)
    {
        uint8 confirmedCount = 0;
        for (uint8 i = 0; i < _confirmers.length; i++) {
            if (_confirmInfos[_confirmers[i]].confirmed == true 
                && _confirmInfos[_confirmers[i]].validTime > block.timestamp) 
            {
                confirmedCount++;
            }
        }

        if (confirmedCount > 1) return true;
        else return false;
    }

    function _checkConfirmer(address walletAddress)
        internal
        view
        returns (bool)
    {
        for (uint8 i = 0; i < _confirmers.length; i++) {
            if (_confirmers[i] == walletAddress) {
                return true;
            }
        }

        return false;
    }    

    function addConfirmer(address walletAddress) 
        public
        onlyOwner
        isConfirmed
    {
        require(!_checkConfirmer(walletAddress), "Aleady exist confirmer.");

        _confirmers.push(walletAddress);
        _resetConfirmed();

        emit AddConfirmer(walletAddress);
    }

    function removeConfirmer(address walletAddress)
        public
        onlyOwner
        isConfirmed
        isConfirmer(walletAddress)
    {
        require(_confirmers.length > 3, "Must be at least 3 confirmers.");
        uint8 j = 0;
        for (uint8 i = 0; i < _confirmers.length; i++) {
            if (_confirmers[i] != walletAddress) {
                _confirmers[j] = _confirmers[i];
                j++;
            } else if (_confirmers[i] == walletAddress){
                delete _confirmers[i];
                delete _confirmInfos[_confirmers[i]];
            }
        }

        _confirmers.pop();
        _resetConfirmed();

        emit RemoveConfirmer (walletAddress);
    }

    function _resetConfirmed()
        internal
    {
        require((_checkConfirmer(msg.sender) || msg.sender == owner()), "Caller is not the owner or confirmer.");
        for (uint8 i = 0; i < _confirmers.length; i++) {
            _confirmInfos[_confirmers[i]].confirmed = false;
            _confirmInfos[_confirmers[i]].validTime = block.timestamp;
        }     
    }

    function toConfirm()
        public
        isConfirmer(msg.sender)
    {
        _confirmInfos[msg.sender].confirmed = true;
        _confirmInfos[msg.sender].validTime = block.timestamp + 21600;

        emit Confirmed(msg.sender, block.timestamp);
    }

    function getConfirmer() 
        public
        view
        onlyOwner
        returns (address[] memory) 
    {
        return (_confirmers);
    }

    function getConfirmed(address walletAddress) 
        public
        view
        onlyOwner
        returns (bool, uint256)
    {
        return (_confirmInfos[walletAddress].confirmed, _confirmInfos[walletAddress].validTime);
    }    

}