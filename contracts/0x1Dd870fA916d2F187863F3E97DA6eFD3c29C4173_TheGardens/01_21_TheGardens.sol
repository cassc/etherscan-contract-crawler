// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "./ERC721AOS.sol";

// StakedNFTMetadata Interface:
// This interface defines a blueprint for the NFT Stake contract. Its purpose is to enable the creation of
// the minting contract independently from the stake contract, allowing developers to work on the stake
// contract's logic without deploying it simultaneously.
//
// The stake contract must implement this interface for proper integration with the minting contract,
// which works with newly staked NFTs. The getMetadata method is called by the minting contract's tokenURI
// method after stakeSupplyStart varible is reached (10k) tokens have been minted.
//
// By following this interface, the stake contract is responsible for managing the metadata for staked NFTs,
// ensuring that the stake contract is in control of the metadata and its associated logic.

interface StakedNFTMetadata {
    function getMetadata(uint256 tokenId) external view returns (string memory);
}



// ,---------. .---.  .---.     .-''-.            .-_'''-.      ____    .-------.     ______         .-''-.  ,---.   .--.   .-'''-.  
// \          \|   |  |_ _|   .'_ _   \          '_( )_   \   .'  __ `. |  _ _   \   |    _ `''.   .'_ _   \ |    \  |  |  / _     \ 
//  `--.  ,---'|   |  ( ' )  / ( ` )   '        |(_ o _)|  ' /   '  \  \| ( ' )  |   | _ | ) _  \ / ( ` )   '|  ,  \ |  | (`' )/`--' 
//     |   \   |   '-(_{;}_). (_ o _)  |        . (_,_)/___| |___|  /  ||(_ o _) /   |( ''_'  ) |. (_ o _)  ||  |\_ \|  |(_ o _).    
//     :_ _:   |      (_,_) |  (_,_)___|        |  |  .-----.   _.-`   || (_,_).' __ | . (_) `. ||  (_,_)___||  _( )_\  | (_,_). '.  
//     (_I_)   | _ _--.   | '  \   .---.        '  \  '-   .'.'   _    ||  |\ \  |  ||(_    ._) ''  \   .---.| (_ o _)  |.---.  \  : 
//    (_(=)_)  |( ' ) |   |  \  `-'    /         \  `-'`   | |  _( )_  ||  | \ `'   /|  (_.\.' /  \  `-'    /|  (_,_)\  |\    `-'  | 
//     (_I_)   (_{;}_)|   |   \       /           \        / \ (_ o _) /|  |  \    / |       .'    \       / |  |    |  | \       /  
//     '---'   '(_,_) '---'    `'-..-'             `'-...-'   '.(_,_).' ''-'   `'-'  '-----'`       `'-..-'  '--'    '--'  `-...-' 
//
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░░░▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░▒▒▒░░░░░▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▓▓▓▓▓░░░░░░▒▒▒░░░░░░▒▒▒▒▒▒░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒░░░░░▒▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░▒▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░
//                      ░░░░░░░░░░░░▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒▒▒░░░░░░░░░░░░░░▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓░░░░░░▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓░░░░░░▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▒░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▓▓▓▓▓▓░░░░░░▒▒▒░░░░░▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▓▓▓▓▓▒░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒░░░░░░▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░▒▒▒░░░░░▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▓▓▓▓▓▒░░░░░▒▒▒░░░░░░▒▒▒▒▒▒░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒░░░░░░▒▒▒▒▒▒░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░▒▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░
//                      ░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░
//                      ░░░░░░░░░░░░▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒▒▒░░░░░░░░░░░░░░▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓░░░░░░▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▒░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▓▓▒▒▒░░░░░░▒▒▒░░░░░▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▓▓▓▒▒▒░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒░░░░░░▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//                      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// Contract By @R4vonus
//  ________                                                
//  ___  __ \______ ____   ________ _______ ____  __________
//  __  /_/ /_  __ `/__ | / /_  __ \__  __ \_  / / /__  ___/
//  _  _, _/ / /_/ / __ |/ / / /_/ /_  / / // /_/ / _(__  ) 
//  /_/ |_|  \__,_/  _____/  \____/ /_/ /_/ \__,_/  /____/
//  
////////////////////////////////////////////////////////                                                        

contract TheGardens is ERC2981, ERC721AOS {
    bytes32 public                   queenHash;
    bytes32 public                   metadataHash;

    uint32 public immutable          maxTotalSupply = 100000;

    uint16 public                    stakeSupplyStart;

    string public                    metamorphosisURI;
    string public                    metamorphosisHash;

    MintBeesData public              beesParams;

    bool public                      locked;
    bool public                      hiveStarted;

    address public                   hiveContract;
    address public                   signerAddress;
    
    address private                  beekeeper;
    address private                  honeykeeper;
    IERC20 public                    pepeContract;

    
    mapping(address => uint8) public mintingData;
    mapping(address => uint8) public honeyPassMints;

    // Status mapping:
    // 0 - Disabled: minting is not allowed
    // 1 - Whitelist: only whitelisted addresses can mint
    // 2 - Waitlist: whitelisted and waitlisted addresses can mint
    // 3 - Public: anyone can mint - maxMint is reset back to 0, but is still 5
    // 4 - Hive: Stake minting is enabled - You can now mint the rest of the 90k supply

    struct MintBeesData {
        uint256 price;                  // The price of one Bee NFT
        uint256 pepePrice;              // The price of of pepe Bee NFT
        uint256 multiplier;             // The multiplier applied to the price after each NFT mint is completed
        uint256 pepeMultiplier;         // The multiplier applied to the price after each Pepe  NFT mint is completed
        uint256 discountPrice;          // The discounted price of a NFT during a sale must buy 5
        uint256 pepeDiscountPrice;      // The discounted price of a Pepe NFT during a sale must buy 5
        uint16  maxHoneycombSupplyMint; // The maximum number of NFTs that can be minted during the sale
        uint16  maxMintPerWallet;       // The maximum number of NFTs that a wallet can mint (5)
        uint8   status;                 // The current status of the NFT sale (see above for mapping)
    }

    struct HoneyMintParams {
        uint256 tokenAmount;
        uint16  amount;
        bytes   signature;
    }

    //Check status mapping above for more info
    event statusChanged(uint8 status);

    error InvalidSignature();
    error MintingError();
    error TokenDoesNotExist();
    error AccessError();
    error WithdrawError();
    error MinterIsContract();
    error InsufficientFunds();
    error HiveAlreadyStarted();
    error MintingSupplyError();
    error MetadataAlreadyGenerated();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint16        _maxMintSupply,
        uint16        _maxMintPerWallet,
        address       _admin,
        address       _signer,
        address       _pepe
    ) ERC721AOS(_name, _symbol) {
        stakeSupplyStart = _maxMintSupply;
        metamorphosisURI = _baseURI;
        pepeContract = IERC20(_pepe);
        honeykeeper = owner();
        //  extraQueenURI = string(abi.encodePacked(_baseURI, "/queens"));
        beesParams = MintBeesData({
            price:                  0.045 ether,
            pepePrice:              49477000 ether,
            multiplier:             0.01 ether,
            pepeMultiplier:         10000000 ether,
            discountPrice:          0.025 ether,
            pepeDiscountPrice:      27382139 ether,
            maxHoneycombSupplyMint: _maxMintSupply,
            maxMintPerWallet:       _maxMintPerWallet,
            status:                 0
        });
        beekeeper = _admin;
        signerAddress = _signer;
       _setDefaultRoyalty(_admin, 700);
        emit statusChanged(0);
    }

    // ***************************************************************
    //                     MODIFIERS
    // ***************************************************************

    /**
     * @dev Modifier to ensure the minted amount does not exceed the maximum total supply
     *      for the hive. Reverts the transaction with a `MintingError` if the requested
     *      mint amount would cause the total supply to exceed the maximum allowed for the hive.
     *      The supply is determined if the hive exists or not. (Hive is stake contract)
     *
     * @param _amount uint256 - The number of bee NFTs to mint.
     */
    modifier maxHoneycombSupplyMint(uint256 _amount) {
        //Set it to the mint supply first
        uint256 supply = beesParams.maxHoneycombSupplyMint;

        if (beesParams.status == 4) {
            supply = maxTotalSupply; // If hive status is 4 (hive on), use the maximum total supply instead of the mint supply
        }

        // Revert the transaction if the total supply plus the requested amount exceeds the maximum supply
        if (totalSupply() + _amount > supply) {
            revert MintingError();
        }

        _;
    }
    /**
     * @dev Modifier to ensure that the contract is not locked (Beehive lock), enabling certain
     *      actions to be performed. Reverts the transaction with an `AccessError`
     *      if the contract is locked (Beehive lock).
     */
    modifier noBeehiveLock() {
        // Revert the transaction if the contract is locked
        if (locked) {
            revert AccessError();
        }

        _;
    }

    /**
     * @dev Modifier to ensure that the caller is not a contract. This is useful for
     *      preventing potential exploits or automated actions from contracts.
     *      Reverts the transaction with a `MinterNotContract` error if the caller is a contract.
     */
    modifier beeCallerOnly() {
        // Revert the transaction if the caller is a contract
        if (msg.sender != tx.origin) {
            revert MinterIsContract();
        }

        _;
    }

    /**
     * @dev Modifier to ensure that the caller has beekeeper (admin) `honeylistAccess`. Reverts the
     *      transaction with an `AccessError` if the caller is not an authorized beekeeper.
     */
    modifier beekeeperAccess() {
        // Revert the transaction if the caller is not an authorized beekeeper
        if (beekeeper != msg.sender) {
            revert AccessError();
        }

        _;
    }

    /**
     * @dev hive:
     *      Modifier to ensure that the Hive staking is currently enabled. Reverts the
     *      transaction with a MintingError if the staking is not currently enabled.
     */
    modifier hive() {
        // If the staking is not currently enabled, revert the transaction with a MintingError
        if (beesParams.status < 3) revert MintingError();
        _;
    }

    /**
     * @dev isHive:
     *      Modifier to ensure that the caller is the Hive contract address. This is useful for
     *      ensuring that certain functions can only be called by the Hive contract.
     *      Reverts the transaction with an AccessError if the caller is not the Hive address.
     */
    modifier isHive() {
        // If the caller is not the Hive address, revert the transaction with an AccessError
        if (msg.sender != hiveContract) revert AccessError();
        _;
    }

    /**
     * @dev Modifier to ensure that the transaction is authorized by checking the provided
     *      signature and custom data hash. The signature must be signed by the contract owner.
     *      Reverts the transaction with an `InvalidSignature` error if the authorization fails.
     *
     * @param _signature bytes - The signature to verify the caller's `honeylistAccess`.
     * @param _hashMessage bytes32 - The hash of the custom data to verify the signature.
     */
    modifier hiveBouncer(bytes memory _signature, bytes32 _hashMessage) {
        // Generate the prefixed hash of the message using the EIP-191 standard
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hashMessage)
        );

        // Split the signature into its v, r, and s components
        (uint8 v, bytes32 r, bytes32 s) = signatureToVRS(_signature);

        // Recover the address of the signer from the signature
        address signer = ecrecover(prefixedHashMessage, v, r, s);

        // Revert the transaction if the signer is not the contract owner
        if (signer != signerAddress) {
            revert InvalidSignature();
        }

        _;
    }

    // ***************************************************************
    //                     ADMIN/OWNER OPERATIONS
    // ***************************************************************

    /**
     * @dev lockBeehive:
     *      Function to lock the contract and prevent further modifications. Only the owner
     *      of the contract can perform this action. The contract must not be already locked.
     */
    function lockBeehive() public onlyOwner noBeehiveLock {
        locked = true;
    }

    /**
    * @dev This function sets the address of the signer.
    * @notice Can only be called by an account with the beekeeper role.
    * @param _signer The address of the new signer.
    */
    function addSigner(address _signer) public beekeeperAccess {
        signerAddress = _signer;
    }

    /**
     * @dev swarmUpdate:
     *      Function to start the bee swarm and enable bee NFT minting. Only the owner
     *      of the contract can perform this action. This will enable the honeylist sale and
     *      set the swarm to active.
     */
    function swarmUpdate(uint8 _status) public beekeeperAccess {
        if(hiveStarted) {
            if(_status != 0 && _status != 4) {
                revert HiveAlreadyStarted();
            }
        }
        beesParams.status = _status;
        emit statusChanged(_status);
    }

    /**
    * @dev This function sets the address of the token contract to interact with.
    * @notice Can only be called by an account with the beekeeper role.
    * @param _token The address of the token contract.
    */
    function addToken(address _token) public beekeeperAccess {
        pepeContract = IERC20(_token);
    }

    /**
     * @dev setBeekeeper:
     *      Function to add or remove a beekeeper role. Only the owner
     *      of the contract can perform this action. This will grant or revoke the beekeeper
     *      role for the specified address.
     *
     * @param _admin address - The address of the beekeeper to add or remove.
     */
    function setBeekeeper(address _admin, bool finance) public onlyOwner {
        //We dont add lock here because we want to be able to change beekeeper in case of community take over long into the future.
        //When contract is locked beekeeper has very limited access.
        if(finance) {
            honeykeeper = _admin;
        } else {
            beekeeper = _admin;
        }
    }

    /**
     * @dev Function to enable a new Hive staking contract. Only users with the beekeeper role
     *      can perform this action. This will enable the Hive staking contract.
     *
     * Requirements:
     * - The caller must have `beekeeper` access.
     * - The contract must not be locked (Beehive lock).
     */
    function enableHive() public beekeeperAccess noBeehiveLock {
        // If the `hiveContract` address is not set, revert the transaction with an AccessError
        if (hiveContract == address(0)) {
            revert AccessError();
        }

        // Enable the Hive staking contract by updating the `status` parameter in the `beesParams` struct
        beesParams.status = 4;
        hiveStarted = true;

        // Emit an event to signal that the `status` parameter has been changed
        emit statusChanged(beesParams.status);
    }
        
    /**
    * @dev Changes the pricing parameters of the contract. Only updates parameters if the new values are greater than zero.
    *      Sending a value of 0 for a parameter will allow changing other parameters without impacting the one with the 0 value.
    * @notice Can only be called by an account with the beekeeper role and when the beehive is not locked.
    * @param _price The new price. Set to 0 to leave unchanged.
    * @param _pepePrice The new Pepe price. Set to 0 to leave unchanged.
    * @param _multiplier The new multiplier. Set to 0 to leave unchanged.
    * @param pepeMultiplier The new Pepe multiplier. Set to 0 to leave unchanged.
    * @param discountPrice The new discount price. Set to 0 to leave unchanged.
    * @param pepeDiscountPrice The new Pepe discount price. Set to 0 to leave unchanged.
    * @return Updated parameters of the bees.
    */
    function changePrice(uint256 _price, uint256 _pepePrice, uint256 _multiplier, uint256 pepeMultiplier, uint256 discountPrice, uint256 pepeDiscountPrice) public beekeeperAccess noBeehiveLock returns (MintBeesData memory) {

        if(_price > 0) {
            beesParams.price = _price;
        }
        if(_pepePrice > 0) {
            beesParams.pepePrice = _pepePrice;
        }
        if(_multiplier > 0) {
            beesParams.multiplier = _multiplier;
        }
        if(pepeMultiplier > 0) {
            beesParams.pepeMultiplier = pepeMultiplier;
        }
        if(discountPrice > 0) {
            beesParams.discountPrice = discountPrice;
        }
        if(pepeDiscountPrice > 0) {
            beesParams.pepeDiscountPrice = pepeDiscountPrice;
        }
        return beesParams;
    }

    /**
     * @dev setHive:
     *      Function to set the address of the Hive contract. Only a beekeeper can perform this action
     *      and only if the contract is not locked.
     *
     * @param _hiveContract address - The address of the Hive contract.
     */
    function setHive(
        address _hiveContract
    ) public noBeehiveLock beekeeperAccess {
        // Set the Hive contract address
        hiveContract = _hiveContract;
    }

    /**
     * @dev setHiveExpansionData:
     *      Function to set the maximum hive expansion supply and maximum expansion per wallet.
     *      Only the owner of the beehive can perform this action. The beehive must not be locked.
     * @param _maxMintSupply The maximum number of hive expansions that can be added.
     * @param _maxMintPerWallet The maximum number of hive expansions that can be added per wallet.
     */
    function setHiveExpansionData(
        uint16 _maxMintSupply,
        uint16 _maxMintPerWallet
    ) public beekeeperAccess noBeehiveLock {
        beesParams.maxHoneycombSupplyMint = _maxMintSupply;
        beesParams.maxMintPerWallet = _maxMintPerWallet;
    }

    /**
     * @dev adjustStakeSupplyStart:
     *      Function to adjust the stake supply start index. Only a beekeeper can perform this action
     *      and only if the contract is not in Hive mode.
     *
     * This method is needed because if the public sale does not sell out, the stake supply start index
     * needs to be adjusted so that the token IDs are correct.
     */
    function adjustStakeSupplyStart() public beekeeperAccess {
        // Adjust the stake supply start index incase the public sale does not sell out
        if (hiveStarted) revert HiveAlreadyStarted();
        stakeSupplyStart = uint16(totalSupply() + 1);
    }

    /**
     * @dev addQueenHash:
     *      Function for a beekeeper to add a new queen bee hash value to the hive.
     *      If a hash value has already been revealed, the function will revert.
     * @param _queenHash The hash value for the new queen bee.
     */
    function addQueenHash(bytes32 _queenHash) external beekeeperAccess {
        // If a hash value has already been revealed, revert.
        if (queenHash != 0) revert AccessError();
        queenHash = _queenHash;
    }

    // ***************************************************************
    //                     REVANUE OPERATIONS
    // ***************************************************************

    /**
     * @dev Function to withdraw the contract balance to the admin. Anyone
     *      with access to the contract can perform this action.
     *
     * Requirements:
     * - The contract must have a non-zero balance.
     */
    function withdraw() public onlyOwner {
        // Get the current balance of the contract
        uint256 balance = address(this).balance;

        // Transfer the balance to the `beekeeper` address
        (bool success, ) = honeykeeper.call{value: balance}("");

        // Revert the transaction with a WithdrawError if the transfer was not successful
        if (!success) {
            revert WithdrawError();
        }
    }

    /**
     * @dev Function to withdraw Pepe tokens from the contract to the `beekeeper` address.
     *
     * Requirements:
     * - The contract must have a non-zero balance of the specified Pepe token.
     */
    function withdrawPepe() public onlyOwner {
        // Get the instance of the Pepe token contract

        // Get the current balance of the Pepe token held by the contract
        uint256 balance = pepeContract.balanceOf(address(this));

        // Transfer the Pepe token balance to the `beekeeper` address
        bool success = pepeContract.transfer(honeykeeper, balance);

        // Revert the transaction with a WithdrawError if the transfer was not successful
        if (!success) {
            revert WithdrawError();
        }
    }

    /**
     * @dev Function to set the royalty information for the specified receiver.
     *
     * @param receiver address - The address to set the royalty information for.
     * @param feeBasisPoints uint96 - The royalty fee basis points to set.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     */
    function setRoyaltyInfo(
        address receiver,
        uint96 feeBasisPoints
    ) external onlyOwner {
        // Call the internal `_setDefaultRoyalty` function to set the royalty information
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    // ***************************************************************
    //                     CONTRACT OPERATIONS
    // ***************************************************************

    /**
     * @dev Function to calculate the total price in ether for a given number of bees.
     *
     * @param _amount uint16 - The number of bees to calculate the price for.
     *
     * Returns:
     * - The total price in ether for the specified number of bees.
     */
    function grabHoneyPrice(uint16 _amount) public view returns (uint256) {
        unchecked {
            // Get the current status of the contract
            uint256 sale = beesParams.status;

            // Calculate the total price based on the current contract status and the number of bees
            uint256 price = (beesParams.price + sale * beesParams.multiplier) *
                _amount;

            // Apply discount if purchasing 5 bees
            if (_amount == 5) {
                price -= beesParams.discountPrice;
            }

            // //check eth balance of user and see if they can afford it
            // uint256 userBalance = address(msg.sender).balance;

            // if (userBalance < price) {
            //     revert InsufficientFunds();
            // }


            // Return the total price
            return price;
        }
    }

    /**
     * @dev grabHoneyPepe:
     *      Function to calculate the total price for minting a specified number of honeycomb tokens with Pepe.
     *      Reverts if the specified number of honeycomb tokens is zero or exceeds the maximum allowed per wallet.
     * @param _amount uint16 - The number of honeycomb tokens to calculate the total price for.
     * @return uint256 - The total price in Wei.
     */
    function grabHoneyPepe(uint16 _amount) public view returns (uint256) {
        unchecked {
            uint256 sale = beesParams.status;
            uint256 price = (beesParams.pepePrice +
                sale *
                beesParams.pepeMultiplier) * _amount;

            if (_amount == 5) {
                price -= beesParams.pepeDiscountPrice;
            }

            // uint256 balance = IERC20(pepeContract).balanceOf(msg.sender);

            // if (balance < price) {
            //     revert InsufficientFunds();
            // }

            return price;
        }
    }

    /**
     * @dev checkHive:
     *      Private function to check the current status of the honeycomb minting process and revert
     *      with a `MintingError` if certain conditions are not met.
     * @param _honeyList A boolean indicating whether the honeycomb list should be checked.
     */
    function checkHive(bool _honeyList) private view {
        uint8 status = beesParams.status;
        bool isRevealed = metadataHash != 0;
        if (status == 0 || isRevealed) {
            revert MintingError();
        }

        if (!_honeyList && status < 3) {
            revert MintingError();
        }

        if (_honeyList && status > 2) {
            revert MintingError();
        }
    }

    /**
     * @dev setBeeMintingData:
     *      Function to set the minting data for a bee NFT minting transaction. This function is private
     *      and should only be called internally by the contract.
     *
     * @param _isHoneylistSale bool - A boolean value indicating whether the minting transaction is part
     *      of the Honeylist sale.
     * @param _amount uint8 - The number of bee NFTs to mint.
     *
     * This function sets the minting data for a bee NFT minting transaction based on whether it is part
     * of the Honeylist sale or not. The minting data is used to determine the number of bee NFTs that can
     * be minted per wallet during the sale.
     */
    function setBeeMintingData(bool _isHoneylistSale, uint8 _amount) private {
        unchecked {
            if (_isHoneylistSale) {
                mintingData[msg.sender] =
                    (mintingData[msg.sender] & 0xF0) |
                    ((mintingData[msg.sender] + _amount) & 0x0F);
            } else {
                mintingData[msg.sender] =
                    (mintingData[msg.sender] & 0x0F) |
                    (((mintingData[msg.sender] + (_amount << 4)) & 0xF0));
            }
        }
    }

    /**
     * @dev getBeeMintingData:
     *      Function to get the bee NFT minting data for a minter. This function is public and can
     *      be called by anyone.
     *
     * @return honeySaleMinted uint8 - The number of bee NFTs minted by the minter during the Honeylist sale.
     * @return pollenSaleMinted uint8 - The number of bee NFTs minted by the minter during the Pollen sale.
     *
     * This function gets the minting data for a minter, which is used to determine the number of bee NFTs
     * that can be minted per wallet during the sale. The minting data consists of two values: the number
     * of bee NFTs minted during the Honeylist sale and the number of bee NFTs minted during the Pollen sale.
     */
    function getBeeMintingData()
        public
        view
        returns (uint8 honeySaleMinted, uint8 pollenSaleMinted)
    {
        // Get the minter's minting data from the mapping
        uint8 _mintingData = mintingData[msg.sender];

        // Extract the number of bee NFTs minted during the Honeylist sale and the Pollen sale
        honeySaleMinted = uint8(_mintingData & 0x0F);
        pollenSaleMinted = uint8((_mintingData & 0xF0) >> 4);
    }

    /**
     * @dev signatureToVRS:
     *      Function to convert a signature in bytes format to its VRS components.
     *      This function is internal and can only be called internally by the contract.
     *
     * @param _signature bytes - The signature to convert.
     *
     * @return _v uint8 - The V value of the signature.
     * @return _r bytes32 - The R value of the signature.
     * @return _s bytes32 - The S value of the signature.
     *
     * This function converts a signature in bytes format to its VRS components, which are the
     * three values used in Ethereum's ECDSA signature scheme. The V value is a single byte value
     * that represents the recovery ID. The R and S values are 32-byte values that represent the
     * signature's output.
     */

    function signatureToVRS(
        bytes memory _signature
    ) internal pure returns (uint8 _v, bytes32 _r, bytes32 _s) {
        assembly {
            _r := mload(add(_signature, 32))
            _s := mload(add(_signature, 64))
            _v := byte(0, mload(add(_signature, 96)))
        }
        return (_v, _r, _s);
    }

    // ***************************************************************
    //                     MINT OPERATIONS
    // ***************************************************************

    /**
     * @dev apiaryMint:
     *      Function to mint a specified number of bee NFTs during the public sale.
     *      Ensures that the sender is not a contract, the public sale has swarmStarted,
     *      and the transaction doesn't exceed per-transaction or total supply limits.
     *
     * @param _amount uint16 - The number of bee NFTs to mint.
     *
     * Emits a MintingError event if the requested number of bee NFTs exceeds
     * the maximum allowed per wallet.
     */
    function apiaryMint(
        uint16 _amount
    ) public payable beeCallerOnly maxHoneycombSupplyMint(_amount) {
        // Ensure that the hive has not been locked and that the public sale has started
        checkHive(false);

        // Get the current minting data for the caller
        (, uint8 publicData) = getBeeMintingData();

        // Ensure that the requested number of bee NFTs does not exceed the maximum allowed per wallet
        if (publicData + _amount > beesParams.maxMintPerWallet)
            revert MintingError();

        // Update the minting data for the caller
        setBeeMintingData(false, uint8(_amount));

        // // Calculate the cost of the bee NFTs
        // grabHoneyPrice(_amount);

        // Ensure that the caller has sent enough ether to cover the cost of the bee NFTs
        if (msg.value < grabHoneyPrice(_amount)) revert MintingError();

        // Mint the requested number of bee NFTs and assign them to the caller
        _mint(msg.sender, _amount);
    }

    /**
     * @dev honeyMint:
     *      Function to mint a specified number of bee NFTs for whitelisted users
     *      during the honeylist sale. Ensures that the sender is not a contract,
     *      the mint has started, and the transaction is authorized by checking
     *      the provided signature and custom data hash.
     *
     * @param _amount uint16 - The number of bee NFTs to mint.
     * @param _signature bytes - The signature to verify the caller's access to honeylist minting.
     *
     * Emits a MintingError event if the requested number of bee NFTs exceeds
     * the maximum allowed per wallet.
     */
    function honeyMint(
        uint16 _amount,
        bytes calldata _signature
    )
        external
        payable
        beeCallerOnly // Ensures that the sender is not a contract
        maxHoneycombSupplyMint(_amount) // Ensures that the mint has started and the transaction doesn't exceed limits
        hiveBouncer(
            _signature,
            keccak256(abi.encodePacked(address(this), msg.sender, _amount))
        ) // Checks that the transaction is authorized by the contract owner
    {
        checkHive(true); // Checks that the hive staking contract is active

        (uint8 wlData, ) = getBeeMintingData(); // Gets the whitelisted user's minting data

        if (wlData + _amount > beesParams.maxMintPerWallet)
            // Checks if the requested minting amount exceeds the maximum allowed per wallet
            revert MintingError();

        setBeeMintingData(true, uint8(_amount)); // Updates the whitelisted user's minting data
        if (msg.value < grabHoneyPrice(_amount)) revert MintingError(); // Checks if the transaction value is sufficient
        _mint(msg.sender, _amount); // Mints the specified number of bee NFTs for the whitelisted user
    }

    function honeyPollenMint(
        HoneyMintParams memory params
    )
        external
        beeCallerOnly
        maxHoneycombSupplyMint(params.amount)
        hiveBouncer(
            params.signature,
            keccak256(
                abi.encodePacked(address(this), msg.sender, params.amount)
            )
        )
    {
        checkHive(true);

        (uint8 wlData, ) = getBeeMintingData();

        // Ensure the total mint amount doesn't exceed the max mint per wallet
        if (wlData + params.amount > beesParams.maxMintPerWallet) {
            revert MintingError();
        }

        // Update the bee minting data
        setBeeMintingData(true, uint8(params.amount));

        // Check if the provided token amount is enough for the minting process
        if (params.tokenAmount < grabHoneyPepe(params.amount)) {
            revert MintingError();
        }

        // Transfer the specified amount of ERC20 tokens from the sender to the contract
        pepeContract.transferFrom(
            msg.sender,
            address(this),
            params.tokenAmount
        );

        // Mint the new tokens for the sender
        _mint(msg.sender, params.amount);
    }

    /**
     * @dev pollenMintPublic:
     *      Function to mint a specified number of bee NFTs using Pepe tokens during the public sale.
     *      Ensures that the sender is not a contract, the public sale has not started, and the transaction
     *      doesn't exceed per-transaction or total supply limits.
     *
     * @param _tokenAmount uint256 - The amount of Pepe tokens to use for the minting process.
     * @param _amount uint16 - The number of bee NFTs to mint.
     *
     * Emits a MintingError event if the requested number of bee NFTs exceeds
     * the maximum allowed per wallet or if the ERC20 token address is not approved.
     */
    function pollenMintPublic(
        uint256 _tokenAmount,
        uint16 _amount
    ) external beeCallerOnly maxHoneycombSupplyMint(_amount) {
        checkHive(false);

        (, uint8 pollenData) = getBeeMintingData();

        // Ensure the total mint amount doesn't exceed the max mint per wallet
        if (pollenData + _amount > beesParams.maxMintPerWallet) {
            revert MintingSupplyError();
        }

        // Update the bee minting data
        setBeeMintingData(false, uint8(_amount));

        // Check if the provided token amount is enough for the minting process
        if (_tokenAmount < grabHoneyPepe(_amount)) {
            revert MintingError();
        }

        // Transfer the specified amount of ERC20 tokens from the sender to the contract
        pepeContract.transferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );

        // Mint the new tokens for the sender
        _mint(msg.sender, _amount);
    }

    /**
     * @dev gardenMint:
     *      Function to mint a specified number of bee NFTs for free with a specific Garden Pass NFT.
     *      Ensures that the sender is not a contract, the mint has started, and the transaction is authorized
     *      by checking the provided signature and custom data hash.
     *
     * @param _amount uint8 - The number of bee NFTs to mint.
     * @param _allocation uint8 - The maximum number of bee NFTs that can be minted with the Garden Pass NFT.
     * @param _signature bytes - The signature to verify the caller's access to Garden Pass minting.
     *
     * Emits a MintingError event if the requested number of bee NFTs exceeds the maximum allowed per wallet.
     */
    function gardenMint(
        uint8 _amount,
        uint8 _allocation,
        bytes calldata _signature
    )
        external
        beeCallerOnly
        maxHoneycombSupplyMint(_amount)
        hiveBouncer(
            _signature,
            keccak256(
                abi.encodePacked(
                    address(this),
                    msg.sender,
                    _amount,
                    _allocation
                )
            )
        )
    {
        // If the contract is locked (Beehive lock), revert the transaction with an AccessError
        if (beesParams.status == 0) revert MintingError();

        // If the contract is already at max supply, revert the transaction with a MintingError
        if (beesParams.status == 4) revert MintingError();

        // Check if the sender has already minted the maximum number of bee NFTs with the Garden Pass NFT
        uint8 currentMinted = honeyPassMints[msg.sender];
        if (currentMinted + _amount > _allocation) revert MintingError();

        // Update the bee minting data
        honeyPassMints[msg.sender] += _amount;

        // Mint the new tokens for the sender
        _mint(msg.sender, _amount);
    }

    /**
     * @dev hiveMint:
     *      Function to mint a specified number of bee NFTs for a given address
     *      as a reward from the staking contract, which is the hive.
     *      Ensures that the sender has the appropriate "hive" role, the minted
     *      amount doesn't exceed the total supply limit, and the contract is not locked.
     *
     * @param _to address - The address to mint the bee NFTs to.
     * @param _amount uint256 - The number of bee NFTs to mint.
     */
    function hiveMint(
        address _to,
        uint256 _amount
    ) public hive isHive maxHoneycombSupplyMint(_amount) noBeehiveLock {
        _mint(_to, _amount);
    }

    /**
     * @dev queenBeeMint:
     *      Function to mint a specified number of bee NFTs for a given address
     *      with admin honeylistAccess, typically reserved for special events or promotions.
     *      Ensures that the sender has the appropriate admin honeylistAccess and the minted
     *      amount doesn't exceed the total supply limit.
     *
     * @param _to address - The address to mint the bee NFTs to.
     * @param _amount uint256 - The number of bee NFTs to mint.
     */
    function queenBeeMint(
        address _to,
        uint256 _amount
    ) public beekeeperAccess maxHoneycombSupplyMint(_amount) noBeehiveLock {
        if(hiveStarted) revert MintingError();
        _mint(_to, _amount);
    }

    // ***************************************************************
    //                     METADATA OPERATIONS
    // ***************************************************************

    /**
     * @dev metamorphosis:
     *      Function to set the base URI for bee NFTs and update the reveal status of the contract.
     *      This function is public and can only be called by beekeepers.
     *
     * @param _uri string - The new base URI to set for bee NFTs.
     * @param _metadataHash bytes32 - The hash of the metadata for the bee NFTs.
     * @param _queenHash bytes32 - The hash of the queen bee NFT metadata.
     *
     * This function sets the base URI for bee NFTs to a new value and updates the reveal status of the contract.
     * The base URI is the prefix to all token URIs, which are used to uniquely identify each bee NFT.
     * The reveal status determines whether or not the metadata for the bee NFTs is publicly visible.
     */
    function metamorphosis(
        string memory _uri,
        string memory _ipfsHash,
        bytes32 _metadataHash,
        bytes32 _queenHash
    ) external beekeeperAccess {
        //TODO: Make sure we can set a metadata URI in case if IPFS issues
        //Also make sure that when contract is locked we can still set the metadata URI, but not the hash (This keeps intgrity of the art)
        //since the hash is techically the file contents. THis lets us change hosts if we need to without breaking the art. (Users know the art is the same since the hash can't change)
        if (metadataHash == 0) {
            metadataHash = _metadataHash;
            queenHash = _queenHash;
        }

        metamorphosisURI = _uri;
        //Add lock here instead of modifier to allow for metadata URI changes in case of IPFS host issues
        if(locked == false)
        metamorphosisHash = _ipfsHash;
    }

    function fixBeforeReveal(string memory uri) external beekeeperAccess {
        if(metadataHash != 0) revert MetadataAlreadyGenerated();
        metamorphosisURI = uri;
    }

    /**
     * @dev metamorphosisURI:
     *      Function to get the metadata URI for a bee NFT based on its token ID.
     *      This function is public and can be called by anyone.
     *
     * @param _tokenId uint256 - The token ID of the bee NFT to get the metadata URI for.
     *
     * @return string - The metadata URI for the bee NFT.
     *
     * This function gets the metadata URI for a bee NFT based on its token ID. If the token ID is
     * within the first 10,000 IDs minted, it determines the metadata URI based on the current seed value.
     * If the seed value is not set, it returns the base URI for the bee NFTs. If the token ID is not within
     * the first 10,000 IDs minted, it gets the metadata URI from the hive contract using the token ID.
     */
    function getMetamorphosisURI(
        uint256 _tokenId
    ) public view returns (string memory) {
        if (_tokenId < stakeSupplyStart) {
            if (metadataHash == 0) {
                return metamorphosisURI;
            } else {
                return
                    string(
                        abi.encodePacked(
                            metamorphosisURI,
                            "/",
                            metamorphosisHash,
                            "/Bee_",
                            Strings.toString(_tokenId),
                            ".json"
                        )
                    );
            }
        } else {
            return StakedNFTMetadata(hiveContract).getMetadata(_tokenId);
        }
    }

    // ***************************************************************
    //                     OVERRIDES
    // ***************************************************************

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert TokenDoesNotExist();
        }
        return string(getMetamorphosisURI(_tokenId));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721AOS, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}