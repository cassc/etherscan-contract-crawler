// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Interfaces/Pendle/IPendleRouter.sol";
import "./Interfaces/IBaseRewardPool.sol";
import "./Interfaces/IPendleBooster.sol";

contract EqbZap is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address internal constant NATIVE = address(0);

    IPendleBooster public booster;
    address public pendleRouter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function setParams(
        address _booster,
        address _pendleRouter
    ) external onlyOwner {
        require(_booster != address(0), "invalid _booster");
        require(_pendleRouter != address(0), "invalid _pendleRouter");

        booster = IPendleBooster(_booster);
        pendleRouter = _pendleRouter;
    }

    function zapIn(
        uint256 _pid,
        uint256 _minLpOut,
        IPendleRouter.ApproxParams calldata _guessPtReceivedFromSy,
        IPendleRouter.TokenInput calldata _input,
        bool _stake
    ) external payable {
        (address market, address token, address rewardPool, ) = booster
            .poolInfo(_pid);
        _transferIn(_input.tokenIn, msg.sender, _input.netTokenIn);
        _approveTokenIfNeeded(_input.tokenIn, pendleRouter, _input.netTokenIn);
        (uint256 netLpOut, ) = IPendleRouter(pendleRouter)
            .addLiquiditySingleToken{
            value: _input.tokenIn == NATIVE ? _input.netTokenIn : 0
        }(address(this), market, _minLpOut, _guessPtReceivedFromSy, _input);
        _approveTokenIfNeeded(market, address(booster), netLpOut);
        booster.deposit(_pid, netLpOut, false);

        if (_stake) {
            _approveTokenIfNeeded(token, rewardPool, netLpOut);
            IBaseRewardPool(rewardPool).stakeFor(msg.sender, netLpOut);
        } else {
            IERC20(token).safeTransfer(msg.sender, netLpOut);
        }
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        (address market, address token, address rewardPool, ) = booster
            .poolInfo(_pid);
        IBaseRewardPool(rewardPool).withdrawFor(msg.sender, _amount);
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        booster.withdraw(_pid, _amount);
        IERC20(market).safeTransfer(msg.sender, _amount);
    }

    function zapOut(
        uint256 _pid,
        uint256 _amount,
        IPendleRouter.TokenOutput calldata _output,
        bool _stake
    ) external {
        (address market, address token, address rewardPool, ) = booster
            .poolInfo(_pid);

        if (_stake) {
            IBaseRewardPool(rewardPool).withdrawFor(msg.sender, _amount);
        }

        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

        booster.withdraw(_pid, _amount);

        _approveTokenIfNeeded(market, pendleRouter, _amount);
        IPendleRouter(pendleRouter).removeLiquiditySingleToken(
            msg.sender,
            market,
            _amount,
            _output
        );
    }

    function claimRewards(uint256[] calldata _pids) external {
        for (uint256 i = 0; i < _pids.length; i++) {
            (, , address rewardPool, ) = booster.poolInfo(_pids[i]);
            require(rewardPool != address(0), "invalid _pids");
            IBaseRewardPool(rewardPool).getReward(msg.sender);
        }
    }

    function _transferIn(
        address _token,
        address _from,
        uint256 _amount
    ) internal {
        if (_token == NATIVE) {
            require(msg.value == _amount, "eth mismatch");
        } else if (_amount != 0) {
            require(msg.value == 0, "eth mismatch");
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        }
    }

    function _approveTokenIfNeeded(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_token == NATIVE) {
            return;
        }
        if (IERC20(_token).allowance(address(this), _to) < _amount) {
            IERC20(_token).safeApprove(_to, 0);
            IERC20(_token).safeApprove(_to, type(uint256).max);
        }
    }
}