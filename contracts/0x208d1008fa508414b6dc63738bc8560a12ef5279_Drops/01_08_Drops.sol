// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**

    -+#@@@@***#%%#*=.                                                           
      [email protected]@@%      -%@@#:                                                         
      [email protected]@@%        %@@@+     .=   .==.    :===-:        .=  :==-       :-=-.  -.
      [email protected]@@%        [email protected]@@@. .=%@@.=%@@@# .*@#. :%@@+   .=%@@[email protected]@@@@*.  [email protected]@+::=+%@:
      [email protected]@@%        [email protected]@@@=.-%@@@:..#@@%:@@@-    @@@@..-%@@@=::-#@@@%  @@@*:   [email protected]:
      [email protected]@@%        :@@@@-  #@@@   ++- #@@@-    [email protected]@@#  #@@@.    #@@@= *@@@@@*- :.
      [email protected]@@%        *@@@%   #@@@       %@@@=    [email protected]@@@  #@@@.    [email protected]@@= .:[email protected]@@@@@*.
      [email protected]@@%       :@@@#    #@@@       [email protected]@@%    :@@@*  #@@@.    %@@@..%.  :+%@@@%
      [email protected]@@%      [email protected]@#-     #@@@        [email protected]@@=   [email protected]@#   #@@@=..:#@@@: [email protected]@=    *@@#
    -+#####****+++-      .=####+-.      .=#@#=+#+:    #@@@:*@@@%+.  .%:.+**#@%= 
                                                      #@@@.                     
    -----------------------------------------         #@@@.                     
     F R O M   S A M   K I N G   S T U D I O        .=####+-.
    -----------------------------------------

 */

import "solmate/tokens/ERC1155.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import "openzeppelin/utils/cryptography/draft-EIP712.sol";
import "./lib/Auth.sol";
import "./IMetadata.sol";

/**
 * @title  Drops from Sam King Studio
 * @author Sam King (samkingstudio.eth)
 * @notice
 * Allows Sam King Studio to drop NFTs to any ETH address
 *   - NFTs are ERC-1155 tokens
 *   - Can be dropped by the studio directly
 *   - Can also be claimed by an address with a valid EIP-712 signature
 * For more details and license info, check out https://drops.samking.studio
 */
contract Drops is ERC1155, EIP712, Auth {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    string public name = "Drops from Sam King Studio";
    string public symbol = "SKSDRP";

    /// @dev EIP-712 signing domain
    string public constant SIGNING_DOMAIN = "SamKingStudioDrops";

    /// @dev EIP-712 signature version
    string public constant SIGNATURE_VERSION = "1";

    /// @dev EIP-712 signed data type hash for claiming drops
    bytes32 public constant CLAIM_DROP_TYPEHASH =
        keccak256("ClaimDropData(uint256 dropId,uint256 amount,address to,uint256 nonce)");

    /// @dev EIP-712 signed data struct for claiming drops
    struct ClaimDropData {
        uint256 dropId;
        uint256 amount;
        address to;
        uint256 nonce;
        bytes signature;
    }

    /// @dev Approved signer public addresses
    mapping(address => bool) public approvedSigners;

    /// @dev Nonce management to avoid signature replay attacks
    mapping(address => uint256) public nonces;

    /// @notice Set a token metadata URI per drop
    mapping(uint256 => string) public dropURI;

    /// @notice Optional token metadata contract per drop
    mapping(uint256 => address) public dropMetadataAddress;

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    event Initialised();

    /**
     * @notice Init the contract
     * @param owner_ The owner of the contract. Can use drops.
     * @param admin_ The initial admin of the contract. Can use drops.
     * @param signer_ An initial EIP-712 signing address
     */
    constructor(
        address owner_,
        address admin_,
        address signer_
    ) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) Auth(owner_, admin_) {
        approvedSigners[signer_] = true;
        emit SignerAdded(signer_);
        emit Initialised();
    }

    /* ------------------------------------------------------------------------
       M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev
     * Only allows the function to be called when a URI or metadata address has been
     * set for the particular drop
     *
     * @param dropId The id of the drop to check
     */
    modifier onlyWhenDropIsReady(uint256 dropId) {
        // If there's no metadata address, then check if there's a uri set
        if (dropMetadataAddress[dropId] == address(0)) {
            bytes memory dropUri = bytes(dropURI[dropId]);
            require(dropUri.length > 0, "DROP_NOT_READY");
        }
        _;
    }

    /* ------------------------------------------------------------------------
       D R O P S
    ------------------------------------------------------------------------ */

    /// @dev Emitted when an admin has called any of the drop functions
    event Dropped(uint256 indexed dropId);

    /**
     * @notice Mints one token from the specified drop to each recipient
     *
     * @param dropId The id of the drop
     * @param recipients The list of address to mint tokens to
     */
    function drop(uint256 dropId, address[] calldata recipients)
        external
        onlyWhenDropIsReady(dropId)
        onlyOwnerOrAdmin
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], dropId, 1, "");
        }
        emit Dropped(dropId);
    }

    /**
     * @notice Mints multiple tokens from the specified drop to each recipient
     *
     * @param dropId The id of the drop
     * @param recipients The list of address to mint tokens to
     * @param amount The amount of tokens to mint to each recipient
     */
    function drop(
        uint256 dropId,
        address[] calldata recipients,
        uint256 amount
    ) external onlyWhenDropIsReady(dropId) onlyOwnerOrAdmin {
        if (amount > 0) {
            for (uint256 i = 0; i < recipients.length; i++) {
                _mint(recipients[i], dropId, amount, "");
            }
        }
        emit Dropped(dropId);
    }

    /**
     * @notice Mints multiple tokens from the specified drop to each recipient
     *
     * @param dropId The id of the drop
     * @param recipients The list of address to mint tokens to
     * @param amounts The amount of tokens to mint per recipient
     */
    function drop(
        uint256 dropId,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyWhenDropIsReady(dropId) onlyOwnerOrAdmin {
        require(recipients.length == amounts.length, "LENGTH_MISMATCH");
        for (uint256 i = 0; i < recipients.length; i++) {
            if (amounts[i] > 0) {
                _mint(recipients[i], dropId, amounts[i], "");
            }
        }
        emit Dropped(dropId);
    }

    /**
     * @notice Mints tokens from the specified drop to a specific address,
     * usually the Sam King Studio or owner address.
     *
     * @param dropId The id of the drop
     * @param to The list of address to mint tokens to
     * @param amount The amount of tokens to mint per recipient
     */
    function studioMint(
        uint256 dropId,
        address to,
        uint256 amount
    ) external onlyWhenDropIsReady(dropId) onlyOwnerOrAdmin {
        _mint(to, dropId, amount, "");
        emit Dropped(dropId);
    }

    /// @dev Emitted when a drop is claimed using EIP-712
    event DropClaimed(uint256 indexed dropId, address indexed by, uint256 indexed amount);

    /**
     * @notice Claims a drop using an EIP-712 signature. Caller pays gas to claim
     * instead of being airdropped by Sam King Studio.
     *
     * @param dropId The id of the drop
     * @param amount The amount of tokens to mint
     * @param signature A valid EIP-712 signature
     */
    function claimDrop(
        uint256 dropId,
        uint256 amount,
        bytes calldata signature
    ) external onlyWhenDropIsReady(dropId) {
        // Reconstruct the signed data on-chain
        ClaimDropData memory data = ClaimDropData({
            dropId: dropId,
            amount: amount,
            to: msg.sender,
            nonce: nonces[msg.sender],
            signature: signature
        });

        // Hash the data for verification
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    CLAIM_DROP_TYPEHASH,
                    data.dropId,
                    data.amount,
                    data.to,
                    nonces[data.to]++
                )
            )
        );

        // Verifiy signature is ok
        address addr = ECDSA.recover(digest, data.signature);
        require(approvedSigners[addr] && addr != address(0), "INVALID_SIGNATURE");

        // Claim the drop
        if (data.amount > 0) {
            _mint(data.to, data.dropId, data.amount, "");
            emit DropClaimed(data.dropId, data.to, data.amount);
        }
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to set the URI for a particular drop
     * @dev Emits the URI event from ERC1155
     *
     * @param dropId The id of the drop to set the URI for
     * @param uri_ The new URI
     */
    function setDropURI(uint256 dropId, string calldata uri_) external onlyOwnerOrAdmin {
        dropURI[dropId] = uri_;
        emit URI(uri_, dropId);
    }

    /**
     * @notice Admin function to set the URI for a particular drop
     * @dev Emits the URI event from ERC1155
     *
     * @param dropId The id of the drop to set the URI for
     * @param metadata The new metadata contract address
     */
    function setDropMetadataAddress(uint256 dropId, address metadata) external onlyOwnerOrAdmin {
        dropMetadataAddress[dropId] = metadata;
        emit URI(IMetadata(metadata).uri(dropId), dropId);
    }

    /// @dev Emitted when a new signer is added to this contract
    event SignerAdded(address indexed signer);

    /**
     * @notice Admin function to add a new EIP-712 signer address
     * @dev Emits the SignerAdded event
     *
     * @param signer The address of the new signer
     */
    function addSigner(address signer) external onlyOwnerOrAdmin {
        approvedSigners[signer] = true;
        emit SignerAdded(signer);
    }

    /// @dev Emitted when an existing signer is removed from this contract
    event SignerRemoved(address indexed signer);

    /**
     * @notice Admin function to remove an existing EIP-712 signer address
     * @dev Emits the SignerRemoved event
     *
     * @param signer The address of the signer to remove
     */
    function removeSigner(address signer) external onlyOwnerOrAdmin {
        approvedSigners[signer] = false;
        emit SignerRemoved(signer);
    }

    /* ------------------------------------------------------------------------
       M E T A D A T A
    ------------------------------------------------------------------------ */

    /**
     * @notice ERC1155 token URI
     * @param id The token id to get token metadata for
     * @return metadata The token metadata URI or Base64 encoded JSON token metadata
     */
    function uri(uint256 id) public view override returns (string memory) {
        address metadata = dropMetadataAddress[id];
        if (metadata != address(0)) return IMetadata(metadata).uri(id);
        return dropURI[id];
    }
}