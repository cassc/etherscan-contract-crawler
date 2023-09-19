// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library OrbitProxy {
    // AIORBIT Contract Used To Forge AIBOLT (This Contract)

    struct CommonValues {
        uint256 hue;
        uint256 rotationSpeed;
        uint256 numCircles;
        uint256[] radius;
        uint256[] distance;
        uint256[] strokeWidth;
    }

    function generateAIORBITTraits(
        uint256 _tokenId
    ) public pure returns (CommonValues memory) {
        uint256 hue = uint256(keccak256(abi.encodePacked(_tokenId, "hue"))) %
            360;
        uint256 rotationSpeed = (uint256(
            keccak256(abi.encodePacked(_tokenId, "rotationSpeed"))
        ) % 11) + 5;

        uint256 numCircles = (uint256(
            keccak256(abi.encodePacked(_tokenId, "numCircles"))
        ) % 3) + 3;
        uint256[] memory radius = new uint256[](numCircles);
        uint256[] memory distance = new uint256[](numCircles);
        uint256[] memory strokeWidth = new uint256[](numCircles);

        for (uint256 i = 0; i < numCircles; i++) {
            radius[i] =
                (uint256(keccak256(abi.encodePacked(_tokenId, "radius", i))) %
                    40) +
                20;
            distance[i] =
                (uint256(keccak256(abi.encodePacked(_tokenId, "distance", i))) %
                    80) +
                40;
            strokeWidth[i] =
                (uint256(
                    keccak256(abi.encodePacked(_tokenId, "strokeWidth", i))
                ) % 16) +
                5;
        }

        return
            CommonValues(
                hue,
                rotationSpeed,
                numCircles,
                radius,
                distance,
                strokeWidth
            );
    }
}