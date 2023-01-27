// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISquidRouter} from "./interfaces/ISquidRouter.sol";
import {ISquidMulticall} from "./interfaces/ISquidMulticall.sol";
import {AxelarForecallable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarForecallable.sol";
import {IAxelarGasService} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {AddressToString} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/StringAddressUtils.sol";
import {Upgradable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradables/Upgradable.sol";
import {RoledPausable} from "./RoledPausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SquidRouter is ISquidRouter, AxelarForecallable, Upgradable, RoledPausable {
    using AddressToString for address;

    IAxelarGasService private immutable gasService;
    IAxelarGasService private immutable forecallGasService;
    ISquidMulticall private immutable squidMulticall;

    error ZeroAddressProvided();

    constructor(
        address _gateway,
        address _gasService,
        address _forecallGasService,
        address _multicall
    ) AxelarForecallable(_gateway) {
        if (
            _gateway == address(0) ||
            _gasService == address(0) ||
            _forecallGasService == address(0) ||
            _multicall == address(0)
        ) revert ZeroAddressProvided();

        gasService = IAxelarGasService(_gasService);
        forecallGasService = IAxelarGasService(_forecallGasService);
        squidMulticall = ISquidMulticall(_multicall);
    }

    function bridgeCall(
        string calldata destinationChain,
        string calldata bridgedTokenSymbol,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        address refundRecipient,
        bool enableForecall
    ) external payable whenNotPaused {
        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);

        _safeTransferFrom(bridgedTokenAddress, msg.sender, amount);
        _bridgeCall(destinationChain, bridgedTokenSymbol, bridgedTokenAddress, calls, refundRecipient, enableForecall);
    }

    function callBridge(
        address token,
        uint256 amount,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata bridgedTokenSymbol,
        ISquidMulticall.Call[] calldata calls
    ) external payable whenNotPaused {
        fundAndRunMulticall(token, amount, calls);

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        uint256 bridgedTokenAmount = IERC20(bridgedTokenAddress).balanceOf(address(this));

        _approve(bridgedTokenAddress, address(gateway), bridgedTokenAmount);
        gateway.sendToken(destinationChain, destinationAddress, bridgedTokenSymbol, bridgedTokenAmount);
    }

    function callBridgeCall(
        address token,
        uint256 amount,
        string calldata destinationChain,
        string calldata bridgedTokenSymbol,
        ISquidMulticall.Call[] calldata sourceCalls,
        ISquidMulticall.Call[] calldata destinationCalls,
        address refundRecipient,
        bool enableForecall
    ) external payable whenNotPaused {
        fundAndRunMulticall(token, amount, sourceCalls);

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);

        _bridgeCall(
            destinationChain,
            bridgedTokenSymbol,
            bridgedTokenAddress,
            destinationCalls,
            refundRecipient,
            enableForecall
        );
    }

    function contractId() external pure override returns (bytes32 id) {
        id = keccak256("squid-router");
    }

    function fundAndRunMulticall(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] memory calls
    ) public payable whenNotPaused {
        uint256 valueToSend;

        if (token == address(0)) {
            valueToSend = amount;
        } else {
            _transferTokenToMulticall(token, amount);
        }

        squidMulticall.run{value: valueToSend}(calls);
    }

    function _executeWithToken(
        string calldata,
        string calldata,
        bytes calldata payload,
        string calldata bridgedTokenSymbol,
        uint256
    ) internal override {
        (ISquidMulticall.Call[] memory calls, address refundRecipient) = abi.decode(
            payload,
            (ISquidMulticall.Call[], address)
        );
        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        uint256 contractBalance = IERC20(bridgedTokenAddress).balanceOf(address(this));

        _approve(bridgedTokenAddress, address(squidMulticall), contractBalance);

        try squidMulticall.run(calls) {
            emit CrossMulticallExecuted(keccak256(payload));
        } catch (bytes memory reason) {
            // Refund tokens to refund recepient if swap fails
            _safeTransfer(bridgedTokenAddress, refundRecipient, contractBalance);
            emit CrossMulticallFailed(keccak256(payload), reason, refundRecipient);
        }
    }

    function _bridgeCall(
        string calldata destinationChain,
        string calldata bridgedTokenSymbol,
        address bridgedTokenAddress,
        ISquidMulticall.Call[] calldata calls,
        address refundRecipient,
        bool enableForecall
    ) private {
        if (refundRecipient == address(0)) revert ZeroAddressProvided();

        bytes memory payload = abi.encode(calls, refundRecipient);
        // Only works if destination router has same address
        string memory destinationContractAddress = address(this).toString();
        uint256 bridgedTokenBalance = IERC20(bridgedTokenAddress).balanceOf(address(this));

        if (address(this).balance > 0) {
            IAxelarGasService executionService = enableForecall ? forecallGasService : gasService;
            executionService.payNativeGasForContractCallWithToken{value: address(this).balance}(
                address(this),
                destinationChain,
                destinationContractAddress,
                payload,
                bridgedTokenSymbol,
                bridgedTokenBalance,
                refundRecipient
            );
        }
        _approve(bridgedTokenAddress, address(gateway), bridgedTokenBalance);
        gateway.callContractWithToken(
            destinationChain,
            destinationContractAddress,
            payload,
            bridgedTokenSymbol,
            bridgedTokenBalance
        );
    }

    function _approve(address tokenAddress, address spender, uint256 amount) private {
        if (IERC20(tokenAddress).allowance(address(this), spender) < amount) {
            // Not a security issue since the contract doesn't store tokens
            IERC20(tokenAddress).approve(spender, type(uint256).max);
        }
    }

    function _transferTokenToMulticall(address token, uint256 amount) private {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, msg.sender, address(squidMulticall), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TransferFailed();
    }

    function _setup(bytes calldata data) internal override {
        address _pauser = abi.decode(data, (address));
        if (_pauser == address(0)) revert("Invalid pauser address");
        _setPauser(_pauser);
    }
}