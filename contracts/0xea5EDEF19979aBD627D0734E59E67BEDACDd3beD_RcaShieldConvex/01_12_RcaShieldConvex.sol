/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "../RcaShieldBase.sol";
import "../../external/Convex.sol";

contract RcaShieldConvex is RcaShieldBase {
    using SafeERC20 for IERC20Metadata;

    IConvexRewardPool public immutable rewardPool;

    constructor(
        string memory _name,
        string memory _symbol,
        address _uToken,
        address _governance,
        address _controller,
        IConvexRewardPool _rewardPool
    ) RcaShieldBase(_name, _symbol, _uToken, _governance, _controller) {
        rewardPool = _rewardPool;
        uToken.safeApprove(address(rewardPool), type(uint256).max);
    }

    function getReward() external {
        rewardPool.getReward(address(this), true);
    }

    function purchase(
        address _token,
        uint256 _amount, // token amount to buy
        uint256 _tokenPrice,
        bytes32[] calldata _tokenPriceProof,
        uint256 _underlyingPrice,
        bytes32[] calldata _underlyinPriceProof
    ) external {
        require(_token != address(uToken), "cannot buy underlying token");
        controller.verifyPrice(_token, _tokenPrice, _tokenPriceProof);
        controller.verifyPrice(address(uToken), _underlyingPrice, _underlyinPriceProof);
        uint256 underlyingAmount = (_amount * _tokenPrice) / _underlyingPrice;
        if (discount > 0) {
            underlyingAmount -= (underlyingAmount * discount) / DENOMINATOR;
        }
        IERC20Metadata(_token).safeTransfer(msg.sender, _amount);
        uToken.safeTransferFrom(msg.sender, address(this), underlyingAmount);
        rewardPool.stake(underlyingAmount);
    }

    function _uBalance() internal view override returns (uint256) {
        return uToken.balanceOf(address(this)) + rewardPool.balanceOf(address(this));
    }

    function _afterMint(uint256 _uAmount) internal override {
        rewardPool.stake(_uAmount);
    }

    function _afterRedeem(uint256 _uAmount) internal override {
        // CHEK : we are not going to claims rewards here since it will be claimed on _update
        rewardPool.withdraw(_uAmount, false);
    }
}