// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {NounletMinter as Minter, Permission} from "./NounletMinter.sol";
import {NFTReceiver as Receiver} from "../utils/NFTReceiver.sol";
import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {SafeCastLib} from "@rari-capital/solmate/src/utils/SafeCastLib.sol";
import {SafeSend} from "../utils/SafeSend.sol";

import {INounletAuction as IAuction, Auction, Vault} from "../interfaces/INounletAuction.sol";
import {INounletRegistry as IRegistry} from "../interfaces/INounletRegistry.sol";
import {INounletToken as INounlet} from "../interfaces/INounletToken.sol";

/// @title NounletAuction
/// @author Tessera
/// @notice Module contract for holding auctions of newly minted fractions
contract NounletAuction is IAuction, Minter, Receiver, ReentrancyGuard, SafeSend {
    /// @dev Using safe casting library for uint256 types
    using SafeCastLib for uint256;
    /// @notice Address of NounletRegistry contract
    address public immutable registry;
    /// @notice Duration time of each auction
    uint48 public constant DURATION = 4 hours;
    /// @notice Percentage of minimum bid increase
    uint48 public constant MIN_INCREASE = 5;
    /// @notice Duration time extension for bids placed in final 10 minutes
    uint48 public constant TIME_BUFFER = 10 minutes;
    /// @notice Total supply of Nounlet tokens for each Noun
    uint48 public constant TOTAL_SUPPLY = 100;
    /// @notice Mapping of Vault address to struct of vault curator and current token ID
    mapping(address => Vault) public vaultInfo;
    /// @notice Mapping of Vault address to id to auction struct with bidder, bid amount, and endtime
    mapping(address => mapping(uint256 => Auction)) public auctionInfo;

    /// @dev Initializes NounletRegistry and NounletSupply contracts
    constructor(address _registry, address _supply) Minter(_supply) {
        registry = _registry;
    }

    /// @notice Creates a new auction for the first Nounlet of each Noun
    /// @param _vault Address of the vault
    /// @param _curator Address of the Noun owner
    /// @param _mintProof Merkle proof for minting new Nounlets
    function createAuction(
        address _vault,
        address _curator,
        bytes32[] calldata _mintProof
    ) external {
        // Reverts if first token has already been minted
        if (vaultInfo[_vault].currentId != 0) revert AuctionAlreadyCreated();

        // Sets the vault info and mints the first Nounlet
        vaultInfo[_vault] = Vault(_curator, 1);
        _create(_vault, 1, _mintProof);
    }

    /// @notice Settles the current auction and mints the next Nounlet
    /// @param _vault Address of the vault
    /// @param _mintProof Merkle proof for minting new Nounlets
    function settleAuction(address _vault, bytes32[] calldata _mintProof) external nonReentrant {
        // Settles the current auction and increments current ID in memory
        uint256 id = uint256(vaultInfo[_vault].currentId);
        _settle(_vault, id);
        // Mints the next Nounlet if total supply is greater than or equal to current ID
        if (uint256(TOTAL_SUPPLY) >= ++id) _create(_vault, id, _mintProof);
    }

    /// @notice Creates a new bid on the current auction of a given vault
    /// @param _vault Address of the vault
    function bid(address _vault) external payable nonReentrant {
        // Gets the current ID and declares auction info in storage
        uint256 id = uint256(vaultInfo[_vault].currentId);
        Auction storage auction = auctionInfo[_vault][id];
        // Reverts if end time of auction is less than current time
        uint256 endTime = uint256(auction.endTime);
        if (endTime < block.timestamp) revert AuctionExpired();
        // Reverts if current bid is not at least 5% greater than the previous bid
        uint256 ethAmount = auction.amount;
        if (msg.value < ethAmount + ((ethAmount * MIN_INCREASE) / 100)) revert InvalidBidIncrease();

        // Updates auction end time if less than current time plus time buffer of 10 minutes
        address token = IRegistry(registry).vaultToToken(_vault);
        uint256 extendedTime = block.timestamp + TIME_BUFFER;
        if (endTime < extendedTime) auction.endTime = extendedTime.safeCastTo32();

        // Sets bidder and bid amount to auction info in storage
        _sendEthOrWeth(auction.bidder, ethAmount);
        auction.bidder = msg.sender;
        auction.amount = msg.value.safeCastTo64();

        // Emits bid event and transfers bid amount to this contract
        emit Bid(_vault, token, id, msg.sender, msg.value, auction.endTime);
    }

    /// @dev Creates a new auction and initializes auction info
    /// @param _vault Address of the vault
    /// @param _id ID of the token
    /// @param _mintProof Merkle proof for minting new Nounlets
    function _create(
        address _vault,
        uint256 _id,
        bytes32[] calldata _mintProof
    ) internal {
        // Mints a new fraction through NounletMinter module
        _mintFraction(_vault, address(this), _id, _mintProof);

        // Initializes end time and sets first bidder as vault curator
        address token = IRegistry(registry).vaultToToken(_vault);
        uint256 endTime = block.timestamp + DURATION;
        auctionInfo[_vault][_id].endTime = endTime.safeCastTo32();
        auctionInfo[_vault][_id].bidder = vaultInfo[_vault].curator;

        // Emits event for creating new auction
        emit Created(_vault, token, _id, endTime);
    }

    /// @dev Settles a finished auction
    /// @param _vault Address of the vault
    /// @param _id ID of the token
    function _settle(address _vault, uint256 _id) internal {
        // Reverts if auction end time is greater than current time
        Auction memory auction = auctionInfo[_vault][_id];
        if (uint256(auction.endTime) > block.timestamp) revert AuctionNotCompleted();
        if (uint256(TOTAL_SUPPLY) < _id) revert AuctionExpired();

        // Gets royalty info based on final bid amount
        uint64 bidAmount = auction.amount;
        address token = IRegistry(registry).vaultToToken(_vault);
        (address beneficiary, uint256 royaltyAmount) = INounlet(token).royaltyInfo(_id, bidAmount);

        //Transfers nounlet to winner
        INounlet(token).transferFrom(address(this), auction.bidder, _id, 1, "");

        // Increments current ID in storage
        ++vaultInfo[_vault].currentId;

        // Transfers bid amount to curator and royalties to creator
        _sendEthOrWeth(vaultInfo[_vault].curator, bidAmount - royaltyAmount);
        _sendEthOrWeth(beneficiary, royaltyAmount);

        // Emits event for settling current auction
        emit Settled(_vault, token, _id, auction.bidder, bidAmount);
    }
}