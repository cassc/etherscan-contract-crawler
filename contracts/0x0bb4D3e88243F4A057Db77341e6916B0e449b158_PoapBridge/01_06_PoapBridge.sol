// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
* @dev Interface to interact with POAP contract
* - Limited functionality as needed
**/
interface IPoap {
    function mintToken(uint256 eventId, uint256 tokenId, address to) external returns (bool);

    function renounceAdmin() external;
}

/**
 * @title POAP Bridge contract
 * @dev Migrate POAP from the main chain to a secondary chain
 * - Users can:
 *   # Set migration fee
 *   # Set migration fee receiver
 *   # Renounce as Admin of POAP contract
 *   # Migrate a POAP
 *   # Pause contract if admin
 *   # Unpause contract if admin
 * @author POAP
 * - Developers:
 *   # Agustin Lavarello
 *   # Rodrigo Manuel Navarro Lajous
 *   # Ramiro Gonzales
**/
contract PoapBridge is Ownable, Pausable {

    /**
     * @dev Emitted when signature is verified
     */
    event VerifiedSignature(
        bytes _signature
    );

    /**
     * @dev Emitted when the signer changes
     */
    event ValidSignerChange(
        address indexed previousValidSigner,
        address indexed newValidSigner
    );

    /**
     * @dev Emitted when the fee receiver changes
     */
    event FeeReceiverChange(
        address indexed previousFeeReceiver,
        address indexed newFeeReceiver
    );

    /**
     * @dev Emitted when the migration fee changes
     */
    event MigrationFeeChange(
        uint256 indexed previousFeeReceiver,
        uint256 indexed newFeeReceiver
    );

    using ECDSA for bytes32;

    // Name of the contract
    string public constant NAME = "POAP Bridge";

    // Interface to interact with POAP contract
    // solhint-disable-next-line var-name-mixedcase
    IPoap immutable private POAPToken;

    // POAP valid token minter
    address public validSigner;

    // POAP fee receiver
    address payable public feeReceiver;

    // POAP fee
    uint256 public migrationFee;

    // Processed signatures
    mapping(bytes => bool) public processed;

    constructor (
        address _poapContractAddress,
        address _validSigner,
        address payable _feeReceiver,
        uint256 _migrationFee
    ) {
        require(_validSigner != address(0), "The zero address can't be a valid signer");
        validSigner = _validSigner;
        POAPToken = IPoap(_poapContractAddress);
        feeReceiver = _feeReceiver;
        migrationFee = _migrationFee;
    }
    
    /**
     * @dev Called by the owner to pause, triggers stopped state.
     * Requires 
     * - The msg sender to be the owner
     */
    function pause() external onlyOwner {
        _pause();
    }

     /**
     * @dev Called by the owner to pause, triggers unstopped state.
     * Requires 
     * - The msg sender to be the owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets address that will receive the migration fee
     * Requires 
     * - The msg sender to be the owner
     * @param _feeReceiver ( address payable ) The address that will receive the fee
     */
    function setFeeReceiver(address payable _feeReceiver) external onlyOwner {
        address oldFeeReceiver = feeReceiver;
        feeReceiver = _feeReceiver;
        emit FeeReceiverChange(oldFeeReceiver, _feeReceiver);
    }

    /**
     * @dev Sets address fee to be charged for migration
     * Requires 
     * - The msg sender to be the owner
     * @param _migrationFee ( uint256 ) The amount of wei to charge
     */
    function setMigrationFee(uint256 _migrationFee) external onlyOwner {
        uint256 oldMigrationFee = migrationFee;
        migrationFee = _migrationFee;
        emit MigrationFeeChange(oldMigrationFee, _migrationFee);
    }

    /**
     * @dev Sets valid signer, the signer can sign the message to migrate a poap
     * Requires
     * - The msg sender to be the owner
     * - The _validSigner not to be the zero address
     * @param _validSigner ( address ) The new valid signer
     */
    function setValidSigner(address _validSigner) external onlyOwner {
        require(_validSigner != address(0), "The zero address can't be a valid signer");
        address oldValidSigner = validSigner;
        validSigner = _validSigner;
        emit ValidSignerChange(oldValidSigner, _validSigner);
    }

    /**
     * @dev Function to renounce as Admin in POAP contract
     * Requires 
     * - The msg sender to be the owner
     */
    function renouncePoapAdmin() external onlyOwner {
        POAPToken.renounceAdmin();
    }

    /**
     * @dev Function to verify signature
     * @param _eventId ( uint256 ) EventId for the token
     * @param _tokenId ( uint256 ) The token id to mint.
     * @param _receiver ( address ) The address that will receive the minted tokens.
     * @param _expirationTime ( uint256 ) Token expiration time.
     * @param _signature ( bytes ) Signature of the message digest.
     * @return A boolean that indicates if the signature is valid.
     */
    function isValidSignature(
        uint256 _eventId,
        uint256 _tokenId,
        address _receiver,
        uint256 _expirationTime,
        bytes memory _signature
    ) private view returns(bool) {
        require(_signature.length == 65, "Unsupported signature length");
        bytes32 message = keccak256(abi.encodePacked(_eventId, _tokenId, _receiver, _expirationTime));
        return message.recover(_signature) == validSigner;
    }

    /**
     * @dev Function to mint tokens
     * Requires 
     * - The sender to send value equal to or greater than the fee
     * - The contract must not be paused
     * @param eventId ( uint256 ) EventId for the token
     * @param tokenId ( uint256 ) The token id to mint.
     * @param receiver ( address ) The address that will receive the minted tokens.
     * @param expirationTime ( uint256 ) Token expiration time.
     * @param signature ( bytes ) Signature of the message digest.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToken(
        uint256 eventId,
        uint256 tokenId,
        address receiver,
        uint256 expirationTime,
        bytes calldata signature
    ) external payable whenNotPaused returns (bool) {
        // Check that the timestamp hasn't expired
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < expirationTime, "Signature expired");
        // Check that the user pay the migration fee
        require(msg.value >= migrationFee, "Insufficient payment");
        // Check that the signature is valid
        require(isValidSignature(eventId, tokenId, receiver, expirationTime, signature), "Invalid signature");
        // Check that the signature was not already processed
        require(processed[signature] == false, "Signature already processed");

        processed[signature] = true;

        // Send the message value to the receiver
        feeReceiver.transfer(msg.value);

        emit VerifiedSignature(signature);
        return POAPToken.mintToken(eventId, tokenId, receiver);
    }
}