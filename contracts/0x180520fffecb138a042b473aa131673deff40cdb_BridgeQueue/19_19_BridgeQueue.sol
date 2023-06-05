pragma solidity 0.8.18;
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

error ETH_TRANSFER_FAILED_TO_COMMUNITY_WALLET();
error ETH_TRANSFER_FAILED_TO_COLD_WALLET();
error AMOUNT_PARAMETER_NOT_ZERO_WHEN_BRIDGING_ETH();
error MSG_VALUE_NOT_ZERO_WHEN_BRIDGING_ERC20();
error REQUESTED_BRIDGE_AMOUNT_IS_ZERO();
error TOKEN_ALREADY_SUPPORTED();
error TOKEN_NOT_SUPPORTED();
error MORE_THAN_MAX_FEE();
error INVALID_COLD_WALLET();
error INVALID_COMMUNITY_WALLET();

contract BridgeQueue is UUPSUpgradeable, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public constant ETH = address(0);
    uint256 public constant MAX_FEE = 10000;

    // Cold wallet that will receive the net bridged amount
    address public coldWallet;

    // Community wallet that receive transaction fee
    address public communityWallet;

    // Transaction fee when bridging from EVM to DeFiChain. Based on dps (e.g. 1% = 100dps)
    uint256 public transactionFee;

    // Mapping to check whether a token is supported or not
    mapping(address => bool) public supportedTokens;

    /**
     * @notice Emitted when a bridgeToDeFiChain operation is performed
     * @param defiAddress DeFiChain address of user
     * @param tokenAddress Supported token's being bridged
     * @param bridgeAmount Amount of the bridged token
     */
    event BRIDGE_TO_DEFI_CHAIN(bytes defiAddress, address indexed tokenAddress, uint256 indexed bridgeAmount);

    /**
     * @notice Emitted when a token is supported
     * @param tokenAddress address of the token being added support for
     */
    event TOKEN_SUPPORTED(address indexed tokenAddress);

    /**
     * @notice Emitted when a token is removed out of support
     * @param tokenAddress address of the token being removed out of support
     */
    event TOKEN_REMOVED(address indexed tokenAddress);

    /**
     * @notice Emitted when the transaction fee is changed
     * @param oldTxFee the old transaction fee
     * @param transactionFee the new transaction fee
     */
    event TRANSACTION_FEE_CHANGED(uint256 indexed oldTxFee, uint256 indexed transactionFee);

    /**
     * @notice Emitted when the cold wallet is changed
     * @param oldColdWallet the old cold wallet address
     * @param newColdWallet the new cold wallet address
     */
    event COLD_WALLET_CHANGED(address indexed oldColdWallet, address indexed newColdWallet);

    /**
     * @notice Emitted when the community wallet is changed
     * @param oldCommunityWallet the old community wallet address
     * @param newCommunityWallet the new community wallet address
     */
    event COMMUNITY_WALLET_CHANGED(address indexed oldCommunityWallet, address indexed newCommunityWallet);

    /**
     * @notice constructor to disable initialization of implementation smart contract
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice function to limit the right to upgrade the smart contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @notice To initialize this contract
     * @param _timelockContract TimelockContract who will have the DEFAULT_ADMIN_ROLE
     * @param _coldWallet Cold wallet to receive the net bridge amount
     * @param _fee Fee charge per each bridgeToDeFiChain operation (100% = 10000)
     * @param _communityWallet Community wallet that will receive a fee for each bridgeToDeFiChain transaction
     */
    function initialize(
        address _timelockContract,
        address _coldWallet,
        uint256 _fee,
        address _communityWallet,
        address[] calldata _supportedTokens
    ) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _timelockContract);
        coldWallet = _coldWallet;
        transactionFee = _fee;
        communityWallet = _communityWallet;
        for (uint256 i = 0; i < _supportedTokens.length; ++i) {
            supportedTokens[_supportedTokens[i]] = true;
        }
    }

    /**
     * @notice Used to transfer the supported token from Mainnet(EVM) to DefiChain
     * @param _defiAddress DefiChain address
     * @param _tokenAddress Supported token address that being bridged
     * @param _amount Amount to be bridged, this in in Wei
     */
    function bridgeToDeFiChain(bytes calldata _defiAddress, address _tokenAddress, uint256 _amount) external payable {
        if (!supportedTokens[_tokenAddress]) revert TOKEN_NOT_SUPPORTED();
        uint256 requestedAmount;
        if (_tokenAddress == ETH) {
            if (_amount > 0) revert AMOUNT_PARAMETER_NOT_ZERO_WHEN_BRIDGING_ETH();
            requestedAmount = msg.value;
        } else {
            if (msg.value > 0) revert MSG_VALUE_NOT_ZERO_WHEN_BRIDGING_ERC20();
            requestedAmount = _amount;
        }
        if (requestedAmount == 0) revert REQUESTED_BRIDGE_AMOUNT_IS_ZERO();
        uint256 txFee = calculateFee(requestedAmount);
        uint256 netAmount = requestedAmount - txFee;
        emit BRIDGE_TO_DEFI_CHAIN(_defiAddress, _tokenAddress, netAmount);
        if (_tokenAddress == ETH) {
            (bool sentTxFee, ) = communityWallet.call{value: txFee}('');
            if (!sentTxFee) revert ETH_TRANSFER_FAILED_TO_COMMUNITY_WALLET();
            (bool sentNetAmount, ) = coldWallet.call{value: netAmount}('');
            if (!sentNetAmount) revert ETH_TRANSFER_FAILED_TO_COLD_WALLET();
        } else {
            IERC20Upgradeable(_tokenAddress).safeTransferFrom(msg.sender, communityWallet, txFee);
            IERC20Upgradeable(_tokenAddress).safeTransferFrom(msg.sender, coldWallet, netAmount);
        }
    }

    /**
     * @notice Function to calculate the fee for bridgeToDeFiChain operation
     */
    function calculateFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * transactionFee) / 10000;
    }

    /**
     * @notice Function to add support for a token
     * @param _tokenAddress address of the token to be supported
     */
    function addSupportedToken(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (supportedTokens[_tokenAddress]) revert TOKEN_ALREADY_SUPPORTED();
        supportedTokens[_tokenAddress] = true;
        emit TOKEN_SUPPORTED(_tokenAddress);
    }

    /**
     * @notice Function to remove support for a token
     * @param _tokenAddress address of the token to be removal of support
     */
    function removeSupportedToken(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!supportedTokens[_tokenAddress]) revert TOKEN_NOT_SUPPORTED();
        supportedTokens[_tokenAddress] = false;
        emit TOKEN_REMOVED(_tokenAddress);
    }

    /**
     * @notice Function to change transaction fee
     * @param _fee the transaction fee to be changed to
     */
    function changeTxFee(uint256 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_fee > MAX_FEE) revert MORE_THAN_MAX_FEE();
        uint256 oldTxFee = transactionFee;
        transactionFee = _fee;
        emit TRANSACTION_FEE_CHANGED(oldTxFee, _fee);
    }

    /**
     * @notice Function to change the cold wallet address
     * @param _newColdWallet the new cold wallet address
     */
    function changeColdWallet(address _newColdWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newColdWallet == address(0)) revert INVALID_COLD_WALLET();
        address oldColdWallet = coldWallet;
        coldWallet = _newColdWallet;
        emit COLD_WALLET_CHANGED(oldColdWallet, _newColdWallet);
    }

    /**
     * @notice Function to change the community wallet address
     * @param _newCommunityWallet the new community wallet address
     */
    function changeCommunityWallet(address _newCommunityWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newCommunityWallet == address(0)) revert INVALID_COMMUNITY_WALLET();
        address oldCommunityWallet = communityWallet;
        communityWallet = _newCommunityWallet;
        emit COMMUNITY_WALLET_CHANGED(oldCommunityWallet, _newCommunityWallet);
    }
}