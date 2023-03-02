// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import "./IShields.sol";
import "./IFieldGenerator.sol";
import "./IHardwareGenerator.sol";
import "./IFrameGenerator.sol";

interface IShieldsAPI {
    function getShield(uint256 shieldId)
        external
        view
        returns (IShields.Shield memory);

    function getShieldSVG(uint256 shieldId)
        external
        view
        returns (string memory);

    function getShieldSVG(
        uint16 field,
        uint24[4] memory colors,
        uint16 hardware,
        uint16 frame
    ) external view returns (string memory);

    function isShieldBuilt(uint256 shieldId) external view returns (bool);

    function getField(uint16 field, uint24[4] memory colors)
        external
        view
        returns (IFieldGenerator.FieldData memory);

    function getFieldTitle(uint16 field, uint24[4] memory colors)
        external
        view
        returns (string memory);

    function getFieldSVG(uint16 field, uint24[4] memory colors)
        external
        view
        returns (string memory);

    function getHardware(uint16 hardware)
        external
        view
        returns (IHardwareGenerator.HardwareData memory);

    function getHardwareTitle(uint16 hardware)
        external
        view
        returns (string memory);

    function getHardwareSVG(uint16 hardware)
        external
        view
        returns (string memory);

    function getFrame(uint16 frame)
        external
        view
        returns (IFrameGenerator.FrameData memory);

    function getFrameTitle(uint16 frame) external view returns (string memory);

    function getFrameSVG(uint16 frame) external view returns (string memory);
}