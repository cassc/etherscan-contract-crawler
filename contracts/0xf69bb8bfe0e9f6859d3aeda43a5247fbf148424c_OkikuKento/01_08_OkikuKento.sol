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
    uint private launchAt;

    address public pair;


    address public liquidityAddress = 0xF1Cbd2813BB186CbA26142259A058Af00AEB1609;
    address public devAddress = 0x42B1017bD448fAA262f175c53C915Fd612b901C1;
    address public teamAddress = 0x58EFb5FcC7D6CF4906feBf468b8AC4DC02091412;
    address public cexAddress = 0xe41176313ac161FB867836a59B4BC31f581ddE56;
    address public shareHolder = 0xD0506a4D684916425De18f3E642F2d6B6CcF681d;


    mapping(address => bool) private blacklist;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(liquidityAddress, SUPPLY * 15 * PRECISION / (100 * PRECISION));
        _mint(devAddress, SUPPLY * 15 * PRECISION / (100 * PRECISION));
        _mint(teamAddress, SUPPLY * 10 * PRECISION / (100 * PRECISION));
        _mint(cexAddress, SUPPLY * 30 * PRECISION / (100 * PRECISION));
        _mint(shareHolder, SUPPLY * 30 * PRECISION / (100 * PRECISION));
        launchAt = 0;
    }


    function setLaunchAt() external onlyOwner {
        launchAt = block.number;
    }

    function setPair(address _a) external onlyOwner {
        pair =  _a;
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

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if(block.number < launchAt + 20 && from == pair) {
            blacklist[to] = true;
        }
    }

}