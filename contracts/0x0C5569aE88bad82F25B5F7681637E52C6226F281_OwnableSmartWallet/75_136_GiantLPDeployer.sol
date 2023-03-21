pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { GiantLP } from "./GiantLP.sol";

contract GiantLPDeployer {

    event NewDeployment(address indexed instance);

    /// @notice Deploy a giant LP on behalf of the LSDN factory
    function deployToken(
        address _pool,
        address _transferHookProcessor,
        string memory _name,
        string memory _symbol
    ) external returns (address) {
        address newToken = address(new GiantLP(_pool, _transferHookProcessor, _name, _symbol));

        emit NewDeployment(newToken);

        return newToken;
    }
}