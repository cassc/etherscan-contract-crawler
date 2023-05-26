// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './IShields.sol';
import './IFrameGenerator.sol';
import './IFieldGenerator.sol';
import './IHardwareGenerator.sol';

/// @dev Generate Customizable Shields
interface IEmblemWeaver {
    function fieldGenerator() external returns (IFieldGenerator);

    function hardwareGenerator() external returns (IHardwareGenerator);

    function frameGenerator() external returns (IFrameGenerator);

    function generateShieldURI(IShields.Shield memory shield) external view returns (string memory);

    function generateShieldBadgeURI(IShields.ShieldBadge shieldBadge) external view returns (string memory);
}