// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Library Imports */
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { IL2StandardERC20 } from "@eth-optimism/contracts/contracts/standards/IL2StandardERC20.sol";

import { IAltL1Bridge } from "./interfaces/IAltL1Bridge.sol";
import "./lzApp/NonblockingLzApp.sol";

/**
 * @title AltL1Bridge
 * @dev The AltL1Bridge is a contract which works together with the EthBridge to
 * enable ERC20 transitions between layers
 * This contract acts as a minter for new tokens when it hears about deposits into the EthBridge.
 * This contract also acts as a burner of the tokens intended for withdrawal, informing the
 * EthBridge to release L1 funds.
 *
 * Runtime target: EVM
 */
 contract AltL1Bridge is IAltL1Bridge, NonblockingLzApp {

    // set l1(eth) bridge address as setTrustedDomain()
    // dstChainId is primarily ethereum
    uint16 public dstChainId;

    // set allowance for custom gas limit
    bool public useCustomAdapterParams;
    uint public constant NO_EXTRA_GAS = 0;
    uint public constant FUNCTION_TYPE_SEND = 1;

    // set maximum amount of tokens can be transferred in 24 hours
    uint256 public maxTransferAmountPerDay;
    uint256 public transferredAmount;
    uint256 public transferTimestampCheckPoint;

    // Note: Specify the _lzEndpoint on this layer, _dstChainId is not the actual evm chainIds, but the layerZero
    // proprietary ones, pass the chainId of the destination for _dstChainId
    function initialize(address _lzEndpoint, uint16 _dstChainId, address _ethBridgeAddress) public initializer {
        require(_lzEndpoint != address(0), "lz endpoint cannot be zero address");

        __NonblockingLzApp_init(_lzEndpoint);
        // allow only a specific destination
        dstChainId = _dstChainId;
        // set l1(eth) bridge address on destination as setTrustedDomain()
        setTrustedRemote(_dstChainId, abi.encodePacked(_ethBridgeAddress));

        // set maximum amount of tokens can be transferred in 24 hours
        transferTimestampCheckPoint = block.timestamp;
        maxTransferAmountPerDay = 500_000e18;
    }

    /***************
     * Withdrawing *
     ***************/

    function withdraw(
        address _l2Token,
        uint256 _amount,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        bytes calldata _data
    ) external virtual payable {
        _initiateWithdrawal(_l2Token, msg.sender, msg.sender, _amount, _zroPaymentAddress, _adapterParams, _data);
    }

    function withdrawTo(
        address _l2Token,
        address _to,
        uint256 _amount,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        bytes calldata _data
    ) external virtual payable {
        _initiateWithdrawal(_l2Token, msg.sender, _to, _amount, _zroPaymentAddress, _adapterParams, _data);
    }

    function _initiateWithdrawal(
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
            require(transferredAmount <= maxTransferAmountPerDay, "max amount per day exceeded");
            transferTimestampCheckPoint = block.timestamp;
        }

        // When a withdrawal is initiated, we burn the withdrawer's funds to prevent subsequent L2
        // usage
        IL2StandardERC20(_l2Token).burn(msg.sender, _amount);

        // Construct calldata for l1TokenBridge.finalizeERC20Withdrawal(_to, _amount)
        address l1Token = IL2StandardERC20(_l2Token).l1Token();

        bytes memory payload = abi.encode(
            l1Token,
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

        // Send payload to Ethereum
        _lzSend(dstChainId, payload, payable(msg.sender), _zroPaymentAddress, _adapterParams);

        emit WithdrawalInitiated(l1Token, _l2Token, msg.sender, _to, _amount, _data);
    }

    /************************************
     * Cross-chain Function: Depositing *
     ************************************/

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

        // Check the target token is compliant and
        // verify the deposited token on L1 matches the L2 deposited token representation here
        if (
            ERC165Checker.supportsInterface(_l2Token, 0x1d1d8b63) &&
            _l1Token == IL2StandardERC20(_l2Token).l1Token()
        ) {
            // When a deposit is finalized, we credit the account on L2 with the same amount of
            // tokens.
            IL2StandardERC20(_l2Token).mint(_to, _amount);
            emit DepositFinalized(_l1Token, _l2Token, _from, _to, _amount, _data);
        } else {
            // Either the L2 token which is being deposited-into disagrees about the correct address
            // of its L1 token, or does not support the correct interface.
            // This should only happen if there is a  malicious L2 token, or if a user somehow
            // specified the wrong L2 token address to deposit into.
            // In either case, we stop the process here and construct a withdrawal
            // message so that users can get their funds out in some cases.
            // since, sending messages will need fees to be paid in the native token, this call cannot succeed directly
            // users, will have to call retryMessage with paying appropriate fee
            bytes memory payload = abi.encode(
                _l1Token,
                _l2Token,
                _to, // _to and _from interchanged
                _from,
                _amount,
                _data
            );

            // this is going to fail on the original relay, to get refund back in this case, user would
            // have to call retryMessage, also paying for the xMessage fee
            // custom adapters would not be applicable for this
            _lzSend(dstChainId, payload, payable(msg.sender), address(0x0), bytes(""));
        }
    }

    /**************
     *    Admin    *
     **************/

    function setDstChainId(uint16 _dstChainId) external onlyOwner {
        dstChainId = _dstChainId;
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams, uint _dstGasAmount) external onlyOwner() {
        useCustomAdapterParams = _useCustomAdapterParams;
        // set dstGas lookup, since only one dstchainId is allowed and its known
        setMinDstGasLookup(dstChainId, FUNCTION_TYPE_SEND, _dstGasAmount);
    }

    function setMaxTransferAmountPerDay(uint256 _maxTransferAmountPerDay) external onlyOwner() {
        maxTransferAmountPerDay = _maxTransferAmountPerDay;
    }
 }