//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {OnlySocketGatewayOwner} from "../errors/SocketErrors.sol";

contract DisabledSocketRoute {
    using SafeTransferLib for ERC20;

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketGateway;
    error RouteDisabled();

    /**
     * @notice Construct the base for all BridgeImplementations.
     * @param _socketGateway Socketgateway address, an immutable variable to set.
     */
    constructor(address _socketGateway) {
        socketGateway = _socketGateway;
    }

    /// @notice Implementing contract needs to make use of the modifier where restricted access is to be used
    modifier isSocketGatewayOwner() {
        if (msg.sender != ISocketGateway(socketGateway).owner()) {
            revert OnlySocketGatewayOwner();
        }
        _;
    }

    /**
     * @notice function to rescue the ERC20 tokens in the bridge Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param token address of ERC20 token being rescued
     * @param userAddress receipient address to which ERC20 tokens will be rescued to
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice function to rescue the native-balance in the bridge Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param userAddress receipient address to which native-balance will be rescued to
     * @param amount amount of native balance tokens being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        userAddress.transfer(amount);
    }

    /**
     * @notice Handle route function calls gracefully.
     */
    fallback() external payable {
        revert RouteDisabled();
    }

    /**
     * @notice Support receiving ether to handle refunds etc.
     */
    receive() external payable {}
}