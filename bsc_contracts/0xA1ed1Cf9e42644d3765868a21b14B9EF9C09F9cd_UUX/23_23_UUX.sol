// SPDX-License-Identifier: MIT
// contracts/UUXS.sol

pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./structs/UUXSDATA.sol";

contract UUX is UUXSDATA,AccessControlEnumerableUpgradeable,ERC20PausableUpgradeable{
    uint public constant MAX_MINT = 4400000 * 10**18;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    SysConfigStruct public tokenConfig;
    address public uniswapV2Router;
    address public uniswapV2Pair;
    address public USDT = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;

    function initialize() public initializer {
        __ERC20_init("UUX TOKEN", "UUX");

        _mint(_msgSender(), MAX_MINT);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        tokenConfig.minHold = 0* 10**18;
        tokenConfig.buyService = 0;
        tokenConfig.sellService = 600;
        tokenConfig.burnService = 500;
        tokenConfig.runService = 100;
        tokenConfig.userService = 0;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(amount > 0, "transfer amount to small");
        if (from == uniswapV2Router) {
            _transferToBuy(from, to, amount);
        } else if (from == uniswapV2Pair) {
            _transferToBuy(from, to, amount);
        } else if (to == uniswapV2Pair) {
            _transferToSell(from, to, amount);
        } else {
            _transferToUser(from, to, amount);
        }
    }

    function _transferToBuy(
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 feeAmount = (amount * tokenConfig.buyService) / 10000;
        if (feeAmount > 0) {
            _lpReward(feeAmount);
            super._transfer(from, tokenConfig.serviceAddress, feeAmount);
        }

        amount = amount - feeAmount;
        require(amount > 0, "Invalid amount");

        super._transfer(from, to, amount);
    }

    function _transferToSell(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(balanceOf(from) - amount >= tokenConfig.minHold, "Transfer amount over min hold");

        uint256 sellAmount = (amount * tokenConfig.sellService) / 10000;
        if (sellAmount > 0) {
            super._transfer(from, tokenConfig.serviceAddress, sellAmount);
        }

        uint256 runAmount = (amount * tokenConfig.runService) / 10000;
        if (runAmount > 0) {
            super._transfer(from, tokenConfig.runAddress, runAmount);
        }

        uint256 burnAmount = (amount * tokenConfig.burnService) / 10000;
        if (burnAmount > 0) {
            super._transfer(from, BURN_ADDRESS, burnAmount);
        }

        amount = amount - sellAmount - runAmount - burnAmount;
        require(amount > 0, "Invalid amount");

        super._transfer(from, to, amount);
    }

    function _transferToUser(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(balanceOf(from) - amount >= tokenConfig.minHold, "GOH: Transfer amount over min hold");

        uint256 userAmount = (amount * tokenConfig.userService) / 10000;
        if (userAmount > 0) {
            super._transfer(from, tokenConfig.serviceAddress, userAmount);
        }

        amount = amount - userAmount;
        require(amount > 0, "Invalid amount");

        super._transfer(from, to, amount);
    }

    function _lpReward(uint amount) internal {
        // TODO 实现
    }

    function setTokenConfig(SysConfigStruct memory config) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GOH: Must have admin role to set fee");

        tokenConfig = config;
    }

    function setUniswapAddress(address router, address usdt) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GOH: Must have admin role to set router");

        address pair;
        address factory = IUniswapV2Router02(router).factory();
        if (IUniswapV2Factory(factory).getPair(address(this), usdt) == address(0)) {
            pair = IUniswapV2Factory(factory).createPair(address(this), usdt);
        } else {
            pair = IUniswapV2Factory(factory).getPair(address(this), usdt);
        }
        uniswapV2Router = router;
        uniswapV2Pair = pair;
        USDT = usdt;
    }
    function pause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to pause");

        _pause();
    }

    function unpause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to unpause");

        _unpause();
    }
    uint256[50] private __gap;
}