// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC721Drop} from "zora/ERC721Drop.sol";
import {IERC721Drop} from "zora/interfaces/IERC721Drop.sol";
import {IMetadataRenderer} from "zora/interfaces/IMetadataRenderer.sol";
import {EditionMetadataRenderer} from "zora/metadata/EditionMetadataRenderer.sol";
import {ZoraNFTCreatorV1} from "zora/ZoraNFTCreatorV1.sol";

contract ArtBattle is Owned {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    ZoraNFTCreatorV1 public immutable zoraNftCreator;
    uint256 public immutable joinCloseTime;
    uint256 public immutable mintPrice;
    uint256 public immutable openMintDuration;
    uint256 public immutable charityPercentage;

    /* -------------------------------------------------------------------------- */
    /*                                    STATE                                   */
    /* -------------------------------------------------------------------------- */
    uint256 public joinFee;

    struct Contestant {
        bool allowed;
        bool submitted;
        bool bailed;
        ERC721Drop collection;
    }

    address[] public contestantsList;
    mapping(address => Contestant) public contestants;
    uint256 public contestEndTime;
    bool public contestFinished;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event ContestInitialized(
        uint256 joinFee, uint256 joinCloseTime, uint256 mintPrice, uint256 openMintDuration, uint256 charityPercentage
    );
    event ContestantAdded(address contestantAddress);
    event ContestantJoined(address contestantAddress, string name, string symbol, ERC721Drop collection);
    event ContestantSubmitted(address contestantAddress, string imageURI, string description);
    event ContestStarted(uint256 contestEndTime);
    event ContestFinished(address winner, uint256 prize);
    event CharityAwarded(address charityAddress, uint256 prize);

    error ContestantsAlreadySet();
    error InvalidJoinFee();
    error ContestAlreadyJoined();
    error ContestNotFinished();
    error ContestantNotAllowed();
    error InvalidImageURI();
    error CantBail();

    /* -------------------------------------------------------------------------- */
    /*                                    HOST                                    */
    /* -------------------------------------------------------------------------- */
    constructor(
        uint256 _joinFee,
        uint256 _joinCloseTimeFromNow,
        uint104 _mintPrice,
        uint256 _openMintDuration,
        uint256 _charityPercentage,
        ZoraNFTCreatorV1 _zoraNFTCreator
    ) Owned(msg.sender) {
        joinFee = _joinFee;
        joinCloseTime = block.timestamp + _joinCloseTimeFromNow;
        mintPrice = _mintPrice;
        openMintDuration = _openMintDuration;
        charityPercentage = _charityPercentage;
        zoraNftCreator = _zoraNFTCreator;

        emit ContestInitialized(joinFee, joinCloseTime, mintPrice, openMintDuration, charityPercentage);
    }

    function setContestants(address[] memory contestantAddresses) external onlyOwner {
        if (contestEndTime != 0) revert ContestantsAlreadySet();

        contestantsList = contestantAddresses;
        for (uint256 i = 0; i < contestantAddresses.length; i++) {
            contestants[contestantAddresses[i]].allowed = true;
            emit ContestantAdded(contestantAddresses[i]);
        }
    }

    function setJoinFee(uint256 _joinFee) external onlyOwner {
        joinFee = _joinFee;
    }

    function awardCharity(address charityAddress) external onlyOwner {
        if (!contestFinished) revert ContestNotFinished();
        (bool success,) = charityAddress.call{value: address(this).balance}("");
        if (!success) revert();
        emit CharityAwarded(charityAddress, address(this).balance);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 CONTESTANTS                                */
    /* -------------------------------------------------------------------------- */
    function joinContest(string memory name, string memory symbol) external payable onlyContestant {
        if (msg.value != joinFee) revert InvalidJoinFee();
        if (address(contestants[msg.sender].collection) != address(0)) {
            revert ContestAlreadyJoined();
        }

        ERC721Drop collection = ERC721Drop(
            payable(
                zoraNftCreator.createEdition({
                    name: name,
                    symbol: symbol,
                    editionSize: type(uint64).max,
                    royaltyBPS: 0,
                    fundsRecipient: payable(address(this)),
                    defaultAdmin: address(this),
                    saleConfig: IERC721Drop.SalesConfiguration({
                        publicSalePrice: uint104(mintPrice),
                        maxSalePurchasePerAddress: type(uint32).max,
                        publicSaleStart: 0,
                        publicSaleEnd: 0,
                        presaleStart: 0,
                        presaleEnd: 0,
                        presaleMerkleRoot: 0x0
                    }),
                    description: "",
                    animationURI: "",
                    imageURI: ""
                })
            )
        );

        contestants[msg.sender].collection = collection;

        // The owner of the collection can update the collection metadata on sites like Zora, OpenSea, etc.
        // All other contract write functions are restricted to this controller contract.
        collection.setOwner(msg.sender);

        emit ContestantJoined(msg.sender, name, symbol, collection);
    }

    function setArt(string memory imageURI, string memory description) external onlyContestant {
        if (bytes(imageURI).length == 0) revert InvalidImageURI();

        ERC721Drop collection = contestants[msg.sender].collection;
        if (address(collection) == address(0)) revert();

        (IMetadataRenderer metadataRenderer,,,) = collection.config();
        EditionMetadataRenderer collectionMetadataRenderer = EditionMetadataRenderer(address(metadataRenderer));
        collectionMetadataRenderer.updateDescription(address(collection), description);
        collectionMetadataRenderer.updateMediaURIs(address(collection), imageURI, "");

        contestants[msg.sender].submitted = true;

        emit ContestantSubmitted(msg.sender, imageURI, description);
    }

    function bail() external onlyContestant {
        if (block.timestamp < joinCloseTime) revert CantBail();
        if (contestEndTime != 0) revert CantBail();
        if (address(contestants[msg.sender].collection) == address(0)) revert CantBail();
        if (contestants[msg.sender].bailed) revert CantBail();

        bool atLeastOneContestantHasNotSubmitted = false;
        for (uint256 i = 0; i < contestantsList.length; i++) {
            if (!contestants[contestantsList[i]].submitted) {
                atLeastOneContestantHasNotSubmitted = true;
                break;
            }
        }
        if (!atLeastOneContestantHasNotSubmitted) revert CantBail();

        contestants[msg.sender].bailed = true;

        (bool success,) = msg.sender.call{value: joinFee}("");
        if (!success) revert CantBail();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   PUBLIC                                   */
    /* -------------------------------------------------------------------------- */
    function startContest() external {
        if (contestEndTime != 0) revert();
        for (uint256 i = 0; i < contestantsList.length; i++) {
            if (!contestants[contestantsList[i]].submitted) revert();
        }

        for (uint256 i = 0; i < contestantsList.length; i++) {
            ERC721Drop collection = contestants[contestantsList[i]].collection;
            collection.setSaleConfiguration({
                publicSalePrice: uint104(mintPrice),
                maxSalePurchasePerAddress: type(uint32).max,
                publicSaleStart: uint64(block.timestamp),
                publicSaleEnd: uint64(block.timestamp + openMintDuration),
                presaleStart: 0,
                presaleEnd: 0,
                presaleMerkleRoot: 0x0
            });
        }

        contestEndTime = block.timestamp + openMintDuration;
        emit ContestStarted(contestEndTime);
    }

    function finishContest() external {
        if (contestEndTime == 0) revert();
        if (contestFinished) revert();
        if (block.timestamp < contestEndTime) revert();

        contestFinished = true;

        uint256 maxTotalSupply;
        uint256 leaderCount;
        uint256[] memory totalSupplies = new uint256[](contestantsList.length);

        for (uint256 i = 0; i < contestantsList.length; i++) {
            ERC721Drop collection = contestants[contestantsList[i]].collection;
            totalSupplies[i] = collection.totalSupply();
            if (totalSupplies[i] > maxTotalSupply) {
                maxTotalSupply = totalSupplies[i];
                leaderCount = 1;
            } else if (totalSupplies[i] == maxTotalSupply) {
                leaderCount++;
            }
            collection.withdraw();
        }

        uint256 charityPrize = (address(this).balance * charityPercentage) / 10000;
        uint256 winnerPrize = (address(this).balance - charityPrize) / leaderCount;

        for (uint256 i = 0; i < contestantsList.length; i++) {
            if (totalSupplies[i] == maxTotalSupply) {
                (bool success,) = contestantsList[i].call{value: winnerPrize}("");
                if (!success) revert();
                emit ContestFinished(contestantsList[i], winnerPrize);
            }
        }
    }

    function collectionForContestant(address contestantAddress) external view returns (ERC721Drop) {
        return contestants[contestantAddress].collection;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    MODS                                    */
    /* -------------------------------------------------------------------------- */
    modifier onlyContestant() {
        if (!contestants[msg.sender].allowed) revert ContestantNotAllowed();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    FUNDS                                   */
    /* -------------------------------------------------------------------------- */
    receive() external payable {}

    fallback() external payable {}
}