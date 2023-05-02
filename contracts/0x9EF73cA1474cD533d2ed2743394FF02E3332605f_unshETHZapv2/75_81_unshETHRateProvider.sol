// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


interface IRateProvider {
    function getRate() external view returns (uint256);
}

interface ILSDVault {
    function stakedETHperunshETH() external view returns (uint256);
}

interface IunshETH {
    function timelock_address() external view returns (address);
}


/**
 * @title unshETH Rate Provider
 * @notice Returns the value of unshETH in terms of ETH
 */
contract unshETHRateProvider is IRateProvider {

    address public constant unshethAddress = 0x0Ae38f7E10A43B5b2fB064B42a2f4514cbA909ef;

    constructor() { }

    /**
     * @return the value of unshETH in terms of stETH
     */
    function getRate() external view override returns (uint256) {
        address vaultAddress = IunshETH(unshethAddress).timelock_address();
        ILSDVault vault = ILSDVault(vaultAddress);
        return vault.stakedETHperunshETH();
    }
}