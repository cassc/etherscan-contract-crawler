// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@1inch/delegating/contracts/FarmingDelegationPod.sol";
import "./helpers/VotingPowerCalculator.sol";
import "./interfaces/IVotable.sol";
import "./St1inch.sol";

contract PowerPod is FarmingDelegationPod, VotingPowerCalculator, IVotable {
    uint256 private constant _MAX_SHARE_PODS = 3;
    uint256 private constant _SHARE_POD_GAS_LIMIT = 140_000;

    constructor(string memory name_, string memory symbol_, St1inch st1inch)
        FarmingDelegationPod(name_, symbol_, st1inch, _MAX_SHARE_PODS, _SHARE_POD_GAS_LIMIT)
        VotingPowerCalculator(st1inch.expBase(), st1inch.origin())
    {}

    function votingPowerOf(address account) external view virtual returns (uint256) {
        return _votingPowerAt(balanceOf(account), block.timestamp);
    }
}