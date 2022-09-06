// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "rainbow-bridge-sol/nearprover/contracts/INearProver.sol";
import "rainbow-bridge-sol/nearprover/contracts/ProofDecoder.sol";
import "rainbow-bridge-sol/nearbridge/contracts/Borsh.sol";

import "./IProofConsumer.sol";
import "./BridgeToken.sol";
import "./BridgeTokenProxy.sol";
import "./ResultsDecoder.sol";
import "./SelectivePausableUpgradable.sol";

contract BridgeTokenFactory is AccessControlUpgradeable, SelectivePausableUpgradable {
    using Borsh for Borsh.Data;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum WhitelistMode {
        NotInitialized,
        Blocked,
        CheckToken,
        CheckAccountAndToken
    }

    mapping(address => string) private _ethToNearToken;
    mapping(string => address) private _nearToEthToken;
    mapping(address => bool) private _isBridgeToken;

    mapping(string => WhitelistMode) private _whitelistedTokens;
    mapping(bytes => bool) private _whitelistedAccounts;
    bool private _isWhitelistModeEnabled;

    address public proofConsumerAddress;

    bytes32 public constant ADMIN_PAUSE_ROLE = keccak256("ADMIN_PAUSE_ROLE");
    bytes32 public constant PAUSE_DEPOSIT_ROLE = keccak256("PAUSE_DEPOSIT_ROLE");
    bytes32 public constant PAUSE_WITHDRAW_ROLE = keccak256("PAUSE_WITHDRAW_ROLE");
    bytes32 public constant PAUSE_SET_METADATA_ROLE = keccak256("PAUSE_SET_METADATA_ROLE");
    bytes32 public constant WHITELIST_ADMIN_ROLE = keccak256("WHITELIST_ADMIN_ROLE");
    uint constant UNPAUSED_ALL = 0;
    uint constant PAUSED_WITHDRAW = 1 << 0;
    uint constant PAUSED_DEPOSIT = 1 << 1;
    uint constant PAUSED_SET_METADATA = 1 << 2;

    // Event when funds are withdrawn from Ethereum back to NEAR.
    event Withdraw (
        string indexed token,
        address indexed sender,
        uint256 amount,
        string recipient
    );

    event Deposit (
        string indexed token,
        uint256 amount,
        address recipient
    );

    event SetMetadata (
        address indexed token,
        string name,
        string symbol,
        uint8 decimals
    );

    // BridgeTokenFactory is linked to the bridge token factory on NEAR side.
    // It also links to the prover that it uses to unlock the tokens.
    function initialize(address _proofConsumerAddress) external initializer {
        require(_proofConsumerAddress != address(0), "Proof consumer shouldn't be zero address");
        proofConsumerAddress = _proofConsumerAddress;

        __AccessControl_init();
        __Pausable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_PAUSE_ROLE, _msgSender());
        _setupRole(PAUSE_DEPOSIT_ROLE, _msgSender());
        _setupRole(PAUSE_WITHDRAW_ROLE, _msgSender());
        _setupRole(PAUSE_SET_METADATA_ROLE, _msgSender());
        _setupRole(WHITELIST_ADMIN_ROLE, _msgSender());
        _isWhitelistModeEnabled = true;
    }

    function isBridgeToken(address token) external view returns (bool) {
        return _isBridgeToken[token];
    }

    function ethToNearToken(address token) external view returns (string memory) {
        require(_isBridgeToken[token], "ERR_NOT_BRIDGE_TOKEN");
        return _ethToNearToken[token];
    }

    function nearToEthToken(string calldata nearTokenId) external view returns (address) {
        require(_isBridgeToken[_nearToEthToken[nearTokenId]], "ERR_NOT_BRIDGE_TOKEN");
        return _nearToEthToken[nearTokenId];
    }

    function newBridgeToken(string calldata nearTokenId) external returns (BridgeTokenProxy) {
        require(!_isBridgeToken[_nearToEthToken[nearTokenId]], "ERR_TOKEN_EXIST");

        BridgeToken bridgeToken = new BridgeToken();
        BridgeTokenProxy bridgeTokenProxy = new BridgeTokenProxy(
            address(bridgeToken),
            abi.encodeWithSelector(BridgeToken(address(0)).initialize.selector, "", "", 0)
        );
        _isBridgeToken[address(bridgeTokenProxy)] = true;
        _ethToNearToken[address(bridgeTokenProxy)] = nearTokenId;
        _nearToEthToken[nearTokenId] = address(bridgeTokenProxy);

        return bridgeTokenProxy;
    }

    function setMetadata(bytes memory proofData, uint64 proofBlockHeight) external whenNotPaused(PAUSED_SET_METADATA) {
        ProofDecoder.ExecutionStatus memory status =
            IProofConsumer(proofConsumerAddress).parseAndConsumeProof(proofData, proofBlockHeight);
        ResultsDecoder.MetadataResult memory result = ResultsDecoder.decodeMetadataResult(status.successValue);

        require(_isBridgeToken[_nearToEthToken[result.token]], "ERR_NOT_BRIDGE_TOKEN");
        require(
            result.blockHeight >= BridgeToken(_nearToEthToken[result.token]).metadataLastUpdated(),
            "ERR_OLD_METADATA"
        );

        BridgeToken(_nearToEthToken[result.token])
            .setMetadata(result.name, result.symbol, result.decimals, result.blockHeight);

        emit SetMetadata(_nearToEthToken[result.token], result.name, result.symbol, result.decimals);
    }

    function deposit(bytes memory proofData, uint64 proofBlockHeight) external whenNotPaused(PAUSED_DEPOSIT) {
        ProofDecoder.ExecutionStatus memory status
            = IProofConsumer(proofConsumerAddress).parseAndConsumeProof(proofData, proofBlockHeight);
        ResultsDecoder.LockResult memory result = ResultsDecoder.decodeLockResult(status.successValue);

        require(_isBridgeToken[_nearToEthToken[result.token]], "ERR_NOT_BRIDGE_TOKEN");
        BridgeToken(_nearToEthToken[result.token]).mint(result.recipient, result.amount);

        emit Deposit(result.token, result.amount, result.recipient);
    }

    function withdraw(string memory token, uint256 amount, string memory recipient) external whenNotPaused(PAUSED_WITHDRAW) {
        _checkWhitelistedToken(token, msg.sender);
        require(_isBridgeToken[_nearToEthToken[token]], "ERR_NOT_BRIDGE_TOKEN");

        BridgeToken(_nearToEthToken[token]).burn(msg.sender, amount);

        emit Withdraw(token, msg.sender, amount, recipient);
    }

    function pause(uint flags) external onlyRole(ADMIN_PAUSE_ROLE) {
        _pause(flags);
    }

    function pauseDeposit() external onlyRole(PAUSE_DEPOSIT_ROLE) {
        _pause(pausedFlags() | PAUSED_DEPOSIT);
    }

    function pauseWithdraw() external onlyRole(PAUSE_WITHDRAW_ROLE) {
        _pause(pausedFlags() | PAUSED_WITHDRAW);
    }

    function pauseSetMetadata() external onlyRole(PAUSE_SET_METADATA_ROLE) {
        _pause(pausedFlags() | PAUSED_SET_METADATA);
    }

    function upgradeToken(string calldata nearTokenId, address implementation) external onlyRole(DEFAULT_ADMIN_ROLE) {
       require(_isBridgeToken[_nearToEthToken[nearTokenId]], "ERR_NOT_BRIDGE_TOKEN");
       BridgeTokenProxy proxy = BridgeTokenProxy(payable(_nearToEthToken[nearTokenId]));
       proxy.upgradeTo(implementation);
    }

    function setProofConsumer(address newProofConsumerAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        proofConsumerAddress = newProofConsumerAddress;
    }

    function enableWhitelistMode() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _isWhitelistModeEnabled = true;
    }

    function disableWhitelistMode() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _isWhitelistModeEnabled = false;
    }

    function setTokenWhitelistMode(string calldata token, WhitelistMode mode) external onlyRole(WHITELIST_ADMIN_ROLE) {
        _whitelistedTokens[token] = mode;
    }

    function addAccountToWhitelist(string calldata token, address account) external onlyRole(WHITELIST_ADMIN_ROLE) {
        require(_whitelistedTokens[token] != WhitelistMode.NotInitialized, "ERR_NOT_INITIALIZED_WHITELIST_TOKEN");
       _whitelistedAccounts[abi.encodePacked(token, account)] = true;
    }

    function removeAccountFromWhitelist(string calldata token, address account) external onlyRole(WHITELIST_ADMIN_ROLE) {
        delete _whitelistedAccounts[abi.encodePacked(token, account)];
    }

    function _checkWhitelistedToken(string memory token, address account) internal view {
        if (!_isWhitelistModeEnabled) {
            return;
        }

        WhitelistMode tokenMode = _whitelistedTokens[token];
        require(tokenMode != WhitelistMode.NotInitialized, "ERR_NOT_INITIALIZED_WHITELIST_TOKEN");

        if (tokenMode == WhitelistMode.CheckAccountAndToken) {
            require(_whitelistedAccounts[abi.encodePacked(token, account)], "ERR_ACCOUNT_NOT_IN_WHITELIST");
        } else if (tokenMode == WhitelistMode.Blocked) {
            revert("ERR_WHITELIST_TOKEN_BLOCKED");
        }
    }
}