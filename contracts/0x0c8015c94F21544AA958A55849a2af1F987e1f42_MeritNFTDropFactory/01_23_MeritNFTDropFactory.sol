// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interfaces/IMeritMintableNFT.sol";
import "./MeritNFT.sol";

error MerkleSetterError();

contract MeritNFTDropFactory {

    error MerkleProofError();

    struct MerkleTree {
        bytes32 root;
        string ipfsHash; //to be able to fetch the merkle tree without relying on a centralized UI
    }

    mapping(address => address) public NFTMerkleSetter;
    mapping(address => MerkleTree) public NFTMerkleTree;
    IMeritMintableNFT[] public NFTs;
    
    modifier onlyMerkleSetter(address _NFT) {
        if(NFTMerkleSetter[_NFT] != msg.sender) {
            revert MerkleSetterError();
        }
        _;
    }

    event NFTDeployed(address indexed NFT, address indexed deployer, bool indexed isImmutable);
    event MerkleTreeUpdated(address indexed NFT, bytes32 indexed root, string ipfsHash);
    event MerkleSetterUpdated(address indexed NFT, address indexed newSetter);
    event NFTClaimed(address indexed NFT, uint256 indexed tokenId, address indexed receiver);

    /// @notice deploys an NFT contract
    /// @param _name Name of the NFT
    /// @param _symbol Symbol aka ticker
    /// @param _baseTokenURI Prepends the tokenId for the tokenURI
    /// @param _merkleRoot root of the merkle drop tree
    /// @param _merkleIpfsHash IPFS hash of all leafs in the merkle tree
    function deployNFT(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        bytes32 _merkleRoot,
        string memory _merkleIpfsHash,
        bool _immutable
    ) external returns(address) {
        // TODO consider using a transparant proxy to bring down gas cost
        MeritNFT NFT = new MeritNFT(
            _name,
            _symbol,
            _baseTokenURI
        );
        
        NFT.grantRole(NFT.MINTER_ROLE(), address(this));
        NFTMerkleTree[address(NFT)] = MerkleTree({
            root: _merkleRoot,
            ipfsHash: _merkleIpfsHash
        });

        // If non immutable, set the NFT admin and allow the merkle root to be updated
        if(!_immutable) {
            NFT.grantRole(NFT.DEFAULT_ADMIN_ROLE(), msg.sender);
            NFTMerkleSetter[address(NFT)] = msg.sender;
        }

        emit NFTDeployed(address(NFT), msg.sender, _immutable);

        return address(NFT);
    }

    /// @notice Updates the NFT drop merkle tree. Can only be called by the merkle setter
    /// @param _NFT address of the NFT contract
    /// @param _merkleRoot new merkleRoot
    /// @param _merkleIpfsHash IPFS hash of all leafs in the merkle tree
    function updateNFTMerkleTree(
        address _NFT,
        bytes32 _merkleRoot,
        string memory _merkleIpfsHash
    ) onlyMerkleSetter(_NFT) external {
        NFTMerkleTree[_NFT] = MerkleTree({
            root: _merkleRoot,
            ipfsHash: _merkleIpfsHash
        });

        emit MerkleTreeUpdated(_NFT, _merkleRoot, _merkleIpfsHash);
    }

    /// @notice Update the Merkle setter. Can only be called by the current setter
    /// @param _NFT address of the nft contract
    /// @param _merkleSetter address of the new merkleSetter
    function setMerkleSetter(address _NFT, address _merkleSetter) onlyMerkleSetter(_NFT) external {
        NFTMerkleSetter[_NFT] = _merkleSetter;
        emit MerkleSetterUpdated(_NFT, _merkleSetter);
    }

    /// @notice Claim an nft using the merkleProof
    /// @param _NFT address of the nft contract
    /// @param _tokenId ID of the token to claim
    /// @param _receiver Receiver of the NFT
    /// @param _proof merkle proof
    function claim(address _NFT, uint256 _tokenId, uint256 _size, address _receiver, bytes32[] calldata _proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(_tokenId, _receiver));
        
        if(!MerkleProof.verify(_proof, NFTMerkleTree[_NFT].root, leaf)) {
            revert MerkleProofError();
        }

        // Mint NFT
        MeritNFT NFT = MeritNFT(_NFT);

        // relies on nft contract enforcing the same NFT cannot be minted twice
        NFT.mint(_tokenId, _receiver, _size);

        emit NFTClaimed(_NFT, _tokenId, _receiver);
    }

}