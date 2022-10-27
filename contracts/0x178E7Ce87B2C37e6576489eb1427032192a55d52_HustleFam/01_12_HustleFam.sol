// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// @title HustleFam NFT Minting Contract
// @author John Pioc (www.johnpioc.com)
// @notice This contract is intended to allow users to mint ERC-1155 standard NFTs for the HustleFam collection

error InsufficientFunds();
error SaleNotStarted();
error NotVerified();
error MintingTooMany();
error CannotBeCalledByContract();

contract HustleFam is ERC1155Supply, Ownable {

    // @dev All variables are constant / immutable meaning they cannot be changed after deployment
    uint256 constant public COLLECTION_SIZE = 247;
    uint256 constant public TOKEN_ID = 1;
    uint256 constant public MINT_AMOUNT = 1;
    uint256 constant public TIER_1_MINT_PRICE = 0.06 ether;
    uint256 constant public TIER_2_MINT_PRICE = 0.075 ether;
    address constant public COMMUNITY_WALLET = 0x7346D51F9B5Ac0647D63a2C16bde6c062E16deC9;

    bytes32 public tier1MerkleRoot;
    bytes32 public tier2MerkleRoot;
    bool public isSaleOpen;

    // @notice Mapping that determines if an address has minted or not
    // @param User address
    // @return True / False value if they have minted or not
    mapping(address => bool) public hasMinted;

    modifier callerIsUser() {
        if(tx.origin != msg.sender) revert CannotBeCalledByContract();
        _;
    }

    // @dev Place metadata base URI in ERC1155 constructor but leave "{id}.json" at the end. Make sure to leave a slash at the end of the URI.
    constructor(
        bytes32 _tier1MerkleRoot,
        bytes32 _tier2MerkleRoot
    ) ERC1155("ipfs://bafybeick63mz4po76lxxbwmrr2cjrf7sme2zq25flw4yyl2u6j35gil7ta/{id}.json") {
        isSaleOpen = false;
        tier1MerkleRoot = _tier1MerkleRoot;
        tier2MerkleRoot = _tier2MerkleRoot;
    }

    // @notice Mints an ERC-1155 NFT if user is verified
    // @param The merkle proof for a given address
    // @dev Generate merkle proof through merkle trees
    function mint(bytes32[] memory _merkleProof) public payable callerIsUser {
        if (totalSupply(TOKEN_ID) + MINT_AMOUNT > COLLECTION_SIZE) revert MintingTooMany();
        if (!isSaleOpen) revert SaleNotStarted();
        if (hasMinted[msg.sender]) revert MintingTooMany();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, tier1MerkleRoot, leaf)) {
            if (msg.value < TIER_1_MINT_PRICE) revert InsufficientFunds();
        } else if (MerkleProof.verify(_merkleProof, tier2MerkleRoot, leaf)) {
            if (msg.value < TIER_2_MINT_PRICE) revert InsufficientFunds();
        } else revert NotVerified();

        hasMinted[msg.sender] = true;
        _mint(msg.sender, TOKEN_ID, MINT_AMOUNT, "");
    }

    // @notice Mints all remaining NFTs to community wallet
    // @dev Call after tier 2 mint sale
    function communityMint() public onlyOwner {
        if (totalSupply(TOKEN_ID) == COLLECTION_SIZE) revert MintingTooMany();

        uint256 mintAmount = COLLECTION_SIZE - totalSupply(TOKEN_ID);
        _mint(COMMUNITY_WALLET, TOKEN_ID, mintAmount, "");
    }

    // @notice Sets the Merkle Root for the Tier 1 Addresses
    // @param Merkle Root for tier 1 addresses
    function setTier1MerkleRoot(bytes32 _tier1MerkleRoot) public onlyOwner {
        tier1MerkleRoot = _tier1MerkleRoot;
    }

    // @notice Sets the Merkle Root for the Tier 2 Addresses
    // @param Merkle Root for tier 2 addresses
    function setTier2MerkleRoot(bytes32 _tier2MerkleRoot) public onlyOwner {
        tier2MerkleRoot = _tier2MerkleRoot;
    }

    // @notice Toggles the Sale State Boolean Value
    // @dev Starts at false
    function toggleSaleState() public onlyOwner {
        isSaleOpen = !isSaleOpen;
    }

    // @notice Withdraws all ETH from contract
    function withdraw() public payable onlyOwner {
        (bool os,) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}