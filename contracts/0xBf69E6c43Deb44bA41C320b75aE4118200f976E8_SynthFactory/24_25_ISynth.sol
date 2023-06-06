// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Should be implemented by "treasury" contract in cases when third party token used instead of our synth.
 *
 * Mint\Burn can be implemented as Lock\Unlock in treasury contract.
 */
interface ISynthAdapter {
    enum SynthType { Unknown, DefaultSynth, CustomSynth, ThirdPartySynth, ThirdPartyToken }

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function setCap(uint256) external;

    function decimals() external view returns (uint8);

    function originalToken() external view returns (address);

    function synthToken() external view returns (address);

    function chainIdFrom() external view returns (uint64); // TODO what if token native in 2-3-4 chains? // []

    function chainSymbolFrom() external view returns (string memory);

    function synthType() external view returns (uint8);

    function cap() external view returns (uint256);

    event CapSet(uint256 cap);
}

interface ISynthERC20 is ISynthAdapter, IERC20 {
    function mintWithAllowanceIncrease(address account, address spender, uint256 amount) external;
    function burnWithAllowanceDecrease(address account, address spender, uint256 amount) external;
}