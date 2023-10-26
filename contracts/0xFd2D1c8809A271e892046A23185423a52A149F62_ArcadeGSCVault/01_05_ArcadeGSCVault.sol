// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./external/council/vaults/GSCVault.sol";

/**
 * @title ArcadeGSCVault
 * @author Non-Fungible Technologies, Inc.
 *
 * The Arcade GSC Voting Vault contract enables a 'council' of delegates who act as a steering committee
 * for the Arcade DAO.
 *
 * This GSC voting vault gives one vote to each member of the GSC council. To become a member of the GSC council,
 * a user must meet a minimum voting power threshold and prove their membership on chain. Members can be kicked
 * off the council if their voting power falls below the minimum threshold. The voting parameters in the GSC Vault
 * can only be set by the Arcade DAO not the GSC committee.
 *
 * Members of the GSC council in the Arcade DAO have a few unique abilities in the context of governance. They
 * can propose on-chain DAO votes directly, without meeting voting power requirements for proposal creation. They
 * can extend the locking period of a proposal in the timelock, as well as execute small spends from the Treasury
 * without votes from DAO participants. Additionally, GSC votes only need to be approved by GSC members and not by
 * the entire DAO.
 */
contract ArcadeGSCVault is GSCVault {
    // ==================================== CONSTRUCTOR ================================================

    /**
     * @notice Constructs the contract and initial variables.
     *
     * @param coreVoting                The core voting contract.
     * @param votingPowerBound          The amount of voting power needed to be on the GSC.
     * @param owner                     The owner of this contract.
     */
    constructor(
        ICoreVoting coreVoting,
        uint256 votingPowerBound,
        address owner
    ) GSCVault(coreVoting, votingPowerBound, owner) {}
}