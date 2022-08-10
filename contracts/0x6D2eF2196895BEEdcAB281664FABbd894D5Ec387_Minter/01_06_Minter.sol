// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IOwnable.sol";

contract Minter is Ownable {

    // sale details
    address public tokenAddress;
    uint256 public nextTokenId = 1999;
    uint256 public maxHolderAllocation = 5;
    uint256 public maxWhitelistAllocation = 20;

    /// @notice minter address => # already minted for MintPhase.HoldersOnly
    mapping(address => uint256) public hasMintedHolderAllocation;
    /// @notice minter address => # already minted for MintPhase.WhitelistOnly
    mapping(address => uint256) public hasMintedWhitelistAllocation;

    /// @notice merkle root of valid holder addresses and quantities allowed
    bytes32 public holderMerkleRoot;
    /// @dev this is a superset of holderMerkleRoot
    bytes32 public whitelistMerkleRoot;

    enum MintPhase { Paused, HoldersOnly, WhitelistOnly, Open }
    MintPhase public mintPhase;

    /// @notice mint on the main token contract
    /// @param merkleProof the merkle proof for the minter's address
    /// @param quantity number of mints desired
    function proxyMint(
        bytes32[] calldata merkleProof,
        uint256 quantity
    ) external payable {
        //===================== CHECKS =======================
        IToken tokenContract = IToken(tokenAddress);
        
        // PRIMARY CHECKS

        // check mint is not paused
        if (mintPhase == MintPhase.Paused) {
            revert("Minting paused");
        }

        // check we won't exceed max tokens allowed
        uint256 maxTokens = tokenContract.maxTokens();
        require(nextTokenId + quantity <= maxTokens, "Exceeds max supply");
        
        // check enough ether is sent
        uint256 price = tokenContract.price();
        require(msg.value >= price * quantity, "Not enough ether");
        
        // block contracts
        require(msg.sender == tx.origin, "No contract mints");

        // `HoldersOnly` PHASE CHECKS
        if (mintPhase == MintPhase.HoldersOnly) {
            // check merkle proof against holder root
            require(checkMerkleProof(merkleProof, msg.sender, holderMerkleRoot), "Invalid holder proof");

            // make sure user won't have already minted max HolderOnly amount
            require(hasMintedHolderAllocation[msg.sender] + quantity <= maxHolderAllocation, "Exceeds holder allocation");
            
            // EFFECT. log the amount this user has minted for holder allocation
            hasMintedHolderAllocation[msg.sender] = hasMintedHolderAllocation[msg.sender] + quantity;
        }

        // `WhitelistOnly` PHASE CHECKS
        if (mintPhase == MintPhase.WhitelistOnly) {
            // check merkle proof against whitelist root
            require(checkMerkleProof(merkleProof, msg.sender, whitelistMerkleRoot), "Invalid whitelist proof");

            // make sure user won't have already minted maxWhitelistAllocation amount
            require(hasMintedWhitelistAllocation[msg.sender] + quantity <= maxWhitelistAllocation, "Exceeds whitelist allocation");

            // EFFECT. log the amount this user has minted for whitelist allocation
            hasMintedWhitelistAllocation[msg.sender] = hasMintedWhitelistAllocation[msg.sender] + quantity;
        }

        // `Open` PHASE CHECKS
        if (mintPhase == MintPhase.Open) {
            // check maxMintsPerTx from token contract. note that in all other phases,
            // we have phase-specific limits and thus don't need to check this.
            uint256 maxMintsPerTx = tokenContract.maxMintsPerTx();
            require(quantity <= maxMintsPerTx, "Too many mints per txn");
        }

        //=================== EFFECTS =========================

        // forward funds to token contract
        (bool success, ) = tokenAddress.call{value: msg.value }("");
        require(success, "Payment forwarding failed");

        // increase our local tokenId. we only need to do this bc we made the 
        // tokenId on the main token contract private.
        nextTokenId += quantity;

        //=================== INTERACTIONS =======================
        tokenContract.mintAdmin(quantity, msg.sender);

    }

    /// @notice check whether the merkleProof is valid for a given address and root
    function checkMerkleProof(
        bytes32[] calldata merkleProof,
        address _address,
        bytes32 _root
    ) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(merkleProof, _root, leaf);
    }

    /// @notice let owner set main token address
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }

    /// @notice let owner set the holder merkle root
    function setHolderMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        holderMerkleRoot = _merkleRoot;
    }

    /// @notice let owner set the whitelist merkle root
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    /// @notice Sets mint phase, takes uint that refers to MintPhase enum (0 indexed).
    function setMintPhase(MintPhase phase) external onlyOwner {
        mintPhase = phase;
    }

    /// @notice set max holder allocation amount
    function setMaxHolderAllocation(uint256 amount) external onlyOwner {
        maxHolderAllocation = amount;
    }

    /// @notice set max whitelist allocation amount
    function setMaxWhitelistAllocation(uint256 amount) external onlyOwner {
        maxWhitelistAllocation = amount;
    }

    /// @notice change the next token id (to match token contract)
    function setNextTokenId(uint256 id) external onlyOwner {
        nextTokenId = id;
    }

}