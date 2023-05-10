// SPDX-License-Identifier: AGPL-3.0-or-later

/// AAVEAdapter.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

import "../helpers/AaveV3ProxyActions.sol";
import "../interfaces/IAccountImplementation.sol";
import "../interfaces/IAdapter.sol";
import "../McdView.sol";

contract AAVEAdapter is IExecutableAdapter {
    address public immutable aavePA;
    address public immutable botAddress;
    string private constant AAVE_PROXY_ACTIONS = "AAVE_PROXY_ACTIONS";
    string private constant AUTOMATION_BOT_KEY = "AUTOMATION_BOT_V2";

    constructor(ServiceRegistry _serviceRegistry) {
        aavePA = _serviceRegistry.getRegisteredService(AAVE_PROXY_ACTIONS);
        botAddress = _serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
    }

    function decode(
        bytes memory triggerData
    )
        public
        pure
        returns (address proxyAddress, uint256 triggerType, uint256 maxCoverage, address debtToken)
    {
        (proxyAddress, triggerType, maxCoverage, debtToken) = abi.decode(
            triggerData,
            (address, uint16, uint256, address)
        );
    }

    function getCoverage(
        bytes memory triggerData,
        address receiver,
        address coverageToken,
        uint256 amount
    ) external {
        require(msg.sender == botAddress, "aave-adapter/only-bot");
        (address proxy, , uint256 maxCoverage, address debtToken) = decode(triggerData);
        require(debtToken == coverageToken, "aave-adapter/invalid-coverage-token");
        require(amount <= maxCoverage, "aave-adapter/coverage-too-high");
        //reverts if code fails
        IAccountImplementation(proxy).execute(
            aavePA,
            abi.encodeWithSelector(
                AaveV3ProxyActions.drawDebt.selector,
                coverageToken,
                receiver,
                amount
            )
        );
    }
}