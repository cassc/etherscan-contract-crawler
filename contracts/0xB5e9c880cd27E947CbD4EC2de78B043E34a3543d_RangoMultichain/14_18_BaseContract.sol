// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IThorchainRouter.sol";
import "../../interfaces/IRangoMessageReceiver.sol";


/// @title The base contract for the non-TransparentProxy based contracts
/// @notice It supports refund and DEX whitelisting
/// @author Uchiha Sasuke
/// @notice It contains storage for whitelisted contracts, refund ERC20 and native tokens and on-chain swap
contract BaseContract is Pausable, Ownable, ReentrancyGuard {
    address payable constant NULL_ADDRESS = payable(0x0000000000000000000000000000000000000000);

    using SafeMath for uint;

    /// @dev keccak256("exchange.rango.basecontract")
    bytes32 internal constant BASE_CONTRACT_NAMESPACE = hex"4c641b369cb23edb735ebedf93a426da9d88d71734c5e7d6076697dcf08d6878";

    struct BaseContractStorage {
        address nativeWrappedAddress;
        mapping (address => bool) whitelistContracts;
        mapping (address => bool) whitelistMessagingContracts;
    }

    /// @notice The output money (ERC20/Native) is sent to a wallet
    /// @param _token The token that is sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address
    /// @param _nativeOut means the output was native token
    /// @param _withdraw If true, indicates that we swapped WETH to ETH before sending the money and _nativeOut is also true
    event SendToken(address _token, uint256 _amount, address _receiver, bool _nativeOut, bool _withdraw);

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

    /// @notice Notifies that a new contract is whitelisted
    /// @param _factory The address of the contract
    /// @param _isMessagingDApp If true the whitelisted contract is a dApp based on Rango messaging dApp, otherwise it's a dex or dex aggregator
    event ContractWhitelisted(address _factory, bool _isMessagingDApp);

    /// @notice Notifies that a new contract is blacklisted
    /// @param _factory The address of the contract
    /// @param _isMessagingDApp If true the whitelisted contract is a dApp based on Rango messaging dApp, otherwise it's a dex or dex aggregator
    event ContractBlacklisted(address _factory, bool _isMessagingDApp);

    /// @notice Notifies that admin manually refunded some money
    /// @param _token The address of refunded token, 0x000..00 address for native token
    /// @param _amount The amount that is refunded
    event Refunded(address _token, uint _amount);

    /// @notice Adds a contract to the whitelisted DEXes or whitelisted messaging dApps that can be called
    /// @param _factory The address of the DEX or dApp
    /// @param isMessagingDApp Is true for dApps and false for DEX
    function addWhitelist(address _factory, bool isMessagingDApp) external onlyOwner {
        BaseContractStorage storage baseStorage = getBaseContractStorage();
        if (isMessagingDApp)
            baseStorage.whitelistMessagingContracts[_factory] = true;
        else
            baseStorage.whitelistContracts[_factory] = true;

        emit ContractWhitelisted(_factory, isMessagingDApp);
    }

    /// @notice Removes a contract from the whitelisted DEXes or dApps that can be called
    /// @param _factory The address of the DEX or dApp
    /// @param isMessagingDApp Is true for dApps and false for DEX
    function removeWhitelist(address _factory, bool isMessagingDApp) external onlyOwner {
        BaseContractStorage storage baseStorage = getBaseContractStorage();

        if (isMessagingDApp) {
            require(baseStorage.whitelistMessagingContracts[_factory], 'Factory not found');
            delete baseStorage.whitelistMessagingContracts[_factory];
        } else {
            require(baseStorage.whitelistContracts[_factory], 'Factory not found');
            delete baseStorage.whitelistContracts[_factory];
        }

        emit ContractBlacklisted(_factory, isMessagingDApp);
    }

    /// @notice Transfers an ERC20 token from this contract to msg.sender
    /// @dev This endpoint is to return money to a user if we didn't handle failure correctly and the money is still in the contract
    /// @dev Currently the money goes to admin and they should manually transfer it to a wallet later
    /// @param _tokenAddress The address of ERC20 token to be transferred
    /// @param _amount The amount of money that should be transfered
    function refund(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 ercToken = IERC20(_tokenAddress);
        uint balance = ercToken.balanceOf(address(this));
        require(balance >= _amount, 'Insufficient balance');

        SafeERC20.safeTransfer(IERC20(_tokenAddress), msg.sender, _amount);
        emit Refunded(_tokenAddress, _amount);
    }

    /// @notice Transfers the native token from this contract to msg.sender
    /// @dev This endpoint is to return money to a user if we didn't handle failure correctly and the money is still in the contract
    /// @dev Currently the money goes to admin and they should manually transfer it to a wallet later
    /// @param _amount The amount of native token that should be transfered
    function refundNative(uint256 _amount) external onlyOwner {
        uint balance = address(this).balance;
        require(balance >= _amount, 'Insufficient balance');

        _sendToken(
            NULL_ADDRESS,
            _amount,
            msg.sender,
            true,
            false,
            new bytes(0),
            NULL_ADDRESS,
            IRangoMessageReceiver.ProcessStatus.SUCCESS
        );

        emit Refunded(NULL_ADDRESS, _amount);
    }

    /// @notice Approves an ERC20 token to a contract to transfer from the current contract
    /// @param token The address of an ERC20 token
    /// @param to The contract address that should be approved
    /// @param value The amount that should be approved
    function approve(address token, address to, uint value) internal {
        SafeERC20.safeApprove(IERC20(token), to, 0);
        SafeERC20.safeIncreaseAllowance(IERC20(token), to, value);
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
    function _sendToken(
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
        BaseContractStorage storage baseStorage = getBaseContractStorage();
        emit SendToken(_token, _amount, immediateReceiver, _nativeOut, _withdraw);

        if (_nativeOut) {
            if (_withdraw) {
                require(_token == baseStorage.nativeWrappedAddress, "token mismatch");
                IWETH(baseStorage.nativeWrappedAddress).withdraw(_amount);
            }
            _sendNative(immediateReceiver, _amount);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), immediateReceiver, _amount);
        }

        if (thereIsAMessage) {
            require(
                baseStorage.whitelistMessagingContracts[_dAppReceiverContract],
                "Third-party message handler contract not whitelisted"
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

    /// @notice An internal function to send native token to a contract or wallet
    /// @param _receiver The address that will receive the native token
    /// @param _amount The amount of the native token that should be sent
    function _sendNative(address _receiver, uint _amount) internal {
        (bool sent, ) = _receiver.call{value: _amount}("");
        require(sent, "failed to send native");
    }

    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getBaseContractStorage() internal pure returns (BaseContractStorage storage s) {
        bytes32 namespace = BASE_CONTRACT_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }

    /// @notice To extract revert message from a DEX/contract call to represent to the end-user in the blockchain
    /// @param _returnData The resulting bytes of a failed call to a DEX or contract
    /// @return A string that describes what was the error
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}