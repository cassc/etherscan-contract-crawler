// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title Soulbound Certificates for Scalene Academy
/// @author Scalene
/// @dev https://docs.openzeppelin.com/contracts/4.x/erc1155
/// @dev https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable
/// @dev https://coinsbench.com/tutorial-building-an-erc1155-souldbound-token-e39e3d69ccf8
contract ScaleneAcademyCertificates is ERC1155, Ownable2Step {
    /// merkle roots for each token
    mapping(uint256 => bytes32) public whitelists;
    /// whether a user has already minted
    mapping(uint256 => mapping(address => bool)) internal hasMinted;
    /// One metadata URI per token
    mapping(uint256 => string) private uris;

    string private contractUri;

    /// Sets the contract deployer as the owner
    /// @dev The `uri_` ends up unused
    constructor(string memory uri_, string memory initialContractURI) ERC1155(uri_) Ownable2Step() {
        contractUri = initialContractURI;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setContractURI(string calldata newContractUri) public onlyOwner {
        contractUri = newContractUri;
    }

    /// @dev We use the optional `IERC1155MetadataURI` interface to store one URI per token: https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155MetadataURI-uri-uint256-
    function uri(uint256 id) public view override returns (string memory) {
        return uris[id];
    }

    function setUriForToken(uint256 id, string calldata newUri) external onlyOwner {
        require(bytes(uris[id]).length == 0, "ScaleneAcademyCertificates: Token URI can only be set once");
        emit URI(newUri, id);
        uris[id] = newUri;
    }

    /// @dev Update this before the token becomes available for minting, from cohort 2 onwards
    function setWhitelist(uint256 id, bytes32 whitelistMerkleRoot) external onlyOwner {
        whitelists[id] = whitelistMerkleRoot;
    }

    function isWhitelisted(uint256 id, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, whitelists[id], leaf);
    }

    /// @notice Mints one token `id` to the caller if they are whitelisted
    /// @dev Users will use this from cohort 2 and onwards
    function mintOneToSelf(uint256 id, bytes32[] calldata _merkleProof) external {
        require(isWhitelisted(id, _merkleProof), "ScaleneAcademyCertificates: can't mint, you must be whitelisted");
        require(hasMinted[id][msg.sender] == false, "ScaleneAcademyCertificates: can't mint, you've already minted");
        // mark as minted
        hasMinted[id][msg.sender] = true;

        _mint(msg.sender, id, 1, "");
    }

    /// @notice Mint one token `id` to each address in `to`
    /// @dev Owner should call this for Academy cohort 1. Once for each course
    function mintSingleTokenToManyAddresses(uint256 id, address[] calldata to) external onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id, 1, "");
        }
    }

    /// @notice Blocks any transfers from address to address
    function _beforeTokenTransfer(
        address,
        address from,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) internal pure override {
        require(
            // can only mint
            from == address(0),
            "ScaleneAcademyCertificates: The certificates are soulbound. They cannot be transferred - only minted"
        );
    }

    function renounceOwnership() public pure override {
        revert("ScaleneAcademyCertificates: renounceOwnership is disabled");
    }
}