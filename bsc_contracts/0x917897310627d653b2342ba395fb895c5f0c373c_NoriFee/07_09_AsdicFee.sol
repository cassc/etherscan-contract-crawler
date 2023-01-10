// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPancakeSwap.sol";
import "./interfaces/IAsdicFee.sol";

contract NoriFee is Ownable, INoriFee {
    using SafeERC20 for IERC20;

    IPancakeSwapV2Router02 public pancakeRouter;
    IERC20 public mos;
    IERC20 public asdic;
    IPancakeSwapV2Pair public pancakeSwapV2Pair;

    address public lpReceiver;
    bool public entered;


    address public mosNFTPool;  //10%
    address public mosLPPool;//10%
    address public asdicLPStakePool;//30%
    address public vipPermanentPool;//10%
    address public vipYearPool;//10%

    uint public mosNFTPoolRatio;  //10%
    uint public mosLPPoolRatio;//10%
    uint public asdicLPStakePoolRatio;//30%
    uint public asdicBottomPoolRatio;//30%
    uint public vipPermanentPoolRatio;//10%
    uint public vipYearPoolRatio;//10%

    uint constant internal PRECISION = 1000;


    modifier onlyAsdic() {
        require(msg.sender == address(asdic), "invalid caller");
        _;
    }

    constructor(address _pancakeRouter, address _mos, address pair,
        address _asdic, address _lpReceiver) {
        mos = IERC20(_mos);
        asdic = IERC20(_asdic);
        lpReceiver = _lpReceiver;
        pancakeRouter = IPancakeSwapV2Router02(_pancakeRouter);
        pancakeSwapV2Pair = IPancakeSwapV2Pair(pair);
        lpReceiver = msg.sender;
        mosNFTPoolRatio = 100;
        mosLPPoolRatio = 100;
        //10%
        asdicLPStakePoolRatio = 300;
        //30%
        asdicBottomPoolRatio = 300;
        //30%
        vipPermanentPoolRatio = 100;
        //10%
        vipYearPoolRatio = 100;
    }

    function setLpReceiver(address _lpReceiver) public onlyOwner {
        lpReceiver = _lpReceiver;
    }

    function setPoolAddress(address _mosNFTPool,
        address _mosLPPool, address _asdicLPStakePool,
        address _vipPermanentPool, address _vipYearPool) public onlyOwner {
        mosNFTPool = _mosNFTPool;
        mosLPPool = _mosLPPool;
        asdicLPStakePool = _asdicLPStakePool;
        vipPermanentPool = _vipPermanentPool;
        vipYearPool = _vipYearPool;
    }

    function setRatio(uint _coin2NFTPoolRatio, uint _coin2LPPoolRatio,
        uint _noriLPStakePoolRatio, uint _noriBottomPoolRatio,
        uint _vipPermanentPoolRatio, uint _vipYearPoolRatio) public onlyOwner {
        require(_coin2NFTPoolRatio + _coin2LPPoolRatio + _noriLPStakePoolRatio + _noriBottomPoolRatio +
        _vipPermanentPoolRatio + _vipYearPoolRatio == PRECISION, "invalid param");
        mosNFTPoolRatio = _coin2NFTPoolRatio;
        mosLPPoolRatio = _coin2LPPoolRatio;
        asdicLPStakePoolRatio = _noriLPStakePoolRatio;
        asdicBottomPoolRatio = _noriBottomPoolRatio;
        vipPermanentPoolRatio = _vipPermanentPoolRatio;
        vipYearPoolRatio = _vipYearPoolRatio;
    }

    function distributeFee(uint fee) public onlyAsdic {
        //TODO 买成coin2进入矿池
        addMosNFTPool(fee);
        asdic.transfer(mosLPPool, mosLPPoolRatio * fee / PRECISION);
        asdic.transfer(asdicLPStakePool, asdicLPStakePoolRatio * fee / PRECISION);
        //TODO 30个coin2——15个coin2买成nori+15coin2添加LP，把LP锁死，打入指定地址
        addAsdicBottomPool(fee);
        asdic.transfer(vipPermanentPool, vipPermanentPoolRatio * fee / PRECISION);
        asdic.transfer(vipYearPool, vipYearPoolRatio * fee / PRECISION);
    }

    function addMosNFTPool(uint fee) internal {
        uint coin2NFTPoolAmount = mosNFTPoolRatio * fee / PRECISION;
        address[] memory path = new address[](2);
        path[0] = address(asdic);
        path[1] = address(mos);
        uint coin2BalBefore = mos.balanceOf(address(this));
        asdic.approve(address(pancakeRouter), coin2NFTPoolAmount);
        pancakeRouter.swapExactTokensForTokens(coin2NFTPoolAmount, 0, path, address(this), block.timestamp);
        uint coin2BalAfter = mos.balanceOf(address(this));
        uint coin2Amount = coin2BalAfter - coin2BalBefore;
        mos.safeTransfer(mosNFTPool, coin2Amount);
    }

    function addAsdicBottomPool(uint fee) internal {
        uint noriBottomPoolAmount = asdicBottomPoolRatio * fee / PRECISION;
        address[] memory path = new address[](2);
        path[0] = address(asdic);
        path[1] = address(mos);
        uint coin2BalBefore = mos.balanceOf(address(this));
        asdic.approve(address(pancakeRouter), noriBottomPoolAmount);
        pancakeRouter.swapExactTokensForTokens(noriBottomPoolAmount / 2, 0, path, address(this), block.timestamp);
        uint coin2BalAfter = IERC20(mos).balanceOf(address(this));
        uint coin2Amount = coin2BalAfter - coin2BalBefore;
        mos.approve(address(pancakeRouter), coin2Amount);
        pancakeRouter.addLiquidity(address(asdic), address(mos),
            noriBottomPoolAmount / 2, coin2Amount,
            0, 0, lpReceiver, block.timestamp);
    }
}