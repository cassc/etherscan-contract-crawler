// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

interface IReentryProvider {
    function getReentries(address user, uint256 tier) external view returns (uint256);
}

abstract contract ReentryProvider {
    using Address for address;

    address private _provider;

    function _upgradeReentriesProvider(address provider_) internal {
        _provider = provider_;
    }

    function getReentries(address user, uint256 tier) public view returns (uint256) {
        if (_provider == address(0)) return (tier == 4) ? 1 : (4 - tier);
        
        bytes memory data = _provider.functionStaticCall(abi.encodeWithSelector(IReentryProvider.getReentries.selector, user, tier));
        return abi.decode(data, (uint256));
    }
}