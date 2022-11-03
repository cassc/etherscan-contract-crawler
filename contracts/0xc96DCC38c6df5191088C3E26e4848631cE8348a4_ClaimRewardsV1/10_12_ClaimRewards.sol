// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {StringV1} from "../libraries/StringV1.sol";
import {IClaimRewards} from "./IClaimRewards.sol";

contract ClaimRewardsStateV1 {
    uint256 internal _nextClaimNonce;

    uint256[49] private __gap;
}

contract ClaimRewardsV1 is Initializable, ClaimRewardsStateV1, IClaimRewards {
    uint256 public constant BPS_DENOMINATOR = 10000;

    event LogClaimRewards(
        uint256 indexed claimNonce,
        address indexed operatorAddress,
        string assetSymbol,
        string recipientAddress,
        string recipientChain,
        bytes recipientPayload,
        uint256 fractionInBps,
        // Repeated values for indexing.
        string indexed assetSymbolIndexed
    );

    function __ClaimRewards_init() public initializer {}

    function getNextClaimNonce() public view returns (uint256) {
        return _nextClaimNonce;
    }

    /**
     * claimRewardsToChain allows darknode operators to withdraw darknode
     * earnings, as an on-chain alternative to the JSON-RPC claim method.
     *
     * It will the operators total sum of rewards, for all of their nodes.
     *
     * @param assetSymbol The token symbol being claimed (e.g. "BTC", "DOGE" or
     *        "FIL").
     * @param recipientAddress An address on the asset's native chain, for
     *        receiving the withdrawn rewards. This should be a string as
     *        provided by the user - no encoding or decoding required.
     *        E.g.: "miMi2VET41YV1j6SDNTeZoPBbmH8B4nEx6" for BTC.
     * @param recipientChain A string indicating which chain the rewards should
     *        be withdrawn to. It should be the name of the chain as expected by
     *        RenVM (e.g. "Ethereum" or "Solana"). Support for different chains
     *        will be rolled out after this contract is deployed, starting with
     *        "Ethereum", then other host chains (e.g. "Polygon" or "Solana")
     *        and then lock chains (e.g. "Bitcoin" for "BTC"), also represented
     *        by an empty string "".
     * @param recipientPayload An associated payload that can be provided along
     *        with the recipient chain and address. Should be empty if not
     *        required.
     * @param fractionInBps A value between 0 and 10000 (inclusive) that
     *        indicates the percent to withdraw from each of the operator's
     *        darknodes. The value should be in BPS (e.g. 10000 represents 100%,
     *        and 5000 represents 50%).
     */
    function claimRewardsToChain(
        string memory assetSymbol,
        string memory recipientAddress,
        string memory recipientChain,
        bytes memory recipientPayload,
        uint256 fractionInBps
    ) public returns (uint256) {
        // Validate asset symbol.
        require(StringV1.isNotEmpty(assetSymbol), "ClaimRewards: invalid empty asset");
        require(StringV1.isAlphanumeric(assetSymbol), "ClaimRewards: invalid asset");

        // Validate recipient address.
        require(StringV1.isNotEmpty(recipientAddress), "ClaimRewards: invalid empty recipient address");
        require(StringV1.isAlphanumeric(recipientAddress), "ClaimRewards: invalid recipient address");

        // Validate recipient chain.
        // Note that the chain can be empty - which is planned to represent the
        // asset's native lock chain.
        require(StringV1.isAlphanumeric(recipientChain), "ClaimRewards: invalid recipient chain");

        // Validate the fraction being withdrawn.
        require(fractionInBps <= BPS_DENOMINATOR, "ClaimRewards: invalid fraction value greater than 10000");

        address operatorAddress = msg.sender;

        uint256 nonce = getNextClaimNonce();
        _nextClaimNonce = nonce + 1;

        // Emit event.
        emit LogClaimRewards(
            nonce,
            operatorAddress,
            assetSymbol,
            recipientAddress,
            recipientChain,
            recipientPayload,
            fractionInBps,
            // Indexed
            assetSymbol
        );

        return nonce;
    }

    /**
     * `claimRewardsToEthereum` calls `claimRewardsToChain` internally,
     * converting the recipientAddress to a string and providing an empty
     * payload.
     */
    function claimRewardsToEthereum(
        string memory assetSymbol,
        address recipientAddress,
        uint256 fractionInBps
    ) public override returns (uint256) {
        return
            claimRewardsToChain(
                assetSymbol,
                StringsUpgradeable.toHexString(uint160(recipientAddress), 20),
                "Ethereum",
                "",
                fractionInBps
            );
    }
}

contract ClaimRewardsProxy is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin,
        bytes memory data
    ) TransparentUpgradeableProxy(logic, admin, data) {}
}