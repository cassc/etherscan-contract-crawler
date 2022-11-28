// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IFlashLoanSimpleReceiver} from "@aave/core-v3/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DefiiWithParams} from "../DefiiWithParams.sol";

import "hardhat/console.sol";

contract SonneOptimismDai is DefiiWithParams {
    IERC20 constant DAI = IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
    IERC20 constant USDC = IERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607);
    IERC20 constant SONNE = IERC20(0x1DB2466d9F5e10D7090E7152B68d62703a2245F0);
    ICErc20 constant soDAI =
        ICErc20(0x5569b83de187375d43FBd747598bfe64fC8f6436);
    IComptroller constant comptroller =
        IComptroller(0x60CF091cD3f50420d50fD7f707414d0DF4751C58);
    IPool constant aavePool = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    IRouter constant router =
        IRouter(0x9c12939390052919aF3155f41Bf4160Fd3666A6f);

    function encodeParams(uint8 loopCount, uint8 ltv)
        external
        pure
        returns (bytes memory encodedParams)
    {
        require(ltv < 100, "LTV must be in range [0, 100]");
        encodedParams = abi.encode(loopCount, ltv);
    }

    function hasAllocation() external view override returns (bool) {
        return soDAI.balanceOf(address(this)) > 0;
    }

    function _enterWithParams(bytes memory params) internal override {
        (uint8 loopCount, uint8 ltv) = abi.decode(params, (uint8, uint8));

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(soDAI);
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0, "Comptroller.enterMarkets failed.");

        DAI.approve(address(soDAI), type(uint256).max);
        uint256 balance = DAI.balanceOf(address(this));
        for (uint8 i = 0; i < loopCount; i++) {
            soDAI.mint(balance);
            soDAI.borrow((balance * ltv) / 100);
            balance = DAI.balanceOf(address(this));
        }
        soDAI.mint(balance);
        DAI.approve(address(soDAI), 0);
    }

    function _exit() internal override {
        uint256 borrowAmount = soDAI.borrowBalanceCurrent(address(this));
        aavePool.flashLoanSimple(
            address(this),
            address(DAI),
            borrowAmount,
            bytes(""),
            0
        );
        _claimSonneAndConvertToUsdc();
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(initiator == address(this), "FLASHLOAN initiator");
        require(msg.sender == address(aavePool), "FLASHLOAN sender");
        require(asset == address(DAI), "FLASHLOAN asset");

        DAI.approve(address(soDAI), amount);
        soDAI.repayBorrow(amount);
        soDAI.redeem(soDAI.balanceOf(address(this)));

        DAI.approve(address(aavePool), amount + premium);
        return true;
    }

    function _harvest() internal override {
        _claimSonneAndConvertToUsdc();
        _withdrawFunds();
    }

    function _claimSonneAndConvertToUsdc() internal {
        comptroller.claimComp(address(this));
        uint256 sonneBalance = SONNE.balanceOf(address(this));
        (uint256 usdcFromSonne, ) = router.getAmountOut(
            sonneBalance,
            address(SONNE),
            address(USDC)
        );

        if (usdcFromSonne == 0) {
            return;
        }

        SONNE.approve(address(router), sonneBalance);
        router.swapExactTokensForTokensSimple(
            sonneBalance,
            0,
            address(SONNE),
            address(USDC),
            false,
            address(this),
            block.timestamp
        );
    }

    function _withdrawFunds() internal override {
        withdrawERC20(DAI);
        withdrawERC20(USDC);
    }
}

interface ICErc20 is IERC20 {
    function borrow(uint256 borrowAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);
}

interface IComptroller {
    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);

    function claimComp(address holder) external;
}

interface IRouter {
    function swapExactTokensForTokensSimple(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amount, bool stable);
}