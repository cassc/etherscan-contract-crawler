// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmPosition {
    event Create(
        address owner,
        uint256 positionId,
        address pair,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    event Increase(
        address owner,
        uint256 positionId,
        address pair,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    event Decrease(
        address owner,
        uint256 positionId,
        address pair,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    event Claim(
        address owner,
        uint256 positionId,
        address pair,
        uint256 amount
    );

    event Lock(
        address owner,
        uint256 positionId,
        address pair,
        uint256 locktime
    );

    event Burn(address owner, uint256 positionId);

    struct Position {
        address pair;
        address delegate;
        bool enableLock;
        uint32 lock;
        uint256 claimedAmount;
    }

    function factory() external view returns (address);

    function WETH() external view returns (address);

    function antfarmToken() external view returns (address);

    struct PositionDetails {
        uint256 id;
        address owner;
        address delegate;
        address pair;
        address token0;
        address token1;
        uint256 lp;
        uint256 reserve0;
        uint256 reserve1;
        uint256 dividend;
        uint256 cumulatedDividend;
        uint16 fee;
        bool enableLock;
        uint32 lock;
    }

    function getPositionDetails(uint256 positionId)
        external
        view
        returns (PositionDetails memory positionDetails);

    function getPositionsDetails(uint256[] calldata positionIds)
        external
        view
        returns (PositionDetails[] memory positionsDetails);

    function createPosition(
        address tokenA,
        address tokenB,
        uint16 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function createPositionETH(
        address token,
        uint16 fee,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    struct IncreasePositionParams {
        address tokenA;
        address tokenB;
        uint16 fee;
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 amountAMin;
        uint256 amountBMin;
        uint256 deadline;
        uint256 positionId;
    }

    function increasePosition(IncreasePositionParams calldata params)
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    struct IncreasePositionETHParams {
        address token;
        uint16 fee;
        uint256 amountTokenDesired;
        uint256 amountTokenMin;
        uint256 amountETHMin;
        uint256 deadline;
        uint256 positionId;
    }

    function increasePositionETH(IncreasePositionETHParams calldata params)
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function enableLock(uint256 positionId, uint256 deadline) external;

    function disableLock(uint256 positionId, uint256 deadline) external;

    function lockPosition(
        uint32 locktime,
        uint256 positionId,
        uint256 deadline
    ) external;

    function burn(uint256 positionId) external;

    function claimDividendGrouped(uint256[] calldata positionIds)
        external
        returns (uint256 claimedAmount);

    function getDividendPerPosition(address owner)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    struct DecreasePositionParams {
        address tokenA;
        address tokenB;
        uint16 fee;
        uint256 liquidity;
        uint256 amountAMin;
        uint256 amountBMin;
        address to;
        uint256 deadline;
        uint256 positionId;
    }

    function decreasePosition(DecreasePositionParams calldata params)
        external
        returns (uint256 amountA, uint256 amountB);

    struct DecreasePositionETHParams {
        address token;
        uint16 fee;
        uint256 liquidity;
        uint256 amountTokenMin;
        uint256 amountETHMin;
        address to;
        uint256 deadline;
        uint256 positionId;
    }

    function decreasePositionETH(DecreasePositionETHParams calldata params)
        external
        returns (uint256 amountToken, uint256 amountETH);

    function claimDividend(uint256 positionId)
        external
        returns (uint256 claimedAmount);

    function getPositionsIds(address owner)
        external
        view
        returns (uint256[] memory positionIds);
}