pragma solidity ^0.8.13;

import {IL1GatewayRouter} from "arbitrum/tokenbridge/ethereum/gateway/IL1GatewayRouter.sol";
import {IInbox} from "arbitrum-nitro/contracts/src/bridge/IInbox.sol";
import "src/arbi-fed/ArbiGasManager.sol";

contract ArbiGovMessengerL1 is ArbiGasManager{
    IL1GatewayRouter public immutable gatewayRouter = IL1GatewayRouter(0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef); 
    
    IInbox public inbox;
    mapping(address => bool) public allowList;

    event MessageSent(address to, bytes data);

    constructor (address _gov, address _inbox, address _gasClerk) ArbiGasManager(gov, _gasClerk){
        gov = _gov;
        inbox = IInbox(_inbox);
    }

    error OnlyAllowed();

    modifier onlyAllowed {
        if (msg.sender != gov && !allowList[msg.sender]) revert OnlyAllowed();
        _;
    }
    /**
     * @notice Generalized function for sending messages to Arbitrum
     * @dev Call value of the function should be the funds necessary for gasLimit * gasPrice
     * @param _to The destination L2 address
     * @param _refundTo The L2 address to which the excess fee is credited (l1CallValue - (autoredeem ? ticket execution cost : submission cost) - l2CallValue)
     * @param _callValueRefundAddress The L2 address to which the l2CallValue is credited if the ticket times out or gets cancelled (this is also called the `beneficiary`, who's got a critical permission to cancel the ticket)
     * @param _l2CallValue The callvalue for retryable L2 message that is supplied within the deposit (l1CallValue)
     * @param _l2GasParams A struct consisting of three variables:
        - `uint256 maxSubmissionCost`: The maximum amount of ETH to be paid for submitting the ticket. This amount is (1) supplied within the deposit (l1CallValue) to be later deducted from sender's L2 balance and is (2) directly proportional to the size of the retryable’s data and L1 basefee
        - `uint256 gasLimit`: Maximum amount of gas used to cover L2 execution of the ticket
        - `uint256 maxFeePerGas`: The gas price bid for L2 execution of the ticket that is supplied within the deposit (l1CallValue)
     * @param _data The calldata to the destination L2 address
     */    
    function sendMessage(
        address _to,
        address _refundTo,
        address _callValueRefundAddress,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        L2GasParams memory _l2GasParams,
        bytes memory _data
    ) external payable onlyAllowed() returns (uint256) {
        
        emit MessageSent(_to, _data);

        return inbox.createRetryableTicket{ value: _l1CallValue }(
            _to,
            _l2CallValue,
            _l2GasParams._maxSubmissionCost,
            _refundTo, // only refund excess fee to the custom address
            _callValueRefundAddress, // user can cancel the retryable and receive call value refund
            _l2GasParams._maxGas,
            _l2GasParams._gasPriceBid,
            _data
        );
    }

    /**
     * @notice Send message to L2 address
     * @dev This function automatically handles gas estimation. Default gas limit may be too low to execute.
     * @param _to L2 address to send message to
     * @param _functionSelector Function selector of the function to call at the L2 address
     * @param _data The calldata to the L2 address
     */
    function sendMessage(
        address _to,
        bytes4 _functionSelector,
        bytes calldata _data
    ) external payable onlyAllowed() returns (uint256) {
        emit MessageSent(_to, _data);
        bytes32 functionId = keccak256(abi.encodePacked(_functionSelector, _to)); //Hash of address + functionSelector should be collision resistant
        uint gasLimit = functionGasLimit[functionId];
        if(gasLimit == 0) gasLimit = defaultGasLimit;

        return inbox.createRetryableTicket{ value: gasLimit * gasPrice + maxSubmissionCost}(
            _to,
            0,
            maxSubmissionCost,
            refundAddress,
            refundAddress, // refundAddress can cancel the retryable ticket and receive call value refund
            gasLimit,
            gasPrice,
            _data
        );
    }

    /**
     * @notice Sets the arbitrum bridge inbox
     * @param _newInbox Address of the new inbox
     */
    function setInbox(address _newInbox) external onlyGov {
        inbox = IInbox(_newInbox);
    }

    /**
     * @notice Sets the status of an address that is allowed to send messages on behalf of gov on L2
     * @dev Allows for the creation of governance contracts for specific contracts, simplifying proposal making. Should never allow an EOA, MSIG or upgradeable contract.
     * @param allowee Address of the contract to set allowed status for
     * @param isAllowed true for allowing a contract, false for disallowing
     */
    function setAllowed(address allowee, bool isAllowed) external onlyGov {
        allowList[allowee] = isAllowed;
    }

    /**
     * @notice Sweep Eth to gov
     */
    function sweepEth() external onlyGov {
        uint amount = address(this).balance;
        payable(gov).transfer(amount);
    }

    receive() external payable{}
}