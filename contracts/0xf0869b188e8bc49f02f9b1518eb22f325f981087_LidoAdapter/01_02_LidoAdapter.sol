/*

    Copyright 2023 31Third B.V.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import "../IExchangeAdapter.sol";

contract LidoAdapter is IExchangeAdapter {
    /*** ### Events ### ***/

    event LidoAdapterDeployed(
        address lidoAddress
    );

    address public immutable lidoAddress;

    address public immutable getSpender;

    /*** ### constructor ### ***/

    constructor(address _lidoAddress) {
        require(_lidoAddress != address(0), "Lido address is required");

        lidoAddress = _lidoAddress;
        getSpender = _lidoAddress;

        emit LidoAdapterDeployed(_lidoAddress);
    }

    /*** ### External Getter Functions ### ***/

    function getTradeCalldata(
        address _from,
        uint256 _fromAmount,
        address _to,
        uint256 _minToReceive,
        address _taker,
        uint256 _value,
        bytes calldata _data
    ) external view returns (address, uint256, bytes memory) {
        return (
        lidoAddress,
        _fromAmount,
        _data
        );
    }
}