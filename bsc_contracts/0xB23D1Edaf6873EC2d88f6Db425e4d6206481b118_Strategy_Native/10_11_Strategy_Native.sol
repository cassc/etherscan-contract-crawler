// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Strategy.sol";

contract Strategy_Native is Strategy {
    address public earned0Address;
    address[] public earned0ToEarnedPath;

    constructor(
        address[] memory _addresses,
        address[] memory _tokenAddresses,
        bool _isSingleVault,
        uint256 _withdrawFeeFactor
    ) public {
        vault = _addresses[0];
        govAddress = _addresses[1];

        wantAddress = _tokenAddresses[0];

        isSingleVault = _isSingleVault;
        isAutoComp = false;

        withdrawFeeFactor = _withdrawFeeFactor;
    }

    // not used
    function _farm() internal override {}
    // not used
    function _unfarm(uint256 _wantAmt) internal override {}
    // not used
    function _harvest() internal override {}
    // not used
    function earn() public override {}
    // not used
    function distributeFees(uint256 _earnedAmt) internal override returns (uint256) {}
    // not used
    function convertDustToEarned() public override {}
}