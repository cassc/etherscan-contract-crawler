// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @title Keep3rHelper contract
/// @notice Contains all the helper functions used throughout the different files.
interface IKeep3rHelper {
    // Errors

    /// @notice Throws when none of the tokens in the liquidity pair is KP3R
    error LiquidityPairInvalid();

    // Variables

    /// @notice Address of KP3R token
    /// @return _kp3r Address of KP3R token
    // solhint-disable func-name-mixedcase
    function KP3R() external view returns (address _kp3r);

    /// @notice Address of KP3R-WETH pool to use as oracle
    /// @return _kp3rWeth Address of KP3R-WETH pool to use as oracle
    function KP3R_WETH_POOL() external view returns (address _kp3rWeth);

    /// @notice The minimum multiplier used to calculate the amount of gas paid to the Keeper for the gas used to perform a job
    ///         For example: if the quoted gas used is 1000, then the minimum amount to be paid will be 1000 * MIN / BOOST_BASE
    /// @return _multiplier The MIN multiplier
    function MIN() external view returns (uint256 _multiplier);

    /// @notice The maximum multiplier used to calculate the amount of gas paid to the Keeper for the gas used to perform a job
    ///         For example: if the quoted gas used is 1000, then the maximum amount to be paid will be 1000 * MAX / BOOST_BASE
    /// @return _multiplier The MAX multiplier
    function MAX() external view returns (uint256 _multiplier);

    /// @notice The boost base used to calculate the boost rewards for the keeper
    /// @return _base The boost base number
    function BOOST_BASE() external view returns (uint256 _base);

    /// @notice The targeted amount of bonded KP3Rs to max-up reward multiplier
    ///         For example: if the amount of KP3R the keeper has bonded is TARGETBOND or more, then the keeper will get
    ///                      the maximum boost possible in his rewards, if it's less, the reward boost will be proportional
    /// @return _target The amount of KP3R that comforms the TARGETBOND
    function TARGETBOND() external view returns (uint256 _target);

    // Methods
    // solhint-enable func-name-mixedcase

    /// @notice Calculates the amount of KP3R that corresponds to the ETH passed into the function
    /// @dev This function allows us to calculate how much KP3R we should pay to a keeper for things expressed in ETH, like gas
    /// @param _eth The amount of ETH
    /// @return _amountOut The amount of KP3R
    function quote(uint256 _eth) external view returns (uint256 _amountOut);

    /// @notice Returns the amount of KP3R the keeper has bonded
    /// @param _keeper The address of the keeper to check
    /// @return _amountBonded The amount of KP3R the keeper has bonded
    function bonds(address _keeper) external view returns (uint256 _amountBonded);

    /// @notice Calculates the reward (in KP3R) that corresponds to a keeper for using gas
    /// @param _keeper The address of the keeper to check
    /// @param _gasUsed The amount of gas used that will be rewarded
    /// @return _kp3r The amount of KP3R that should be awarded to the keeper
    function getRewardAmountFor(address _keeper, uint256 _gasUsed) external view returns (uint256 _kp3r);

    /// @notice Calculates the boost in the reward given to a keeper based on the amount of KP3R that keeper has bonded
    /// @param _bonds The amount of KP3R tokens bonded by the keeper
    /// @return _rewardBoost The reward boost that corresponds to the keeper
    function getRewardBoostFor(uint256 _bonds) external view returns (uint256 _rewardBoost);

    /// @notice Calculates the reward (in KP3R) that corresponds to tx.origin for using gas
    /// @param _gasUsed The amount of gas used that will be rewarded
    /// @return _amount The amount of KP3R that should be awarded to tx.origin
    function getRewardAmount(uint256 _gasUsed) external view returns (uint256 _amount);

    /// @notice Given a pool address, returns the underlying tokens of the pair
    /// @param _pool Address of the correspondant pool
    /// @return _token0 Address of the first token of the pair
    /// @return _token1 Address of the second token of the pair
    function getPoolTokens(address _pool) external view returns (address _token0, address _token1);

    /// @notice Defines the order of the tokens in the pair for twap calculations
    /// @param _pool Address of the correspondant pool
    /// @return _isKP3RToken0 Boolean indicating the order of the tokens in the pair
    function isKP3RToken0(address _pool) external view returns (bool _isKP3RToken0);

    /// @notice Given an array of secondsAgo, returns UniswapV3 pool cumulatives at that moment
    /// @param _pool Address of the pool to observe
    /// @param _secondsAgo Array with time references to observe
    /// @return _tickCumulative1 Cummulative sum of ticks until first time reference
    /// @return _tickCumulative2 Cummulative sum of ticks until second time reference
    /// @return _success Boolean indicating if the observe call was succesfull
    function observe(address _pool, uint32[] memory _secondsAgo)
        external
        view
        returns (
            int56 _tickCumulative1,
            int56 _tickCumulative2,
            bool _success
        );

    /// @notice Given a tick and a liquidity amount, calculates the underlying KP3R tokens
    /// @param _liquidityAmount Amount of liquidity to be converted
    /// @param _tickDifference Tick value used to calculate the quote
    /// @param _timeInterval Time value used to calculate the quote
    /// @return _kp3rAmount Amount of KP3R tokens underlying on the given liquidity
    function getKP3RsAtTick(
        uint256 _liquidityAmount,
        int56 _tickDifference,
        uint256 _timeInterval
    ) external pure returns (uint256 _kp3rAmount);

    /// @notice Given a tick and a token amount, calculates the output in correspondant token
    /// @param _baseAmount Amount of token to be converted
    /// @param _tickDifference Tick value used to calculate the quote
    /// @param _timeInterval Time value used to calculate the quote
    /// @return _quoteAmount Amount of credits deserved for the baseAmount at the tick value
    function getQuoteAtTick(
        uint128 _baseAmount,
        int56 _tickDifference,
        uint256 _timeInterval
    ) external pure returns (uint256 _quoteAmount);
}