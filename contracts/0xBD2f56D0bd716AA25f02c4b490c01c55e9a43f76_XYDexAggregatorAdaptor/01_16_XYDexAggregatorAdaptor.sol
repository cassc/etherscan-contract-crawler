// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.2;

import { Address } from "Address.sol";
import "SafeERC20.sol";
import "ERC20.sol";
import "SafeMath.sol";
import "AccessControl.sol";
import "ReentrancyGuard.sol";
import "IDexAggregatorAdaptor.sol";
import "UniERC20.sol";


/// @title XYDexAggregatorAdaptor is to help exchange assets based on swap description struct
/// @notice Users can call `swap` method to swap assets
/// XYDexAggregatorAdaptor will forward the swap description to `caller` contract to perform multi-swap of assets
contract XYDexAggregatorAdaptor is IDexAggregatorAdaptor, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using UniERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    // ROLE_OWNER is superior to ROLE_STAFF
    bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");
    bytes32 public constant ROLE_STAFF = keccak256("ROLE_STAFF");
    bytes32 public constant ROLE_SWAPPER = keccak256("ROLE_SWAPPER");

    /// A contract that performs multi-swap according to given input data
    /// See Multicaller.sol for more info
    address payable public aggregator;

    /* ========== CONSTRUCTOR ========== */

    /// @dev Constuctor with owner / staff / caller
    /// @param owner The owner address
    /// @param staff The staff address
    /// @param _aggregator The caller contract address (MUST be a contract)
    constructor(address owner, address staff, address payable _aggregator) {
        _setRoleAdmin(ROLE_OWNER, ROLE_OWNER);
        _setRoleAdmin(ROLE_STAFF, ROLE_OWNER);
        _setRoleAdmin(ROLE_SWAPPER, ROLE_OWNER);
        _setupRole(ROLE_OWNER, owner);
        _setupRole(ROLE_STAFF, staff);

        require(Address.isContract(_aggregator), "Aggregator should be a contract");
        aggregator = _aggregator;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Set swapper address.
    /// @param swapper The swapper address. This adaptor should only be used
    /// by `swapper`.
    function setSwapper(address swapper) external onlyRole(ROLE_STAFF) {
        require(Address.isContract(swapper), "Swapper should be a contract");
        _setupRole(ROLE_SWAPPER, swapper);
    }

    /* ========== WRITE FUNCTIONS ========== */

    /// @notice Swap and check if it's done correctly according to swap description `desc`
    /// This function transfers asset from sender `msg.sender` and then call multicaller contract `caller` to perform multi-swap,
    /// and checks `minReturnAmount` in `desc` to ensure enough amount of desired token `toToken` is received after the swap.
    /// Only `ROLE_SWAPPER` is allowed to access the function.
    /// @param desc The description of the swap. See IDexAggregatorAdaptor.sol for more info.
    /// @param data Bytecode to execute the swap, forwarded to `caller`
    /// @return Received amount of `toToken` after the swap
    function swap(
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        override
        payable
        onlyRole(ROLE_SWAPPER)
        nonReentrant
        returns (uint256)
    {
        require(desc.minReturnAmount > 0, "Min return should not be 0");
        require(desc.receiver != address(0), "Invalid receiver");
        require(data.length > 0, "data should be not zero");

        IERC20 fromToken = desc.fromToken;
        IERC20 toToken = desc.toToken;

        require(msg.value == (fromToken.isETH() ? desc.amount : 0), "Invalid msg.value");
        uint256 amount;
        if (!fromToken.isETH()) {
            // Calculate balance diff for rebasing tokens.
            amount = fromToken.balanceOf(address(this));
            fromToken.safeTransferFrom(msg.sender, address(this), desc.amount);
            amount = fromToken.balanceOf(address(this)) - amount;
            fromToken.safeApprove(address(aggregator), amount);
        } else {
            amount = desc.amount;
        }

        address receiver = desc.receiver;
        uint256 toTokenBalance = toToken.uniBalanceOf(receiver);
        Address.functionCallWithValue(address(aggregator), data, msg.value, "call to XYDexAggregator failed");

        uint256 returnAmount = toToken.uniBalanceOf(receiver) - toTokenBalance;
        require(returnAmount >= desc.minReturnAmount, "Return amount is not enough");

        emit Swapped(
            msg.sender,
            fromToken,
            toToken,
            receiver,
            amount,
            returnAmount
        );
        return returnAmount;
    }

    /* ========== EVENTS ========== */

    event Swapped(
        address sender,
        IERC20 fromToken,
        IERC20 toToken,
        address receiver,
        uint256 spentAmount,
        uint256 returnAmount
    );
}