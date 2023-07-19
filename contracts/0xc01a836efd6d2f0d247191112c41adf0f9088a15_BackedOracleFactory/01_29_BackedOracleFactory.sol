/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2021-2023 Backed Finance AG
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./BackedOracle.sol";
import "./BackedOracleForwarder.sol";

/**
 * @dev
 * TransparentUpgradeableProxy contract, renamed as BackedOracleProxy.
 */
contract BackedOracleProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, _admin, _data) {}
}

contract BackedOracleFactory is Ownable {
    ProxyAdmin public proxyAdmin;
    TimelockController public timelockController;
    BackedOracle public implementation;

    event NewOracle(address indexed newOracle);
    event NewOracleForwarder(address indexed newOracleForwarder);
    event NewImplementation(address indexed newImplementation);

    /**
     * @param admin- The address of the account that will be set as owner of the deployed ProxyAdmin and will have the
     *      timelock admin role for the timelock contract
     */
    constructor(address admin, address[] memory timelockWorkers) {
        require(
            admin != address(0),
            "Factory: address should not be 0"
        );

        implementation = new BackedOracle();

        proxyAdmin = new ProxyAdmin();

        timelockController = new TimelockController(
            7 days,
            timelockWorkers,
            timelockWorkers
        );

        proxyAdmin.transferOwnership(address(timelockController));
        timelockController.grantRole(timelockController.TIMELOCK_ADMIN_ROLE(), admin);
    }

    function deployOracle(
        uint8 decimals,
        string memory description,
        address oracleUpdater
    ) external onlyOwner returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(description));

        BackedOracleProxy proxy = new BackedOracleProxy{salt: salt}(
            address(implementation),
            address(proxyAdmin),
            abi.encodeWithSelector(
                BackedOracle(address(0)).initialize.selector,
                decimals,
                description,
                address(timelockController),
                oracleUpdater
            )
        );

        emit NewOracle(address(proxy));

        BackedOracleForwarder forwarder = new BackedOracleForwarder{salt: salt}(
            address(proxy),
            address(timelockController)
        );
        emit NewOracleForwarder(address(forwarder));

        return address(forwarder);
    }

    /**
     * @dev Update the implementation for future deployments
     *
     * Emits a { NewImplementation } event
     *
     * @param newImplementation - the address of the new implementation
     */
    function updateImplementation(
        address newImplementation
    ) external onlyOwner {
        require(
            newImplementation != address(0),
            "Factory: address should not be 0"
        );

        implementation = BackedOracle(newImplementation);

        emit NewImplementation(newImplementation);
    }
}