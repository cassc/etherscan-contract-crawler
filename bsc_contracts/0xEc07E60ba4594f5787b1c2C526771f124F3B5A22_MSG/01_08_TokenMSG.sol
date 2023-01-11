// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IMSG.sol";
import "./libraries/Config.sol";

contract MSG is IMSG, ERC20, Ownable {
    uint256 constant MAX_SUPPLY = 10000000e18; // 8B token
    mapping(address => bool) isMinter;
    bool private isInit;

    modifier onlyMinter() {
        require(
            isMinter[_msgSender()],
            "Caller is not minter");
        _;
    }

    constructor(address owner, string memory name, string memory symbol) ERC20(name, symbol) {
        transferOwnership(owner);
    }

    function initilize(
        address sale, 
        address ecosystem,
        address team,
        address treasury, 
        address liq
    ) external onlyOwner{
        require(!isInit, "Only one time");
        _mint(sale, Constant.SALE_MINT_TOKEN_AMOUNT);
        _mint(ecosystem, Constant.ECOSYSTEM_MINT_TOKEN_AMOUNT);
        _mint(team, Constant.TEAM_MINT_TOKEN_AMOUNT);
        _mint(treasury, Constant.TREASURY_MINT_TOKEN_AMOUNT);
        _mint(liq, Constant.LIQUIDITY_MINT_TOKEN_AMOUNT);
        isInit = true;
    }

    function addMinter(address minter) external override onlyOwner{
        isMinter[minter] = true;
    }

    function removeMinter(address minter) external override onlyOwner{
        isMinter[minter] = false;
    }

    function mintToken(address receiver, uint256 amount) external override  onlyMinter{
        require(totalSupply() + amount <= MAX_SUPPLY, "Cap exceeded");
        _mint(receiver, amount);
    }

    function burnToken(uint256 amount) external override {
        _burn(_msgSender(), amount);
    }
}