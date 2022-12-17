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
    address public vBase;
    address public vQuote;
    address public vBTC;
    mapping(address=>uint256) public totalBorrow;
    address public XVS;
    address immutable inch_aggregation_router;

    mapping(address=>mapping(address=>uint256)) public depositInfo;

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    struct FlashLoanInfo {
        address loanedToken;
        address returnToken;
        uint256 loanedAmount;
        uint256 returnAmount;
        address supplyToken;
        address vSupplyToken;
        address loanToken;
        address vLoanToken;
        uint256 loanAmount;
        uint256[] minOuts;
        bytes[] inchDatas;
    }
 

    constructor(address _dodo, 
        address _unitroller, 
        address _vBase, 
        address _vQuote,
        address _router,
        address _xvs,
        address _vBTC
    ) {
        _DODO_ = _dodo;
        vBase = _vBase;
        vQuote = _vQuote;
        Unitroller_address = _unitroller;
        inch_aggregation_router = _router;
        XVS = _xvs;
        vBTC = _vBTC;

        _BASE_ = IDODO(_DODO_)._BASE_TOKEN_();
        _QUOTE_ = IDODO(_DODO_)._QUOTE_TOKEN_();


        IERC20(_BASE_).approve(_DODO_, uint256(MAX_AMOUNT));
        IERC20(_QUOTE_).approve(_DODO_, uint256(MAX_AMOUNT));
    }

    function repayBorrow(
        address vToken,
        uint256 amount,
        uint256 minOut,
        bytes calldata data
    ) public onlyOwner returns (uint256 quoteProfit) {
        return _repayBorrow(vToken, amount, minOut, data);
    }

    function _repayBorrow(
        address _vToken, 
        uint256 _amount,
        uint256 _minOut,
        bytes calldata _data
    ) internal returns (uint256 quoteProfit) {
        bytes memory data = abi.encode(
            _vToken,        // vToken address of Borrowed Token
            "",             // loan Token so unnecessary in repay
            0,              // loanAmount so unnecessary in repay
            _minOut,        // 1inch swap MinSwap Amount
            _data           // 1inch swap Params
        );
        IDODO(_DODO_).buyBaseToken(_amount, uint256(MAX_AMOUNT), data);
        quoteProfit = IERC20(_QUOTE_).balanceOf(address(this));
        return quoteProfit;
    }

    function flashLoan(
        uint256 amount,             // Amount to Flash Loan
        address vSupplyToken,       // vSupply Token address in Venus
        address vloanToken,          // vLoan Token address from Venus
        uint256 loanAmount,         // Loan Amount from Venus
        uint256[] memory minOuts,   // 1inch swap MinSwap Amount
        bytes[] calldata _data      // 1inch swap Params
    ) external onlyOwner returns (uint256 baseProfit) {
        bytes memory data = abi.encode(
            vSupplyToken,
            vloanToken,
            loanAmount,
            minOuts,
            _data
        );
        console.log("flashLoan");
        console.log("flashLoan2:", minOuts.length);
        console.log("flashLoan3:", _data.length);
        IDODO(_DODO_).sellBaseToken(amount, 0, data);
        baseProfit = IERC20(_BASE_).balanceOf(address(this));
        return baseProfit;
    }

    function _repay(FlashLoanInfo memory info) internal {
        //Repay Borrowed Token to Venus
        address borrowedToken = info.supplyToken;
        IvBEP20 vBorrowedToken = IvBEP20(info.vSupplyToken);
        uint256 borrowedAmount = info.loanedAmount;
        uint256 dodoReturnAmount = info.returnAmount;
        IERC20(borrowedToken).approve(address(vBorrowedToken), borrowedAmount);
        assert(vBorrowedToken.repayBorrowBehalf(address(this),borrowedAmount) == 0);
        // Withdraw Deposit Token from Venus
        IvBEP20 vTokenQuote = IvBEP20(vQuote);
        assert(vTokenQuote.redeemUnderlying(dodoReturnAmount)==0);
        totalBorrow[borrowedToken] -= borrowedAmount;       
    }

    function _setCollateral(address[] memory tokens) internal {
        // Set Supply as Colletral
        IUnitroller troll = IUnitroller(Unitroller_address);
        troll.enterMarkets(tokens);
    }
    function _action(FlashLoanInfo memory info, uint256 swapIndex) internal {
        console.log("action start=");
        address[] memory vTokens = new address[](1);
        address supplyToken = info.supplyToken;
        IvBEP20 vSupplyToken = IvBEP20(info.vSupplyToken);
        uint256 loanedAmount = info.loanedAmount;
        address loanToken = info.loanToken;
        IvBEP20 vLoanToken = IvBEP20(info.vLoanToken);
        uint256 returnAmount = info.returnAmount;
        uint256 loanAmount = info.loanAmount;
        vTokens[0] = info.vSupplyToken;
        _setCollateral(vTokens);
        console.log("action=",info.loanedAmount);
        console.log("action2=",info.returnAmount);
        console.log("action3=",info.loanAmount);
        // Deposit Supply Token to Venus
        IERC20(supplyToken).approve(address(vSupplyToken), loanedAmount);
        assert(vSupplyToken.mint(loanedAmount) == 0);
        // Borrow Loan Token from Venus
        console.log("action4=");

        //Check if loan Token is the same as return Token
        if( loanToken == info.returnToken ) {
            console.log("action5=");
            require(
                vLoanToken.borrow(returnAmount) == 0,
                "Borrow from Venus failed!"
            );
            totalBorrow[address(vLoanToken)] += returnAmount;                
            console.log("action6=");
        }
        else {
                require(
                vLoanToken.borrow(loanAmount) == 0,
                "Borrow from Venus failed!"
            );
            //Swap Loan Token to Return Token
            uint256 returnTokenOut = this.Swap(info.minOuts[swapIndex], info.inchDatas[swapIndex]);
            require(returnTokenOut>=returnAmount);
            totalBorrow[address(vLoanToken)] += loanAmount;               
        }        
    }

    function dodoCall(
        bool isRepayBorrow,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        console.log("dodoCall");
        uint256 inchIdx = 0;
        FlashLoanInfo memory info;
        (
            info.vSupplyToken,           // Supply vToken or Borrowed vToken address
            info.vLoanToken,              // Token address to loan from Venus(Don't necessary in repay)
            info.loanAmount,             // Token Amount to loan from Venus(Don't necessary in repay)
            info.minOuts,       // 1inch swap Min require amount
            info.inchDatas        // 1inch swap parameters
        ) = abi.decode(data,(address,address,uint256,uint256[],bytes[]));

        info.loanedToken = isRepayBorrow ? _BASE_ : _QUOTE_;
        info.loanedAmount = isRepayBorrow ? baseAmount : quoteAmount;
        info.returnAmount = isRepayBorrow ? quoteAmount : baseAmount;
        info.returnToken = isRepayBorrow ? _QUOTE_ : _BASE_;
        info.supplyToken = getUnderlyingAddress(info.vSupplyToken);
        info.loanToken = getUnderlyingAddress(info.vLoanToken);
        console.log("dodoCall2");
        require(msg.sender == _DODO_, "WRONG_DODO");
        console.log("dodoCall3", info.loanedToken);
        console.log("dodoCall3-2", info.supplyToken);
        console.log("dodoCall3-3:", info.minOuts.length);
        console.log("dodoCall3-4:", info.inchDatas.length);

        //console.log("dodoCall4", info.minOuts[0]);
        //console.log("dodoCall5", info.inchDatas[0]);
        console.log("dodoCall6", isRepayBorrow);
        // Check if Loaned Token == Supply Token
        if( info.loanedToken != info.supplyToken) {
            // Swap Loaned Token to Supply Token
            info.loanedAmount = this.Swap(info.minOuts[inchIdx], info.inchDatas[inchIdx]);
            inchIdx++;
        }

        if( isRepayBorrow ) {
            _repay( info);
        }
        else {
            _action(info, inchIdx);
        }
    }

    function retrieve(address token, uint256 amount) external onlyOwner{
        IERC20(token).transfer(msg.sender, amount);
    }

    function depositToVenus(address _vToken, uint256 _amount) external {
        address _token = getUnderlyingAddress(_vToken);
        IvBEP20 vToken;
        vToken = IvBEP20(_vToken);
        IERC20(_token).transferFrom(msg.sender, address(this),_amount);
        IERC20(_token).approve(address(vToken), _amount);
        assert(vToken.mint(_amount) == 0);

        //Set Token as Calletral
        address[] memory vTokens = new address[](1);
        vTokens[0] = _vToken;
        _setCollateral(vTokens);

        depositInfo[msg.sender][_token] += _amount;
    }

    function withdrawFromVenus(
        address _vToken, 
        uint256 _amount, 
        uint256 _minOut,
        bytes calldata _data
    ) external {
        address _token = getUnderlyingAddress(_vToken);
        require(depositInfo[msg.sender][_token] >= _amount, "no token to withdraw");
        if( totalBorrow[_token] > 0)
            _repayBorrow(_vToken, totalBorrow[_token], _minOut, _data);
        IvBEP20 vToken;
        vToken = IvBEP20(_vToken);
        assert(vToken.redeemUnderlying(_amount) == 0);
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function claimReward(uint256 minOut, bytes calldata inchData) external onlyOwner {
        IUnitroller troll = IUnitroller(Unitroller_address);
        troll.claimVenus(address(this));

        uint256 amount = IERC20(XVS).balanceOf(address(this));
        // Approve XVS to 1inch Router
        IERC20(XVS).approve(inch_aggregation_router, amount);
        // Swap to USDT   
        Swap(minOut, inchData);
    }

    function getUnderlyingAddress(address _vToken) internal returns(address) {
        IvBEP20 vToken;
        vToken = IvBEP20(_vToken);
        return vToken.underlying();  
    }

    function Swap( uint minOut, bytes calldata _data) public returns(uint256){
        (, SwapDescription memory desc, ) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        IERC20(desc.srcToken).transferFrom(msg.sender, address(this), desc.amount);
        IERC20(desc.srcToken).approve(inch_aggregation_router, desc.amount);

        (bool succ, bytes memory _result) = address(inch_aggregation_router).call(_data);
        if (succ) {
            (uint returnAmount, ) = abi.decode(_result, (uint, uint));
            require(returnAmount >= minOut);
            return returnAmount;
        } else {
            revert();
        }
    }
}