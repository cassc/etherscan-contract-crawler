// SPDX-License-Identifier: GPL-3.0-or-later

import {ITransferGatewayEvents} from "../_interfaces/bridge-gateways/ITransferGatewayEvents.sol";

contract ChainBridgeTransferGateway is ITransferGatewayEvents {
    // overridden on the base chain gateway (ethereum)
    function validateAndLock(
        address sender,
        address recipientAddressInTargetChain,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external virtual {
        require(false, "Gateway function NOT_IMPLEMENTED");
    }

    // overridden on the base chain gateway (ethereum)
    function unlock(
        address senderAddressInSourceChain,
        address recipient,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external virtual {
        require(false, "Gateway function NOT_IMPLEMENTED");
    }

    // overridden on the satellite chain gateway (tron, acala, near)
    function mint(
        address senderAddressInSourceChain,
        address recipient,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external virtual {
        require(false, "Gateway function NOT_IMPLEMENTED");
    }

    // overridden on the satellite chain gateway (tron, acala, near)
    function validateAndBurn(
        address sender,
        address recipientAddressInTargetChain,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external virtual {
        require(false, "Gateway function NOT_IMPLEMENTED");
    }
}