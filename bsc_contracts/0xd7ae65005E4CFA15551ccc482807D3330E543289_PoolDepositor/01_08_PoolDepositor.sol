// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Interfaces.sol";
import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/utils/Address.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/utils/Address.sol";

/**
 * @title   PoolDepositor
 * @author  WombexFinance
 * @notice  Allows to deposit underlying tokens and wrap them in lp tokens
 */
contract PoolDepositor is Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using SafeMath for uint256;

    address public weth;
    address public booster;
    address public masterWombat;
    mapping (address => uint256) public lpTokenToPid;

    /**
     * @param _weth             WETH
     * @param _booster          Booster
     * @param _masterWombat     MasterWombat
     */
    constructor(address _weth, address _booster, address _masterWombat) public Ownable() {
        weth =  _weth;
        booster =  _booster;
        masterWombat = _masterWombat;
    }

    /**
     * @notice Approve spending of router tokens by pool
     * @dev Needs to be done after asset deployment for router to be able to support the tokens
     * @param tokens    array of tokens to be approved
     * @param pool      to be approved to spend
     */
    function approveSpendingByPool(address[] calldata tokens, address pool) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            IERC20(tokens[i]).safeApprove(pool, 0);
            IERC20(tokens[i]).safeApprove(pool, type(uint256).max);
        }
    }

    function resqueTokens(address[] calldata _tokens, address _recipient) external onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeTransfer(_recipient, IERC20(_tokens[i]).balanceOf(address(this)));
        }
    }

    function resqueNative(address payable _recipient) external onlyOwner {
        _recipient.sendValue(address(this).balance);
    }

    function setBoosterLpTokensPid() external {
        uint256 poolLength = IBooster(booster).poolLength();

        for (uint256 i = 0; i < poolLength; i++) {
            (address lptoken, , , , ) = IBooster(booster).poolInfo(i);
            lpTokenToPid[lptoken] = i;
        }
    }

    receive() external payable {}

    function depositNative(address _lptoken, uint256 _minLiquidity, bool _stake) external payable {
        uint256 amount = msg.value;
        IWETH(weth).deposit{value: amount}();
        _deposit(_lptoken, weth, amount, _minLiquidity, _stake);
    }

    function withdrawNative(address _lptoken, uint256 _amount, uint256 _minOut, address payable _recipient) external {
        uint256 wethBalanceBefore = IERC20(weth).balanceOf(address(this));
        withdraw(_lptoken, _amount, _minOut, address(this));
        uint256 wethAmount = IERC20(weth).balanceOf(address(this)).sub(wethBalanceBefore);

        IWETH(weth).withdraw(wethAmount);
        _recipient.sendValue(wethAmount);
    }

    function deposit(address _lptoken, uint256 _amount, uint256 _minLiquidity, bool _stake) public {
        address underlying = IAsset(_lptoken).underlyingToken();

        IERC20(underlying).transferFrom(msg.sender, address(this), _amount);
        _deposit(_lptoken, underlying, _amount, _minLiquidity, _stake);
    }

    function _deposit(address _lptoken, address _underlying, uint256 _amount, uint256 _minLiquidity, bool _stake) internal {
        address pool = IAsset(_lptoken).pool();
        uint256 balanceBefore = IERC20(_lptoken).balanceOf(address(this));
        IPool(pool).deposit(_underlying, _amount, _minLiquidity, address(this), block.timestamp + 1, false);
        uint256 resultLpAmount = IERC20(_lptoken).balanceOf(address(this)).sub(balanceBefore);

        IBooster(booster).depositFor(lpTokenToPid[_lptoken], resultLpAmount, _stake, msg.sender);
    }

    function withdraw(address _lptoken, uint256 _amount, uint256 _minOut, address _recipient) public {
        address pool = IAsset(_lptoken).pool();
        (, , , address crvRewards, ) = IBooster(booster).poolInfo(lpTokenToPid[_lptoken]);

        IRewards(crvRewards).withdraw(_amount, address(this), msg.sender);

        address underlying = IAsset(_lptoken).underlyingToken();
        IPool(pool).withdraw(underlying, _amount, _minOut, _recipient, block.timestamp + 1);
    }
}