// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * ░██████╗██╗░░██╗██╗░░░██╗██╗░░░░░██╗░░░██╗███╗░░░███╗
 * ██╔════╝██║░██╔╝╚██╗░██╔╝██║░░░░░██║░░░██║████╗░████║
 * ╚█████╗░█████═╝░░╚████╔╝░██║░░░░░██║░░░██║██╔████╔██║
 * ░╚═══██╗██╔═██╗░░░╚██╔╝░░██║░░░░░██║░░░██║██║╚██╔╝██║
 * ██████╔╝██║░╚██╗░░░██║░░░███████╗╚██████╔╝██║░╚═╝░██║
 * ╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝░╚═════╝░╚═╝░░░░░╚═╝
 * 
 * NFT contract for Skylum metaverse apartment ownership
 */
contract Skylum is ERC721, Ownable {

    using ECDSA for bytes32;

    // Total number of apartments
    uint public immutable APARTMENTS_TOTAL;

    // Hex-encoded SHA256 hash of the concatenated list of apartment unit IDs
    string public PROVENANCE_HASH;

    // Total number of minted tokens in all rounds
    uint private mintedTotal;

    // Number of unsold tokens remaining in the current sales round
    uint public roundRemainder;

    // Discount percentage (e.g. 10 = 10%)
    uint public discount;

    // Base URI of the token metadata
    string public baseUri;

    // Address that signs mint signatures
    address public signer;

    /**
     * @param apartmentsTotal Total number of apartments
     * @param provenanceHash Hex-encoded SHA256 hash of the concatenated list of apartment unit IDs
     */
    constructor(uint apartmentsTotal, string memory provenanceHash) ERC721("Skylum", "SKLM") {
        APARTMENTS_TOTAL = apartmentsTotal;
        PROVENANCE_HASH = provenanceHash;
    }

    /**
     * @dev Mint a token
     * @param tokenId Token ID
     * @param signature Mint signature
     *
     * Requirements:
     * - Mint signature must encode the contract's address, given token ID, current discount, total
     *   token price and the buyer address
     * - Mint signature must be signed by the current signer address
     * - Current sales round must have at least one apartment left
     * - See {Skylum-_mint}
     */
    function mint(uint tokenId, bytes memory signature) external payable {

        bytes32 hash = keccak256(abi.encodePacked(
            address(this),
            tokenId,
            discount,
            msg.value,
            msg.sender
        ));

        address recovered = hash.toEthSignedMessageHash().recover(signature);
        require(recovered == signer, "Invalid mint signature");

        require(roundRemainder > 0, "Sales round is closed");
        roundRemainder -= 1;

        _safeMint(msg.sender, tokenId);
    }

    /**
     * @dev Free token minting for the contract's owner
     * @param tokenId Token ID
     *
     * Requirements:
     * - The msg.sender must be the contract owner
     * - See {Skylum-_mint}
     */
    function ownerMint(uint tokenId) external onlyOwner {

        // Owner mints shouldn't count as sales in the current round, but if we're running out of
        // tokens, the round remainder may exceed the remaining supply and should be adjusted.
        if (roundRemainder > 0 && roundRemainder == remainingSupply()) {
            roundRemainder -= 1;
        }

        // Also reverts if the token is already minted or on invalid tokenId
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @dev See {ERC721-_mint}.
     *
     * Requirements:
     * - Token ID must be between 1 and APARTMENTS_TOTAL
     * - Token with the given ID must not be already minted
     */
    function _mint(address to, uint tokenId) internal override {
        require(tokenId > 0 && tokenId <= APARTMENTS_TOTAL, "Out of bounds tokenId");

        mintedTotal += 1;

        // Also reverts if the token is already minted
        super._mint(to, tokenId);
    }

    /**
     * @dev Starts a new sales round
     * @param roundSize Number of apartments that can be minted
     * @param discount_ Discount percentage for the round, e.g. 10 = 10%
     *
     * Requirements:
     * - Round size can't be bigger than the number of remaining apartments
     * - Discount percentage must be a number between 0 and 100
     */
    function startSalesRound(uint roundSize, uint discount_) external onlyOwner {
        require(roundSize <= remainingSupply(), "Not enough supply");
        require(discount_ <= 100, "Discount can't be bigger than 100%");

        roundRemainder = roundSize;
        discount = discount_;
    }

    /**
     * @dev Sets address that signs mint signatures
     * @param signer_ Signing address
     *
     * Note that the signatures signed with the old address won't be accepted after the change.
     */
    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    /**
     * @dev Sets base URI for the metadata
     * @param baseUri_ Base URI, where the token's ID could be appended at the end of it
     */
    function setBaseUri(string memory baseUri_) external onlyOwner {
        baseUri = baseUri_;
    }

    /**
     * @dev Sends contract's balance to the owner's wallet
     */
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Overwrites parent to provide actual base URI
     * @return Base URI of the token metadata
     */
    function _baseURI() override internal view returns (string memory) {
        return baseUri;
    }

    /**
     * @dev Checks if the given token exists (has been minted)
     * @param tokenId Token ID
     * @return True, if token is minted
     */
    function exists(uint tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Checks all possible token IDs if they exist (have been minted)
     * @return True if token exists, false otherwise, in a list ordered by token ID
     */
    function existsAll() external view returns (bool[] memory) {
        bool[] memory statuses = new bool[](APARTMENTS_TOTAL);
        for (uint i = 0; i < APARTMENTS_TOTAL; i++) {
            statuses[i] = _exists(i + 1);
        }
        return statuses;
    }

    /**
     * @dev Returns total number of minted tokens
     * @return Total number of minted tokens
     *
     * Note: Partially implements IERC721Enumerable
     */
    function totalSupply() external view returns (uint) {
        return mintedTotal;
    }

    /**
     * @dev Returns total number of remaining tokens
     * @return Total number of tokens that may still be minted
     */
    function remainingSupply() public view returns (uint) {
        return APARTMENTS_TOTAL - mintedTotal;
    }
}