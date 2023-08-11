pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IAccess.sol";

contract Access is Initializable, OwnableUpgradeable, IAccess {
    mapping(address => bool) public signValidationWhitelist; //Mapping of addresses of contracts who can use preAuthValidations
    mapping(address => mapping(bytes32 => bool)) public tokenUsed; //Mapping to track token is used or not
    mapping(address => bool) public sendManagers; // Mapping of addresses who can send delegate trxs

    receive() external payable {
        revert("Accesses: Contract cannot work with COINS");
    }

    /**
     * @dev Initializes the contract
     */
    function initialize() public initializer {
        __Ownable_init();
        sendManagers[msg.sender] = true;
    }

    /**
     * @notice Update addressess who can send delegate trxs
     * @dev Only owner can call
     * @param _manager The wallet of the user
     * @param _isManager Bool variable that indicates is wallet is manager or not
     */
    function updateSenders(address _manager, bool _isManager)
    external
    onlyOwner
    {
        require(_manager != address(0), "Access: Zero address is not allowed");
        sendManagers[_manager] = _isManager;
    }


    /**
     * @notice Update whitelist of addresses of contracts who can use preAuthValidations
     * @dev Only owner can call
     * @param _contract The address of the contract
     * @param _canValidate Bool variable that indicates is address can use preAuthValidations
     */
    function updateSignValidationWhitelist(address _contract, bool _canValidate)
    external
    onlyOwner
    {
        require(_contract != address(0), "Access: Zero address is not allowed");
        signValidationWhitelist[_contract] = _canValidate;
    }

    /**
     * @notice Validates the message and signature
     * @param message The message that user signed
     * @param signature Signature
     * @param token The unique token for each delegated function
     * @return address Signer of message
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
        return signer;
    }

    /**
     * @notice Check if address is owner
     */
    function isOwner(address _manager) external view override returns (bool) {
        return _manager == owner();
    }

    /**
     * @notice Check if address is sender
     */
    function isSender(address _manager) external view override returns (bool) {
        return sendManagers[_manager];
    }

    /**
     * @notice Find signer
     * @param message The message that user signed
     * @param signature Signature
     * @return address Signer of message
     */
    function getSigner(bytes32 message, bytes memory signature)
    public
    pure
    returns (address)
    {
        message = ECDSA.toEthSignedMessageHash(message);
        address signer = ECDSA.recover(message, signature);
        return signer;
    }
}