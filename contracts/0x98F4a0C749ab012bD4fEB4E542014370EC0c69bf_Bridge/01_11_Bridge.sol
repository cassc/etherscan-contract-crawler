// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bridge is CCIPReceiver, OwnerIsCreator {
    IRouterClient router;
    IERC20 clh;
    mapping(uint64 => bool) public allowChainSelector;
    event TokenMove(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        uint256 amount,
        uint256 fees
    );
    event SetAlowChain(uint64 chainSelector, bool allow);

    constructor(address _router, address _clh) CCIPReceiver(_router) {
        router = IRouterClient(_router);
        clh = IERC20(_clh);
    }

    /// handle a received message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {}

    function calculatedFees(
        uint64 destinationChainSelector,
        uint256 amount
    ) external view returns (uint256) {
        Client.EVMTokenAmount[]
            memory _tokenAmounts = new Client.EVMTokenAmount[](1);
        _tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(clh),
            amount: amount
        });
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encode(msg.sender),
            tokenAmounts: _tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
            ),
            feeToken: address(0)
        });
        return router.getFee(destinationChainSelector, evm2AnyMessage);
    }

    function moveToChain(
        uint64 destinationChainSelector,
        uint256 amount
    ) external payable returns (bytes32 messageId) {
        require(
            allowChainSelector[destinationChainSelector],
            "not allow chain"
        );
        clh.transferFrom(msg.sender, address(this), amount);
        clh.approve(address(router), amount);
        Client.EVMTokenAmount[]
            memory _tokenAmounts = new Client.EVMTokenAmount[](1);
        _tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(clh),
            amount: amount
        });
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(msg.sender),
            data: "",
            tokenAmounts: _tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
            ),
            feeToken: address(0)
        });
        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);
        require(msg.value >= fees, "Insufficient funds");
        if (msg.value - fees > 0) {
            bool success = payable(msg.sender).send(msg.value - fees);
            require(success, "Transfer failed");
        }
        messageId = router.ccipSend{value: fees}(
            destinationChainSelector,
            evm2AnyMessage
        );
        emit TokenMove(
            messageId,
            destinationChainSelector,
            msg.sender,
            amount,
            fees
        );
        return messageId;
    }

    function setAlowChain(uint64 chainSelector, bool allow) external onlyOwner {
        allowChainSelector[chainSelector] = allow;
        emit SetAlowChain(chainSelector, allow);
    }
}