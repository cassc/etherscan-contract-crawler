// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IPool {
    struct Position {
        uint256 openPrice;
        uint256 openBlock;
        uint256 margin;
        uint256 size;
        uint256 openRebase;
        address account;
        uint8 direction;
    }

    function _positions(uint32 positionId)
        external
        view
        returns (
            uint256 openPrice,
            uint256 openBlock,
            uint256 margin,
            uint256 size,
            uint256 openRebase,
            address account,
            uint8 direction
        );

    function debtToken() external view returns (address);

    function lsTokenPrice() external view returns (uint256);

    function addLiquidity(address user, uint256 amount) external;

    function removeLiquidity(address user, uint256 lsAmount, uint256 bondsAmount, address receipt) external;

    function openPosition(
        address user,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external returns (uint32);

    function addMargin(
        address user,
        uint32 positionId,
        uint256 margin
    ) external;

    function closePosition(
        address receipt,
        uint32 positionId
    ) external;

    function liquidate(
        address user,
        uint32 positionId,
        address receipt
    ) external;

    function exit(
        address receipt,
        uint32 positionId
    ) external;

    event MintLiquidity(uint256 amount);

    event AddLiquidity(
        address indexed sender,
        uint256 amount,
        uint256 lsAmount,
        uint256 bonds
    );

    event RemoveLiquidity(
        address indexed sender,
        uint256 amount,
        uint256 lsAmount,
        uint256 bondsRequired
    );

    event OpenPosition(
        address indexed sender,
        uint256 openPrice,
        uint256 openRebase,
        uint8 direction,
        uint16 level,
        uint256 margin,
        uint256 size,
        uint32 positionId
    );

    event AddMargin(
        address indexed sender,
        uint256 margin,
        uint32 positionId
    );

    event ClosePosition(
        address indexed receipt,
        uint256 closePrice,
        uint256 serviceFee,
        uint256 fundingFee,
        uint256 pnl,
        uint32  positionId,
        bool isProfit,
        int256 debtChange
    );

    event Liquidate(
        address indexed sender,
        uint32 positionID,
        uint256 liqPrice,
        uint256 serviceFee,
        uint256 fundingFee,
        uint256 liqReward,
        uint256 pnl,
        bool isProfit,
        uint256 debtRepay
    );

    event Rebase(uint256 rebaseAccumulatedLong, uint256 rebaseAccumulatedShort);
}