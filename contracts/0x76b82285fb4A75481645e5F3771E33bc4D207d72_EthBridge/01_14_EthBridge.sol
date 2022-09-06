// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IEthBridge } from "./interfaces/IEthBridge.sol";
import "./lzApp/NonblockingLzApp.sol";

/**
 * @title EthBridge
 * @dev EthBridge is a contract on Ethereum which stores deposited L1 funds (ERC20s) in order to be wrapped
 * and used on other L1s. It uses LayerZero messages to synchronize a corresponding Bridge on the
 * other layer, informing it of deposits and listening to it for newly finalized withdrawals.
 *
 * Runtime target: EVM
 */
 contract EthBridge is IEthBridge, NonblockingLzApp {
    using SafeERC20 for IERC20;

    // set altl1 bridge address as setTrustedDomain()
    uint16 public dstChainId;

    // set allowance for custom gas limit
    bool public useCustomAdapterParams;
    uint public constant NO_EXTRA_GAS = 0;
    uint public constant FUNCTION_TYPE_SEND = 1;

    // set maximum amount of tokens can be transferred in 24 hours
    uint256 public maxTransferAmountPerDay;
    uint256 public transferredAmount;
    uint256 public transferTimestampCheckPoint;

    // Maps L1 token to wrapped token on alt l1 to balance of the L1 token deposited
    mapping(address => mapping(address => uint256)) public deposits;

    // Note: Specify the _lzEndpoint on this layer, _dstChainId is not the actual evm chainIds, but the layerZero
    // proprietary ones, pass the chainId of the destination for _dstChainId
    function initialize(address _lzEndpoint, uint16 _dstChainId, address _altL1BridgeAddress) public initializer {
        require(_lzEndpoint != address(0), "lz endpoint cannot be zero address");

        __NonblockingLzApp_init(_lzEndpoint);
        // allow only a specific destination
        dstChainId = _dstChainId;
        // set altl1 bridge address on destination as setTrustedDomain()
        setTrustedRemote(_dstChainId, abi.encodePacked(_altL1BridgeAddress));

        // set maximum amount of tokens can be transferred in 24 hours
        transferTimestampCheckPoint = block.timestamp;
        maxTransferAmountPerDay = 500_000e18;
    }

    /**************
     * Depositing *
     **************/

    /** @dev Modifier requiring sender to be EOA.  This check could be bypassed by a malicious
     *  contract via initcode, but it takes care of the user error we want to avoid.
     */
    modifier onlyEOA() {
        // Used to stop deposits from contracts (avoid accidentally lost tokens)
        require(!Address.isContract(msg.sender), "Account not EOA");
        _;
    }

    function depositERC20(
        address _l1Token,
        address _l2Token,
        uint256 _amount,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        bytes calldata _data
    ) external virtual payable onlyEOA {
        _initiateERC20Deposit(_l1Token, _l2Token, msg.sender, msg.sender, _amount, _zroPaymentAddress, _adapterParams, _data);
    }

    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        bytes calldata _data
    ) external virtual payable {
        _initiateERC20Deposit(_l1Token, _l2Token, msg.sender, _to, _amount, _zroPaymentAddress, _adapterParams, _data);
    }

    // add nonreentrant
    function _initiateERC20Deposit(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        bytes calldata _data
    ) internal {
        require(_to != address(0), "_to cannot be zero address");

        // check if the total amount transferred is smaller than the maximum amount of tokens can be transferred in 24 hours
        // if it's out of 24 hours, reset the transferred amount to 0 and set the transferTimestampCheckPoint to the current time
        if (block.timestamp < transferTimestampCheckPoint + 86400) {
            transferredAmount += _amount;
            require(transferredAmount <= maxTransferAmountPerDay, "max amount per day exceeded");
        } else {
            transferredAmount = _amount;
            transferTimestampCheckPoint = block.timestamp;
        }

        // When a deposit is initiated on Ethereum, the Eth Bridge transfers the funds to itself for future
        // withdrawals. safeTransferFrom also checks if the contract has code, so this will fail if
        // _from is an EOA or address(0).
        IERC20(_l1Token).safeTransferFrom(_from, address(this), _amount);

        // construct payload to send, we don't explicitly specify the action, the receive on the
        // other side should expect only this action
        bytes memory payload = abi.encode(
            _l1Token,
            _l2Token,
            _from,
            _to,
            _amount,
            _data
        );
        if (useCustomAdapterParams) {
            _checkGasLimit(dstChainId, FUNCTION_TYPE_SEND, _adapterParams, NO_EXTRA_GAS);
        } else {
            require(_adapterParams.length == 0, "LzApp: _adapterParams must be empty.");
        }

        deposits[_l1Token][_l2Token] = deposits[_l1Token][_l2Token] + _amount;

        // Send payload to the other L1
        _lzSend(dstChainId, payload, payable(msg.sender), _zroPaymentAddress, _adapterParams);

        emit ERC20DepositInitiated(_l1Token, _l2Token, _from, _to, _amount, _data);
    }

    /**************
     * Withdrawing *
     **************/

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        // sanity check
        // _srcAddress is already checked on an upper level
        require(_srcChainId == dstChainId, "Invalid source chainId");
        (
            address _l1Token,
            address _l2Token,
            address _from,
            address _to,
            uint256 _amount,
            bytes memory _data
        ) = abi.decode(_payload, (address, address, address, address, uint256, bytes));

        deposits[_l1Token][_l2Token] = deposits[_l1Token][_l2Token] - _amount;
        IERC20(_l1Token).safeTransfer(_to, _amount);

        emit ERC20WithdrawalFinalized(_l1Token, _l2Token, _from, _to, _amount, _data);
    }

    /**************
     *    Admin    *
     **************/

    function setUseCustomAdapterParams(bool _useCustomAdapterParams, uint _dstGasAmount) external onlyOwner() {
        useCustomAdapterParams = _useCustomAdapterParams;
        // set dstGas lookup, since only one dstchainId is allowed and its known
        setMinDstGasLookup(dstChainId, FUNCTION_TYPE_SEND, _dstGasAmount);
    }

    function setMaxTransferAmountPerDay(uint256 _maxTransferAmountPerDay) external onlyOwner() {
        maxTransferAmountPerDay = _maxTransferAmountPerDay;
    }
}