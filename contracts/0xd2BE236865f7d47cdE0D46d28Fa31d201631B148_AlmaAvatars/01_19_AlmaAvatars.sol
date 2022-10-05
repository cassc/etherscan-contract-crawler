// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {MerkleDistributor} from "./MerkleDistributor.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract AlmaAvatars is
    Initializable,
    UUPSUpgradeable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    MerkleDistributor
{
    using MerkleProofUpgradeable for bytes32[];
    using AddressUpgradeable for address payable;

    // IPFS base URI used to locate the NFT-JSON Metadata for each address 
    // in the merkel tree
    string public baseURI;

    // DAO costs to create the NFT Art + contract gas
    // this value is required for minting the NFT
    uint256 internal constant MINT_COST = 0.0375 ether;

    function initialize(
        string memory _name,
        string memory _symbol,
        bytes32 _root
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __MerkleDistributor_init(_root);
    }

    function setBaseURI(string memory baseURI_) external virtual onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function exists(uint256 _tokenId) external view virtual returns (bool) {
        return _exists(_tokenId);
    }

    function mint(bytes32[] calldata _proof, uint256 _tokenId)
        external
        payable
        virtual
    {
        require(
            msg.value == MINT_COST,
            "AlmaAvatars: Insufucient funds sent to mint"
        );
        require(!_exists(_tokenId), "AlmaAvatars: nft already minted");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _tokenId));
        require(_proof.verify(root, leaf), "AlmaAvatars: invalid merkle proof");

        _mint(msg.sender, _tokenId);
    }

    function withdraw() external virtual {
        uint256 balance = address(this).balance;
        payable(owner()).sendValue(balance);
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}

    /// @dev UUPSUpgradeable storage gap
    uint256[49] private __gap;
}