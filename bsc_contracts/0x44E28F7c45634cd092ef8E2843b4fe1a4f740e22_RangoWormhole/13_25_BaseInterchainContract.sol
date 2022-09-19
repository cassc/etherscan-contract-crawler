// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IUniswapV2.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IRangoStargate.sol";
import "../../interfaces/IStargateReceiver.sol";
import "./BaseProxyContract.sol";
import "../../interfaces/IRangoMessageReceiver.sol";

contract BaseInterchainContract is BaseProxyContract {

    /// @dev keccak256("exchange.rango.baseinterchaincontract")
    bytes32 internal constant BASE_MESSAGING_CONTRACT_NAMESPACE = hex"4c086c3e971f21b430782c034d778469729e11e13e4bc8ec046299c71c4c2877";

    struct BaseInterchainStorage {
        mapping (address => bool) whitelistMessagingContracts;
    }

    /// @notice Status of cross-chain swap
    /// @param Created It's sent to bridge and waiting for bridge response
    /// @param Succeeded The whole process is success and end-user received the desired token in the destination
    /// @param RefundInSource Bridge was out of liquidity and middle asset (ex: USDC) is returned to user on source chain
    /// @param RefundInDestination Our handler on dest chain this.executeMessageWithTransfer failed and we send middle asset (ex: USDC) to user on destination chain
    /// @param SwapFailedInDestination Everything was ok, but the final DEX on destination failed (ex: Market price change and slippage)
    enum OperationStatus {
        Created,
        Succeeded,
        RefundInSource,
        RefundInDestination,
        SwapFailedInDestination
    }

    /// @notice Notifies that a new contract is whitelisted
    /// @param _dapp The address of the contract
    event MessagingDAppWhitelisted(address _dapp);

    /// @notice Notifies that a new contract is blacklisted
    /// @param _dapp The address of the contract
    event MessagingDAppBlacklisted(address _dapp);


    /// @notice This event indicates that a dApp used Rango messaging (dAppMessage field) and we delivered the message to it
    /// @param _receiverContract The address of dApp's contract that was called
    /// @param _token The address of the token that is sent to the dApp, NULL_ADDRESS for native token
    /// @param _amount The amount of the token sent to them
    /// @param _status The status of operation, informing the dApp that the whole process was a success or refund
    /// @param _appMessage The custom message that the dApp asked Rango to deliver
    /// @param success Indicates that the function call to the dApp encountered error or not
    /// @param failReason If success = false, failReason will be the string reason of the failure (aka message of require)
    event CrossChainMessageCalled(
        address _receiverContract,
        address _token,
        uint _amount,
        IRangoMessageReceiver.ProcessStatus _status,
        bytes _appMessage,
        bool success,
        string failReason
    );

    /// @notice Adds a contract to the whitelisted messaging dApps that can be called
    /// @param _dapp The address of dApp
    function addMessagingDApp(address _dapp) public onlyOwner {
        BaseInterchainStorage storage baseStorage = getBaseMessagingContractStorage();
        baseStorage.whitelistMessagingContracts[_dapp] = true;
        emit MessagingDAppWhitelisted(_dapp);
    }

    /// @notice Adds a list of contracts to the whitelisted messaging dApps that can be called
    /// @param _dapps The addresses of dApps
    function addMessagingDApps(address[] calldata _dapps) external onlyOwner {
        for (uint i = 0; i < _dapps.length; i++)
            addMessagingDApp(_dapps[i]);
    }

    /// @notice Removes a contract from dApps that can be called
    /// @param _dapp The address of dApp
    function removeMessagingDApp(address _dapp) external onlyOwner {
        BaseInterchainStorage storage baseStorage = getBaseMessagingContractStorage();

        require(baseStorage.whitelistMessagingContracts[_dapp], "Factory not found");
        delete baseStorage.whitelistMessagingContracts[_dapp];

        emit MessagingDAppBlacklisted(_dapp);
    }

    function handleDestinationMessage(
        address _token,
        uint _amount,
        Interchain.RangoInterChainMessage memory m
    ) internal returns (address receivedToken, uint256 dstAmount, OperationStatus status) {
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();

        bool shouldDeposit = m.bridgeNativeOut || (_token == NULL_ADDRESS && m.path[0] == baseStorage.nativeWrappedAddress);

        if (!shouldDeposit)
            require(_token == m.path[0], "bridged token must be the same as the first token in destination swap path");
        
        require(_token == m.fromToken, "bridged token must be the same as the requested swap token");
        if (m.bridgeNativeOut) {
            require(_token == baseStorage.nativeWrappedAddress, "_token must be WETH address");
        }

        status = OperationStatus.Succeeded;
        receivedToken = _token;

        if (m.path.length > 1) {
            if (shouldDeposit) {
                IWETH(baseStorage.nativeWrappedAddress).deposit{value: _amount}();
            }
            bool ok = true;
            (ok, dstAmount) = _trySwap(m, _amount);
            if (ok) {
                _sendTokenWithDApp(
                    m.toToken,
                    dstAmount,
                    m.recipient,
                    m.nativeOut,
                    true,
                    m.dAppMessage,
                    m.dAppDestContract,
                    IRangoMessageReceiver.ProcessStatus.SUCCESS
                );

                status = OperationStatus.Succeeded;
                receivedToken = m.nativeOut ? NULL_ADDRESS : m.toToken;
            } else {
                // handle swap failure, send the received token directly to receiver
                _sendTokenWithDApp(
                    _token,
                    _amount,
                    m.recipient,
                    false,
                    false,
                    m.dAppMessage,
                    m.dAppDestContract,
                    IRangoMessageReceiver.ProcessStatus.REFUND_IN_DESTINATION
                );

                dstAmount = _amount;
                status = OperationStatus.SwapFailedInDestination;
                receivedToken = _token;
            }
        } else {
            // no need to swap, directly send the bridged token to user
            if (m.bridgeNativeOut) {
                require(m.nativeOut, "You should enable native out when m.bridgeNativeOut is true");
            }
            address sourceToken = m.bridgeNativeOut ? NULL_ADDRESS: _token;
            bool withdraw = m.bridgeNativeOut ? false : true;
            _sendTokenWithDApp(
                sourceToken,
                _amount,
                m.recipient,
                m.nativeOut,
                withdraw,
                m.dAppMessage,
                m.dAppDestContract,
                IRangoMessageReceiver.ProcessStatus.SUCCESS
            );
            dstAmount = _amount;
            status = OperationStatus.Succeeded;
            receivedToken = m.nativeOut ? NULL_ADDRESS : m.path[0];
        }

        return (receivedToken, dstAmount, status);
    }

    /// @notice Performs a uniswap-v2 operation
    /// @param _swap The interchain message that contains the swap info
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _trySwap(
        Interchain.RangoInterChainMessage memory _swap,
        uint256 _amount
    ) private returns (bool ok, uint256 amountOut) {
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();
        require(baseStorage.whitelistContracts[_swap.dexAddress] == true, "Dex address is not whitelisted");
        uint256 zero;
        approve(_swap.fromToken, _swap.dexAddress, _amount);

        try
            IUniswapV2(_swap.dexAddress).swapExactTokensForTokens(
                _amount,
                _swap.amountOutMin,
                _swap.path,
                address(this),
                _swap.deadline
            )
        returns (uint256[] memory amounts) {
            return (true, amounts[amounts.length - 1]);
        } catch {
            return (false, zero);
        }
    }

    /// @notice An internal function to send a token from the current contract to another contract or wallet
    /// @dev This function also can convert WETH to ETH before sending if _withdraw flat is set to true
    /// @dev To send native token _nativeOut param should be set to true, otherwise we assume it's an ERC20 transfer
    /// @dev If there is a message from a dApp it sends the money to the contract instead of the end-user and calls its handleRangoMessage
    /// @param _token The token that is going to be sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address or contract
    /// @param _nativeOut means the output is native token
    /// @param _withdraw If true, indicates that we should swap WETH to ETH before sending the money and _nativeOut must also be true
    function _sendTokenWithDApp(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _nativeOut,
        bool _withdraw,
        bytes memory _dAppMessage,
        address _dAppReceiverContract,
        IRangoMessageReceiver.ProcessStatus processStatus
    ) internal {
        bool thereIsAMessage = _dAppReceiverContract != NULL_ADDRESS;
        address immediateReceiver = thereIsAMessage ? _dAppReceiverContract : _receiver;
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();
        BaseInterchainStorage storage messagingStorage = getBaseMessagingContractStorage();
        emit SendToken(_token, _amount, immediateReceiver, _nativeOut, _withdraw);

        if (_nativeOut) {
            if (_withdraw) {
                require(_token == baseStorage.nativeWrappedAddress, "token mismatch");
                IWETH(baseStorage.nativeWrappedAddress).withdraw(_amount);
            }
            _sendNative(immediateReceiver, _amount);
        } else {
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_token), immediateReceiver, _amount);
        }

        if (thereIsAMessage) {
            require(
                messagingStorage.whitelistMessagingContracts[_dAppReceiverContract],
                "3rd-party contract not whitelisted"
            );

            address receivedToken = _nativeOut ? NULL_ADDRESS : _token;
            try IRangoMessageReceiver(_dAppReceiverContract)
                .handleRangoMessage(receivedToken, _amount, processStatus, _dAppMessage)
            {
                emit CrossChainMessageCalled(_dAppReceiverContract, receivedToken, _amount, processStatus, _dAppMessage, true, "");
            } catch Error(string memory reason) {
                emit CrossChainMessageCalled(_dAppReceiverContract, receivedToken, _amount, processStatus, _dAppMessage, false, reason);
            } catch (bytes memory lowLevelData) {
                emit CrossChainMessageCalled(_dAppReceiverContract, receivedToken, _amount, processStatus, _dAppMessage, false, _getRevertMsg(lowLevelData));
            }
        }
    }

    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getBaseMessagingContractStorage() internal pure returns (BaseInterchainStorage storage s) {
        bytes32 namespace = BASE_MESSAGING_CONTRACT_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}