// SPDX-License-Identifier: MIT
// contracts/SpartaToken.sol

pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./modules/Blacklist.sol";
import "./modules/Whitelist.sol";

contract SpartaToken is ERC20, Blacklist, Whitelist {
    uint public constant MAX_ISSUE = 500000 * 10 ** 18;

    uint public constant MAX_MINT = 49500000 * 10 ** 18;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public uniswapV2Router;

    address public USDT;

    mapping(address => bool) public swapPairs;

    uint private _minHold;
    uint private _transferFeeToBurnPer;
    uint private _addLiquidityFeeToBurnPer;
    address private _daoAddress;
    address private _ecoAddress;
    address private _serAddress;

    struct BuyFeeConfig {
        uint lpAwardPer;
        uint otherPer;
        uint otherBurnPer;
        uint otherDaoPer;
        uint otherSerPer;
        uint otherEcoPer;
        uint otherNFTAwardPer;
        bool enable;
    }
    BuyFeeConfig private _buyFeeConfig;

    struct SellFeeConfig {
        uint daoPer;
        uint ecoPer;
        uint burnPer;
        uint otherPer;
        uint otherBurnPer;
        uint otherDaoPer;
        uint otherEcoPer;
        bool enable;
    }
    SellFeeConfig private _sellFeeConfig;

    event TransferToBuyEvent(address indexed from, address indexed to, uint amount, uint lpAwardAmount, uint otherBurnAmount, uint otherSerAmount, uint otherDaoAmount, uint otherEcoAmount, uint otherNFTAwardAmount);

    event TransferToSellEvent(address indexed from, address indexed to, uint amount, uint daoAmount, uint ecoAmount, uint burunAmount, uint otherBurnAmount, uint otherDaoAmount, uint otherEcoAmount);

    event TransferToUserEvent(address indexed from, address indexed to, uint amount, uint burnFeeAmount);

    constructor() ERC20("Sparta Token", "SPA") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());

        _mint(_msgSender(), MAX_ISSUE);

        setWhitelist(address(this), true);

        uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

        _minHold = 1 * 10 ** decimals();
        _transferFeeToBurnPer = 600;
        _addLiquidityFeeToBurnPer = 300;

        // Buy Fee
        _buyFeeConfig.lpAwardPer = 300;
        _buyFeeConfig.otherPer = 3000;
        _buyFeeConfig.otherBurnPer = 3000;
        _buyFeeConfig.otherSerPer = 3000;
        _buyFeeConfig.otherDaoPer = 500;
        _buyFeeConfig.otherEcoPer = 500;
        _buyFeeConfig.otherNFTAwardPer = 3000;
        _buyFeeConfig.enable = false;

        // Sell Fee
        _sellFeeConfig.daoPer = 2000;
        _sellFeeConfig.ecoPer = 2000;
        _sellFeeConfig.burnPer = 2000;
        _sellFeeConfig.otherPer = 0;
        _sellFeeConfig.otherBurnPer = 6000;
        _sellFeeConfig.otherDaoPer = 2000;
        _sellFeeConfig.otherEcoPer = 2000;
        _sellFeeConfig.enable = false;
    }

    function mint(address to, uint amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "SPA: Must have minter role to mint");
        require(amount + totalSupply() <= MAX_ISSUE + MAX_MINT, "SPA: Exceeds mint amount");

        _mint(to, amount);
    }

    function _transfer(address from, address to, uint amount) internal override {
        require(from != address(0), "SPA: transfer from the zero address");
        require(to != address(0), "SPA: transfer to the zero address");
        require(amount > 0, "SPA: transfer amount to small");

        _beforeTokenTransfer(from, to, amount);

        if (isWhitelist(from) || isWhitelist(to)) {
            super._transfer(from, to, amount);
            return;
        }

        if (swapPairs[from]) {
            _transferToBuy(from, to, amount);
        } else if (swapPairs[to]) {
            _transferToSell(from, to, amount);
        } else {
            _transferToUser(from, to, amount);
        }
    }

    function _transferToBuy(address from, address to, uint amount) internal {
        require(_buyFeeConfig.enable, "SPA: Swap to buy not enabled");

        uint lpAwardAmount = (amount * _buyFeeConfig.lpAwardPer) / 10000;
        if (lpAwardAmount > 0) {
            super._transfer(from, _serAddress, lpAwardAmount);
        }

        uint ohterAmount = (amount * _buyFeeConfig.otherPer) / 10000;
        uint otherBurnAmount;
        uint otherSerAmount;
        uint otherDaoAmount;
        uint otherEcoAmount;
        uint otherNFTAwardAmount;
        if (ohterAmount > 0) {
            otherBurnAmount = (ohterAmount * _buyFeeConfig.otherBurnPer) / 1000;
            super._transfer(from, BURN_ADDRESS, otherBurnAmount);

            otherSerAmount = (ohterAmount * _buyFeeConfig.otherSerPer) / 1000;
            super._transfer(from, _serAddress, otherSerAmount);

            otherDaoAmount = (ohterAmount * _buyFeeConfig.otherDaoPer) / 1000;
            super._transfer(from, _daoAddress, otherDaoAmount);

            otherEcoAmount = (ohterAmount * _buyFeeConfig.otherEcoPer) / 1000;
            super._transfer(from, _ecoAddress, otherEcoAmount);

            otherNFTAwardAmount = (ohterAmount * _buyFeeConfig.otherNFTAwardPer) / 1000;
            super._transfer(from, _serAddress, otherNFTAwardAmount);
        }

        amount = amount - lpAwardAmount - ohterAmount;
        require(amount > 0, "SPA: Invalid amount");

        super._transfer(from, to, amount);

        emit TransferToBuyEvent(from, to, amount, lpAwardAmount, otherBurnAmount, otherSerAmount, otherDaoAmount, otherEcoAmount, otherNFTAwardAmount);
    }

    function _transferToSell(address from, address to, uint amount) internal {
        require(_sellFeeConfig.enable, "SPA: Swap to sell not enabled");
        require(balanceOf(from) - amount > _minHold, "SPA: Transfer amount over min hold");

        uint daoAmount = (amount * _sellFeeConfig.daoPer) / 10000;
        if (daoAmount > 0) {
            super._transfer(from, _daoAddress, daoAmount);
        }

        uint ecoAmount = (amount * _sellFeeConfig.ecoPer) / 10000;
        if (ecoAmount > 0) {
            super._transfer(from, _ecoAddress, ecoAmount);
        }

        uint burunAmount = (amount * _sellFeeConfig.burnPer) / 10000;
        if (burunAmount > 0) {
            super._transfer(from, BURN_ADDRESS, burunAmount);
        }

        uint otherAmount = (amount * _sellFeeConfig.otherPer) / 10000;
        uint otherBurnAmount;
        uint otherDaoAmount;
        uint otherEcoAmount;
        if (otherAmount > 0) {
            otherBurnAmount = (otherAmount * _sellFeeConfig.otherBurnPer) / 1000;
            super._transfer(from, BURN_ADDRESS, otherBurnAmount);

            otherDaoAmount = (otherAmount * _sellFeeConfig.otherDaoPer) / 1000;
            super._transfer(from, _daoAddress, otherDaoAmount);

            otherEcoAmount = (otherAmount * _sellFeeConfig.otherEcoPer) / 1000;
            super._transfer(from, _ecoAddress, otherEcoAmount);
        }

        amount = amount - daoAmount - ecoAmount - burunAmount - otherAmount;
        require(amount > 0, "SPA: Invalid amount");

        super._transfer(from, to, amount);

        emit TransferToSellEvent(from, to, amount, daoAmount, ecoAmount, burunAmount, otherBurnAmount, otherDaoAmount, otherEcoAmount);
    }

    function _transferToUser(address from, address to, uint amount) internal {
        require(balanceOf(from) - amount >= _minHold, "SPA: Transfer amount over min hold");

        uint burnFeeAmount = (amount * _transferFeeToBurnPer) / 10000;
        if (burnFeeAmount > 0) {
            super._transfer(from, BURN_ADDRESS, burnFeeAmount);
        }

        amount = amount - burnFeeAmount;
        require(amount > 0, "SPA: Invalid amount");

        super._transfer(from, to, amount);

        emit TransferToUserEvent(from, to, amount, burnFeeAmount);
    }

    function addLiquidity(uint256 amountIn) public {
        require(amountIn > 0, "SPA: Invalid amount");

        uint burnAmount = (amountIn * _addLiquidityFeeToBurnPer) / 10000;
        super._transfer(_msgSender(), _ecoAddress, burnAmount);

        amountIn -= burnAmount;
        super._transfer(_msgSender(), address(this), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        uint[] memory amounts = IUniswapV2Router02(uniswapV2Router).getAmountsOut(amountIn, path);
        uint amountOut = amounts[amounts.length - 1];
        IERC20(USDT).transferFrom(_msgSender(), address(this), amountOut);

        _approve(address(this), uniswapV2Router, amountIn);
        IERC20(USDT).approve(uniswapV2Router, amountOut);

        IUniswapV2Router02(uniswapV2Router).addLiquidity(address(this), USDT, amountIn, amountOut, 0, 0, _msgSender(), block.timestamp);
    }

    function setSwapPair(address pair, bool enbale) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SPA: Must have admin role to set pair");

        swapPairs[pair] = enbale;
    }

    function setUniswapAddress(address router, address u) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SPA: Must have admin role to set router");

        uniswapV2Router = router;
        USDT = u;
    }

    function setAddress(address dao, address eco, address ser) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SPA: Must have admin role to set address");
        _daoAddress = dao;
        _ecoAddress = eco;
        _serAddress = ser;
    }

    function setBuyFeeConfig(BuyFeeConfig memory config) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SPA: Must have admin role to set config");

        _buyFeeConfig = config;
    }

    function setSellFeeConfig(SellFeeConfig memory config) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SPA: Must have admin role to set config");

        _sellFeeConfig = config;
    }

    function setConfig(uint minHold, uint transferFeeToBurnPer, uint addLiquidityFeeToBurnPer) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SPA: Must have admin role to set config");

        _minHold = minHold;
        _transferFeeToBurnPer = transferFeeToBurnPer;
        _addLiquidityFeeToBurnPer = addLiquidityFeeToBurnPer;
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!isBlacklist(from), "Blacklist: Blacklisted send address");
        require(!isBlacklist(to), "Blacklist: Blacklisted receive address");
    }
}