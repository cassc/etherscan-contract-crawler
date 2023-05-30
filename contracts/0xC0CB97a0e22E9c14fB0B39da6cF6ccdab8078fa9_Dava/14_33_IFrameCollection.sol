//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IFrameCollection is IERC165 {
    struct Frame {
        uint256 zIndex;
        string ipfsHash;
    }

    struct FrameWithUri {
        uint256 id;
        string ipfsHash;
        string imgUri;
        uint256 zIndex;
    }

    function frameOf(uint256 frameId)
        external
        view
        returns (FrameWithUri memory);

    function getAllFrames() external view returns (FrameWithUri[] memory);

    function totalFrames() external view returns (uint256);
}