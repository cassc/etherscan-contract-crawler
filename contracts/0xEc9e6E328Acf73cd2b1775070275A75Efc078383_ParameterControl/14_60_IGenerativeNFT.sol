// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../lib/helpers/BoilerplateParam.sol";

interface IGenerativeNFT {
    function mint(address mintTo, address creator, string memory uri, BoilerplateParam.ParamsOfProject calldata _paramsTemplateValue, bool clientSeed) external;

    function init(
        string memory name,
        string memory symbol,
        address admin,
        address boilerplateAdd,
        uint256 boilerplateId
    ) external;
}