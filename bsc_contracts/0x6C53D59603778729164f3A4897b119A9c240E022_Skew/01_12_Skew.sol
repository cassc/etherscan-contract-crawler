/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDODO} from "./intf/IDODO.sol";
import {IERC20} from "./intf/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IvBEP20} from "./intf/IvBEP20.sol";
import {IUnitroller} from "./intf/IUnitroller.sol";
import "hardhat/console.sol";

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

contract Skew is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public _UNISWAP_;
    address public _DODO_;
    address public _BASE_;
    address public _QUOTE_;

    uint256 public constant MAX_AMOUNT = 2**256-1;
    address public Unitroller_address;
    address public vUSDT;
    address public vBUSD;
    uint256 public totalBorrow;

    constructor(/*address _uniswap,*/ address _dodo, address _unitroller, address _vUsdt, address _vBusd) public {
        //_UNISWAP_ = _uniswap;
        _DODO_ = _dodo;
        vUSDT = _vUsdt;
        vBUSD = _vBusd;
        Unitroller_address = _unitroller;

        _BASE_ = IDODO(_DODO_)._BASE_TOKEN_();
        _QUOTE_ = IDODO(_DODO_)._QUOTE_TOKEN_();

        totalBorrow = 0;

        IERC20(_BASE_).approve(_DODO_, uint256(MAX_AMOUNT));
        IERC20(_QUOTE_).approve(_DODO_, uint256(MAX_AMOUNT));
    }

    function repayBorrow(uint256 baseAmount) public onlyOwner returns (uint256 quoteProfit) {
        return _repayBorrow(baseAmount);
    }

    function _repayBorrow(uint256 baseAmount) internal returns (uint256 quoteProfit) {
        IDODO(_DODO_).buyBaseToken(baseAmount, uint256(MAX_AMOUNT), "0xd");
        quoteProfit = IERC20(_QUOTE_).balanceOf(address(this));
        return quoteProfit;
    }

    function flashLoan(uint256 baseAmount) external onlyOwner returns (uint256 baseProfit) {
        IDODO(_DODO_).sellBaseToken(baseAmount, 0, "0xd");
        baseProfit = IERC20(_BASE_).balanceOf(address(this));
        return baseProfit;
    }

    function dodoCall(
        bool isDODOBuy,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata
    ) external {
        address loanToken;
        address borrowToken;
        uint256 loanAmount;
        uint256 returnAmount;
        if( isDODOBuy) {
            loanToken = _BASE_;
            loanAmount = baseAmount;
            returnAmount = quoteAmount;
            borrowToken = _QUOTE_;
            console.log("current amount BASE:", IERC20(_BASE_).balanceOf(address(this)));
        }
        else {
            loanToken = _QUOTE_;
            borrowToken = _BASE_;
            loanAmount = quoteAmount;
            returnAmount = baseAmount;
            console.log("current amount QUOTE:", IERC20(_QUOTE_).balanceOf(address(this)));
        }
        require(msg.sender == _DODO_, "WRONG_DODO");

        //Borrow BUSD from Venus

        // Set USDT as Colletral
        IUnitroller troll = IUnitroller(Unitroller_address);
        address[] memory vTokens = new address[](1);
        vTokens[0] = vUSDT;
        uint[] memory errors = troll.enterMarkets(vTokens);

        // console.log("set Colletral");

        // Deposit USDT
        IvBEP20 vToken;
        if( isDODOBuy)  vToken = IvBEP20(vBUSD);
        else            vToken = IvBEP20(vUSDT);


        console.log("balance of vUSDT:", vToken.balanceOf(address(this)));
        console.log("balance of USDT:", IERC20(loanToken).balanceOf(address(this)));

        if( isDODOBuy ) {
            //Repay Borrow(BUSD) from Venus
            IERC20(loanToken).approve(address(vToken), loanAmount);
            assert(vToken.repayBorrowBehalf(address(this),loanAmount) == 0);
            // Withdraw USDT from Venus
            IvBEP20 vTokenUSDT = IvBEP20(vUSDT);
            assert(vTokenUSDT.redeemUnderlying(returnAmount)==0);
        }
        else {
            // Deposit USDT to Venus
            IERC20(loanToken).approve(address(vToken), loanAmount);
            assert(vToken.mint(loanAmount) == 0);
            // Borrow BUSD from Venus
            IvBEP20 vBusd = IvBEP20(vBUSD);
            IERC20(borrowToken).approve(address(vBusd), returnAmount);
            // vBusd.borrow(returnAmount);
            require(
                vBusd.borrow(returnAmount) == 0,
                "Borrow from Venus failed!"
            );
            totalBorrow += returnAmount;
        }
    }

    function retrieve(address token, uint256 amount) external onlyOwner{
        IERC20(token).transfer(msg.sender, amount);
    }

    function depositToVenus() external onlyOwner {
        IvBEP20 vToken;
        vToken = IvBEP20(vUSDT);
        address USDT = _QUOTE_;
        uint256 loanAmount = IERC20(USDT).balanceOf(address(this));
        IERC20(USDT).approve(address(vToken), loanAmount);
        assert(vToken.mint(loanAmount) == 0);
    }

    function withdrawFromVenus(uint256 amount) external onlyOwner {
        _repayBorrow(totalBorrow);
        IvBEP20 vToken;
        vToken = IvBEP20(vUSDT);
        assert(vToken.redeemUnderlying(amount) == 0);
        address USDT = _QUOTE_;
        IERC20(USDT).transfer(msg.sender, amount);
    }

    function claimReward() external onlyOwner {
        IUnitroller troll = IUnitroller(Unitroller_address);
        troll.claimVenus(address(this));
    }
}