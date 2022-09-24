// SPDX-License-Identifier: MIT

/**
*   @title ERC-721A TL Merkle
*   @notice ERC-721A contract with owner and admin, merkle claim allowlist, public minting, and owner minting
*   @author transientlabs.xyz
*/

/*
   ___       _ __   __  ___  _ ______                 __ 
  / _ )__ __(_) /__/ / / _ \(_) _/ _/__ _______ ___  / /_
 / _  / // / / / _  / / // / / _/ _/ -_) __/ -_) _ \/ __/
/____/\_,_/_/_/\_,_/ /____/_/_//_/ \__/_/  \__/_//_/\__/                                                          
 ______                  _          __    __        __     
/_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/ 
*/

pragma solidity >0.8.9 <0.9.0;

import "ERC721ATLCore.sol";
import "ReentrancyGuard.sol";

contract ERC721ATLMerkle is ERC721ATLCore, ReentrancyGuard {

    bool public allowlistSaleOpen;
    bool public publicSaleOpen;
    uint256 public mintAllowance;
    uint256 public mintPrice;
    bytes32 public allowlistMerkleRoot;

    /**
    *   @param name is the name of the contract
    *   @param symbol is the symbol
    *   @param royaltyRecipient is the royalty recipient
    *   @param royaltyPercentage is the royalty percentage to set
    *   @param price is the mint price
    *   @param supply is the total token supply for minting
    *   @param merkleRoot is the allowlist merkle root
    *   @param admin is the admin address
    *   @param payout is the payout address
    */
    constructor (
        string memory name,
        string memory symbol,
        address royaltyRecipient,
        uint256 royaltyPercentage,
        uint256 price,
        uint256 supply,
        bytes32 merkleRoot,
        address admin,
        address payout
    )
        ERC721ATLCore(
            name,
            symbol,
            royaltyRecipient,
            royaltyPercentage,
            supply,
            admin,
            payout
        )
        ReentrancyGuard()
    {
        mintPrice = price;
        allowlistMerkleRoot = merkleRoot;
    }

    /**
    *   @notice function to set the allowlist mint status
    *   @param status is the true/false flag for the allowlist mint status
    */
    function setAllowlistSaleStatus(bool status) external virtual adminOrOwner {
        allowlistSaleOpen = status;
    }

    /**
    *   @notice function to set the public mint status
    *   @param status is the true/false flag for the allowlist mint status
    */
    function setPublicSaleStatus(bool status) external virtual adminOrOwner {
        publicSaleOpen = status;
    }

    /**
    *   @notice sets the mint allowance for each address
    *   @dev requires admin or owner
    *   @param allowance is the new allowance
    */
    function setMintAllowance(uint256 allowance) external virtual adminOrOwner {
        mintAllowance = allowance;
    }

    /**
    *   @notice function for batch minting to many addresses
    *   @dev requires owner or admin
    *   @dev using _mint... it is imperitive that receivers are vetted as being EOA or able to accept ERC721 tokens
    *   @dev airdrop not subject to mint allowance constraints
    *   @param addresses is an array of addresses to mint to
    */
    function airdrop(address[] calldata addresses) external virtual adminOrOwner {
        require(_totalMinted() + addresses.length <= maxSupply, "ERC721ATLMerkle: No token supply left");
        for (uint256 i; i < addresses.length; i++) {
            _mint(addresses[i], 1);
        }
    }

    /**
    *   @notice function for minting to the owner's address
    *   @dev requires owner or admin
    *   @dev not subject to per-wallet mint allowance constraints
    *   @dev owner() should be an address capable of receiving ERC721 tokens
    *   @param numToMint is the number to mint
    */
    function ownerMint(uint128 numToMint) external virtual adminOrOwner {
        require(_totalMinted() + numToMint <= maxSupply, "ERC721ATLMerkle: No token supply left");
        _mint(owner(), numToMint);
    }

    /**
    *   @notice function for users to mint
    *   @dev requires payment
    *   @param numToMint is the number to mint
    *   @param merkleProof is the hash for merkle proof verification
    */
    function mint(uint256 numToMint, bytes32[] calldata merkleProof) external virtual payable nonReentrant {
        require(_totalMinted() + numToMint <= maxSupply, "ERC721ATLMerkle: No token supply left");
        require(msg.value >= mintPrice * numToMint, "ERC721ATLMerkle: Not enough ether attached to the transaction");
        require(_numberMinted(msg.sender) + numToMint <= mintAllowance, "ERC721ATLMerkle: Mint allowance reached");
        if (allowlistSaleOpen) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, allowlistMerkleRoot, leaf), "ERC721ATLMerkle: Not on allowlist");
        }
        else if (!publicSaleOpen) {
            revert("ERC721ATLMerkle: Mint not open");
        }

        _safeMint(msg.sender, numToMint);
    }
}