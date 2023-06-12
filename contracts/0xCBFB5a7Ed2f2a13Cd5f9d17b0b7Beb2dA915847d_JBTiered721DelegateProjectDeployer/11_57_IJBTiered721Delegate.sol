// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IJBDirectory } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import { IJBFundingCycleStore } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleStore.sol";
import { IJBPrices } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPrices.sol";

import { IJB721Delegate } from "./IJB721Delegate.sol";
import { IJB721TokenUriResolver } from "./IJB721TokenUriResolver.sol";
import { IJBTiered721DelegateStore } from "./IJBTiered721DelegateStore.sol";
import { JB721PricingParams } from "./../structs/JB721PricingParams.sol";
import { JB721TierParams } from "./../structs/JB721TierParams.sol";
import { JBTiered721Flags } from "./../structs/JBTiered721Flags.sol";
import { JBTiered721MintReservesForTiersData } from "./../structs/JBTiered721MintReservesForTiersData.sol";
import { JBTiered721MintForTiersData } from "./../structs/JBTiered721MintForTiersData.sol";

interface IJBTiered721Delegate is IJB721Delegate {
    event Mint(
        uint256 indexed tokenId,
        uint256 indexed tierId,
        address indexed beneficiary,
        uint256 totalAmountContributed,
        address caller
    );

    event MintReservedToken(
        uint256 indexed tokenId, uint256 indexed tierId, address indexed beneficiary, address caller
    );

    event AddTier(uint256 indexed tierId, JB721TierParams data, address caller);

    event RemoveTier(uint256 indexed tierId, address caller);

    event SetEncodedIPFSUri(uint256 indexed tierId, bytes32 encodedIPFSUri, address caller);

    event SetBaseUri(string indexed baseUri, address caller);

    event SetContractUri(string indexed contractUri, address caller);

    event SetTokenUriResolver(IJB721TokenUriResolver indexed newResolver, address caller);

    event AddCredits(
        uint256 indexed changeAmount, uint256 indexed newTotalCredits, address indexed account, address caller
    );

    event UseCredits(
        uint256 indexed changeAmount, uint256 indexed newTotalCredits, address indexed account, address caller
    );

    function codeOrigin() external view returns (address);

    function store() external view returns (IJBTiered721DelegateStore);

    function fundingCycleStore() external view returns (IJBFundingCycleStore);

    function pricingContext() external view returns (uint256, uint256, IJBPrices);

    function creditsOf(address _address) external view returns (uint256);

    function firstOwnerOf(uint256 _tokenId) external view returns (address);

    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function adjustTiers(JB721TierParams[] memory tierDataToAdd, uint256[] memory tierIdsToRemove) external;

    function mintReservesFor(JBTiered721MintReservesForTiersData[] memory mintReservesForTiersData) external;

    function mintReservesFor(uint256 tierId, uint256 count) external;

    function mintFor(uint16[] calldata tierIds, address beneficiary) external returns (uint256[] memory tokenIds);

    function setMetadata(
        string memory baseUri,
        string calldata contractMetadataUri,
        IJB721TokenUriResolver tokenUriResolver,
        uint256 encodedIPFSUriTierId,
        bytes32 encodedIPFSUri
    ) external;

    function initialize(
        uint256 projectId,
        IJBDirectory directory,
        string memory name,
        string memory symbol,
        IJBFundingCycleStore fundingCycleStore,
        string memory baseUri,
        IJB721TokenUriResolver tokenUriResolver,
        string memory contractUri,
        JB721PricingParams memory pricing,
        IJBTiered721DelegateStore store,
        JBTiered721Flags memory flags
    ) external;
}