// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/interfaces/token/IToken.sol";
import "./Stargate.sol";

/// @title This Strategy will deposit ETH in a Stargate Pool
/// Stake LP Token and accrue swap rewards
contract StargateETH is Stargate {
    using SafeERC20 for TokenLike;

    TokenLike public immutable stargateETH;
    TokenLike public immutable wrappedNativeToken;

    constructor(
        address pool_,
        address swapper_,
        IStargateRouter stargateRouter_,
        IStargatePool stargateLp_,
        IStargateLpStaking stargateLpStaking_,
        uint256 stargatePoolId_,
        uint256 stargateLpStakingPoolId_,
        TokenLike wrappedNativeToken_,
        string memory name_
    )
        Stargate(
            pool_,
            swapper_,
            stargateRouter_,
            stargateLp_,
            stargateLpStaking_,
            stargatePoolId_,
            stargateLpStakingPoolId_,
            name_
        )
    {
        require(address(wrappedNativeToken_) != address(0), "wrapped-eth-is-null");

        stargateETH = TokenLike(stargateLp.token());
        wrappedNativeToken = wrappedNativeToken_;
    }

    receive() external payable {
        /// @dev Stargate will send ETH when we withdraw from Stargate ETH pool.
        /// So convert ETH to WETH if ETH sender is not WETH contract.
        if (msg.sender != address(wrappedNativeToken)) {
            wrappedNativeToken.deposit{value: address(this).balance}();
        }
    }

    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        stargateETH.safeApprove(address(stargateRouter), amount_);
    }

    /**
     * @dev Stargate ETH strategy supports sgETH as collateral and Vesper deals
     * in WETH. Hence withdraw ETH from WETH and deposit ETH into sgETH.
     */
    function _beforeDeposit(uint256 collateralAmount_) internal override {
        wrappedNativeToken.withdraw(collateralAmount_);
        stargateETH.deposit{value: collateralAmount_}();
    }
}