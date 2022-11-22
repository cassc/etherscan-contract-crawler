// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Initializable.sol";
import "./Upgradeable.sol";
import "./Claimable.sol";
import "./components/bridged/BridgedTokensRegistry.sol";
import "./components/native/NativeTokensRegistry.sol";
import "./components/native/MediatorBalanceStorage.sol";
import "./components/common/TokensRelayer.sol";
import "./components/common/BrewlabsBridgeInfo.sol";
import "./components/common/TokensBridgeLimits.sol";
import "./components/common/FailedMessagesProcessor.sol";
import "../interfaces/IBurnableMintableERC677Token.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20Receiver.sol";
import "../libraries/TokenReader.sol";
import "../libraries/SafeMint.sol";

/**
 * @title BasicBrewlabsBridge
 * @dev Common functionality for multi-token mediator intended to work on top of AMB bridge.
 */
abstract contract BasicBrewlabsBridge is
    Initializable,
    Upgradeable,
    Claimable,
    BrewlabsBridgeInfo,
    TokensRelayer,
    FailedMessagesProcessor,
    BridgedTokensRegistry,
    NativeTokensRegistry,
    MediatorBalanceStorage,
    TokensBridgeLimits
{
    using SafeERC20 for IERC677;
    using SafeMint for IBurnableMintableERC677Token;
    using SafeMath for uint256;

    event LiquidityAdded(address indexed user, address indexed token, uint256 amount);
    event LiquidityRemoved(address indexed user, address indexed token, uint256 amount);

    // Since contract is intended to be deployed under EternalStorageProxy, only constant and immutable variables can be set here
    constructor() {}

    /**
     * @dev Handles the bridged tokens for the first time, includes deployment of new TokenProxy contract.
     * Checks that the value is inside the execution limits and invokes the Mint or Unlock accordingly.
     * @param _token address of the native ERC20/ERC677 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function registerAndHandleBridgedTokens(
        address _token,
        address _recipient,
        uint256 _value
    ) external onlyMediator {
        address bridgedToken = _getBridgedTokenOrRegister(_token);
        uint256 _valueToReceive = _calcReceivedAmount(bridgedToken, _value);

        _handleTokens(bridgedToken, false, _recipient, _valueToReceive);
    }

    /**
     * @dev Handles the bridged tokens for the first time, includes deployment of new TokenProxy contract.
     * Executes a callback on the receiver.
     * Checks that the value is inside the execution limits and invokes the Mint accordingly.
     * @param _token address of the native ERC20/ERC677 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     * @param _data additional data passed from the other chain.
     */
    function registerAndHandleBridgedTokensAndCall(
        address _token,
        address _recipient,
        uint256 _value,
        bytes calldata _data
    ) external onlyMediator {
        address bridgedToken = _getBridgedTokenOrRegister(_token);
        uint256 _valueToReceive = _calcReceivedAmount(bridgedToken, _value);

        _handleTokens(bridgedToken, false, _recipient, _valueToReceive);

        _receiverCallback(_recipient, bridgedToken, _valueToReceive, _data);
    }
    /**
     * @dev Handles the bridged tokens for the already registered token pair.
     * Checks that the value is inside the execution limits and invokes the Mint accordingly.
     * @param _token address of the native ERC20/ERC677 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function handleBridgedTokens(
        address _token,
        address _recipient,
        uint256 _value
    ) external onlyMediator {
        address token = bridgedTokenAddress(_token);
        uint256 _valueToReceive = _calcReceivedAmount(token, _value);

        require(isTokenRegistered(token));

        _handleTokens(token, false, _recipient, _valueToReceive);
    }

    /**
     * @dev Handles the bridged tokens for the already registered token pair.
     * Checks that the value is inside the execution limits and invokes the Unlock accordingly.
     * Executes a callback on the receiver.
     * @param _token address of the native ERC20/ERC677 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     * @param _data additional transfer data passed from the other side.
     */
    function handleBridgedTokensAndCall(
        address _token,
        address _recipient,
        uint256 _value,
        bytes memory _data
    ) external onlyMediator {
        address token = bridgedTokenAddress(_token);
        uint256 _valueToReceive = _calcReceivedAmount(token, _value);

        require(isTokenRegistered(token));

        _handleTokens(token, false, _recipient, _valueToReceive);

        _receiverCallback(_recipient, token, _valueToReceive, _data);
    }

    /**
     * @dev Handles the bridged tokens that are native to this chain.
     * Checks that the value is inside the execution limits and invokes the Unlock accordingly.
     * @param _token native ERC20 token.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function handleNativeTokens(
        address _token,
        address _recipient,
        uint256 _value
    ) external onlyMediator {
        _ackBridgedTokenDeploy(_token);
        uint256 _valueToReceive = _calcReceivedAmount(_token, _value);

        _handleTokens(_token, true, _recipient, _valueToReceive);
    }

    /**
     * @dev Handles the bridged tokens that are native to this chain.
     * Checks that the value is inside the execution limits and invokes the Unlock accordingly.
     * Executes a callback on the receiver.
     * @param _token native ERC20 token.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     * @param _data additional transfer data passed from the other side.
     */
    function handleNativeTokensAndCall(
        address _token,
        address _recipient,
        uint256 _value,
        bytes memory _data
    ) external onlyMediator {
        _ackBridgedTokenDeploy(_token);
        uint256 _valueToReceive = _calcReceivedAmount(_token, _value);

        _handleTokens(_token, true, _recipient, _valueToReceive);

        _receiverCallback(_recipient, _token, _valueToReceive, _data);
    }

    /**
     * @dev Checks if a given token is a bridged token that is native to this side of the bridge.
     * @param _token address of token contract.
     * @return message id of the send message.
     */
    function isRegisteredAsNativeToken(address _token) public view returns (bool) {
        return isTokenRegistered(_token) && nativeTokenAddress(_token) == address(0);
    }

    /**
     * @dev Unlock back the amount of tokens that were bridged to the other network but failed.
     * @param _token address that bridged token contract.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function executeActionOnFixedTokens(
        address _token,
        address _recipient,
        uint256 _value
    ) internal override {
        _releaseTokens(nativeTokenAddress(_token) == address(0), _token, _recipient, _value, _value);
    }

    /**
     * @dev Allows to pre-set the bridged token contract for not-yet bridged token.
     * Only the owner can call this method.
     * @param _nativeToken address of the token contract on the other side that was not yet bridged.
     * @param _bridgedToken address of the bridged token contract.
     * @param _isLiquidityMethod  bridge method(true - liquidity mode, false - mint/burn mode).
     */
    function setCustomTokenAddressPair(address _nativeToken, address _bridgedToken, bool _isLiquidityMethod) external onlyOwner {
        require(!isTokenRegistered(_bridgedToken));
        require(nativeTokenAddress(_bridgedToken) == address(0));
        require(bridgedTokenAddress(_nativeToken) == address(0));
        // Unfortunately, there is no simple way to verify that the _nativeToken address
        // does not belong to the bridged token on the other side,
        // since information about bridged tokens addresses is not transferred back.
        // Therefore, owner account calling this function SHOULD manually verify on the other side of the bridge that
        // nativeTokenAddress(_nativeToken) == address(0) && isTokenRegistered(_nativeToken) == false.

        if(!_isLiquidityMethod) {
            IBurnableMintableERC677Token(_bridgedToken).safeMint(address(this), 1);
            IBurnableMintableERC677Token(_bridgedToken).burn(1);
        }

        _setTokenAddressPair(_nativeToken, _bridgedToken, _isLiquidityMethod);
    }

    /**
     * @dev Allows to send to the other network the amount of locked tokens that can be forced into the contract
     * without the invocation of the required methods. (e. g. regular transfer without a call to onTokenTransfer)
     * @param _token address of the token contract.
     * Before calling this method, it must be carefully investigated how imbalance happened
     * in order to avoid an attempt to steal the funds from a token with double addresses
     * (e.g. TUSD is accessible at both 0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E and 0x0000000000085d4780B73119b644AE5ecd22b376)
     * @param _receiver the address that will receive the tokens on the other network.
     */
    function fixMediatorBalance(address _token, address _receiver)
        external
        onlyIfUpgradeabilityOwner
        validAddress(_receiver)
    {
        require(isRegisteredAsNativeToken(_token));

        uint256 diff = _unaccountedBalance(_token);
        require(diff > 0);
        uint256 available = maxAvailablePerTx(_token);
        require(available > 0);
        if (diff > available) {
            diff = available;
        }
        addTotalSpentPerDay(_token, getCurrentDay(), diff);

        bytes memory data = _prepareMessage(address(0), _token, _receiver, diff, new bytes(0));
        bytes32 _messageId = _passMessage(data, true);
        _recordBridgeOperation(_messageId, _token, _receiver, diff);
    }

    /**
     * @dev Adds unaccounted tokens for bridge liquidity.
     * Only the owner can call this method.
     * @param _token address of auto balanced token, address(0) for native
     */
    function autoUpdateMediatorBalance(address _token) external onlyIfUpgradeabilityOwner {
        require(isRegisteredAsNativeToken(_token));

        uint256 diff = _unaccountedBalance(_token);
        require(diff > 0);

        _setMediatorBalance(_token, mediatorBalance(_token).add(diff));
        _addLiquidityBalanceForUser(msg.sender, _token, addedLiquidityBalance(msg.sender, _token).add(diff));
        emit LiquidityAdded(msg.sender, _token, diff);
    }

    /**
     * @dev Adds token liquidity for bridge.
     * If user calls this method, it will be recorded and user can remove liquidity as much as .
     * @param _token address of auto balanced token
     * @param _amount token amount to add
     */
    function addLiquidity(address _token, uint256 _amount) external {
        require(isRegisteredAsNativeToken(_token) || bridgeIsLiquidityMode(_token));

        IERC677(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 diff = _unaccountedBalance(_token);
        require(diff > 0);

        _setMediatorBalance(_token, mediatorBalance(_token).add(diff));
        _addLiquidityBalanceForUser(msg.sender, _token, addedLiquidityBalance(msg.sender, _token).add(diff));
        emit LiquidityAdded(msg.sender, _token, diff);
    }

    /**
     * @dev Removes added token liquidity for bridge.
     * @param _token address of auto balanced token
     * @param _amount token amount to remove
     */
    function removeLiquidity(address _token, uint256 _amount) external {
        require(isRegisteredAsNativeToken(_token) || bridgeIsLiquidityMode(_token));
        require(addedLiquidityBalance(msg.sender, _token) >= _amount, "Exceed added liquidity amount");

        _setMediatorBalance(_token, mediatorBalance(_token).sub(_amount));
        _addLiquidityBalanceForUser(msg.sender, _token, addedLiquidityBalance(msg.sender, _token).sub(_amount));

        IERC677(_token).safeTransfer(msg.sender, _amount);
        emit LiquidityRemoved(msg.sender, _token, _amount);
    }

    /**
     * @dev Claims stuck tokens. Only unsupported tokens can be claimed.
     * When dealing with already supported tokens, fixMediatorBalance can be used instead.
     * @param _token address of claimed token, address(0) for native
     * @param _to address of tokens receiver
     */
    function claimTokens(address _token, address _to) external onlyIfUpgradeabilityOwner {
        // Only unregistered tokens and native coins are allowed to be claimed with the use of this function
        require(_token == address(0) || !isTokenRegistered(_token));
        claimValues(_token, _to);
    }

    /**
     * @dev Withdraws erc20 tokens or native coins from the bridged token contract.
     * Only the proxy owner is allowed to call this method.
     * @param _bridgedToken address of the bridged token contract.
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimTokensFromTokenContract(
        address _bridgedToken,
        address _token,
        address _to
    ) external onlyIfUpgradeabilityOwner {
        IBurnableMintableERC677Token(_bridgedToken).claimTokens(_token, _to);
    }

    /**
     * @dev Internal function for recording bridge operation for further usage.
     * Recorded information is used for fixing failed requests on the other side.
     * @param _messageId id of the sent message.
     * @param _token bridged token address.
     * @param _sender address of the tokens sender.
     * @param _value bridged value.
     */
    function _recordBridgeOperation(
        bytes32 _messageId,
        address _token,
        address _sender,
        uint256 _value
    ) internal {
        setMessageToken(_messageId, _token);
        setMessageRecipient(_messageId, _sender);
        setMessageValue(_messageId, _value);

        emit TokensBridgingInitiated(_token, _sender, _value, _messageId);
    }

    /**
     * @dev Constructs the message to be sent to the other side. Burns/locks bridged amount of tokens.
     * @param _nativeToken address of the native token contract.
     * @param _token bridged token address.
     * @param _receiver address of the tokens receiver on the other side.
     * @param _value bridged value.
     * @param _data additional transfer data passed from the other side.
     */
    function _prepareMessage(
        address _nativeToken,
        address _token,
        address _receiver,
        uint256 _value,
        bytes memory _data
    ) internal returns (bytes memory) {
        bool withData = _data.length > 0 || msg.sig == this.relayTokensAndCall.selector;

        uint8 decimals = TokenReader.readDecimals(_token);
        uint256 _valueForOtherChain = _value * 10**(36 - decimals);
        // process token is native with respect to this side of the bridge
        if (_nativeToken == address(0)) {
            _setMediatorBalance(_token, mediatorBalance(_token).add(_value));

            // process token which bridged alternative was already ACKed to be deployed
            if (isBridgedTokenDeployAcknowledged(_token)) {
                return
                    withData
                        ? abi.encodeWithSelector(
                            this.handleBridgedTokensAndCall.selector,
                            _token,
                            _receiver,
                            _valueForOtherChain,
                            _data
                        )
                        : abi.encodeWithSelector(this.handleBridgedTokens.selector, _token, _receiver, _valueForOtherChain);
            }

            return
                withData
                    ? abi.encodeWithSelector(
                        this.registerAndHandleBridgedTokensAndCall.selector,
                        _token,
                        _receiver,
                        _valueForOtherChain,
                        _data
                    )
                    : abi.encodeWithSelector(
                        this.registerAndHandleBridgedTokens.selector,
                        _token,
                        _receiver,
                        _valueForOtherChain
                    );
        }

        // process already known token that is bridged from other chain
        if(bridgeIsLiquidityMode(_token)) {
            _setMediatorBalance(_token, mediatorBalance(_token).add(_value));
        } else {
            IBurnableMintableERC677Token(_token).burn(_value);
        }
        return
            withData
                ? abi.encodeWithSelector(
                    this.handleNativeTokensAndCall.selector,
                    _nativeToken,
                    _receiver,
                    _valueForOtherChain,
                    _data
                )
                : abi.encodeWithSelector(this.handleNativeTokens.selector, _nativeToken, _receiver, _valueForOtherChain);
    }

    /**
     * @dev Internal function for getting minter proxy address.
     * @param _token address of the token to mint.
     * @return address of the minter contract that should be used for calling mint(address,uint256)
     */
    function _getMinterFor(address _token) internal pure virtual returns (IBurnableMintableERC677Token) {
        return IBurnableMintableERC677Token(_token);
    }

    /**
     * Internal function for unlocking some amount of tokens.
     * @param _isNative true, if token is native w.r.t. to this side of the bridge.
     * @param _token address of the token contract.
     * @param _recipient address of the tokens receiver.
     * @param _value amount of tokens to unlock.
     * @param _balanceChange amount of balance to subtract from the mediator balance.
     */
    function _releaseTokens(
        bool _isNative,
        address _token,
        address _recipient,
        uint256 _value,
        uint256 _balanceChange
    ) internal virtual {
        if (_isNative || bridgeIsLiquidityMode(_token)) {
            IERC677(_token).safeTransfer(_recipient, _value);
            _setMediatorBalance(_token, mediatorBalance(_token).sub(_balanceChange));
        } else {
            _getMinterFor(_token).safeMint(_recipient, _value);
        }
    }

    /**
     * Internal function for getting address of the bridged token. 
     * @param _token address of the token contract on the other side of the bridge.
     */
    function _getBridgedTokenOrRegister(address _token) internal returns (address) {
        address bridgedToken = bridgedTokenAddress(_token);
        require(bridgedToken != address(0x0));        
        if (!isTokenRegistered(bridgedToken)) {
            require(IERC20Metadata(bridgedToken).decimals() <= 36);
            _initializeTokenBridgeLimits(bridgedToken, IERC20Metadata(bridgedToken).decimals());
        }
        return bridgedToken;
    }

    /**
     * Internal function for getting real bridged amount. 
     * @param _token address of the token contract to receive.
     * @param _value estimated value with decimal precision (36 decimals).
     */
    function _calcReceivedAmount(address _token, uint256 _value) internal view returns(uint256) {
        uint256 decimals = IERC20Metadata(_token).decimals();
        return _value / (10 ** (36 - decimals));
    }

    /**
     * Notifies receiving contract about the completed bridging operation.
     * @param _recipient address of the tokens receiver.
     * @param _token address of the bridged token.
     * @param _value amount of tokens transferred.
     * @param _data additional data passed to the callback.
     */
    function _receiverCallback(
        address _recipient,
        address _token,
        uint256 _value,
        bytes memory _data
    ) internal {
        if (Address.isContract(_recipient)) {
            _recipient.call(abi.encodeWithSelector(IERC20Receiver.onTokenBridged.selector, _token, _value, _data));
        }
    }

    /**
     * @dev Internal function for counting excess balance which is not tracked within the bridge.
     * Represents the amount of forced tokens on this contract.
     * @param _token address of the token contract.
     * @return amount of excess tokens.
     */
    function _unaccountedBalance(address _token) internal view virtual returns (uint256) {
        return IERC677(_token).balanceOf(address(this)).sub(mediatorBalance(_token));
    }

    function _handleTokens(
        address _token,
        bool _isNative,
        address _recipient,
        uint256 _value
    ) internal virtual;
}