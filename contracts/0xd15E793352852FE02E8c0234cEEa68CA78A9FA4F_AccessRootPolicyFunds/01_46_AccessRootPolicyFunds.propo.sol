// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../policy/Policy.sol";
import "../../../policy/Policed.sol";
import "./Proposal.sol";
import "../../../currency/ECO.sol";
import "../../../currency/ECOx.sol";

/** @title DeployRootPolicyFundw
 * A proposal to send some root policy funds to another
 * address (multisig, lockup, etc)
 */
contract AccessRootPolicyFunds is Policy, Proposal {
    address public immutable recipient;

    uint256 public immutable ecoAmount;

    uint256 public immutable ecoXAmount;

    constructor(
        address _recipient,
        uint256 _ecoAmount,
        uint256 _ecoXAmount
    ) {
        recipient = _recipient;
        ecoAmount = _ecoAmount;
        ecoXAmount = _ecoXAmount;
    }

    function name() public pure override returns (string memory) {
        return "EGP #007 Website development for the Russian-speaking Eco Community";
    }

    function description() public pure override returns (string memory) {
        return
            "This proposal outlines the building of a central source of Eco-relevant information and updates for non-English speaking community members.";
    }

    function url() public pure override returns (string memory) {
        return
            "https://forums.eco.org/t/updated-egp-007-website-development-for-the-russian-speaking-eco-community/108";
    }

    function enacted(address) public override {
        bytes32 _ecoID = keccak256("ECO");
        ECO eco = ECO(policyFor(_ecoID));

        bytes32 _ecoXID = keccak256("ECOx");
        ECOx ecoX = ECOx(policyFor(_ecoXID));

        // if either ecoAmount or ecoXAmount are zero, parts related to that token should instead be removed
        eco.transfer(recipient, ecoAmount);
        ecoX.transfer(recipient, ecoXAmount);
    }
}