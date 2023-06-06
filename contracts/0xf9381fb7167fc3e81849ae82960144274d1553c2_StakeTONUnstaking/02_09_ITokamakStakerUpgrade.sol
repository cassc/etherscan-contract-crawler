//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface ITokamakStakerUpgrade {

    /// @dev the total staked amount
    function tokamakLayer2() external view returns (address);

    /// @dev the total staked amount
    function totalStakedAmount() external view returns (uint256);

    /// @dev the staking start block, once staking starts, users can no longer apply for staking.
    function startBlock() external view returns (uint256);

    /// @dev the staking end block.
    function endBlock() external view returns (uint256);

    /// @dev Change the TON holded in contract have to WTON, or change WTON to TON.
    /// @param amount the amount to be changed
    /// @param toWTON if it's true, TON->WTON , else WTON->TON
    function swapTONtoWTON(uint256 amount, bool toWTON) external;

    /// @dev  staking the staked TON in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    /// @param stakeAmount the amount that stake to layer2
    function tokamakStaking(address _layer2, uint256 stakeAmount) external;

    /// @dev  request unstaking the wtonAmount in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    /// @param wtonAmount the amount requested to unstaking
    function tokamakRequestUnStaking(address _layer2, uint256 wtonAmount)
        external;

    /// @dev  request unstaking the wtonAmount in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    function tokamakRequestUnStakingAll(address _layer2) external;

    /// @dev process unstaking in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    function tokamakProcessUnStaking(address _layer2) external;

    /// @dev exchange holded WTON to TOS using uniswap-v3
    /// @param _amountIn the input amount
    /// @param _amountOutMinimum the minimun output amount
    /// @param _deadline deadline
    /// @param _sqrtPriceLimitX96 sqrtPriceLimitX96
    /// @param _kind the function type, if 0, use exactInputSingle function, else if, use exactInput function
    function exchangeWTONtoTOS(
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint256 _deadline,
        uint160 _sqrtPriceLimitX96,
        uint256 _kind
    ) external returns (uint256 amountOut);

    function canTokamakRequestUnStaking(address _layer2)
        external
        view
        returns (uint256 canUnStakingAmount);

    function canTokamakRequestUnStakingAll(address _layer2)
        external
        view
        returns (bool can);

    function canTokamakRequestUnStakingAllBlock(address _layer2)
        external
        view
        returns (uint256 _block);

    function canTokamakProcessUnStakingCount(address _layer2)
        external
        view
        returns (uint256 count, uint256 amount);
}