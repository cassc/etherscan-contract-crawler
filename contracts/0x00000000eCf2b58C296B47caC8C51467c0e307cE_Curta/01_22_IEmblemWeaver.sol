// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import "./IShields.sol";
import "./IFrameGenerator.sol";
import "./IFieldGenerator.sol";
import "./IHardwareGenerator.sol";
import "./IShieldBadgeSVGs.sol";

interface IEmblemWeaver {
    function fieldGenerator() external returns (IFieldGenerator);

    function hardwareGenerator() external returns (IHardwareGenerator);

    function frameGenerator() external returns (IFrameGenerator);

    function shieldBadgeSVGGenerator() external returns (IShieldBadgeSVGs);

    function generateShieldURI(IShields.Shield memory shield)
        external
        view
        returns (string memory);

    function generateShieldBadgeURI(IShields.ShieldBadge shieldBadge)
        external
        view
        returns (string memory);
}