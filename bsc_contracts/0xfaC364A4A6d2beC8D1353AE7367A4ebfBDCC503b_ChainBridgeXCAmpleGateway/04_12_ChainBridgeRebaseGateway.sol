// SPDX-License-Identifier: GPL-3.0-or-later

import {IRebaseGatewayEvents} from "../_interfaces/bridge-gateways/IRebaseGatewayEvents.sol";

contract ChainBridgeRebaseGateway is IRebaseGatewayEvents {
    // overridden on the base chain gateway (ethereum)
    function validateRebaseReport(uint256 globalAmpleforthEpoch, uint256 globalAMPLSupply)
        external
        virtual
    {
        require(false, "Gateway function NOT_IMPLEMENTED");
    }

    // overridden on the satellite chain gateway (tron, acala, near)
    function reportRebase(uint256 globalAmpleforthEpoch, uint256 globalAMPLSupply)
        external
        virtual
    {
        require(false, "Gateway function NOT_IMPLEMENTED");
    }
}