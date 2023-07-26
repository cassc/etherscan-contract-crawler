// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface ISplitMain {
    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    event CreateSplit(
        address indexed split,
        address[] accounts,
        uint32[] percentAllocations,
        uint32 distributorFee,
        address controller
    );

    event UpdateSplit(address indexed split, address[] accounts, uint32[] percentAllocations, uint32 distributorFee);

    event InitiateControlTransfer(address indexed split, address indexed newPotentialController);

    event CancelControlTransfer(address indexed split);

    event ControlTransfer(address indexed split, address indexed previousController, address indexed newController);

    event DistributeETH(address indexed split, uint256 amount, address indexed distributorAddress);

    event DistributeERC20(
        address indexed split, address indexed token, uint256 amount, address indexed distributorAddress
    );

    event Withdrawal(address indexed account, uint256 ethAmount, address[] tokens, uint256[] tokenAmounts);

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    function walletImplementation() external returns (address);

    function createSplit(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address controller
    ) external returns (address);

    function predictImmutableSplitAddress(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee
    ) external view returns (address);

    function updateSplit(
        address split,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee
    ) external;

    function transferControl(address split, address newController) external;

    function cancelControlTransfer(address split) external;

    function acceptControl(address split) external;

    function makeSplitImmutable(address split) external;

    function distributeETH(
        address split,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    ) external;

    function updateAndDistributeETH(
        address split,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    ) external;

    function distributeERC20(
        address split,
        address token,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    ) external;

    function updateAndDistributeERC20(
        address split,
        address token,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    ) external;

    function withdraw(address account, uint256 withdrawETH, address[] calldata tokens) external;

    function getHash(address split) external view returns (bytes32);

    function getController(address split) external view returns (address);
}