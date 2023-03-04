// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
/** @notice @dev
/* This error occurs when incoorect nonce provided
*/
error INCORRECT_NONCE();

/** @notice @dev
/* This error occurs when token is not in supported list
*/
error TOKEN_NOT_SUPPORTED();

/** @notice @dev
/* This error occurs when fake signatures being used to claim fund
*/
error FAKE_SIGNATURE();

/** @notice @dev
/* This error occurs when token is already in supported list
*/
error TOKEN_ALREADY_SUPPORTED();

/** @notice @dev
/* This error occurs when using Zero address
*/
error ZERO_ADDRESS();

/** @notice @dev
/* This error occurs when Admin(s) try to change daily allowance of un-supported token.
*/
error ONLY_SUPPORTED_TOKENS();

/** @notice @dev
/* This error occurs when `_newResetTimeStamp` is before block.timestamp
*/
error EXPIRED_CLAIM();

/** @notice @dev
/* This error occurs when `_amount` is zero
*/
error REQUESTED_BRIDGE_AMOUNT_IS_ZERO();

/** @notice @dev
/* This error occurs when transfer of ETH failed
 */
error ETH_TRANSFER_FAILED();

/** @notice @dev
 * This error occurs when _amount input is not zero when bridgeToDeFiChain is requested for ETH
 */
error AMOUNT_PARAMETER_NOT_ZERO_WHEN_BRIDGING_ETH();

/** @notice @dev
 * This error occurs when msg.value is not zero when bridgeToDeFiChain is requested for ERC20
 */
error MSG_VALUE_NOT_ZERO_WHEN_BRIDGING_ERC20();

/** @notice @dev
 * This error will occur when new `fee` is greater than `MAX_FEE`
 */
error MORE_THAN_MAX_FEE();

/** @notice @dev
 * This error will occur when `_toIndex` is greater than `supportedTokens.length()`
 */
error INVALID_TOINDEX();

contract BridgeV1 is UUPSUpgradeable, EIP712Upgradeable, AccessControlUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 constant DATA_TYPE_HASH =
        keccak256('CLAIM(address to,uint256 amount,uint256 nonce,uint256 deadline,address tokenAddress)');

    bytes32 public constant WITHDRAW_ROLE = keccak256('WITHDRAW_ROLE');

    string public constant NAME = 'QUANTUM_BRIDGE';

    address public constant ETH = address(0);
    // Maximum transaction fee when bridging from EVM to DeFiChain. Based on dps (e.g 1% == 100dps)
    uint256 public constant MAX_FEE = 10000;
    // Mapping to track the address's nonce
    mapping(address => uint256) public eoaAddressToNonce;

    // Enumerable set of supportedTokens
    EnumerableSetUpgradeable.AddressSet internal supportedTokens;

    address public relayerAddress;
    // Mapping to track the maximum balance of tokens the contract can hold per token address.
    mapping(address => uint256) public tokenCap;

    // Transaction fee when bridging from EVM to DeFiChain. Based on dps (e.g 1% == 100dps)
    uint256 public transactionFee;
    // Community wallet to send tx fees to
    address public communityWallet;
    // Address to receive the flush
    address public flushReceiveAddress;

    /**
     * @notice Emitted when the user claims funds from the bridge
     * @param tokenAddress Token that is being claimed
     * @param to Address that funds  will be transferred to
     * @param amount Amount of the token being claimed
     */
    event CLAIM_FUND(address indexed tokenAddress, address indexed to, uint256 indexed amount);

    /**
     * @notice Emitted when the user bridges token to DefiChain
     * @param defiAddress defiAddress DeFiChain address of user
     * @param tokenAddress Supported token's being bridged
     * @param amount Amount of the token being bridged
     * @param timestamp TimeStamp of the transaction
     */
    event BRIDGE_TO_DEFI_CHAIN(
        bytes indexed defiAddress,
        address indexed tokenAddress,
        uint256 indexed amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a new token is being added to the supported list by only Admin accounts
     * @param supportedToken Address of the token being added to the supported list
     * @param tokenCap Maximum balance per supported token
     */
    event ADD_SUPPORTED_TOKEN(address indexed supportedToken, uint256 indexed tokenCap);

    /**
     * @notice Emitted when the existing supported token is removed from the supported list by only Admin accounts
     * @param token Address of the token removed from the supported list
     */
    event REMOVE_SUPPORTED_TOKEN(address indexed token);

    /**
     * @notice Emitted when withdrawal of supportedToken only by the Admin account
     * @param withdrawAddress Address initiating withdrawal
     * @param withdrawalTokenAddress Address of the token that being withdrawed
     * @param withdrawalAmount Withdrawal amount of token
     */
    event WITHDRAWAL(
        address indexed withdrawAddress,
        address indexed withdrawalTokenAddress,
        uint256 indexed withdrawalAmount
    );

    /**
     * @notice Emitted when relayer address changes by only Admin accounts
     * @param oldAddress Old relayer's address
     * @param newAddress New relayer's address
     */
    event RELAYER_ADDRESS_CHANGED(address indexed oldAddress, address indexed newAddress);

    /**
     * @notice Emitted when transcation fee is changed by only Admin accounts
     * @param oldTxFee Old transcation fee in bps
     * @param newTxFee New transcation fee in bps
     */
    event TRANSACTION_FEE_CHANGED(uint256 indexed oldTxFee, uint256 indexed newTxFee);

    /**
     * @notice Emitted when the address to send transcation fees to is changed by Admin accounts
     * @param oldAddress Old community's Address
     * @param newAddress Old community's Address
     */
    event TRANSACTION_FEE_ADDRESS_CHANGED(address indexed oldAddress, address indexed newAddress);

    /**
     * @notice Emitted when fund is flushed
     * @param _tokenAddress ERC20 token to be flushed
     */
    event FLUSH_FUND(address indexed _tokenAddress);

    /**
     * @notice Emitted when fund is flushed
     * @param _fromIndex Starting index
     * @param _toIndex Ending index
     */
    event FLUSH_FUND_MULTIPLE_TOKENS(uint256 indexed _fromIndex, uint256 indexed _toIndex);

    /**
     * @notice Emitted when the address to be flushed to is changed
     * @param oldAddress The old address to be flushed to
     * @param newAddress The new address to be flushed to
     */
    event CHANGE_FLUSH_RECEIVE_ADDRESS(address indexed oldAddress, address indexed newAddress);

    /**
     * @notice Emitted when the tokenCap of an existing supported token is changed by only Admin accounts
     * @param supportedToken Address of the supported token
     * @param oldTokenCap The old maximum balance this contract can hold
     * @param newTokenCap The new maximum balance this contract can hold
     */
    event CHANGE_TOKEN_CAP(address indexed supportedToken, uint256 indexed oldTokenCap, uint256 indexed newTokenCap);

    /**
     * @notice Emitted when ETH is received via receive external payable
     * @param sender The sender of ETH
     * @param ethAmount The amount of ETH sent to the smart contract
     */
    event ETH_RECEIVED_VIA_RECEIVE_FUNCTION(address indexed sender, uint256 indexed ethAmount);

    /**
     * constructor to disable initalization of implementation contract
     */
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @notice To initialize this contract (No constructor as part of the proxy pattery )
     * @param _timelockContract TimelockContract who will have the DEFAULT_ADMIN_ROLE
     * @param _initialWithdraw Initial withdraw address of the contract
     * @param _relayerAddress Relayer address for signature
     * @param _communityWallet Community address for tx fees
     * @param _fee Fee charged on each transcation (initial fee: 0.3%)
     */
    function initialize(
        address _timelockContract,
        address _initialWithdraw,
        address _relayerAddress,
        address _communityWallet,
        uint256 _fee,
        address _flushReceiveAddress
    ) external initializer {
        __EIP712_init(NAME, '1');
        _grantRole(DEFAULT_ADMIN_ROLE, _timelockContract);
        _grantRole(WITHDRAW_ROLE, _initialWithdraw);
        communityWallet = _communityWallet;
        relayerAddress = _relayerAddress;
        transactionFee = _fee;
        flushReceiveAddress = _flushReceiveAddress;
    }

    /**
     * @notice Used to claim the tokens that have been approved by the relayer (for bridging from DeFiChain to Ethereum mainnet)
     * @param _to Address to send the claimed fund
     * @param _amount Amount to be claimed
     * @param _nonce Nonce of the address making the claim
     * @param _deadline Deadline of txn. Claims must be made before the deadline.
     * @param _tokenAddress Token address of the supported token
     * @param signature Signature provided by the server
     */
    function claimFund(
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline,
        address _tokenAddress,
        bytes calldata signature
    ) external {
        if (eoaAddressToNonce[_to] != _nonce) revert INCORRECT_NONCE();
        if (!supportedTokens.contains(_tokenAddress)) revert TOKEN_NOT_SUPPORTED();
        if (block.timestamp > _deadline) revert EXPIRED_CLAIM();
        bytes32 struct_hash = keccak256(abi.encode(DATA_TYPE_HASH, _to, _amount, _nonce, _deadline, _tokenAddress));
        bytes32 msg_hash = _hashTypedDataV4(struct_hash);
        if (ECDSAUpgradeable.recover(msg_hash, signature) != relayerAddress) revert FAKE_SIGNATURE();
        eoaAddressToNonce[_to]++;
        emit CLAIM_FUND(_tokenAddress, _to, _amount);
        if (_tokenAddress == ETH) {
            (bool sent, ) = _to.call{value: _amount}('');
            if (!sent) revert ETH_TRANSFER_FAILED();
        } else {
            IERC20Upgradeable(_tokenAddress).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice Used to transfer the supported token from Mainnet(EVM) to DefiChain
     * Transfer will only be possible if not in change allowance peroid.
     * @param _defiAddress DefiChain token address
     * @param _tokenAddress Supported token address that being bridged
     * @param _amount Amount to be bridged, this in in Wei
     */
    function bridgeToDeFiChain(
        bytes calldata _defiAddress,
        address _tokenAddress,
        uint256 _amount
    ) external payable {
        if (!supportedTokens.contains(_tokenAddress)) revert TOKEN_NOT_SUPPORTED();
        uint256 requestedAmount;
        if (_tokenAddress == ETH) {
            if (_amount > 0) revert AMOUNT_PARAMETER_NOT_ZERO_WHEN_BRIDGING_ETH();
            requestedAmount = msg.value;
        } else {
            if (msg.value > 0) revert MSG_VALUE_NOT_ZERO_WHEN_BRIDGING_ERC20();
            requestedAmount = _amount;
        }
        if (requestedAmount == 0) revert REQUESTED_BRIDGE_AMOUNT_IS_ZERO();
        uint256 netAmountInWei = amountAfterFees(requestedAmount);
        uint256 netTxFee = requestedAmount - netAmountInWei;
        emit BRIDGE_TO_DEFI_CHAIN(_defiAddress, _tokenAddress, netAmountInWei, block.timestamp);
        if (_tokenAddress == ETH) {
            if (netTxFee > 0) {
                (bool sent, ) = communityWallet.call{value: netTxFee}('');
                if (!sent) revert ETH_TRANSFER_FAILED();
            }
        } else {
            if (netTxFee > 0) IERC20Upgradeable(_tokenAddress).safeTransferFrom(msg.sender, communityWallet, netTxFee);
            IERC20Upgradeable(_tokenAddress).safeTransferFrom(msg.sender, address(this), netAmountInWei);
        }
    }

    /**
     * @notice anyone can call this function. For example, calling flushMultipleTokenFunds(0,3),
     * only the tokens at index 0, 1 and 2 will be flushed.
     * @param _fromIndex Starting index for array `supportedTokens.values()` to flush from (inclusive)
     * @param _toIndex Ending index for array `supportedTokens.values()` to flush to (exclusive)
     */
    function flushMultipleTokenFunds(uint256 _fromIndex, uint256 _toIndex) external {
        if (_toIndex > supportedTokens.length()) revert INVALID_TOINDEX();
        address _flushReceiveAddress = flushReceiveAddress;
        for (uint256 i = _fromIndex; i < _toIndex; ++i) {
            address supToken = supportedTokens.at(i);
            if (supToken == ETH) {
                if (address(this).balance > tokenCap[ETH]) {
                    uint256 amountToFlush = address(this).balance - tokenCap[ETH];
                    (bool sent, ) = _flushReceiveAddress.call{value: amountToFlush}('');
                    if (!sent) revert ETH_TRANSFER_FAILED();
                }
            } else if (IERC20Upgradeable(supToken).balanceOf(address(this)) > tokenCap[supToken]) {
                uint256 amountToFlush = IERC20Upgradeable(supToken).balanceOf(address(this)) - tokenCap[supToken];
                IERC20Upgradeable(supToken).safeTransfer(_flushReceiveAddress, amountToFlush);
            }
        }
        emit FLUSH_FUND_MULTIPLE_TOKENS(_fromIndex, _toIndex);
    }

    /**
     * @notice Function to flush the excess funds across supported token to a hardcoded address
     * anyone can call this function
     * @param _tokenAddress address of the token to be flushed
     */
    function flushFundPerToken(address _tokenAddress) external {
        if (!supportedTokens.contains(_tokenAddress)) revert TOKEN_NOT_SUPPORTED();
        if (_tokenAddress == ETH) {
            if (address(this).balance > tokenCap[ETH]) {
                uint256 amountToFlush = address(this).balance - tokenCap[ETH];
                (bool sent, ) = flushReceiveAddress.call{value: amountToFlush}('');
                if (!sent) revert ETH_TRANSFER_FAILED();
            }
        } else {
            if (IERC20Upgradeable(_tokenAddress).balanceOf(address(this)) > tokenCap[_tokenAddress]) {
                uint256 amountToFlush = IERC20Upgradeable(_tokenAddress).balanceOf(address(this)) -
                    tokenCap[_tokenAddress];
                IERC20Upgradeable(_tokenAddress).safeTransfer(flushReceiveAddress, amountToFlush);
            }
        }
        emit FLUSH_FUND(_tokenAddress);
    }

    /**
     * @notice to receive ether
     */
    receive() external payable {
        emit ETH_RECEIVED_VIA_RECEIVE_FUNCTION(msg.sender, msg.value);
    }

    /**
     * @notice Used by addresses with Admin and Operational roles to add a new supported token and daily allowance
     * @param _tokenAddress The token address to be added to supported list
     * @param _tokenCap maximum balance of tokens the contract can hold per `_tokenAddress`
     */
    function addSupportedTokens(address _tokenAddress, uint256 _tokenCap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (supportedTokens.contains(_tokenAddress)) revert TOKEN_ALREADY_SUPPORTED();
        supportedTokens.add(_tokenAddress);
        tokenCap[_tokenAddress] = _tokenCap;
        emit ADD_SUPPORTED_TOKEN(_tokenAddress, _tokenCap);
    }

    /**
     * @notice Used by addresses with Admin and Operational roles to remove an exisiting supported token
     * @param _tokenAddress The token address to be removed from supported list
     */
    function removeSupportedTokens(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!supportedTokens.contains(_tokenAddress)) revert TOKEN_NOT_SUPPORTED();
        supportedTokens.remove(_tokenAddress);
        tokenCap[_tokenAddress] = 0;
        emit REMOVE_SUPPORTED_TOKEN(_tokenAddress);
    }

    /**
     * @notice Used by Admin only. When called, the specified amount will be withdrawn
     * @param _tokenAddress The token that will be withdraw
     * @param _amount Requested amount to be withdraw. Amount would be in the denomination of ETH
     */
    function withdraw(address _tokenAddress, uint256 _amount) external onlyRole(WITHDRAW_ROLE) {
        address _flushReceiveAddress = flushReceiveAddress;
        if (_tokenAddress == ETH) {
            (bool sent, ) = _flushReceiveAddress.call{value: _amount}('');
            if (!sent) revert ETH_TRANSFER_FAILED();
        } else IERC20Upgradeable(_tokenAddress).safeTransfer(_flushReceiveAddress, _amount);
        emit WITHDRAWAL(msg.sender, _tokenAddress, _amount);
    }

    /**
     * @notice Used by addresses with Admin and Operational roles to set the new flush receive address
     * @param _newAddress new address to be flushed to
     */
    function changeFlushReceiveAddress(address _newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newAddress == address(0)) revert ZERO_ADDRESS();
        address _oldAddress = flushReceiveAddress;
        flushReceiveAddress = _newAddress;
        emit CHANGE_FLUSH_RECEIVE_ADDRESS(_oldAddress, _newAddress);
    }

    /**
     * @notice Used by addresses with Admin and Operational roles to set the new _relayerAddress
     * @param _relayerAddress The new relayer address, ie. the address used by the server for signing claims
     */
    function changeRelayerAddress(address _relayerAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_relayerAddress == address(0)) revert ZERO_ADDRESS();
        address oldRelayerAddress = relayerAddress;
        relayerAddress = _relayerAddress;
        emit RELAYER_ADDRESS_CHANGED(oldRelayerAddress, _relayerAddress);
    }

    /**
     * @notice Called by addresses with Admin and Operational roles to set the new txn fee
     * @param fee The new fee
     */
    function changeTxFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (fee > MAX_FEE) revert MORE_THAN_MAX_FEE();
        uint256 oldTxFee = transactionFee;
        transactionFee = fee;
        emit TRANSACTION_FEE_CHANGED(oldTxFee, transactionFee);
    }

    /**
     * @notice Called by addresses with Admin and Operational roles to set the new wallet for sending transaction fees to
     * @param _newAddress The new community address
     */
    function changeTxFeeAddress(address _newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newAddress == address(0)) revert ZERO_ADDRESS();
        address oldAddress = communityWallet;
        communityWallet = _newAddress;
        emit TRANSACTION_FEE_ADDRESS_CHANGED(oldAddress, _newAddress);
    }

    /**
     * @notice Called by addresses with Admin and Operational roles to reset the maximum balance of tokens the contract
     * @param _newTokenCap The new maximum balance of tokens the contract can hold per token address.
     */
    function changeTokenCap(address _tokenAddress, uint256 _newTokenCap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!supportedTokens.contains(_tokenAddress)) revert TOKEN_NOT_SUPPORTED();
        uint256 oldTokenCap = tokenCap[_tokenAddress];
        tokenCap[_tokenAddress] = _newTokenCap;
        emit CHANGE_TOKEN_CAP(_tokenAddress, oldTokenCap, _newTokenCap);
    }

    /**
     * @notice To get the current version of the contract
     */
    function version() external view returns (string memory) {
        return StringsUpgradeable.toString(_getInitializedVersion());
    }

    /**
     * @notice to get the supported tokens, as recursive data structure (supportedTokens) cannot be made public
     */
    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokens.values();
    }

    /**
     * @notice to check whether a token is supported
     */
    function isSupported(address _tokenAddress) external view returns (bool) {
        return supportedTokens.contains(_tokenAddress);
    }

    /**
     * This function provides the net amount after deducting fee
     * @param _amount Ideally will be the value of erc20 token
     * @return netAmountInWei net balance after the fee amount taken
     */
    function amountAfterFees(uint256 _amount) internal view returns (uint256 netAmountInWei) {
        netAmountInWei = _amount - (_amount * transactionFee) / 10000;
    }
}