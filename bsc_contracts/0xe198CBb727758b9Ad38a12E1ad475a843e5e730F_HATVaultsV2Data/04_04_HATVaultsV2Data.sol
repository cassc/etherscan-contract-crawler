// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/IHATVaultsV2.sol";
import "../interfaces/IHATVaultsData.sol";

contract HATVaultsV2Data is IHATVaultsData {
    IHATVaultsV2 public hatVaults;

    constructor(IHATVaultsV2 _hatVaults) {
        hatVaults = _hatVaults;
    }

    function getTotalShares(uint256 _pid) external view returns (uint256) {
        return hatVaults.hatVaults(_pid).totalSupply();
    }

    function getShares(uint256 _pid, address _user) external view returns (uint256) {
        return hatVaults.hatVaults(_pid).balanceOf(_user);
    }
}