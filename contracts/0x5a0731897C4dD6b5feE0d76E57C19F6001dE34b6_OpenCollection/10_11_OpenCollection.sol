// SPDX-License-Identifier: MIT

/**
 * @title OpenCollection - Provenance
 * @author zeroknots.eth
 * @notice This contract implements an ERC1155 collection with a minting mechanism that supports
 * a Merkle tree-based allowlist and provenance SBT. Users can mint up to a certain amount of tokens
 * if they are on the allowlist or have a provenance SBT.
 */
pragma solidity 0.8.19;

// Debugging import, TODO: remove in production
import "forge-std/console2.sol";

// ERC1155 standard
import {ERC1155} from "solady/tokens/ERC1155.sol";

// OpenZeppelin's Ownable contract for access control
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

// OpenZeppelin's IERC721 interface for provenance SBT interactions
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

// OpenZeppelin's MerkleProof contract for checking allowlist membership
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

// OpenCollectionLib contract for additional utility functions
import {OpenCollectionLib} from "./OpenCollectionLib.sol";

contract OpenCollection is ERC1155, Ownable {
    // Importing the library for address. This is used to convert an address to a bytes32.
    using OpenCollectionLib for address;

    // Custom errors
    error MaxMintAmount(uint256 amount);
    error InsufficientFunds(uint256 amount);
    error MintNotStarted();
    error NotOnAllowlist();

    // Events
    event Reveal(uint256 seed);
    event Withdraw(uint256 amount);

    // Token ID constants
    uint256 public constant TOKENID_COMMON = 1;
    uint256 public constant TOKENID_UNCOMMON = 2;
    uint256 public constant TOKENID_RARE = 3;

    // Maximum mint amount per user
    uint256 private MAX_MINT_AMOUNT = 2;

    // Total supply constants
    uint256 public immutable COMMON_TOTAL_SUPPLY = 200;
    uint256 public immutable UNCOMMON_TOTAL_SUPPLY = 10;
    uint256 public immutable RARE_TOTAL_SUPPLY = 3;

    // Merkle tree root for the allowlist
    bytes32 public merkleTreeRoot;

    // Mint price in wei
    uint256 public MINTPRICE;

    // Provenance SBT ERC721 contract
    IERC721 provenanceSBT;

    // Base URI for metadata
    string private _uri;

    // Mapping of user's mint allowance
    mapping(bytes32 => uint256) public mintAllowance;

    // Queue of minted addresses
    address[] private queue;

    /**
     * @notice Constructs the OpenCollection contract.
     * @param owner The address of the contract owner.
     * @param _mintPrice The mint price in wei.
     * @param _provenanceSBT The address of the provenance SBT ERC721 contract.
     */
    constructor(address owner, uint256 _mintPrice, address _provenanceSBT) {
        MINTPRICE = _mintPrice;
        provenanceSBT = IERC721(_provenanceSBT);
        transferOwnership(owner);
    }
    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_uri, Strings.toString(tokenId)));
    }

    function updateURI(string memory newuri) public onlyOwner {
        _uri = newuri;
    }

    /**
     * @notice Mints the specified amount of tokens for the given address, subject to mint constraints and eligibility.
     * @dev Checks if the minting constraints are satisfied and if the address is eligible for minting.
     * @param to The address to mint tokens to.
     * @param amount The number of tokens to mint.
     */
    function mint(address to, uint256 amount) external payable {
        _enforceMintConstraints(to, amount);
        // Enforce mint constraints and return the number of tokens already minted for this address
        uint256 alreadyMinted = _enforceMintConstraints(to, amount);

        // Check if the address is eligible for minting using the SBT provenance check
        bool isEligable = _checkProvenanceSBT(to);
        if (!isEligable) return;

        // Update the mint allowance for this address
        mintAllowance[keccak256(abi.encodePacked(to))] = alreadyMinted + amount;

        // Mint the specified amount of tokens to the address
        _mint(to, TOKENID_COMMON, amount, "");

        // Record the minting to the queue
        _recordToQueue(to, amount);
    }

    /**
     * @notice Mints the specified amount of tokens for the given address, if the address is eligible.
     * @dev Verifies if the address is on the allowlist using the provided Merkle proof and leaf.
     * @param to The address to mint tokens to.
     * @param amount The number of tokens to mint.
     * @param proof The Merkle proof to verify.
     * @param leaf The leaf node of the Merkle tree.
     */
    function mint(address to, uint256 amount, bytes32[] memory proof, bytes32 leaf) external payable {
        uint256 alreadyMinted = _enforceMintConstraints(to, amount);
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        bool isEligable = _checkAllowlist(proof, _leaf);
        if (!isEligable) revert NotOnAllowlist();

        mintAllowance[leaf] = alreadyMinted + amount;
        _recordToQueue(to, amount);
        _mint(to, TOKENID_COMMON, amount, "");
    }

    /**
     *
     *                                   ADMIN FUNCTIONS
     *
     */

    /**
     * @notice Withdraws the specified amount of Ether from the contract.
     * @dev Can only be called by the contract owner.
     * @param amount The amount of Ether to withdraw, or 0 to withdraw the entire balance.
     */
    function withdraw(uint256 amount) external onlyOwner {
        if (amount == 0) amount = address(this).balance;
        payable(owner()).transfer(amount);
        emit Withdraw(amount);
    }

    /**
     * @notice Reveal the winners by selecting unique random winners from the queue of addresses that minted tokens.
     * @dev Generates two sets of unique random winners for the two token types (B and C) by utilizing the OpenCollectionLib.
     *      The reveal process involves burning the OPEN tokens of the winners and minting new B or C tokens for them.
     *      This function can only be called by the contract owner.
     */
    function reveal() external onlyOwner {
        // Obtain a seed for random number generation from the previous block's RANDAO value
        uint256 seed = block.prevrandao;

        // Use the OpenCollectionLib's _selectUniqueRandom function to generate two sets of unique random winners.
        // - winners1: Represents the winners of TOKENID_B tokens
        // - winners2: Represents the winners of TOKENID_C tokens
        uint256[] memory winners1 =
            OpenCollectionLib._selectUniqueRandom(seed, COMMON_TOTAL_SUPPLY, UNCOMMON_TOTAL_SUPPLY);
        uint256[] memory winners2 =
            OpenCollectionLib._selectUniqueRandom(seed + 1, COMMON_TOTAL_SUPPLY, RARE_TOTAL_SUPPLY);

        // Iterate through the winners1 array
        for (uint256 i; i < winners1.length;) {
            // Get the address of the winner from the queue
            address winner = queue[winners1[i]];

            // Burn 1 OPEN token from the winner's balance
            _burn(winner, TOKENID_COMMON, 1);

            // Mint 1 TOKENID_B token for the winner
            _mint(winner, TOKENID_UNCOMMON, 1, "");

            // Safely increment the loop counter
            unchecked {
                ++i;
            }
        }

        // Iterate through the winners2 array
        for (uint256 i; i < winners2.length;) {
            // Get the address of the winner from the queue
            address winner = queue[winners2[i]];

            // Burn 1 OPEN token from the winner's balance
            _burn(winner, TOKENID_COMMON, 1);

            // Mint 1 TOKENID_C token for the winner
            _mint(winner, TOKENID_RARE, 1, "");

            // Safely increment the loop counter
            unchecked {
                ++i;
            }
        }

        // Emit the Reveal event with the seed used for random number generation
        emit Reveal(seed);
    }

    /**
     * @dev Updates the mint price for tokens
     * @param _mintPrice The new mint price
     */
    function updateMintPrice(uint256 _mintPrice) external onlyOwner {
        MINTPRICE = _mintPrice;
    }

    /**
     * @notice Updates the Merkle tree root for the allowlist.
     * @dev Can only be called by the contract owner.
     * @param root The new Merkle tree root for the allowlist.
     */
    function setRoot(bytes32 root) external onlyOwner {
        merkleTreeRoot = root;
    }

    /**
     *
     *                                   INTERNAL FUNCTIONS
     *
     */

    /**
     * @notice Enforces minting constraints, such as checking if the minting has started and if the sender has sufficient funds.
     * @dev Reverts if any constraints are not met.
     * @param to The address to mint tokens to.
     * @param amount The number of tokens to mint.
     * @return alreadyMinted The number of tokens already minted by the address.
     */
    function _enforceMintConstraints(address to, uint256 amount) internal returns (uint256 alreadyMinted) {
        if (merkleTreeRoot == 0) revert MintNotStarted();
        if (msg.value < MINTPRICE * amount) {
            revert InsufficientFunds(MINTPRICE * amount);
        }
        alreadyMinted = mintAllowance[keccak256(abi.encodePacked(to))];
        if (amount + alreadyMinted > MAX_MINT_AMOUNT) {
            revert MaxMintAmount(MAX_MINT_AMOUNT);
        }
    }

    /**
     * @notice Records the minted tokens to the queue.
     * @dev Adds the recipient address to the queue 'amount' number of times.
     * @param to The address to mint tokens to.
     * @param amount The number of tokens to mint.
     */
    function _recordToQueue(address to, uint256 amount) internal {
        for (uint256 i; i < amount;) {
            queue.push(to);
            // amount <= MAX_MINT_AMOUNT, so this is safe
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Checks if an address holds a provenance SBT token
     * @param to The address to check
     * @return hasProvenanceSBT A boolean indicating if the address has a provenance SBT token
     */
    function _checkProvenanceSBT(address to) internal view returns (bool hasProvenanceSBT) {
        if (provenanceSBT.balanceOf(to) > 0) {
            return true;
        }
    }

    /**
     * @notice Checks if the given address is on the allowlist using the provided Merkle proof and leaf.
     * @dev Uses the OpenZeppelin MerkleProof library to verify the proof against the current merkleTreeRoot.
     * @param proof The Merkle proof to verify.
     * @param leaf The leaf node of the Merkle tree.
     * @return isOnAllowlist True if the address is on the allowlist, false otherwise.
     */
    function _checkAllowlist(bytes32[] memory proof, bytes32 leaf) internal view returns (bool isOnAllowlist) {
        return MerkleProof.verify(proof, merkleTreeRoot, leaf);
    }
}