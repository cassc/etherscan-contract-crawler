/*

    Copyright 2022 31Third B.V.

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

contract AaveV2Adapter is IExchangeAdapter {
    /*** ### Events ### ***/

    event AaveV2AdapterDeployed(
        address _aavePoolAddress
    );

    address public immutable aavePoolAddress;

    address public immutable getSpender;

    /*** ### constructor ### ***/

    constructor(address _aavePoolAddress) {
        require(_aavePoolAddress != address(0), "aave pool address is required");

        aavePoolAddress = _aavePoolAddress;
        getSpender = _aavePoolAddress;

        emit AaveV2AdapterDeployed(_aavePoolAddress);
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
        aavePoolAddress,
        0,
        _data
        );
    }
}