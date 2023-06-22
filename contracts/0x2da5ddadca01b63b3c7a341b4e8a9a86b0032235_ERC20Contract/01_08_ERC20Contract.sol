// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ERC20Contract is Ownable, Pausable, ERC20, ERC20Burnable  {

    error NoZeroTransfers();
    error ContractPaused();

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _decimals,
        uint256 _deployerBasisPoints,
        address _deployerAddress,
        address _owner
    ) ERC20(_name, _symbol) {
        uint256 deployerShare = (_totalSupply * _deployerBasisPoints) / 10000;
        _mint(_deployerAddress, deployerShare * 10 ** _decimals);
        _mint(_owner, (_totalSupply - deployerShare) * 10 ** _decimals);
        _pause();
        transferOwnership(_owner);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        if (amount == 0) { revert NoZeroTransfers(); }
        if (paused() && owner() != sender) { revert ContractPaused();}
        super._beforeTokenTransfer(sender, recipient, amount);
    }
}