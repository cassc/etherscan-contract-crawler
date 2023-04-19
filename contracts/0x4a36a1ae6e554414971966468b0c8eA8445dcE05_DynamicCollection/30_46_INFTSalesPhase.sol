// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

/**
 *  Sparkblox's 'Drop' contracts are distribution mechanisms for tokens.
 *
 *  A contract admin (i.e. a holder of `DEFAULT_ADMIN_ROLE`) can set a series of mint conditions,
 *  ordered by their respective `startTimestamp`. A mint condition defines criteria under which
 *  accounts can mint tokens. Mint conditions can be overwritten or added to by the contract admin.
 *  At any moment, there is only one active mint condition.
 */

interface INFTSalesPhase {
     /**
     *  @notice The criteria that make up a mint condition.
     *
     *  @param startTimestamp                 The unix timestamp after which the mint condition applies.
     *
     *  @param endTimestamp                   The unix timestamp that mint condition end.
     *                                        
     *  @param maxMitableSupply             The maximum total number of tokens that can be minted under
     *                                        the mint condition.
     *
     *  @param supplyMinted                  At any given point, the number of tokens that have been minted
     *                                        under the mint condition.
     *
     *  @param quantityLimitPerTransaction    The maximum number of tokens that can be minted in a single
     *                                        transaction.
     *
     *  @param waitTimeInSecondsBetweenMints The least number of seconds an account must wait after minting
     *                                        tokens, to be able to mint tokens again.
     *
     *  @param merkleRoot                     The allowlist of addresses that can mint tokens under the mint
     *                                        condition.
     *
     *  @param pricePerToken                  The price required to pay per token minted.
     * 
     * 
     *  @param tokenIds                       The list of tokenId that can mint tokens under the mint condition.
     *  
     */
    struct SalesPhase {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 maxMintableSupply;
        uint256 supplyMinted;
        uint256 quantityLimitPerWallet;
        uint256 waitTimeInSecondsBetweenMints;
        bytes32 merkleRoot;
        uint256 pricePerToken;
        uint256[] tokenIds;
        
    }

    /**
     *  @notice The set of all mint conditions, at any given moment.
     *  Mint Phase ID = [currentStartId, currentStartId + length - 1];
     *
     *  @param currentStartId           The uid for the first mint condition amongst the current set of
     *                                  mint conditions. The uid for each next mint condition is one
     *                                  more than the previous mint condition's uid.
     *
     *  @param count                    The total number of phases / mint conditions in the list
     *                                  of mint conditions.
     *
     *  @param phases                   The mint conditions at a given uid. mint conditions
     *                                  are ordered in an ascending order by their `startTimestamp`.
     *
     *  @param limitLastMintTimestamp  Map from an account and uid for a mint condition, to the last timestamp
     *                                  at which the account minted tokens under that mint condition.
     *
     *  @param supplyMintedByWallet    Map from a mint condition uid and account to supply minted by account.
     */
    struct SalesPhaseList {
        uint256 currentStartId;
        uint256 count;
        mapping(uint256 => SalesPhase) phases;
        mapping(uint256 => mapping(address => uint256)) limitLastMintTimestamp;
        mapping(uint256 => mapping(address => uint256)) supplyMintedByWallet;
    }
}