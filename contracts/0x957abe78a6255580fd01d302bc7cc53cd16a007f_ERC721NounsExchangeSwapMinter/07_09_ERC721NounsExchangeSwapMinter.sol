// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {SafeOwnable} from "../utils/SafeOwnable.sol";

// This is the token-gated (noun owners) minting Disco minting contract
contract ERC721NounsExchangeSwapMinter is SafeOwnable {
    IERC721 internal immutable nounsToken; // the nouns contract
    IERC721Drop internal immutable discoGlasses; // the disco contract
    uint256 public maxAirdropCutoffNounId; // max number of free disco units
    uint256 public costPerNoun; // cost of each disco unit

    uint256 public claimPeriodEnd; // end of the claim period

    mapping(uint256 => bool) public claimedPerNoun; // nounId => isClaimed

    error ClaimPeriodOver();
    error MustWaitUntilAfterClaimPeriod();
    error NotQualifiedForAirdrop();
    error QualifiedForAirdrop();
    error YouNeedToOwnTheNoun();
    error YouAlreadyMinted();
    error WrongPrice();

    event ClaimedFromNoun(
        address indexed claimee,
        uint256 newId,
        uint256 nounId
    );

    event UpdatedMaxAirdropCutoffNounId(uint256);

    constructor(
        address _nounsToken,
        address _discoGlasses,
        uint256 _maxAirdropCutoffNounId,
        uint256 _costPerNoun,
        address _initialOwner,
        uint256 _claimPeriodEnd
    ) {
        // Set variables
        discoGlasses = IERC721Drop(_discoGlasses);
        nounsToken = IERC721(_nounsToken);
        maxAirdropCutoffNounId = _maxAirdropCutoffNounId;
        costPerNoun = _costPerNoun;
        claimPeriodEnd = _claimPeriodEnd;

        // Setup ownership
        __Ownable_init(_initialOwner);
    }

    /// @notice admin function to update the max number of free disco units
    function updateAirdropQuantity(uint256 _maxAirdropCutoffNounId)
        external
        onlyOwner
    {
        maxAirdropCutoffNounId = _maxAirdropCutoffNounId;
        emit UpdatedMaxAirdropCutoffNounId(_maxAirdropCutoffNounId);
    }

    /// @notice admin function to update the cost to mint per noun
    function updateCostPerNoun(uint256 _newCost) external onlyOwner {
        costPerNoun = _newCost;
    }

    /// @notice admin function that lets the admin update the claim period end
    function updateClaimPeriodEnd(uint256 _claimPeriodEnd) external onlyOwner {
        claimPeriodEnd = _claimPeriodEnd;
    }

    // internal minting function which checks if the noun has been claimed
    // and then mints a disco unit
    function _mintWithNoun(uint256 nounId) internal returns (uint256) {
        if (claimedPerNoun[nounId]) {
            revert YouAlreadyMinted();
        }

        claimedPerNoun[nounId] = true;

        // make an admin mint
        uint256 newId = discoGlasses.adminMint(msg.sender, 1);

        emit ClaimedFromNoun(msg.sender, newId, nounId);

        return newId;
    }

    function claimAirdrop(uint256[] memory nounIds)
        external
        returns (uint256 mintedId)
    {
        if (block.timestamp > claimPeriodEnd) {
            revert ClaimPeriodOver();
        }
        // check to see if the current time is within the airdrop claim period
        // go to each nounID and check if the sender is the current owner of the nounID
        for (uint256 i = 0; i < nounIds.length; i++) {
            uint256 nounID = nounIds[i];
            if (nounsToken.ownerOf(nounID) != msg.sender) {
                revert YouNeedToOwnTheNoun();
            }

            // if the user provided nounID is outside the airdrop range, revert.
            if (nounID >= maxAirdropCutoffNounId) {
                revert NotQualifiedForAirdrop();
            }

            // If your noun ID qualifies for the aidrop, then mint a disco unit
            mintedId = _mintWithNoun(nounIds[i]);
        }

        return mintedId;
    }

    function mintDiscoWithNouns(uint256[] memory nounIds)
        external
        payable
        returns (uint256 mintedId)
    {
        // TODO: If the airdrop claim period is over open it up for everyone
        // if the total minted is greater than the airdrop max count, then the user must pay
        if (msg.value != nounIds.length * costPerNoun) {
            revert WrongPrice();
        }

        // for each of nounIDs passed check if the sender is the current owner of the nounID
        // if so, mint a disco unit, and set the nounID to claimed.
        // if the sender doesnt own the noun ID, revert
        for (uint256 i = 0; i < nounIds.length; i++) {
            uint256 nounID = nounIds[i];

            // if the user is not the owner of the nounID, revert.
            if (nounsToken.ownerOf(nounID) != msg.sender) {
                revert YouNeedToOwnTheNoun();
            }

            // checks while claim period is active
            if (block.timestamp < claimPeriodEnd) {
                // if the user provided nounID is within the aidrop,
                // revert because they qualify for an airdrop.
                if (nounID < maxAirdropCutoffNounId) {
                    revert QualifiedForAirdrop();
                }

                // During the claim period, only nounIDs that are less than the max supply
                // are allowed to buy a disco unit. If the nounID is greater than the max supply
                // of the disco units, revert.
                if (nounID >= discoGlasses.saleDetails().maxSupply) {
                    revert MustWaitUntilAfterClaimPeriod();
                }
            }

            mintedId = _mintWithNoun(nounID);
        }
        return mintedId;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }
}