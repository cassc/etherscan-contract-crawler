// SPDX-License-Identifier: MIT.
pragma solidity 0.8.7;

import "./interfaces/IStarknetMessaging.sol";
import "./interfaces/IStarknetEthBridge.sol";
import "./interfaces/IStarknetERC20Bridge.sol";
import "./interfaces/IWidoRouter.sol";
import "./interfaces/IWidoConfig.sol";
import "solmate/src/utils/SafeTransferLib.sol";
import "./lib/WidoL2Payload.sol";
import "hardhat/console.sol";

contract WidoStarknetRouter {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;
    
    IWidoConfig public immutable widoConfig;
    IStarknetMessaging public immutable starknetCore;

    uint256 constant DESTINATION_PAYLOAD_INPUTS_LEN_INDEX = 0;
    uint256 constant DESTINATION_PAYLOAD_INPUT0_TOKEN_ADDRESS_INDEX = 1;

    uint256 constant UINT256_PART_SIZE_BITS = 128;
    uint256 constant UINT256_PART_SIZE = 2**UINT256_PART_SIZE_BITS;

    // The selector of the "execute" l1_handler in WidoL1Router.cairo
    uint256 constant EXECUTE_SELECTOR = 1017745666394979726211766185068760164586829337678283062942418931026954492996;

    IWidoRouter public immutable widoRouter;
    uint256 public l2WidoRecipient;

    /// @notice Event emitted when the order is fulfilled
    /// @param order The order that was fulfilled
    /// @param sender The msg.sender
    /// @param recipient Recipient of the final tokens of the order
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    event OrderInitiated(
        IWidoRouter.Order order,
        address indexed sender,
        uint256 recipient,
        uint256 feeBps,
        address indexed partner
    );

    constructor(IWidoConfig _widoConfig, IStarknetMessaging _starknetCore, IWidoRouter _widoRouter, uint256 _l2WidoRecipient) {
        widoConfig = _widoConfig;
        
        starknetCore = _starknetCore;
        require(address(_widoRouter) != address(0), "WidoStarknetRouter: widoRouter cannot be address(0)");
        widoRouter = _widoRouter;
        l2WidoRecipient = _l2WidoRecipient;
    }

    function _bridgeTokens(address tokenAddress, uint256 amount, uint256 starknetRecipient, uint256 bridgeFee) internal {
        address bridge = widoConfig.getBridgeAddress(tokenAddress);
        
        if (tokenAddress == address(0)) {
            IStarknetEthBridge(bridge).deposit{value: amount + bridgeFee}(amount, starknetRecipient);
        } else {
            if (ERC20(tokenAddress).allowance(address(this), bridge) < amount) {
                ERC20(tokenAddress).safeApprove(bridge, type(uint256).max);
            }
            IStarknetERC20Bridge(bridge).deposit{value: bridgeFee}(amount, starknetRecipient);
        }
    }

    function _sendMessageToL2(uint256[] memory payload, uint256 destinationTxFee) internal {
        starknetCore.sendMessageToL2{value: destinationTxFee}(
            l2WidoRecipient,
            EXECUTE_SELECTOR,
            payload
        );
    }

    function _pullAndApproveTokens(IWidoRouter.OrderInput[] calldata inputs) internal {
        address widoTokenManager = address(widoRouter.widoTokenManager());
        for (uint256 i = 0; i < inputs.length;) {
            IWidoRouter.OrderInput calldata input = inputs[i];

            unchecked {
                i++;
            }
            if (input.tokenAddress == address(0)) {
                continue;
            }

            ERC20(input.tokenAddress).safeTransferFrom(msg.sender, address(this), input.amount);

            if (ERC20(input.tokenAddress).allowance(address(this), widoTokenManager) < input.amount) {
                ERC20(input.tokenAddress).safeApprove(widoTokenManager, type(uint256).max);
            }
        }
    }

    function executeOrder(
        IWidoRouter.Order calldata order,
        IWidoRouter.Step[] calldata steps,
        uint256 feeBps,
        address partner,
        uint256 l2RecipientUser,
        uint256[] calldata destinationPayload,
        uint256 bridgeFee,
        uint256 destinationTxFee
    ) external payable {
        // Do validations
        require(order.user == address(this), "Order user should equal WidoStarknetRouer");
        require(order.outputs.length == 1, "Only single token output expected");
        require(msg.value >= bridgeFee + destinationTxFee, "Insufficient fee");
        require(feeBps <= 100, "Fee out of range");

        address bridgeTokenAddress = order.outputs[0].tokenAddress;

        if (destinationPayload.length > 0) {
            require(WidoL2Payload.isCoherent(destinationPayload), "Incoherent destination payload");

            // Since the user can only bridge one token, allow only single token to be specified.
            require(destinationPayload[DESTINATION_PAYLOAD_INPUTS_LEN_INDEX] == 1, "Only single token input allowed in destination");

            // Bridge token on L1 should correspond to Bridged Token address on starknet
            uint256 bridgedTokenAddress = widoConfig.getBridgedTokenAddress(bridgeTokenAddress);
            require(destinationPayload[DESTINATION_PAYLOAD_INPUT0_TOKEN_ADDRESS_INDEX] == bridgedTokenAddress, "Bridge Token Mismatch");

            // Ensure that the recipient is same as mentioned in the order.
            require(WidoL2Payload.getRecipient(destinationPayload) == l2RecipientUser, "L2 Recipient Mismatch");
        }

        // Fetch tokens from msg.sender.
        _pullAndApproveTokens(order.inputs);
        
        // Run Execute Order in L1
        if (steps.length > 0) {
            widoRouter.executeOrder{value: msg.value - bridgeFee - destinationTxFee}(order, steps, 0, partner);
        }

        // This amount will be the amount that is to be bridged to starknet.
        // It is the token expected as final output of the Order.
        // The minimum tokens to be bridged can be verified as part of the order, if there are steps. Otherwise,
        // It would be same as the input token.
        uint256 amount;
        {
            uint256 fee;
            address bank = IWidoConfig(widoConfig).getBank();

            if (bridgeTokenAddress == address(0)) {
                amount = address(this).balance - bridgeFee - destinationTxFee;
                fee = (amount * feeBps) / 10000;
                bank.safeTransferETH(fee);
            } else {
                amount = ERC20(bridgeTokenAddress).balanceOf(address(this));
                fee = (amount * feeBps) / 10000;
                ERC20(bridgeTokenAddress).safeTransfer(bank, fee);
            }
        }

        if (destinationPayload.length > 0) {
            uint256 amountLow = amount & (UINT256_PART_SIZE - 1);
            uint256 amountHigh = amount >> UINT256_PART_SIZE_BITS;

            // Update the destination payload input token amount to equal
            // the amount being brided.
            uint256[] memory updatedDestionationPayload = destinationPayload;
            updatedDestionationPayload[2] = amountLow;
            updatedDestionationPayload[3] = amountHigh;

            _bridgeTokens(bridgeTokenAddress, amount, l2WidoRecipient, bridgeFee);

            // Messaging to Wido Starknet contract
            _sendMessageToL2(updatedDestionationPayload, destinationTxFee);
        } else {
            // Send tokens directly to the user
            _bridgeTokens(bridgeTokenAddress, amount, l2RecipientUser, bridgeFee);
        }
        emit OrderInitiated(order, msg.sender, l2RecipientUser, feeBps, partner);
    }

    /// @notice Allow receiving of native tokens
    receive() external payable {}
}