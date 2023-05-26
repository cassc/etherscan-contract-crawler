// SPDX-License-Identifier: MIT

/// @title FastFoodPunks

pragma solidity ^0.8.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IProxyRegistry } from "./IProxyRegistry.sol";
import { IOpenseaStorefront } from "./IOpenseaStorefront.sol";

contract FastFoodPunks is ERC721Enumerable, Ownable {
    bool public mintingEnabled = false; // For toggling minting
    bool public metadataLocked = false; // Allows metadata locking in the future whithout renouncing ownership
    string private _contractURI = "";
    string private _baseTokenURI = "ipfs://QmWnvYVwywhKKNQQZBygaPQAXhNBTP2DrnKsooQS5DxvCm/";
    bytes32 public merkleRoot = 0x400a459a7fcfdf9fedf446b47d97197ed1bd0dafa4e129201383c92118e87bd1;
    uint256 constant public MAX_SUPPLY = 1000;

    mapping(uint256 => uint256) public ssn; // Social Security Numbers

    // Opensea
    IProxyRegistry public immutable proxyRegistry;
    address private constant BURN_ADDRESS =
        address(0x000000000000000000000000000000000000dEaD);
    IOpenseaStorefront public immutable openseaSf;

    event Migrated(uint256 tokenId, uint256 ssn);

    constructor(IProxyRegistry _proxyRegistry, address _openseaStoreFront)
        ERC721("FastFoodPunks", "FFP")
    {
        proxyRegistry = _proxyRegistry;
        openseaSf = IOpenseaStorefront(_openseaStoreFront);
    }

    /// @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721)
        returns (bool)
    {
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /// @notice Mint a token with an id to sender and store random seed
    function mint(uint256 id) internal {
        // Store random seed for future attributes or extensions.
        ssn[id] = uint256(
            keccak256(
                abi.encodePacked(
                    id,
                    block.timestamp, // solhint-disable-line not-rely-on-time
                    block.number - 1,
                    block.difficulty
                )
            )
        );
        _mint(msg.sender, id);
    }

    /// @notice Performs NFT migration from Opensea to this contract performing a mint and burn
    function migrateFromOpensea(uint256 osId, uint256 newId, bytes32 leaf, bytes32[] memory proof) external {
        require(mintingEnabled, "Minting is not enabled yet");

        uint256 currentSupply = totalSupply();
        require(currentSupply < MAX_SUPPLY, "All tokens have been minted");

        require(keccak256(abi.encodePacked(osId, newId)) == leaf, "Malformed leaf");
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle proof or leaf");

        require(
            openseaSf.balanceOf(msg.sender, osId),
            "Only token owner can migrate"
        );

        // Mint the new token
        mint(newId);

        // Burn the old token from Opensea contract
        openseaSf.safeTransferFrom(msg.sender, BURN_ADDRESS, osId, 1, "");

        emit Migrated(newId, ssn[newId]);
    }

    /// @notice Resurrects punk 154 which was lost
    function resurrectPunk154() external onlyOwner {
        mint(154);
        emit Migrated(154, ssn[154]);
    }

    /// @notice Locks metadata forever
    function lockMetadata() external onlyOwner {
        metadataLocked = true;
    }

    /// @notice Toggles minting enabled state
    function flipMintingState() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    /// @notice Sets metadata Base URI
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        require(!metadataLocked, "Metadata is locked");
        _baseTokenURI = newBaseURI;
    }
    
    /// @notice Returns metadata Base URI
    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Overrides _baseURI internal getter
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Sets contract metadata URI
    function setContractURI(string memory newContractURI) external onlyOwner {
        require(!metadataLocked, "Metadata is locked");
        _contractURI = newContractURI;
    }

    /// @notice Returns contract metadata URI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }


    /// @notice Sets the Merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}