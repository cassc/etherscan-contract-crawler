// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./SuperRareContracts.sol";
import "./IRoyaltyRegistry.sol";

import "../specs/IManifold.sol";
import "../specs/IRarible.sol";
import "../specs/IFoundation.sol";
import "../specs/ISuperRare.sol";
import "../specs/IEIP2981.sol";
import "../specs/IZoraOverride.sol";
import "../specs/IArtBlocksOverride.sol";
import "../specs/IKODAV2Override.sol";

/**
 * @dev Trimmed down implementation RoyaltyEngineV1 by manifold.xyz - https://github.com/manifoldxyz/royalty-registry-solidity
 * @dev Marketplaces may choose to directly inherit the Royalty Engine to save a bit of gas (from our testing, a possible savings of 6400 gas per lookup).
 * @dev ERC165 was removed because we removed all functions and modified return parameters of `getRoyalty`, thus no function interface is the same as before (0xcb23f816).
 */
contract RoyaltyEngineV1 {

    /**
     * @dev The Royalty Registry is an on chain contract that is responsible for storing Royalty configuration overrides.
     * A reference EIP2981 override implementation can be found here: https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/overrides/RoyaltyOverride.sol.
     * An upgradeable version of both the Royalty Registry and Royalty Engine (v1) has been deployed for public consumption. There should only be one instance of the Royalty Registry (in order to ensure that people who wish to override do not have to do so in multiple places), while many instances of the Royalty Engine can exist.
     * @dev the original contract was modified in order to remove the need for a constructor, as the royalty registry address is public and immutable (it's an upgradable proxy)
     */
    address internal immutable ROYALTY_REGISTRY;
    

    error Unauthorized();
    error InvalidAmount(uint256 amount);
    error LengthMismatch(uint256 recipients, uint256 bps); // only used in RoyaltyEngineV1
    
    /**
     * Get the royalties for a given token and sale amount. 
     *
     * @param tokenAddress - address of token
     * @param tokenId - id of token
     * @param value - sale value of token
     * Returns two arrays, first is the list of royalty recipients, second is the amounts for each recipient.
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        internal
        view
        returns (address payable/*[] memory*/ recipient, uint256/*[] memory*/ amount)
    {
        // External call to limit gas
        try
            /// @dev The way in which RoyaltyEngineV1.getRoyalty is constructed is too trusting by default given that it calls out to a registry of contracts that are user-settable without any restriction on their functionality, and therefore allows for different kinds of attacks for any marketplace that does not explicitly guard itself from gas griefing, control flow hijack or out of gas attacks.
            ///     To mitigate the griefing vector and other potential vulnerabilities, I suggest to limit the gas by default that _getRoyalty is given to an amount that no reasonable use of the RoyaltyRegistry should exceed - in my opinion at most 50,000 gas, but certainly no more than 100,000 gas.
            ///     I would suggest also to use .staticcall by default when calling out to the untrusted royalty-info supplying addresses, as no one should be modifying state within a Royalty*Lookup* context, and that would also by default prevent reentrancy.
            ///     to limit gas effectively it's necessary to limit it when calling into your own trusted function, then calling from that trusted function to an untrusted function
            ///     source: https://githubrecord.com/issue/manifoldxyz/royalty-registry-solidity/17/1067105243
            this._getRoyalty{gas: 100000}(tokenAddress, tokenId, value)
        returns (
            address payable[] memory _recipients,
            uint256[] memory _amounts
        ) {
            recipient = _recipients[0];
            amount = _amounts[0];
        } catch {
            revert InvalidAmount(amount); // technically, it could be any error, perhaps todo i should add the error message instead of simply returning the returned amount (which will be 0 anyay if the tx failed right?!)
        }
    }

    /**
     * @dev Get the royalty for a given token
     * @dev the original RoyaltyEngineV1 has been modified by removing the _specCache and the associated code,
     * using try catch statements is very cheap, no need to store `_specCache` mapping, see {RoyaltyEngineV1-_specCache}. Reference: https://www.reddit.com/r/ethdev/comments/szot8r/comment/hy5vsxb/?utm_source=share&utm_medium=web2x&context=3
     * returns recipients array, amounts array, royalty address
     */
    function _getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (
            address payable[] memory recipients,
            uint256[] memory amounts
        )
    {
        if (msg.sender != address(this) ) revert Unauthorized();

        address royaltyAddress = IRoyaltyRegistry(ROYALTY_REGISTRY)
            .getRoyaltyLookupAddress(tokenAddress);

        try IEIP2981(royaltyAddress).royaltyInfo(tokenId, value) returns (
            address recipient,
            uint256 amount
        ) {
            // Supports EIP2981. Return amounts
            if (amount > value ) revert InvalidAmount(amount); // note doesn't revert if amount == value
            recipients = new address payable[](1);
            amounts = new uint256[](1);
            recipients[0] = payable(recipient);
            amounts[0] = amount;
            return (
                recipients,
                amounts
            );
        } catch { }

        // SuperRare handling
        if (
            tokenAddress == SuperRareContracts.SUPERRARE_V1 ||
            tokenAddress == SuperRareContracts.SUPERRARE_V2
        ) {
            try
                ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY)
                    .tokenCreator(tokenAddress, tokenId)
            returns (address payable creator) {
                try
                    ISuperRareRegistry(
                        SuperRareContracts.SUPERRARE_REGISTRY
                    ).calculateRoyaltyFee(tokenAddress, tokenId, value)
                returns (uint256 amount) {
                    recipients = new address payable[](1);
                    amounts = new uint256[](1);
                    recipients[0] = creator;
                    amounts[0] = amount;
                    return (
                        recipients,
                        amounts
                    );
                } catch {}
            } catch {}
        }

        try IManifold(royaltyAddress).getRoyalties(tokenId) returns (
            address payable[] memory recipients_,
            uint256[] memory bps
        ) {
            // Supports manifold interface.  Compute amounts
            if(recipients_.length != bps.length) revert LengthMismatch(recipients_.length, bps.length);
            return (
                recipients_,
                _computeAmounts(value, bps)
            );
        } catch {}

        try
            IRaribleV2(royaltyAddress).getRaribleV2Royalties(tokenId)
        returns (IRaribleV2.Part[] memory royalties) {
            // Supports rarible v2 interface. Compute amounts
            recipients = new address payable[](royalties.length);
            amounts = new uint256[](royalties.length);
            uint256 totalAmount;
            for (uint256 i = 0; i < royalties.length; i++) {
                recipients[i] = royalties[i].account;
                amounts[i] = (value * royalties[i].value) / 10000;
                totalAmount += amounts[i];
            }
            if (totalAmount > value ) revert InvalidAmount(totalAmount);
            return (
                recipients,
                amounts
            );
        } catch {}
        try IRaribleV1(royaltyAddress).getFeeRecipients(tokenId) returns (
            address payable[] memory recipients_
        ) {
            // Supports rarible v1 interface. Compute amounts
            recipients_ = IRaribleV1(royaltyAddress).getFeeRecipients(
                tokenId
            );
            try IRaribleV1(royaltyAddress).getFeeBps(tokenId) returns (
                uint256[] memory bps
            ) {
                if(recipients_.length != bps.length) revert LengthMismatch(recipients_.length, bps.length);
                return (
                    recipients_,
                    _computeAmounts(value, bps)
                );
            } catch {}
        } catch {}
        try IFoundation(royaltyAddress).getFees(tokenId) returns (
            address payable[] memory recipients_,
            uint256[] memory bps
        ) {
            // Supports foundation interface.  Compute amounts
            if(recipients_.length != bps.length) revert LengthMismatch(recipients_.length, bps.length);
            return (
                recipients_,
                _computeAmounts(value, bps)
            );
        } catch {}
        try
            IZoraOverride(royaltyAddress).convertBidShares(
                tokenAddress,
                tokenId
            )
        returns (
            address payable[] memory recipients_,
            uint256[] memory bps
        ) {
            // Support Zora override
            if(recipients_.length != bps.length) revert LengthMismatch(recipients_.length, bps.length);
            return (
                recipients_,
                _computeAmounts(value, bps)
            );
        } catch {}
        try
            IArtBlocksOverride(royaltyAddress).getRoyalties(
                tokenAddress,
                tokenId
            )
        returns (
            address payable[] memory recipients_,
            uint256[] memory bps
        ) {
            // Support Art Blocks override
            if(recipients_.length != bps.length) revert LengthMismatch(recipients_.length, bps.length);
            return (
                recipients_,
                _computeAmounts(value, bps)
            );
        } catch {}
        try
            IKODAV2Override(royaltyAddress).getKODAV2RoyaltyInfo(
                tokenAddress,
                tokenId,
                value
            )
        returns (
            address payable[] memory _recipients,
            uint256[] memory _amounts
        ) {
            // Support KODA V2 override
            if(_recipients.length != _amounts.length) revert LengthMismatch(_recipients.length, _amounts.length);
            return (
                _recipients,
                _amounts
            );
        } catch {}

        // No supported royalties configured
        return (recipients, amounts);

    }

    /**
     * Compute royalty amounts
     */
    function _computeAmounts(uint256 value, uint256[] memory bps)
        private
        pure
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](bps.length);
        uint256 totalAmount;
        for (uint256 i = 0; i < bps.length; i++) {
            amounts[i] = (value * bps[i]) / 10000;
            totalAmount += amounts[i];
        }
        if (totalAmount > value ) revert InvalidAmount(totalAmount);
        return amounts;
    }

    constructor(address _royaltyRegistry) {
        ROYALTY_REGISTRY = _royaltyRegistry;
    }
}