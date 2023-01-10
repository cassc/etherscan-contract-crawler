// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IERC20ClubFull} from "../ERC20Club/IERC20Club.sol";
import {IERC721MembershipFull} from "../ERC721Membership/IERC721Membership.sol";
import {RugUtilityProperties} from "../ERC721Membership/RugUtilityProperties.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// This module contract allows users to claim available tokens for a given Gensis NFT
/// The caller of the claim function does not have to be the owner of the NFT
contract RugERC20ClaimModule is Ownable, ReentrancyGuard {
    uint256 public constant RUG_TOKEN_DECIMALS_MULTIPLIER = 10**18;

    IERC20ClubFull public rugToken;
    IERC721MembershipFull public genesisNFT;
    RugUtilityProperties public properties;

    // Mapping of TokenIds => time of last claim
    mapping(uint256 => uint256) public lastClaim;
    uint256 public startTime;

    event StartTimeSet(uint256 startTime);
    event RugTokensClaimed(uint256 indexed tokenId, uint256 amount);

    constructor(
        address rugToken_,
        address genesisNFT_,
        address properties_,
        uint256 startTime_
    ) Ownable() ReentrancyGuard() {
        rugToken = IERC20ClubFull(rugToken_);
        genesisNFT = IERC721MembershipFull(genesisNFT_);
        properties = RugUtilityProperties(properties_);
        setStartTime(startTime_);
    }

    modifier onlyAfterStart() {
        require(block.timestamp > startTime, "Token claiming is not active");
        _;
    }

    /// Function to set the start time of the claiming period
    /// Can only be called by the owner of the contract
    /// @param start Start time of claim
    function setStartTime(uint256 start) public onlyOwner {
        require(start != 0, "Start time must not be 0");
        startTime = start;
        emit StartTimeSet(startTime);
    }

    /// Function that returns initial bonus amount of tokens
    /// @param production Get the initial bonus for a given role
    /// @return The amount bonus tokens for a given production amount
    function getStartingBalance(uint256 production)
        internal
        pure
        returns (uint256)
    {
        if (production == 5) {
            return 555;
        } else if (production == 7) {
            return 888;
        } else if (production == 11) {
            return 1111;
        }

        return 0;
    }

    /// Function that calculates the amount of tokens a tokenId has available to claim
    /// IMPORTANT: This returns the number of tokens NOT scaled up with decimals
    /// @param tokenId Gensis NFT ID
    /// @return The amount tokens to mint
    function getClaimAmount(uint256 tokenId)
        public
        view
        onlyAfterStart
        returns (uint256)
    {
        uint256 production = properties.getProduction(tokenId);
        if (lastClaim[tokenId] == 0) {
            return
                (((block.timestamp - startTime) / 1 days) * production) +
                getStartingBalance(production);
        } else {
            return
                ((block.timestamp - lastClaim[tokenId]) / 1 days) * production;
        }
    }

    /// Function that mints/claims the available amount of tokens for a given RR Genesis NFT
    /// @param tokenId Gensis NFT ID
    /// @return The amount tokens claimed
    function claimTokens(uint256 tokenId)
        external
        onlyAfterStart
        nonReentrant
        returns (uint256)
    {
        uint256 amount = getClaimAmount(tokenId) *
            RUG_TOKEN_DECIMALS_MULTIPLIER;
        if (amount == 0) {
            return 0;
        }
        lastClaim[tokenId] = block.timestamp;

        address owner = genesisNFT.ownerOf(tokenId);
        rugToken.mintTo(owner, amount);

        emit RugTokensClaimed(tokenId, amount);
        return amount;
    }

    /// Function that bulk mints/claims for an array of Genesis token Ids
    /// @param tokenIds Array of Gensis NFT IDs
    /// @return True if successful
    function bulkClaimTokens(uint256[] calldata tokenIds)
        external
        onlyAfterStart
        nonReentrant
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            uint256 amount = getClaimAmount(tokenId) *
                RUG_TOKEN_DECIMALS_MULTIPLIER;
            if (amount != 0) {
                lastClaim[tokenId] = block.timestamp;

                address owner = genesisNFT.ownerOf(tokenId);
                rugToken.mintTo(owner, amount);

                emit RugTokensClaimed(tokenId, amount);
            }
        }

        return true;
    }

    /// This function is called for all messages sent to this contract (there
    /// are no other functions). Sending Ether to this contract will cause an
    /// exception, because the fallback function does not have the `payable`
    /// modifier.
    /// Source: https://docs.soliditylang.org/en/v0.8.9/contracts.html?highlight=fallback#fallback-function
    fallback() external {}
}