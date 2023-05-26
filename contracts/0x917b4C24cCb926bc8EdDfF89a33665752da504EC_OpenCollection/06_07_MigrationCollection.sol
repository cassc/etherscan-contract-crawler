// SPDX-License-Identifier: MIT

/**
 * @title OpenCollection - Provenance
 * @author zeroknots.eth
 * @notice This contract implements an ERC1155 collection with a minting mechanism that supports
 * a Merkle tree-based allowlist and provenance SBT. Users can mint up to a certain amount of tokens
 * if they are on the allowlist or have a provenance SBT.
 */
pragma solidity 0.8.19;

// ERC1155 standard
import {ERC1155} from "solady/tokens/ERC1155.sol";

// OpenZeppelin's Ownable contract for access control
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

// OpenZeppelin's MerkleProof contract for checking allowlist membership
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
    uint256 public immutable UNCOMMON_TOTAL_SUPPLY = 10;
    uint256 public immutable RARE_TOTAL_SUPPLY = 3;

    // Merkle tree root for the allowlist
    bytes32 public merkleTreeRoot;

    // Mint price in wei
    uint256 public MINTPRICE;

    // Base URI for metadata
    string private _uri;

    // Mapping of user's mint allowance
    mapping(bytes32 => uint256) public mintAllowance;

    // Queue of minted addresses
    address[] private queue;

    /**
     * @notice Constructs the OpenCollection contract.
     */
    constructor() {}
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
     *
     *                                   ADMIN FUNCTIONS
     *
     */

    function airdrop(address[] calldata to, uint256[] calldata amount) external payable onlyOwner {
        uint256 toLength = to.length;
        require(toLength == amount.length, "Input Error");

        for (uint256 i; i < toLength;) {
            _mint(to[i], TOKENID_COMMON, amount[i], "");
            _recordToQueue(to[i], amount[i]);
            unchecked {
                ++i;
            }
        }
    }
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
        uint256[] memory winners1 = OpenCollectionLib._selectUniqueRandom(seed, queue.length, UNCOMMON_TOTAL_SUPPLY);
        uint256[] memory winners2 = OpenCollectionLib._selectUniqueRandom(seed + 1, queue.length, RARE_TOTAL_SUPPLY);

        // Iterate through the winners1 array
        for (uint256 i; i < winners1.length;) {
            // Get the address of the winner from the queue
            address winner = queue[winners1[i]];

            // Burn 1 OPEN token from the winner's balance
            _burn(winner, TOKENID_COMMON, 1);

            // Mint 1 TOKENID_B token for the winner
            _mint(winner, TOKENID_UNCOMMON, 1, "");

            // Safely increment the loop counterbatch
            unchecked {
                ++i;
            }
        }

        // Iterate through the winners2 array
        for (uint256 i; i < winners2.length;) {
            // Get the address of the winner from the queue
            address winner = queue[winners2[i]];

            while (balanceOf(winner, TOKENID_COMMON) == 0) winner = queue[winners2[i] + 1]; // already won

            // Burn 1 OPEN token from the winner's balance
            _burn(winner, TOKENID_COMMON, 1);

            // Mint 1 TOKENID_C token for the winner
            _mint(winner, TOKENID_RARE, 1, "");

            unchecked {
                ++i;
            }
        }

        // Emit the Reveal event with the seed used for random number generation
        emit Reveal(seed);
    }


    /**
     *
     *                                   INTERNAL FUNCTIONS
     *
     */


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
}