// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {LibERC20} from "../libraries/LibERC20.sol";
import {AppStorage, PartyInfo} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC20} from "../interfaces/IERC20.sol";

/**
 * @notice A struct containing the initialization arguments structs
 * @member partyCreator The user that created the Party
 * @member partyInfo PartyInfo struct
 * @member tokenSymbol Party ERC-20 symbol metadata
 * @member initialDeposit Initial deposit in denomination asset made by the party creator
 * @member platformFeeCollector Fee collector address
 * @member platformFee Fee amount in bps
 * @member platformSentinel Sentinel address
 */
struct InitArgs {
    address partyCreator;
    PartyInfo partyInfo;
    string tokenSymbol;
    uint256 initialDeposit;
    address denominationAsset;
    address platformFeeCollector;
    uint256 platformFee;
    address platformSentinel;
}

contract PartyInit {
    AppStorage internal s;

    /**
     * @notice Emitted exactly once by a party when #initialize is first called
     * @param partyCreator Address of the user that created the party
     * @param partyName Name of the party
     * @param isPublic Visibility of the party
     * @param dAsset Address of the denomination asset for the party
     * @param minDeposit Minimum deposit of the party
     * @param maxDeposit Maximum deposit of the party
     * @param mintedPT Minted party tokens for creating the party
     * @param bio Bio of the party
     * @param img Img url of the party
     * @param model Model of party created
     * @param purpose Purpose of party created
     */
    event PartyCreated(
        address partyCreator,
        string partyName,
        bool isPublic,
        address dAsset,
        uint256 minDeposit,
        uint256 maxDeposit,
        uint256 mintedPT,
        string bio,
        string img,
        string model,
        string purpose
    );

    /**
     * @notice Initialization method for created Parties
     * @dev Must be called by the PartyFactory during the Party creation
     * @param _args Initialization arguments struct
     */
    function init(InitArgs memory _args) external {
        // Main platform addresses
        s.platformFee = _args.platformFee;
        s.platformFeeCollector = _args.platformFeeCollector;
        s.platformSentinel = _args.platformSentinel;
        s.platformFactory = msg.sender;

        // Party data
        s.denominationAsset = _args.denominationAsset;
        s.partyInfo = _args.partyInfo;
        s.tokens.push(_args.denominationAsset);
        s.managers[_args.partyCreator] = true;
        s.members[_args.partyCreator] = true;
        s.creator = _args.partyCreator;

        // Set PartyToken Metadata
        s.name = _args.partyInfo.name;
        s.symbol = _args.tokenSymbol;

        // Mint the initial PartyTokens to the deployer
        uint256 mintedPT = _args.initialDeposit *
            10 ** (18 - IERC20Metadata(_args.denominationAsset).decimals());
        LibERC20._mint(_args.partyCreator, mintedPT);

        // Adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC20).interfaceId] = true;

        // Emit PartyCreated event
        emit PartyCreated(
            _args.partyCreator,
            _args.partyInfo.name,
            _args.partyInfo.isPublic,
            _args.denominationAsset,
            _args.partyInfo.minDeposit,
            _args.partyInfo.maxDeposit,
            mintedPT,
            _args.partyInfo.bio,
            _args.partyInfo.img,
            _args.partyInfo.model,
            _args.partyInfo.purpose
        );
    }
}