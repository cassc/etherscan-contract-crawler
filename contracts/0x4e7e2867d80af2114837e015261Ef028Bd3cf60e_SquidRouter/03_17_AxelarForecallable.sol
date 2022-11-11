// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';
import { IERC20 } from '../interfaces/IERC20.sol';
import { IAxelarForecallable } from '../interfaces/IAxelarForecallable.sol';

contract AxelarForecallable is IAxelarForecallable {
    IAxelarGateway public immutable gateway;

    //keccak256('forecallers');
    uint256 public constant FORECALLERS_SALT = 0xdb79ee324babd8834c3c1a1a2739c004fce73b812ac9f637241ff47b19e4b71f;

    constructor(address gateway_) {
        if (gateway_ == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(gateway_);
    }

    function getForecaller(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) public view override returns (address forecaller) {
        bytes32 pos = keccak256(abi.encode(sourceChain, sourceAddress, payload, FORECALLERS_SALT));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            forecaller := sload(pos)
        }
    }

    function _setForecaller(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        address forecaller
    ) internal {
        bytes32 pos = keccak256(abi.encode(sourceChain, sourceAddress, payload, FORECALLERS_SALT));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(pos, forecaller)
        }
    }

    function forecall(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        _checkForecall(sourceChain, sourceAddress, payload, msg.sender);
        if (getForecaller(sourceChain, sourceAddress, payload) != address(0)) revert AlreadyForecalled();
        _setForecaller(sourceChain, sourceAddress, payload, msg.sender);
        _execute(sourceChain, sourceAddress, payload);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external override {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();
        address forecaller = getForecaller(sourceChain, sourceAddress, payload);
        if (forecaller != address(0)) {
            _setForecaller(sourceChain, sourceAddress, payload, address(0));
        } else {
            _execute(sourceChain, sourceAddress, payload);
        }
    }

    function getForecallerWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) public view override returns (address forecaller) {
        bytes32 pos = keccak256(abi.encode(sourceChain, sourceAddress, payload, symbol, amount, FORECALLERS_SALT));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            forecaller := sload(pos)
        }
    }

    function _setForecallerWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address forecaller
    ) internal {
        bytes32 pos = keccak256(abi.encode(sourceChain, sourceAddress, payload, symbol, amount, FORECALLERS_SALT));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(pos, forecaller)
        }
    }

    function forecallWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external override {
        address token = gateway.tokenAddresses(tokenSymbol);
        uint256 amountPost = amountPostFee(amount, payload);
        _safeTransferFrom(token, msg.sender, amountPost);
        _checkForecallWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount, msg.sender);
        if (getForecallerWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount) != address(0))
            revert AlreadyForecalled();
        _setForecallerWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount, msg.sender);
        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amountPost);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external override {
        bytes32 payloadHash = keccak256(payload);
        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();
        address forecaller = getForecallerWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
        if (forecaller != address(0)) {
            _setForecallerWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount, address(0));
            address token = gateway.tokenAddresses(tokenSymbol);
            _safeTransfer(token, forecaller, amount);
        } else {
            _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
        }
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal virtual {}

    // Override this to keep a fee.
    function amountPostFee(
        uint256 amount,
        bytes calldata /*payload*/
    ) public virtual override returns (uint256) {
        return amount;
    }

    // Override this and revert if you want to only allow certain people/calls to be able to forecall.
    function _checkForecall(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        address forecaller
    ) internal virtual {}

    // Override this and revert if you want to only allow certain people/calls to be able to forecall.
    function _checkForecallWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount,
        address forecaller
    ) internal virtual {}

    function _safeTransfer(
        address tokenAddress,
        address receiver,
        uint256 amount
    ) internal {
        (bool success, bytes memory returnData) = tokenAddress.call(
            abi.encodeWithSelector(IERC20.transfer.selector, receiver, amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || tokenAddress.code.length == 0) revert TransferFailed();
    }

    function _safeTransferFrom(
        address tokenAddress,
        address from,
        uint256 amount
    ) internal {
        (bool success, bytes memory returnData) = tokenAddress.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || tokenAddress.code.length == 0) revert TransferFailed();
    }
}