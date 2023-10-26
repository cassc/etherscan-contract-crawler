// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IAccess.sol";

contract Access is Initializable, OwnableUpgradeable, IAccess {
    mapping(address => bool) public signValidationWhitelist; // Mapping of addresses of contracts that can use preAuthValidations
    mapping(address => mapping(bytes32 => bool)) public tokenUsed; // Mapping to track if a token has been used or not
    mapping(address => bool) public minters; // Mapping of AZX minters
    mapping(address => bool) public sendManagers; // Mapping of addresses that can send delegate transactions
    mapping(address => bool) public signManagers; // Mapping of addresses that can sign internal operations
    mapping(address => bool) public tradeDeskManagers; // Mapping of addresses of TradeDesk users

    event SignatureValidated(address indexed signer, bytes32 token);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract
     */
    function initialize() public initializer {
        __Ownable_init();
        minters[msg.sender] = true;
        sendManagers[msg.sender] = true;
        signManagers[msg.sender] = true;
        tradeDeskManagers[msg.sender] = true;
    }

    receive() external payable {
        revert("Access: Contract cannot work with ETH");
    }

    /**
     * @notice Update manager roles for addresses
     * @dev Only the owner can call this function
     * @param _manager The wallet of the user
     * @param _isManager Bool variable indicating whether the wallet is a manager or not
     */
    function updateMinters(
        address _manager,
        bool _isManager
    ) external onlyOwner {
        require(_manager != address(0), "Access: Zero address is not allowed");
        minters[_manager] = _isManager;
    }

    /**
     * @notice Update addresses that can send delegate transactions
     * @dev Only the owner can call this function
     * @param _manager The wallet of the user
     * @param _isManager Bool variable indicating whether the wallet is a manager or not
     */
    function updateSenders(
        address _manager,
        bool _isManager
    ) external onlyOwner {
        require(_manager != address(0), "Access: Zero address is not allowed");
        sendManagers[_manager] = _isManager;
    }

    /**
     * @notice Update addresses that can sign delegate operations
     * @dev Only the owner can call this function
     * @param _manager The wallet of the user
     * @param _isManager Bool variable indicating whether the wallet is a manager or not
     */
    function updateSigners(
        address _manager,
        bool _isManager
    ) external onlyOwner {
        require(_manager != address(0), "Access: Zero address is not allowed");
        signManagers[_manager] = _isManager;
    }

    /**
     * @notice Update addresses of TradeDesk users
     * @dev Only the owner or sign manager can call this function
     * @param _user The wallet of the user
     * @param _isTradeDesk Bool variable indicating whether the wallet is a TradeDesk user or not
     */
    function updateTradeDeskUsers(
        address _user,
        bool _isTradeDesk
    ) external override {
        require(
            msg.sender == owner() || signValidationWhitelist[msg.sender],
            "Access: Only the owner or sign manager can call this function"
        );
        require(_user != address(0), "Access: Zero address is not allowed");
        tradeDeskManagers[_user] = _isTradeDesk;
    }

    /**
     * @notice Update whitelist of addresses of contracts that can use preAuthValidations
     * @dev Only the owner can call this function
     * @param _contract The address of the contract
     * @param _canValidate Bool variable indicating whether the address can use preAuthValidations
     */
    function updateSignValidationWhitelist(
        address _contract,
        bool _canValidate
    ) external onlyOwner {
        require(_contract != address(0), "Access: Zero address is not allowed");
        signValidationWhitelist[_contract] = _canValidate;
    }

    /**
     * @notice Validates the message and signature
     * @param message The message that the user signed
     * @param signature Signature
     * @param token The unique token for each delegated function
     * @return address Signer of the message
     */
    function preAuthValidations(
        bytes32 message,
        bytes32 token,
        bytes memory signature
    ) external override returns (address) {
        require(
            signValidationWhitelist[msg.sender],
            "Access: Sender is not whitelisted to use preAuthValidations"
        );
        address signer = getSigner(message, signature);
        require(signer != address(0), "Access: Zero address not allowed");
        require(!tokenUsed[signer][token], "Access: Token already used");
        tokenUsed[signer][token] = true;

        emit SignatureValidated(signer, token);
        return signer;
    }

    /**
     * @notice Check if an address is the owner
     */
    function isOwner(address _manager) external view override returns (bool) {
        return _manager == owner();
    }

    /**
     * @notice Check if an address is a minter
     */
    function isMinter(address _manager) external view override returns (bool) {
        return minters[_manager];
    }

    /**
     * @notice Check if an address is a sender
     */
    function isSender(address _manager) external view override returns (bool) {
        return sendManagers[_manager];
    }

    /**
     * @notice Check if an address is a signer
     */
    function isSigner(address _manager) external view override returns (bool) {
        return signManagers[_manager];
    }

    /**
     * @notice Check if an address is a TradeDesk user
     */
    function isTradeDesk(address _user) external view override returns (bool) {
        return tradeDeskManagers[_user];
    }

    /**
     * @notice Find the signer
     * @param message The message that the user signed
     * @param signature Signature
     * @return address Signer of the message
     */
    function getSigner(
        bytes32 message,
        bytes memory signature
    ) public pure returns (address) {
        message = ECDSA.toEthSignedMessageHash(message);
        address signer = ECDSA.recover(message, signature);
        return signer;
    }
}