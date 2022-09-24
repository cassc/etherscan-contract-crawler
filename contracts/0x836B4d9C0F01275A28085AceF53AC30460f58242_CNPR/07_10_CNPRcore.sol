// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ICNPRdescriptor.sol";

/**
 *  @title Core abstract contract for CNPR.
 *  @dev Basic variables and other information are provided.
 */
abstract contract CNPRcore is Ownable {
    // Burn mint struct
    struct BurnMintStruct {
        bool isDone;
        mapping(address => uint256) numberOfBurnMintByAddress;
    }

    // Sale phase enum
    enum SalePhase {
        Locked,
        PreSale,
        BurnMint
    }

    // The CNPR token URI descriptor
    ICNPRdescriptor public descriptor;

    // Phase management
    SalePhase public phase = SalePhase.Locked;

    // Address of withdraw
    address public constant WITHDRAW_ADDRESS =
        0x7dDeE8b16F3F36cFb51De9dE2173dfD522909fb1;

    // Address of adminSigner
    address public adminSigner;

    // Address of admin
    address public admin;

    // The baseURI of metadata
    string public baseURI;

    // The Extension of URI
    string public baseExtension = ".json";

    // Maximum number of CNPR tokens can be minted
    uint256 public constant MAX_SUPPLY = 7777;

    // The CNPR token mint cost
    uint256 public constant MINT_COST = 0.001 ether;

    // Maximum number of BurnMint that can be done
    uint256 public maxBurnMintSupply = 2222;

    // Burn mint cost
    uint256 public burnMintCost = 0.001 ether;

    // Presale mint index
    uint256 public presaleMintIndex;

    // Burn mint index
    uint256 public burnMintIndex;

    // The bool switching to on-chain
    bool public isOnchain;

    // The mapping presale mint count
    mapping(address => uint256) public presaleMintCount;

    // The burn mint struct (index => BurnMintStruct)
    mapping(uint256 => BurnMintStruct) public burnMintStructs;
}