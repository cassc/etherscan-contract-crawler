// SPDX-License-Identifier: MIT

/**
*   @title ERC-721 TL merkle
*   @notice ERC-721 contract with owner and admin, merkle claim allowlist, public minting, airdrop, and owner minting
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

pragma solidity 0.8.14;

import "ERC721TLCore.sol";
import "ReentrancyGuard.sol";

contract ERC721TLMerkle is ERC721TLCore, ReentrancyGuard {

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
    *   @param supply is the total token supply
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
        ERC721TLCore(
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
    *   @notice function to open the allowlist sale
    */
    function openAllowlistSale() external virtual adminOrOwner {
        allowlistSaleOpen = true;
        publicSaleOpen = false;
    }

    /**
    *   @notice function to open the public sale
    */
    function openPublicSale() external virtual adminOrOwner {
        allowlistSaleOpen = false;
        publicSaleOpen = true;
    }

    /**
    *   @notice function to close both sales
    */
    function closeSales() external virtual adminOrOwner {
        allowlistSaleOpen = false;
        publicSaleOpen = false;
    }

    /**
    *   @notice sets the mint allowance for each address
    *   @dev requires admin or owner
    *   @param allowance is the new allowance
    */
    function setMintAllowance(uint16 allowance) external virtual adminOrOwner {
        mintAllowance = allowance;
    }

    /**
    *   @notice function to set the merkle root
    *   @dev requires admin or owner
    *   @param newRoot is the new merkle root
    */
    function setAllowlistMerkleRoot(bytes32 newRoot) external adminOrOwner {
        allowlistMerkleRoot = newRoot;
    }

    /**
    *   @notice function to set the mint price
    *   @dev requires admin or owner
    *   @param newPrice is the new mint price
    */
    function setMintPrice(uint256 newPrice) external adminOrOwner {
        mintPrice = newPrice;
    }

    /**
    *   @notice function for batch minting to many addresses
    *   @dev requires owner or admin
    *   @dev using _mint... it is imperitive that receivers are vetted as being EOA or able to accept ERC721 tokens
    *   @dev airdrop not subject to mint allowance constraints
    *   @param addresses is an array of addresses to mint to
    */
    function airdrop(address[] calldata addresses) external virtual adminOrOwner {
        require(_counter + addresses.length <= maxSupply, "ERC721TLMerkle: No token supply left");

        for (uint256 i; i < addresses.length; i++) {
            _counter++;
            _mint(addresses[i], _counter);
        }
    }

    /**
    *   @notice function for minting to the owner's address
    *   @dev requires owner or admin
    *   @dev not subject to mint allowance constraints
    *   @dev using _mint as owner() should be an EOA or at least knowlegeable if they can receive ERC721 tokens
    *   @param numToMint is the number to mint
    */
    function ownerMint(uint128 numToMint) external virtual adminOrOwner {
        require(_counter + numToMint <= maxSupply, "ERC721TLMerkle: No token supply left");
        for (uint256 i; i < numToMint; i++) {
            _counter++;
            _mint(owner(), _counter);
        }
    }

    /**
    *   @notice function for users to mint
    *   @dev requires payment
    *   @dev only mint one at a time. If looking to mint more than one at a time, utilize ERC721TLMultiMint
    *   @dev using _mint as restricting all function calls to EOAs
    *   @param merkleProof is the hash for merkle proof verification
    */
    function mint(bytes32[] calldata merkleProof) external virtual payable nonReentrant {
        require(_counter < maxSupply, "ERC721TLMerkle: No token supply left");
        require(msg.value >= mintPrice, "ERC721TLMerkle: Not enough ether attached to the transaction");
        require(_numMinted[msg.sender] < mintAllowance, "ERC721TLMerkle: Mint allowance reached");
        if (allowlistSaleOpen) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, allowlistMerkleRoot, leaf), "ERC721TLMerkle: Not on allowlist");
        }
        else if (!publicSaleOpen) {
            revert("ERC721TLMerkle: Mint not open");
        }

        _numMinted[msg.sender]++;
        _counter++;
        _safeMint(msg.sender, _counter);
    }

}