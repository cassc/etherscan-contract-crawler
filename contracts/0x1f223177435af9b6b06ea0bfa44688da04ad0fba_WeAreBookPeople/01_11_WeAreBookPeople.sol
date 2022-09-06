// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {MultiOwnable} from "./MultiOwnable.sol";

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract WeAreBookPeople is ERC721, ERC2981, MultiOwnable {
    bytes32 public merkleRoot = ""; // Construct this from (address, amount) tuple elements
    mapping(address => uint) public whitelistRemaining; // Maps user address to their remaining mints if they have minted some but not all of their allocation
    mapping(address => bool) public whitelistUsed; // Maps user address to bool, true if user has minted

    uint public totalSupply = 0;
    string public baseTokenURI;

    event Mint(address indexed owner, uint indexed tokenId);

    constructor() ERC721("We Are Book People", "WABP") {}

    /// @notice Mint to the owner
    function ownerMint(uint amount) external onlyMintingOwner {
        _mintWithoutValidation(msg.sender, amount);
    }

    /// @notice Mint from whitelist allocation
    function whitelistMint(uint amount, uint totalAllocation, bytes32 leaf, bytes32[] memory proof) external {
        // Create storage element tracking user mints if this is the first mint for them
        if (!whitelistUsed[msg.sender]) {        
            // Verify that (msg.sender, amount) correspond to Merkle leaf
            require(keccak256(abi.encodePacked(msg.sender, totalAllocation)) == leaf, "Sender and amount don't match Merkle leaf");

            // Verify that (leaf, proof) matches the Merkle root
            require(verify(merkleRoot, leaf, proof), "Not a valid leaf in the Merkle tree");

            whitelistUsed[msg.sender] = true;
            whitelistRemaining[msg.sender] = totalAllocation;
        }

        // Require nonzero amount
        require(amount > 0, "Can't mint zero");

        require(whitelistRemaining[msg.sender] >= amount, "Can't mint more than remaining allocation");

        whitelistRemaining[msg.sender] -= amount;
        _mintWithoutValidation(msg.sender, amount);
    }

    /// @notice Perform raw minting
    function _mintWithoutValidation(address to, uint amount) internal {
        for (uint i = 0; i < amount; i++) {
            _mint(to, totalSupply);
            emit Mint(to, totalSupply);
            totalSupply += 1;
        }
    }

    /// @notice Ensure the proof and leaf match the merkle root
    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    // ADMIN FUNCTIONALITY

    /// @notice Set metadata
    function setBaseTokenURI(string memory _baseTokenURI) public onlyMetadataOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Set merkle root
    function setMerkleRoot(bytes32 _merkleRoot) public onlyMintingOwner {
        merkleRoot = _merkleRoot;
    }

    // ROYALTY FUNCTIONALITY

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public pure override(ERC721, ERC2981) returns (bool) {
        return
            interfaceId == 0x2a55205a || // ERC165 Interface ID for ERC2981
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /// @dev See {ERC2981-_setDefaultRoyalty}.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRoyaltyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @dev See {ERC2981-_deleteDefaultRoyalty}.
    function deleteDefaultRoyalty() external onlyRoyaltyOwner {
        _deleteDefaultRoyalty();
    }

    /// @dev See {ERC2981-_setTokenRoyalty}.
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyRoyaltyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @dev See {ERC2981-_resetTokenRoyalty}.
    function resetTokenRoyalty(uint256 tokenId) external onlyRoyaltyOwner{
        _resetTokenRoyalty(tokenId);
    }

    // METADATA FUNCTIONALITY

    /// @notice Returns the metadata URI for a given token
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }
}