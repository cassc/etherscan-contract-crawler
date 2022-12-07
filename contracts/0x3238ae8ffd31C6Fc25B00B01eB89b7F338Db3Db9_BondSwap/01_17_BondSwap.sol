// SPDX-License-Identifier: MIT
// Created by BondSwap https://bondswap.org

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BondSwap is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes {
    address internal deployer;
    bool internal minted = false;
    bool internal afterPresale = false;

    constructor() ERC20("BondSwapToken", "BONDS") ERC20Permit("BONDS") {
        deployer = msg.sender;
    }

    function initialMint(
        address _community,
        address _bonds,
        address _team,
        address _treasury
    ) external {
        require(msg.sender == deployer, "not deployer");
        require(
            _community != address(0) &&
                _bonds != address(0) &&
                _team != address(0) &&
                _treasury != address(0),
            "zero addr"
        );
        require(!minted, "already minted");

        _mint(_community, 35_000_000 * 10**decimals());
        _mint(_bonds, 25_000_000 * 10**decimals());
        _mint(_team, 10_000_000 * 10**decimals());
        _mint(_treasury, 20_000_000 * 10**decimals());
        minted = true;
    }

    function presaleMint(address _presale) external {
        require(msg.sender == deployer, "not deployer");
        require(_presale != address(0), "zero addr");
        require(!afterPresale, "presale already minted");

        _mint(_presale, 10_000_000 * 10**decimals());

        afterPresale = true;
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}