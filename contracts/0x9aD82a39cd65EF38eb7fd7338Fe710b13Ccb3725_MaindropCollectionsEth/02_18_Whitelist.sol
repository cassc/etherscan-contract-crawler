// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    struct WhitelistItem {
        address walletAddress;
        uint count;
    }

    mapping(address => uint) private _whitelistAddresses;
    mapping(address => bool) private _allowedContracts;

    modifier onlyAllowedContractsOrOwner() {
        require(owner() == _msgSender() || _allowedContracts[_msgSender()] == true, "caller is not the allowed contracts");
        _;
    }

    function checkAllowedContracts(address _allowedContract) view public returns (bool) {
        return _allowedContracts[_allowedContract];
    }

    function addAllowedContract(address _contractAddress) public onlyOwner {
        _allowedContracts[_contractAddress] = true;
    }

    function setWhitelistAddress(WhitelistItem memory whitelistAddress) public onlyAllowedContractsOrOwner
    {
        _whitelistAddresses[whitelistAddress.walletAddress] = whitelistAddress.count;
    }

    function setWhitelistAddresses(WhitelistItem[] memory whitelistAddresses) public onlyAllowedContractsOrOwner {
        for (uint i = 0; i < whitelistAddresses.length; i++) {
            _whitelistAddresses[whitelistAddresses[i].walletAddress] = whitelistAddresses[i].count;
        }
    }

    function checkWhitelistAddress(address _walletAddress) public view returns (uint) {
        return _whitelistAddresses[_walletAddress];
    }
}