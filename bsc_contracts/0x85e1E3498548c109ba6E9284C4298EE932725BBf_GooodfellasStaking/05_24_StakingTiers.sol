// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

interface ITierLogic {
    function calculateTierBonus(address user, uint256 weight) external;
}

abstract contract StakingTiers {
    using Address for address;

    address private _logic;

    function _upgradeTierLogic(address logic_) internal {
        _logic = logic_;
    }

    function calculateTierBonus(address user, uint256 weight) public view returns (uint256) {
        if (_logic == address(0)) return 0;
        
        bytes memory data = _logic.functionStaticCall(abi.encodeWithSelector(ITierLogic.calculateTierBonus.selector, user, weight));
        return abi.decode(data, (uint256));
    }
}