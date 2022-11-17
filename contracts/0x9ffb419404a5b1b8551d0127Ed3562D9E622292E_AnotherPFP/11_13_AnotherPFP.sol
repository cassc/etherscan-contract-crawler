// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

error Locked();

error NotAllowed();

error AlreadyMinted();

contract AnotherPFP is ERC721A, Ownable {
    // base Token URI
    string public baseTokenUri;

    // merkle root per season
    mapping(uint256 => bytes32) public merkleRootPerSeason;

    // address minted per season
    mapping(uint256 => mapping(address => bool)) public addressMintedPerSeason;

    // current drop season
    uint256 public currentSeason = 0;

    bool public locked = false;

    /**
     * @notice
     *  AnotherPFP contract constructor
     *
     * @param _merkleRoot : Merkle root for verifying allowlist
     * @param _baseTokenUri : base token URI
     * @param _treasureQuantity : Amount of initial nfts minted to treasury
     * @param _name : name of the NFT contract
     * @param _symbol : symbol / ticker of the NFT contract
     **/
    constructor(
        bytes32 _merkleRoot,
        string memory _baseTokenUri,
        uint256 _treasureQuantity,
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {
        baseTokenUri = _baseTokenUri;
        merkleRootPerSeason[0] = _merkleRoot;

        _mint(msg.sender, _treasureQuantity);
    }

    /**
     * @notice
     *  Update the merkle root (for allowlist)
     *  Only the contract owner can perform this operation
     *
     * @param _merkleRoot : the new merkle root to be set
     */
    function setMerkleRoot(bytes32 _merkleRoot, uint256 season)
        external
        onlyOwner
    {
        merkleRootPerSeason[season] = _merkleRoot;
    }

    function lock() external onlyOwner {
        locked = true;
    }

    function setSeason(uint256 season) external onlyOwner {
        currentSeason = season;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenUri;
    }

    function setBaseURI(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    /**
     * @notice
     *  Lets an allowlisted user mint another pfp
     *
     * @param _to : address to mint to
     * @param _quantity : quantity of nfts to mint
     * @param _proof : merkle tree proof used to verify allowlisted user
     */

    function mint(
        address _to,
        uint256 _quantity,
        bytes32[] memory _proof
    ) public {
        if (locked) {
            revert Locked();
        }

        if (addressMintedPerSeason[currentSeason][_to]) {
            revert AlreadyMinted();
        }

        bool isAllowlisted = MerkleProof.verify(
            _proof,
            merkleRootPerSeason[currentSeason],
            keccak256(abi.encodePacked(_to, _quantity))
        );

        if (!isAllowlisted) {
            revert NotAllowed();
        }

        addressMintedPerSeason[currentSeason][_to] = true;
        _mint(_to, _quantity);
    }
}