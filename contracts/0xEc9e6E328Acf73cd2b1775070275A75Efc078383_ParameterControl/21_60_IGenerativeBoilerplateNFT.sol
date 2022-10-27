// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../lib/helpers/BoilerplateParam.sol";


interface IGenerativeBoilerplateNFT {
    event GenerateSeeds(address sender, uint256 projectId, bytes32[] seeds);
    event MintBatchNFT(address sender, MintRequest request);

    struct MintRequest {
        uint256 _fromProjectId;
        address _mintTo;
        string[] _uriBatch;
        BoilerplateParam.ParamsOfProject[] _paramsBatch;
    }

    function transferSeed(
        address from,
        address to,
        bytes32 seed, uint256 projectId
    ) external;
}