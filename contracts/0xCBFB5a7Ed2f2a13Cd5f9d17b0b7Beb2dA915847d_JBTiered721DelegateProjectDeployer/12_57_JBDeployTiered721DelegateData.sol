// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleStore.sol";
import "./../enums/JB721GovernanceType.sol";
import "./../interfaces/IJB721TokenUriResolver.sol";
import "./../interfaces/IJBTiered721DelegateStore.sol";
import "./JB721PricingParams.sol";
import "./JBTiered721Flags.sol";

/// @custom:member name The name of the token.
/// @custom:member symbol The symbol that the token should be represented by.
/// @custom:member fundingCycleStore A contract storing all funding cycle configurations.
/// @custom:member baseUri A URI to use as a base for full token URIs.
/// @custom:member tokenUriResolver A contract responsible for resolving the token URI for each token ID.
/// @custom:member contractUri A URI where contract metadata can be found. 
/// @custom:member pricing The tier pricing according to which token distribution will be made. 
/// @custom:member reservedTokenBeneficiary The address receiving the reserved token
/// @custom:member store The store contract to use.
/// @custom:member flags A set of flags that help define how this contract works.
/// @custom:member governanceType The type of governance to allow the NFTs to be used for.
struct JBDeployTiered721DelegateData {
    string name;
    string symbol;
    IJBFundingCycleStore fundingCycleStore;
    string baseUri;
    IJB721TokenUriResolver tokenUriResolver;
    string contractUri;
    JB721PricingParams pricing;
    address reservedTokenBeneficiary;
    IJBTiered721DelegateStore store;
    JBTiered721Flags flags;
    JB721GovernanceType governanceType;
}