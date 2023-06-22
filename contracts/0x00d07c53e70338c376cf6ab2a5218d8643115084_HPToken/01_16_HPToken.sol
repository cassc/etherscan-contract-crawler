// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.5.17;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Metadata.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

import "./Minter.sol";
import "./Utils.sol";

contract HPToken is Utils, ERC721Metadata, Ownable, Minter {
    string private _baseURI;
    uint256 private _totalSupply;
    bytes32 private _rootHash;

    constructor(
        string memory baseURI,
        address[] memory mintersWhitelist,
        bytes32 rootHash
    ) public Ownable() ERC721Metadata("Postereum 3", "PEV3") Minter() {
        _baseURI = baseURI;
        _rootHash = rootHash;

        addMinter(msg.sender);

        uint256 accountsCount = mintersWhitelist.length;
        for (uint256 i = 0; i < accountsCount; i++) {
            addMinter(mintersWhitelist[i]);
        }
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _baseURI = uri;
    }

    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);
        _totalSupply = _totalSupply.add(1);
    }

    /**
     * @dev Public function to set calculated root hash.
     * @param rootHash bytes32 Calculated root hash of merkle proof tree
     */
    function setRootHash(bytes32 rootHash) public onlyOwner {
        _rootHash = rootHash;
    }

    /**
     * @dev Public function to check merkleProof and reedem token to owner.
     * @param index uint256- Token index in sorted merkle tree
     * @param tokenId uint256 - Token id
     * @param merkleProof bytes32[] memory array of a storage proof
     */
    function redeem(
        uint256 index,
        uint256 tokenId,
        address owner,
        bytes32[] calldata merkleProof
    ) external returns (uint256) {
        bytes32 leaf = keccak256(abi.encodePacked(index, tokenId, owner));
        require(
            MerkleProof.verify(merkleProof, _rootHash, leaf),
            "Merkle proof verification failed"
        );

        _mint(owner, tokenId);

        return tokenId;
    }

    /**
     * @dev Public function to check minter signature and mint to claimer address
     * @param tokenIds uint256[] - List of tokenIds to claim
     * @param to address - Address of user claiming token
     * @param signature bytes memory signature provided by minter to authroize minting
     */
    function claim(
        uint256[] calldata tokenIds,
        address to,
        bytes calldata signature
    ) external {
        require(to != address(0), "Invalid address");
        bytes32 message = prefixed(keccak256(abi.encodePacked(tokenIds, to)));
        address minter = recoverSigner(message, signature);
        require(isMinter(minter), "Invalid signer");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenId > 0 && tokenId <= 1500, "Invalid tokenId");
            _mint(to, tokenId);
        }
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(_baseURI, "/stamp/", toString(tokenId)));
    }
}