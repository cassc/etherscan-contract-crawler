/*
    Copyright 2021 Babylon Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
import {UpgradeableBeacon} from '@openzeppelin/contracts/proxy/UpgradeableBeacon.sol';
import {BeaconProxy} from '@openzeppelin/contracts/proxy/BeaconProxy.sol';

/**
 * @title GardenFactory
 * @author Babylon Finance
 *
 * Factory to create garden contracts
 */
contract SafeBeaconProxy is BeaconProxy {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) public payable BeaconProxy(beacon, data) {}

    /**
     * @dev Accepts all ETH transfers but does not proxy calls to the implementation.
     *
     * Due to EIP-2929 the proxy overhead gas cost is higher than 2300 gas which is the stipend used by address.transfer.
     * This results to a `out of gas` error for proxy calls initiated by code `address.transfer`.
     * A notable example is WETH https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
     * A downside of this approach is that a proxy implementation contract can not handle receiving pure ETH.
     * In a scope of Babylon project this is acceptable but should be kept in mind at all times.
     *
     */
    receive() external payable override {}
}