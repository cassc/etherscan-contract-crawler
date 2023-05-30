// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interface/IUniswapRouter.sol";
import "./interface/IUniswapFactory.sol";


contract OkikuKento is ERC20, Ownable {
    uint private constant PRECISION = 10**18;
    uint private constant SUPPLY =  420690000000000 * PRECISION;

    address public liquidityAddress = 0x575EE16A09bF9e9AFe24d83AF47c89fE34c8cDcC;
    address public devAddress = 0x8d025cdE8be8e0402b3486dFD72211835B657b60;
    address public teamAddress = 0x0d8639438ac5b45844748E0DD3cA4B7428ad5942;
    address public cexAddress = 0x902F10930369F8E1Da2d9AA13C3a9727f38699fe;
    address public shareHolder = 0x3591A30Ee51CF8802d65A37F46416A7EC226afb0;

    mapping(address => bool) private blacklist;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(liquidityAddress, SUPPLY * 76 * PRECISION / (100 * PRECISION));
        _mint(devAddress, SUPPLY * 5 * PRECISION / (100 * PRECISION));
        _mint(teamAddress, SUPPLY * 9 * PRECISION / (100 * PRECISION));
        _mint(cexAddress, SUPPLY * 5 * PRECISION / (100 * PRECISION));
        _mint(shareHolder, SUPPLY * 5 * PRECISION / (100 * PRECISION));
    }


    function addBlackList(address _a) external onlyOwner {
        blacklist[_a] = true;
    }

    function removeBlackList(address _a) external onlyOwner {
        blacklist[_a] = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklist[from] && !blacklist[to], 'Forbidden');
    }

}