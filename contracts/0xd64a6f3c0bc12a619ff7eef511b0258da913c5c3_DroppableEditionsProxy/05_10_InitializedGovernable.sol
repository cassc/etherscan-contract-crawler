// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {Ownable} from "../lib/Ownable.sol";
import {IGovernable} from "../lib/interface/IGovernable.sol";

contract InitializedGovernable is Ownable, IGovernable {
    // ============ Events ============

    event GovernorChanged(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    // ============ Mutable Storage ============

    // Mirror governance contract.
    address public override governor;

    // ============ Modifiers ============

    modifier onlyGovernance() {
        require(isOwner() || isGovernor(), "caller is not governance");
        _;
    }

    modifier onlyGovernor() {
        require(isGovernor(), "caller is not governor");
        _;
    }

    // ============ Constructor ============

    constructor(address owner_, address governor_) Ownable(owner_) {
        _setGovernor(governor_);
    }

    // ============ Administration ============

    function changeGovernor(address governor_) public override onlyGovernance {
        _setGovernor(governor_);
    }

    // ============ Utility Functions ============

    function isGovernor() public view override returns (bool) {
        return msg.sender == governor;
    }

    // ============ Internal Functions ============

    function _setGovernor(address governor_) internal {
        emit GovernorChanged(governor, governor_);

        governor = governor_;
    }
}