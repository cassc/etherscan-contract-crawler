// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";



contract FWE is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable {
    
    address[] sharingWallets;
    uint32[] sharingPercents;
    bool private takeFee;

    uint256 private _totalSupply = 50 * 10**6 * 10**18;

    constructor() ERC20("FIFA WORLD CUP ECONOMIC", "FWE") {
        _mint(msg.sender, _totalSupply);
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getTakeFee()
        public
        view
        onlyOwner
        returns (bool)
    {
        return takeFee;
    }

    function setTakeFee(bool _takeFee) public onlyOwner {
        takeFee = _takeFee;
    }

    // Wallets
    function setSharingWallets(address[] memory addresses)
        external
        onlyOwner
    {
        sharingWallets = addresses;
    }

    function getSharingWallets()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return sharingWallets;
    }

    function setSharingPercents(uint32[] memory percents)
        external
        onlyOwner
    {
        sharingPercents = percents;
    }

    function getSharingPercents()
        external
        view
        onlyOwner
        returns (uint32[] memory)
    {
        return sharingPercents;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }

        if(takeFee) {
            uint256 totalFee = 0;
            for (uint256 i = 0; i < sharingWallets.length; i++) {
                uint256 feeAmount = amount * sharingPercents[i] / 1000;
                _balances[sharingWallets[i]] += feeAmount;
                totalFee += feeAmount;
                emit Transfer(from, sharingWallets[i], feeAmount);
            }
            amount -= totalFee;
        }

        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
    

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}