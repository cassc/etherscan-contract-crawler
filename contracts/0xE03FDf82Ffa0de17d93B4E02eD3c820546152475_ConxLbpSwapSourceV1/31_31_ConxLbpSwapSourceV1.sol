// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
}

struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

interface Vault {
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256 amountCalculated);
}

/**
 * @title ConxLbpSwapSourceV1
 * @notice A contract that can initiate a cross-chain Balancer vault swap on a target chain,
    where funds and swap params are sent to the target contract/chain.
 */
contract ConxLbpSwapSourceV1 {
    // events
    // Emit this event when the final transfer of lbp token is completed
    event BridgeSwapped(address indexed _recipient, bytes32 indexed _transferId, uint256 _value);

    // The connext contract on the origin domain.
    IConnext public immutable connext;

    constructor(IConnext _connext) {
        connext = _connext;
    }

    /**
     * @notice Transfers funds from one chain to another.
     * @param destinationDomain The destination domain ID.
     * @param tokenAddress Address of the token on the origin chain to transfer.
     * @param amount The amount to transfer.
     * @param connextSlippage The maximum amount of slippage the user will accept in BPS.
     * @param relayerFee The fee offered to relayers. On testnet, this can be 0.
     * @param singleSwap used for swap.
     * @param funds used for swap.
     * @param limit used for swap.
     * @param deadline used for swap.
     */
    function xTransfer(
        address targetContract,
        uint32 destinationDomain,
        address tokenAddress,
        uint256 amount,
        uint256 connextSlippage,
        uint256 relayerFee,
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (bytes32) {
        IERC20 token = IERC20(tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= amount, "User must approve amount");
        require(token.balanceOf(msg.sender) >= amount, "User does not have enough balance");

        // Caution: addition safeguards that cannot be caught on target chain
        require(funds.recipient != address(0), "recipient must be defined");
        require(singleSwap.assetIn != address(0), "assetIn must be defined");
        // because there isd a 0.05% routerFee
        require(singleSwap.amount <= amount, "swap amount cannot be more than bridged amount");

        // User sends funds to this contract
        token.transferFrom(msg.sender, address(this), amount);
        // This contract approves transfer to Connext
        token.approve(address(connext), amount);

        // Caution: Be sure this data encoding matches what will be decoded by the target contract
        bytes memory _callData = abi.encode(singleSwap, funds, limit, deadline);

        return
            connext.xcall{value: relayerFee}(
                destinationDomain, // _destination: Domain ID of the destination chain
                targetContract, // _to: address receiving the funds on the destination
                tokenAddress, // _asset: address of the token contract
                msg.sender, // _delegate: address that can revert or forceLocal on destination
                amount, // _amount: amount of tokens to transfer
                connextSlippage, // _slippage: the maximum amount of slippage the user will accept in BPS
                _callData // _callData: encoded msg.sender
            );
    }
}