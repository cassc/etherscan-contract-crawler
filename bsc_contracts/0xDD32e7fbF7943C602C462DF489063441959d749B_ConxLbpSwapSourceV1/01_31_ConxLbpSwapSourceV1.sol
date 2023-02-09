// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";
//import {IXReceiver} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IXReceiver.sol";
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
 * @title SimpleBridge
 * @notice Example of a cross-domain token transfer.
 */
contract ConxLbpSwapSourceV1 {

    // events
    // Emit this event when the final transfer of lbp token is completed
    event BridgeSwapped(address indexed _recipient, bytes32 indexed _transferId, uint _value);

//    uint256 public cost = 1.0005003e18;

    // The connext contract on the origin domain.
    IConnext public immutable connext;

    constructor(IConnext _connext) {
        connext = _connext;
    }


    /**
     * @notice Transfers funds from one chain to another.
     * @param destinationDomain The destination domain ID.
     * @param tokenAddress Address of the token to transfer.
     * @param amount The amount to transfer.
     * @param connextSlippage The maximum amount of slippage the user will accept in BPS.
     * @param relayerFee The fee offered to relayers. On testnet, this can be 0.
     * @param singleSwap used for swap.
     * @param funds used for swap.
     * @param limit used for swap.
     * @param deadline used for swap.
     * @param lbpContractAddress lbp address on target chain.
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
        uint256 deadline,
        address lbpContractAddress
    ) external payable returns (bytes32) {
        IERC20 token = IERC20(tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= amount, "User must approve amount");
        require(token.balanceOf(msg.sender) >= amount, "User does not have enough balance");
        // User sends funds to this contract
        token.transferFrom(msg.sender, address(this), amount);
        // This contract approves transfer to Connext
        token.approve(address(connext), amount);

        bytes memory _callData = abi.encode(
            singleSwap,
            funds,
            limit,
            deadline,
            lbpContractAddress
        );

        return connext.xcall{value: relayerFee}(
            destinationDomain, // _destination: Domain ID of the destination chain
            targetContract,    // _to: address receiving the funds on the destination
            tokenAddress,      // _asset: address of the token contract
            msg.sender,        // _delegate: address that can revert or forceLocal on destination
            amount,            // _amount: amount of tokens to transfer
            connextSlippage,   // _slippage: the maximum amount of slippage the user will accept in BPS
            _callData         // _callData: encoded msg.sender
        );
    }
    // test function
    function xTransferTest(
        uint256 relayerFee,
        uint256 relayerSlippage,
        address targetContract,
        uint32 destinationDomain,
        address tokenAddress,
        uint256 netTransferAmount,
        bytes memory _callData
    ) external payable {



        IERC20 token = IERC20(tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= netTransferAmount, "User must approve amount");
        // User sends funds to this contract
        token.transferFrom(msg.sender, address(this), netTransferAmount);
        // This contract approves transfer to Connext
        token.approve(address(connext), netTransferAmount);



        connext.xcall{value: relayerFee}(
            destinationDomain, // _destination: Domain ID of the destination chain
            targetContract,    // _to: address receiving the funds on the destination
            tokenAddress,      // _asset: address of the token contract
            msg.sender,        // _delegate: address that can revert or forceLocal on destination
            netTransferAmount, // _amount: amount of tokens to transfer
            relayerSlippage,   // _slippage: the maximum amount of slippage the user will accept in BPS
            _callData         // _callData: encoded msg.sender
        );
    }

//    /**
//    * @notice The receiver function as required by the IXReceiver interface.
//    * @dev The ConXLbpSwapTarget contract will call this function.
//    */
//    function xReceive(
//        bytes32 _transferId,
//        uint256 _amount,
//        address _asset,
//        address _originSender,
//        uint32 _origin,
//        bytes memory _callData
//    ) external returns (bytes memory) {
//        // Because this call is *not* authenticated, the _originSender will be the Zero Address
//        // Probably no call data send here
//        (uint256 _swappedAmount) = abi.decode(_callData, (uint256));
//
//        emit BridgeSwapped(msg.sender, _transferId, _swappedAmount);
//    }

}