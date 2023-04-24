// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "./DForceStrategy.sol";

contract DForceStrategyBSC is DForceStrategy {
    address DODOV2Proxy02;
    address DODO_TokenOut;
    address[] DODO_Pairs;
    uint256 DODO_directions;

    /**
     * @notice Set StrategyToken to BLID swap information
     * @param _DODOV2Proxy02 : address of DODOV2Proxy02
     * @param _DODO_TokenOut : Final out token from DODO swap
     * @param _DODO_Pairs : array of pairs in DODO swap (DF -> _DODO_TokenOut)
     * @param _DODO_directions swap directions for each pair
     */
    function setDODOInfo(
        address _DODOV2Proxy02,
        address _DODO_TokenOut,
        address[] calldata _DODO_Pairs,
        uint256 _DODO_directions
    ) external onlyOwner {
        uint256 length = _DODO_Pairs.length;
        require(length >= 2, "DF6");

        DODOV2Proxy02 = _DODOV2Proxy02;
        DODO_TokenOut = _DODO_TokenOut;
        DODO_directions = _DODO_directions;

        DODO_Pairs = new address[](length);
        for (uint256 i = 0; i < length; ) {
            DODO_Pairs[i] = _DODO_Pairs[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Set Rewards to StrategyToken swap information
     * @param swapRouter : address of swap Router
     * @param path path to rewards to BLID, path[0] = DODO_TokenOut
     */
    function setRewardsToStrategyToken(
        address swapRouter,
        address[] calldata path
    ) external override onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "DF6");
        require(
            strategyToken == ZERO_ADDRESS ||
                (strategyToken != ZERO_ADDRESS &&
                    path[length - 1] == strategyToken),
            "DF8"
        );
        require(path[0] == DODO_TokenOut, "DF7");

        swapRouter_RewardsToStrategyToken = swapRouter;
        path_RewardsToStrategyToken = new address[](length);
        for (uint256 i = 0; i < length; ) {
            path_RewardsToStrategyToken[i] = path[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Adjustment of strategy token with rewards and get BLID
     */
    function _claimRewardsAdjustment(
        address _logic,
        address _rewardsToken,
        address _strategyXToken,
        bool rewardsTokenKill,
        int256 diff
    ) internal override {
        // If we need to lending,  swap Rewards to StrategyToken -> repay
        if (rewardsTokenKill == false) {
            _swapRewardsToStrategyToken(_logic, _rewardsToken);
            if (diff > 0) {
                ILogic(_logic).repayBorrow(_strategyXToken, uint256(diff));
            }
        }

        // If we need to redeem
        if (diff < 0) {
            ILogic(_logic).redeemUnderlying(_strategyXToken, uint256(0 - diff));
        }

        // Swap StrategyToken to BLID
        uint256 balanceStrategyToken = strategyToken == ZERO_ADDRESS
            ? address(_logic).balance
            : IERC20MetadataUpgradeable(strategyToken).balanceOf(_logic);
        if (balanceStrategyToken > 0) {
            ILogic(_logic).swap(
                swapRouter_StrategyTokenToBLID,
                balanceStrategyToken,
                0,
                path_StrategyTokenToBLID,
                true,
                block.timestamp + 300
            );
        }
    }

    /**
     * @notice Swap Rewares to Strategy Token (DODO, PancakeSwap)
     */
    function _swapRewardsToStrategyToken(address _logic, address _rewardsToken)
        internal
        override
    {
        // Swap DF -> BUSD using DODO
        address _DODO_TokenOut = DODO_TokenOut;
        address[] memory path = new address[](DODO_Pairs.length + 2);
        path[0] = _rewardsToken;
        path[1] = _DODO_TokenOut;

        for (uint256 i = 0; i < DODO_Pairs.length; ) {
            path[i + 2] = DODO_Pairs[i];
            unchecked {
                ++i;
            }
        }

        ILogic(_logic).swap(
            DODOV2Proxy02,
            IERC20MetadataUpgradeable(_rewardsToken).balanceOf(_logic),
            1,
            path,
            false,
            block.timestamp + 300 + BASE * DODO_directions
        );

        // Swap BUSD -> StrategyToken
        ILogic(_logic).swap(
            swapRouter_RewardsToStrategyToken,
            IERC20MetadataUpgradeable(_DODO_TokenOut).balanceOf(_logic),
            0,
            path_RewardsToStrategyToken,
            true,
            block.timestamp + 300
        );
    }
}