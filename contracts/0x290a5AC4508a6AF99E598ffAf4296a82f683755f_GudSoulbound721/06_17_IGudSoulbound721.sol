// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

interface IGudSoulbound721 is IERC721MetadataUpgradeable {
    event MerkleMintUsed(MerkleMint merkleMint, uint248[] numMints);
    event TokenBurned(uint256 tokenId);
    event TiersSet(Tier[] tiers);
    event EtherWithdrawn(address payable to, uint256 amount);
    event MintMerkleRootSet(bytes32 mintMerkleRoot);

    /**
     * @dev describes a token tier
     *
     * @param publicPrice describes the publicly available minting price; a value of type(uint256).max means
     * public minting is unavailable for this tier
     * @param maxOwnable maximum tokens of this tier that can be owned by any one address
     * @param maxSupply maximum tokens of this tier than can be minted
     * @param uri URI for this tier
    */
    struct Tier {
        uint256 publicPrice;
        string cid;
        bool idInUri;
        uint248 maxSupply;
        uint248 maxOwnable;
    }

    /**
     * @dev describes a private mint offer for one recipient address; a leaf of the mintMerkle tree
     *
     * @param token recipient address
     * @param tierMaxMints number of times this offer can be used for each tier
     * @param tierPrices price of this offer for each tier
    */
    struct MerkleMint {
        address to;
        uint248[] tierMaxMints;
        uint256[] tierPrices;
    }

    function initialize(string memory name, string memory symbol, Tier[] memory tiers) external;

    /**
     * @dev public minting function
     *
     * @param to token recipient address
     * @param numMints number of tokens of each tier to mint
    */
    function mint(address to, uint248[] calldata numMints) external payable;

    /**
    * @dev private minting function
    *
    * @param numMints number of tokens of each tier to mint
    * @param merkleMint the relevant MerkleMint leaf of the mintMerkle tree
    * @param merkleProof Merkle proof for the leaf
    */
    function mint(
        uint248[] calldata numMints,
        MerkleMint calldata merkleMint,
        bytes32[] calldata merkleProof
    ) external payable;

    /**
     * @dev burns an NFT held by the sender
    */
    function burn(uint256 tokenId) external;

    /**
     * @dev tiers Sets all token tiers. A maximum of 256 tiers are allowed.
    */
    function setTiers(Tier[] calldata tiers) external /*onlyOwner*/;

    /**
     * @dev allows the contract owner to withdraw contract funds
     *
     * @param to Ether recipient
     * @param amount amount of Ether to withdraw
    */
    function withdrawEther(address payable to, uint256 amount) external /*onlyOwner*/;

    /**
     * @dev Sets the Merkle root of the tree describing all current private mint offers. Each leaf is the encoded hash
     * of a MerkleMint.
    */
    function setMintMerkleRoot(bytes32 mintMerkleRoot) external /*onlyOwner*/;

    /**
     * @return Tier description of each tier
    */
    function getTiers() external view returns (Tier[] memory);

    /**
    * @return number of tokens minted in `tier`
    */
    function numMinted(uint8 tier) external view returns (uint248);

    /**
    * @return number of tokens owned by `owner` in `tier`
    */
    function numOwned(address owner, uint8 tier) external view returns (uint248);
}