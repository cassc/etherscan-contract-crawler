// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../lib/helpers/BoilerplateParam.sol";


interface IGenerativeBoilerplateNFT {
    //    event GenerateSeeds(address sender, uint256 projectId, bytes32[] seeds);
    event MintBatchNFT(address sender, MintRequest request);

    struct MintRequest {
        uint256 _fromProjectId;
        address _mintTo;
        string[] _uriBatch;
        BoilerplateParam.ParamsOfNFT[] _paramsBatch;
    }

    function exists(uint256 _id) external view returns (bool);

    function getParamsTemplate(uint256 id) external view returns (BoilerplateParam.ParamsOfProject memory);
}