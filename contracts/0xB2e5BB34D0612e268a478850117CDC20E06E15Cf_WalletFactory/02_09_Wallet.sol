pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IWalletFactory.sol";

contract Wallet is ReentrancyGuard {
    uint256 public nonce;
    address public owner;
    address public factory;
    bytes public lastInstructions;
    bytes[] public lastReturnsData;

    struct Delegator {
        address target;
        uint256 value;
        bytes payload;
        bool isInternalValue;
        bool isDelegate;
    }

    event ChainExecuted (
        uint256 indexed nonce,
        bytes payload,
        bytes[] returnsData
    );

    receive() external payable {}

    constructor(address _owner) {
        factory = msg.sender;
        owner = _owner;
    }

    function execute(bytes calldata _instructions, bytes calldata _signature)
        external
        nonReentrant
        payable
    {
        require(msg.sender == owner, "Wallet: Only owner allowed to execute this func");
        require(
            IWalletFactory(factory).verify(_instructions, _signature),
            "Wallet: Invalid signature"
        );
        (uint256 trxNonce, address user, Delegator[] memory delegator) = abi.decode(
            _instructions,
            (uint256, address, Delegator[])
        );
        require(trxNonce == nonce, "Wallet: Invalid nonce");
        require(user == owner, "Wallet: Invalid user");
        require(delegator.length > 0, "Wallet: No delegators");
        nonce++;

        uint256 valueCheck;
        for (uint256 i = 0; i < delegator.length; i++) {
            if (!delegator[i].isInternalValue) {
                valueCheck += delegator[i].value;
            }
        }
        require(msg.value >= valueCheck, "Wallet: Value is not enough");
        lastInstructions = _instructions;
        delete lastReturnsData;

        for (uint256 i = 0; i < delegator.length; i++) {
            if (delegator[i].isDelegate) {
                (bool success, bytes memory returnsData) = address(
                    delegator[i].target
                ).delegatecall(delegator[i].payload);
                require(success, "Wallet: Trxs chain error");
                lastReturnsData.push(returnsData);
            } else {
                (bool success, bytes memory returnsData) = address(
                    delegator[i].target
                ).call{value: delegator[i].value}(delegator[i].payload);
                require(success, "Wallet: Trxs chain error");
                lastReturnsData.push(returnsData);
            }
        }

        emit ChainExecuted(nonce - 1, _instructions, lastReturnsData);
    }

    function getTokenAmount(address _token) external view returns (uint256) {
        require(_token != address(0), "Wallet: Invalid token address");
        return IERC20(_token).balanceOf(address(this));
    }

    function getETHAmount() external view returns (uint256) {
        return address(this).balance;
    }
    
}