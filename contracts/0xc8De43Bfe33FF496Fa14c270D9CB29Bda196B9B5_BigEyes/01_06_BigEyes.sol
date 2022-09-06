// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract BigEyes is ERC20, Ownable {
    uint8 private _decimals;
    mapping(address => bool) public blacklisted;
    event LogAddToBlacklist(address[] indexed blacklisted);
    event LogRemoveFromBlacklist(address[] indexed removed);
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {       
        _decimals=__decimals;
        _mint(msg.sender, _totalSupply);
    }
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        require(!blacklisted[from] && !blacklisted[to], "ERC20: blacklisted address");
    }

    function addToBlacklist(address[] memory _accounts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            blacklisted[_accounts[i]] = true;
        }
        emit LogAddToBlacklist(_accounts);
    }

    function removeFromBlacklist(address[] memory _accounts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            blacklisted[_accounts[i]] = false;
        }
        emit LogRemoveFromBlacklist(_accounts);
    }
}