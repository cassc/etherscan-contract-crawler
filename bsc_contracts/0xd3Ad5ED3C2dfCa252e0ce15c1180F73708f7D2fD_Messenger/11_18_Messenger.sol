// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./strategies/StrategyConnector.sol";
import "./interfaces/IUSDL.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IMessenger.sol";
import "./interfaces/layerzero/ILayerZeroEndpoint.sol";
import "./interfaces/multichain/IMultichainRouter.sol";

contract Messenger is IMessenger, OwnableUpgradeable {
    using SafeCastUpgradeable for uint256;

    // CONSTANTS

    uint256 public constant RECEIVE_GAS_LIMIT = 350000;

    // STORAGE

    IUSDL public usdl;

    IVault public vault;

    enum MessengingProtocolType {
        None,
        LayerZero
    }

    enum BridgeProtocolType {
        None,
        Multichain
    }

    struct ChainInfo {
        MessengingProtocolType messengingProtocolType;
        BridgeProtocolType bridgeProtocolType;
        bytes messenger;
    }

    mapping(uint256 => ChainInfo) public chains;

    mapping(uint256 => int256) public chainDebts;

    enum MessageType {
        None,
        MintTokens,
        IncreaseDebt
    }

    // LayerZero

    ILayerZeroEndpoint public lzEndpoint;

    mapping(uint256 => uint16) public chainIdToLzId;

    mapping(uint16 => uint256) public lzIdToChainId;

    // Multichain

    IMultichainRouter public multichainRouter;

    mapping(address => address) public anyTokens;

    // EVENTS

    event BridgeUSDL(
        address sender,
        uint256 dstChainId,
        address receiver,
        uint256 amount
    );

    event BridgeCollateral(
        uint256 dstChainId,
        address collateral,
        uint256 amount
    );

    event MessageSent(uint256 dstChainId, bytes message);

    event MessageReceived(uint256 srcChainId, bytes message);

    // ERRORS

    error WrongMessageType(bytes message);

    error NoProtocol(uint256 chainId);

    error WrongSender(address real, address expected);

    error WrongInterlocutor(bytes real, bytes expected);

    error AmountExceedsDebt(uint256 amount, int256 debt);

    error LengthMismatch();

    // INITIALIZER

    function initialize(IUSDL usdl_, IVault vault_) external initializer {
        __Ownable_init();
        usdl = usdl_;
        vault = vault_;
    }

    // PUBLIC RESTRICTED FUNCTIONS

    function setChain(uint256 chainId, ChainInfo calldata chainInfo)
        external
        onlyOwner
    {
        chains[chainId] = chainInfo;
    }

    function setLzEndpoint(ILayerZeroEndpoint lzEndpoint_) external onlyOwner {
        lzEndpoint = lzEndpoint_;
    }

    function setLzIds(uint256[] calldata chainIds, uint16[] calldata lzIds)
        external
        onlyOwner
    {
        if (chainIds.length != lzIds.length) revert LengthMismatch();
        for (uint256 i = 0; i < chainIds.length; i++) {
            chainIdToLzId[chainIds[i]] = lzIds[i];
            lzIdToChainId[lzIds[i]] = chainIds[i];
        }
    }

    function setMultichainRouter(IMultichainRouter multichainRouter_)
        external
        onlyOwner
    {
        multichainRouter = multichainRouter_;
    }

    function setAnyTokens(
        address[] calldata tokensList,
        address[] calldata anyTokensList
    ) external onlyOwner {
        if (tokensList.length != anyTokensList.length) revert LengthMismatch();
        for (uint256 i = 0; i < tokensList.length; i++) {
            anyTokens[tokensList[i]] = anyTokensList[i];
        }
    }

    // PUBLIC FUNCTIONS

    function bridgeUSDL(
        uint256 dstChainId,
        address receiver,
        uint256 amount
    ) external payable {
        // Burn tokens
        usdl.burn(_msgSender(), amount);

        // Account debt
        chainDebts[dstChainId] += amount.toInt256();

        // Call cross-chain messenging protocol
        bytes memory data = abi.encode(receiver, amount);
        bytes memory message = abi.encode(MessageType.MintTokens, data);
        _sendMessage(dstChainId, message);

        // Emit event
        emit BridgeUSDL(_msgSender(), dstChainId, receiver, amount);
    }

    function bridgeCollateral(
        uint256 dstChainId,
        address collateral,
        uint256 amount
    ) external payable {
        // Check debt
        if (chainDebts[dstChainId] < amount.toInt256())
            revert AmountExceedsDebt(amount, chainDebts[dstChainId]);

        // Decrease debt
        chainDebts[dstChainId] -= amount.toInt256();

        // Call cross-chain messenging protocol
        bytes memory data = abi.encode(amount.toInt256());
        bytes memory message = abi.encode(MessageType.IncreaseDebt, data);
        _sendMessage(dstChainId, message);

        // Use collateral from Vault
        vault.useCollateral(collateral, amount);

        // Bridge collateral
        _bridgeCollateral(dstChainId, collateral, amount);

        // Emit event
        emit BridgeCollateral(dstChainId, collateral, amount);
    }

    // MESSAGE ENTRY POINTS

    function lzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint256,
        bytes memory payload
    ) external {
        // Check that sender is protocol executor
        uint256 chainId = lzIdToChainId[srcChainId];
        if (_msgSender() != address(lzEndpoint))
            revert WrongSender(_msgSender(), address(lzEndpoint));

        // Receive message
        address fromAddress;
        assembly {
            fromAddress := mload(add(srcAddress, 20))
        }
        _receiveMessage(chainId, abi.encodePacked(fromAddress), payload);
    }

    // INTERNAL FUNCTIONS

    function _sendMessage(uint256 dstChainId, bytes memory message) internal {
        ChainInfo memory info = chains[dstChainId];
        if (info.messengingProtocolType == MessengingProtocolType.LayerZero) {
            // Send message with LayerZero
            bytes memory remoteAndLocalAddresses = abi.encodePacked(
                info.messenger,
                address(this)
            );
            lzEndpoint.send{value: msg.value}(
                chainIdToLzId[dstChainId],
                remoteAndLocalAddresses,
                message,
                payable(_msgSender()),
                address(0),
                abi.encodePacked(uint16(1), RECEIVE_GAS_LIMIT)
            );
        } else {
            // Revert
            revert NoProtocol(dstChainId);
        }

        emit MessageSent(dstChainId, message);
    }

    function _bridgeCollateral(
        uint256 chainId,
        address collateral,
        uint256 amount
    ) internal {
        ChainInfo memory info = chains[chainId];
        if (info.bridgeProtocolType == BridgeProtocolType.Multichain) {
            IERC20Upgradeable(collateral).approve(
                address(multichainRouter),
                amount
            );
            multichainRouter.anySwapOutUnderlying(
                anyTokens[collateral],
                string(info.messenger),
                amount,
                chainId
            );
        } else {
            revert NoProtocol(chainId);
        }
    }

    function _receiveMessage(
        uint256 srcChainId,
        bytes memory srcAddress,
        bytes memory message
    ) internal {
        // Check that interlocutor is other chain's messenger
        ChainInfo memory info = chains[srcChainId];

        if (keccak256(srcAddress) != keccak256(info.messenger))
            revert WrongInterlocutor(srcAddress, info.messenger);

        // Switch depending on message type
        (MessageType messageType, bytes memory data) = abi.decode(
            message,
            (MessageType, bytes)
        );
        if (messageType == MessageType.MintTokens) {
            // Decode data
            (address receiver, uint256 amount) = abi.decode(
                data,
                (address, uint256)
            );

            // Account debt
            chainDebts[srcChainId] -= amount.toInt256();

            // Mint tokens
            usdl.mint(receiver, amount);
        } else if (messageType == MessageType.IncreaseDebt) {
            // Decode data
            int256 amount = abi.decode(data, (int256));

            // Account debt
            chainDebts[srcChainId] += amount;
        } else {
            // Revert
            revert WrongMessageType(message);
        }

        emit MessageReceived(srcChainId, message);
    }
}