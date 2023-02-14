// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibVault} from  "../libraries/LibVault.sol";
import {LibCexVault} from  "../libraries/LibCexVault.sol";
import {LibPriceFacade} from  "../libraries/LibPriceFacade.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibAlpManager {

    bytes32 constant ALP_MANAGER_STORAGE_POSITION = keccak256("apollox.alp.manager.storage.v2");
    uint8 constant  ALP_DECIMALS = 18;

    struct AlpManagerStorage {
        mapping(address => uint256) lastMintedAt;
        uint256 coolingDuration;
        address alp;
        // blockNumber => ALP Increase in quantity, possibly negative
        mapping(uint256 => int256) alpIncrement;
        uint256 safeguard;
    }

    function alpManagerStorage() internal pure returns (AlpManagerStorage storage ams) {
        bytes32 position = ALP_MANAGER_STORAGE_POSITION;
        assembly {
            ams.slot := position
        }
    }

    function initialize(address alpToken, uint256 safeguard) internal {
        AlpManagerStorage storage ams = alpManagerStorage();
        require(ams.alp == address(0), "LibAlpManager: Already initialized");
        ams.alp = alpToken;
        ams.safeguard = safeguard;
        // default 30 minutes
        ams.coolingDuration = 1800;
    }

    event AddLiquidity(address indexed account, address indexed token, uint256 amount);
    event RemoveLiquidity(address indexed account, address indexed token, uint256 amount);

    function alpPrice(int256 totalValueUsd, uint256 blockNo) internal view returns (uint256) {
        require(totalValueUsd >= 0, "LibAlpManager: Cex vault has a negative number of funds");
        AlpManagerStorage storage ams = alpManagerStorage();
        uint256 totalSupply = IERC20(ams.alp).totalSupply();
        int256 amountOfChange;
        for (uint256 i = 1; i <= block.number - blockNo;) {
            amountOfChange += ams.alpIncrement[blockNo + i];
            unchecked {
                i++;
            }
        }
        int256 beforeTotalSupply = int256(totalSupply) - amountOfChange;
        require(beforeTotalSupply >= 0, "LibAlpManager: ALP quantity error");
        if (beforeTotalSupply == 0) {
            return 10 ** LibPriceFacade.PRICE_DECIMALS;
        } else {
            return uint256(totalValueUsd) * (10 ** LibPriceFacade.PRICE_DECIMALS) / uint256(beforeTotalSupply);
        }
    }

    function mintAlp(address account, address tokenIn, uint256 amount, uint256 _alpPrice) internal returns (uint256 alpAmount){
        alpAmount = _calculateAlpAmount(tokenIn, amount, _alpPrice);
        LibVault.deposit(tokenIn, amount, account, false);
        _addMinted(account);
        _alpIncrease(int256(alpAmount));
        emit AddLiquidity(account, tokenIn, amount);
    }

    function mintAlpBNB(address account, uint256 amount, uint256 _alpPrice) internal returns (uint256 alpAmount){
        address tokenIn = LibVault.WBNB();
        alpAmount = _calculateAlpAmount(tokenIn, amount, _alpPrice);
        LibVault.depositBNB(amount);
        _addMinted(account);
        _alpIncrease(int256(alpAmount));
        emit AddLiquidity(account, tokenIn, amount);
    }

    function _calculateAlpAmount(address tokenIn, uint256 amount, uint256 _alpPrice) private view returns (uint256 alpAmount) {
        LibVault.AvailableToken storage at = LibVault.vaultStorage().tokens[tokenIn];
        require(at.weight > 0, "LibAlpManager: Token does not exist");
        uint256 tokenInPrice = LibPriceFacade.getPrice(tokenIn);
        uint256 amountUsd = tokenInPrice * amount * (10 ** LibPriceFacade.USD_DECIMALS) / (10 ** (at.decimals + LibPriceFacade.PRICE_DECIMALS));
        uint256 afterTaxAmountUsd = amountUsd * (LibVault.BASIS_POINTS_DIVISOR - getMintFeePoint(at)) / LibVault.BASIS_POINTS_DIVISOR;
        alpAmount = afterTaxAmountUsd * 10 ** LibPriceFacade.PRICE_DECIMALS / _alpPrice;
    }

    function _addMinted(address account) private {
        alpManagerStorage().lastMintedAt[account] = block.timestamp;
    }

    function _alpIncrease(int256 amount) private {
        AlpManagerStorage storage ams = alpManagerStorage();
        ams.alpIncrement[block.number] += amount;
    }

    function getMintFeePoint(LibVault.AvailableToken storage at) internal view returns (uint16) {
        // Dynamic rates are not supported in Phase I
        // Soon it will be supported
        require(!at.dynamicFee, "LibAlpManager: Dynamic fee rates are not supported at this time");
        return at.feeBasisPoints;
    }

    function burnAlp(address account, address tokenOut, uint256 alpAmount, uint256 _alpPrice, address receiver) internal returns (uint256 amountOut) {
        amountOut = _calculateTokenAmount(account, tokenOut, alpAmount, _alpPrice);
        LibVault.withdraw(receiver, tokenOut, amountOut);
        _alpIncrease(int256(0) - int256(alpAmount));
        emit RemoveLiquidity(account, tokenOut, amountOut);
    }

    function burnAlpBNB(address account, uint256 alpAmount, uint256 _alpPrice, address payable receiver) internal returns (uint256 amountOut) {
        address tokenOut = LibVault.WBNB();
        amountOut = _calculateTokenAmount(account, tokenOut, alpAmount, _alpPrice);
        LibVault.withdrawBNB(receiver, amountOut);
        _alpIncrease(int256(0) - int256(alpAmount));
        emit RemoveLiquidity(account, tokenOut, amountOut);
    }

    function _calculateTokenAmount(address account, address tokenOut, uint256 alpAmount, uint256 _alpPrice) private view returns (uint256 amountOut) {
        LibVault.AvailableToken storage at = LibVault.vaultStorage().tokens[tokenOut];
        require(at.weight > 0, "LibAlpManager: Token does not exist");
        AlpManagerStorage storage ams = alpManagerStorage();
        require(ams.lastMintedAt[account] + ams.coolingDuration <= block.timestamp, "LibAlpManager: Cooling duration not yet passed");
        uint256 tokenOutPrice = LibPriceFacade.getPrice(tokenOut);
        uint256 amountOutUsd = _alpPrice * alpAmount * (10 ** LibPriceFacade.USD_DECIMALS) / (10 ** (LibPriceFacade.PRICE_DECIMALS + ALP_DECIMALS));
        uint256 afterTaxAmountOutUsd = amountOutUsd * (LibVault.BASIS_POINTS_DIVISOR - getBurnFeePoint(at)) / LibVault.BASIS_POINTS_DIVISOR;
        require(int256(afterTaxAmountOutUsd) <= LibCexVault.maxWithdrawAbleUsd() && int256(afterTaxAmountOutUsd) <= LibCexVault.getCexTokenValueUsd(tokenOut),
            "LibAlpManager: tokenOut balance is insufficient");
        amountOut = afterTaxAmountOutUsd * 10 ** (LibPriceFacade.PRICE_DECIMALS + at.decimals) / (tokenOutPrice * 10 ** LibPriceFacade.USD_DECIMALS);
    }

    function getBurnFeePoint(LibVault.AvailableToken storage at) internal view returns (uint16) {
        // Dynamic rates are not supported in Phase I
        // Soon it will be supported
        require(!at.dynamicFee, "LibAlpManager: Dynamic fee rates are not supported at this time");
        return at.taxBasisPoints;
    }
}