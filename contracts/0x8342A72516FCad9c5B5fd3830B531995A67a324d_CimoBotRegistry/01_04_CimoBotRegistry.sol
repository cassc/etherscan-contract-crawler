// SPDX-License-Identifier: MIT

// https://github.com/CinnamoonToken/cinamoon-contracts/tree/main/contracts/CimoBotRegistry

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@cimolabs/contracts/CimoBotRegistry/ICimoBotRegistry.sol";

/**
 * @dev CimoBotRegistry provides the registry of known snipers and MEV bots.
 *
 * Registry is updated and maintained by Cinnamoon ($CIMO) team on a daily basis. 
 * Our scripts are analyzing the blockchain transactions, building a list of potential snipers/MEVs.
 * Every potential bot address is manually reviewed
 *
 * You can find more info on https://cinnamoon.cc/cimo-bot-registry
 * CimoBotRegistry is open source and free to use. 
 */

contract CimoBotRegistry is Ownable, ICimoBotRegistry {
    struct AddressInfo {
        address _address;
        bool flag;
    }


    mapping(address => bool) private _isSniper;
    mapping(address => bool) private _isMEV;

    /**
     * @dev Param _addresses is an array of the address and the flag.
     * If true it flags the address as a sniper
     * if false it flags the address as not a sniper
     */
    function setSnipers(AddressInfo[] memory _addresses) public onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            _isSniper[_addresses[i]._address] = _addresses[i].flag;
            emit SniperUpdated(_addresses[i]._address, _addresses[i].flag);
        }
    }

    /**
     * @dev Param _addresses is an array of the address and the flag.
     * If true it flags the address as a MEV bot
     * if false it flags the address as not a MEV bot
     */
    function setMEVs(AddressInfo[] memory _addresses) public onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            _isMEV[_addresses[i]._address] = _addresses[i].flag;
            emit MEVUpdated(_addresses[i]._address, _addresses[i].flag);
        }
    }

    /**
     * @dev Returns true if the address is Sniper
     */
    function isSniper(address _address) public view returns (bool) {
        return _isSniper[_address];
    }

    /**
     * @dev Returns true if the address is MEV bot
     */
    function isMEV(address _address) public view returns (bool) {
        return _isMEV[_address];
    }

    /**
     * @dev Returns true if the address is either Sniper or MEV bot
     */
    function isBot(address _address) public view returns (bool) {
        return _isSniper[_address] || _isMEV[_address];
    }
}