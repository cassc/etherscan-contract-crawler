// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

interface IStakingTierProvider {
    function getTier(address user) external view returns (uint256);
}

abstract contract StakingTierProvider {
    using Address for address;

    address private _provider;

    function _upgradeTierProvider(address provider_) internal {
        _provider = provider_;
    }

    function getTier(address user) public view returns (uint256) {
        if (_provider == address(0)) return 4;
        
        bytes memory data = _provider.functionStaticCall(abi.encodeWithSelector(IStakingTierProvider.getTier.selector, user));
        return abi.decode(data, (uint256));
    }
}