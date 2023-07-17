// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// @title Mysterium NFT Minting Contract
// @notice This contract is intended to allow users to mint ERC-1155 standard NFTs for the Mysterium Collection

error InsufficientFunds();
error MintingTooMany();
error SaleNotStarted();
error NotVerified();
error CannotBeCalledByContract();

contract Mysterium is ERC1155, Ownable {

    enum MintState {
        CLOSED,
        ALLOWLIST,
        PUBLIC
    }

    // @dev All variables are constant / immutable meaning they cannot be changed after deployment
    uint256 public constant MAX_COLLECTION_SIZE = 10000;
    uint256 public constant MAX_MINT_AMOUNT = 10;
    uint256 public constant MINT_PRICE = 0.00666 ether;
    bytes32 public allowlistMerkleRoot;

    uint256 public tokenCounter;
    MintState public mintState;

    // @notice mapping that gives a number of how many NFTs an address has minted previously
    // @param User address
    // @return Uint256 number of how many NFTs they've minted
    mapping (address => uint256) public nftsMinted;

    modifier callerIsUser() {
        if(tx.origin != msg.sender) revert CannotBeCalledByContract();
        _;
    }

    // @notice Also mints the owner 10 NFTs
    // @param Allowlist Merkle Root
    // @dev Place metadata base URI in ERC1155 constructor but leave "{id}.json" at the end. Make sure to leave a slash at the end of the URI.
    constructor(
        bytes32 _allowlistMerkleRoot
    ) ERC1155 ("ipfs://bafybeiad2rooqbuvj7cyey4kwmaoxligxugqootcosn532qnzmjqcyn5ni/{id}.json") {
        tokenCounter = 0;
        mintState = MintState.CLOSED;
        allowlistMerkleRoot = _allowlistMerkleRoot;

        for (uint256 i = 0; i < 10; i++) {
            tokenCounter += 1;
            uint256 tokenId = tokenCounter % 10 + 1;
            _mint(msg.sender, tokenId, 1, "");
        }
    }

    // @notice Allows allowlisted addresses to mint up to 10 NFTs
    // @param Merkle proof, Mint Amount
    function allowlistMint(bytes32[] memory _merkleProof, uint256 _mintAmount) public payable callerIsUser {
        if (tokenCounter + _mintAmount > MAX_COLLECTION_SIZE) revert MintingTooMany();
        if (msg.value < _mintAmount * MINT_PRICE) revert InsufficientFunds();
        if (nftsMinted[msg.sender] + _mintAmount > MAX_MINT_AMOUNT) revert MintingTooMany();
        if (mintState != MintState.ALLOWLIST) revert SaleNotStarted();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if(!(MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf))) revert NotVerified();

        nftsMinted[msg.sender] += _mintAmount;
        for (uint256 i = 0; i < _mintAmount; i++) {
            tokenCounter += 1;
            uint256 tokenId = tokenCounter % 10 + 1;
            _mint(msg.sender, tokenId, 1, "");
        }
    }

    // @notice Allows any user to mint up to 10 NFTs. Requires mintState variable to be 2
    // @param Mint Amount
    function publicMint(uint256 _mintAmount) public payable callerIsUser {
        if (tokenCounter + _mintAmount > MAX_COLLECTION_SIZE) revert MintingTooMany();
        if (msg.value < _mintAmount * MINT_PRICE) revert InsufficientFunds();
        if (nftsMinted[msg.sender] + _mintAmount > MAX_MINT_AMOUNT) revert MintingTooMany();
        if (mintState != MintState.PUBLIC) revert SaleNotStarted();

        nftsMinted[msg.sender] += _mintAmount;
        for (uint256 i = 0; i < _mintAmount; i++) {
            tokenCounter += 1;
            uint256 tokenId = tokenCounter % 10 + 1;
            _mint(msg.sender, tokenId, 1, "");
        }
    }

    // @notice allows user to change merkle root
    // @param New Merkle Root
    function changeMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        allowlistMerkleRoot = _newMerkleRoot;
    }

    // @notice Changes the mint state
    // @dev 0 = Closed, 1 = Allowlist, 2 = Public
    function setMintState(uint256 _mintState) public onlyOwner {
        mintState = MintState(_mintState);
    }

    // @notice Withdraws all ETH from contract
    function withdraw() public payable onlyOwner {
        (bool os,) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}