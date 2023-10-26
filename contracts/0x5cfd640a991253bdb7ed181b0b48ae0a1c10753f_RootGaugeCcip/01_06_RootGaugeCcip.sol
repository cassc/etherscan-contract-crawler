// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

/**
 * @title Root-Chain Gauge CCTP Transfer
 * @author DFX Finance
 * @notice Receives total allocated weekly DFX emission mints and sends to L2 gauge
 */
import "IERC20.sol";
import "Initializable.sol";
import {Client} from "Client.sol";
import {IRouterClient} from "IRouterClient.sol";

contract RootGaugeCcip is Initializable {
    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance to cover the fees.

    /// @notice An event emitted when a message is sent to another chain.
    /// @param messageId The unique ID of the CCIP message.
    /// @param destinationChainSelector The chain selector of the destination chain.
    /// @param receiver The address of the receiver on the destination chain.
    /// @param token The token address that was transferred.
    /// @param tokenAmount The token amount that was transferred.
    /// @param feeToken The token address used to pay CCIP fees.
    /// @param fees The fees paid for sending the CCIP message.
    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        address token,
        uint256 tokenAmount,
        address feeToken,
        uint256 fees
    );

    // The name of the gauge
    string public name;
    // The symbole of the gauge
    string public symbol;
    // The start time (in seconds since Unix epoch) of the current period
    uint256 public startEpochTime;

    // The address of the DFX reward token
    address public immutable DFX;
    // Instance of CCIP Router
    IRouterClient router;
    // The address of the rewards distributor on the mainnet (source chain)
    address public distributor;
    // Chain selector for the destination blockchain (see Chainlink docs)
    uint64 public destinationChain;
    // The address of the destination rewards receiver on the sidechain
    address public destination;
    // The token used for paying fees in cross-chain interactions
    address public feeToken;
    // The default gas price for the _ccipReceive function on the L2
    uint256 public l2GasLimitFee = 200_000; // default gas price for _ccipReceive

    // The address with administrative privileges over this contract
    address public admin;

    /// @dev Modifier that checks whether the msg.sender is admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    /// @dev Modifier that checks whether the msg.sender is the distributor contract address
    modifier onlyDistributor() {
        require(msg.sender == distributor, "Not distributor");
        _;
    }

    /// @notice Contract initializer
    /// @param _DFX Address of the DFX token
    constructor(address _DFX) initializer {
        require(_DFX != address(0), "Token cannot be zero address");
        DFX = _DFX;
    }

    /// @notice Contract initializer
    /// @param _symbol Gauge base symbol
    /// @param _distributor Address of the mainnet rewards distributor
    /// @param _router Address of the CCIP message router
    /// @param _destinationChain Chain ID of the chain with the destination gauge. CCIP uses its own set of chain selectors to identify blockchains
    /// @param _destination Address of the destination gauge on the sidechain
    /// @param _admin Admin who can kill the gauge
    function initialize(
        string memory _symbol,
        address _distributor,
        address _router,
        uint64 _destinationChain,
        address _destination,
        address _feeToken,
        address _admin
    ) external initializer {
        name = string(abi.encodePacked("DFX ", _symbol, " Gauge"));
        symbol = string(abi.encodePacked(_symbol, "-gauge"));

        distributor = _distributor;
        router = IRouterClient(_router);
        destinationChain = _destinationChain; // destination chain selector
        destination = _destination; // destination address on l2
        feeToken = _feeToken;
        admin = _admin;
    }

    /* Parameters */
    /// @notice Set a new admin for the contract.
    /// @dev Only callable by the current admin.
    /// @param _newAdmin Address of the new admin.
    function updateAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    /// @notice Set a new destination address for the L2 gauge.
    /// @dev Only callable by the current admin.
    /// @param _newDestination Address of the new L2 gauge.
    function setDestination(address _newDestination) external onlyAdmin {
        destination = _newDestination;
    }

    /// @notice Set a new destination chain selector.
    /// @dev Only callable by the current admin.
    /// @param _newDestinationChain Chain selector for the L2 gauge.
    function setDestinationChain(uint64 _newDestinationChain) external onlyAdmin {
        destinationChain = _newDestinationChain;
    }

    /// @notice Set a new reward distributor.
    /// @dev Only callable by the current admin.
    /// @param _newDistributor Reward distributor on source chain.
    function setDistributor(address _newDistributor) external onlyAdmin {
        distributor = _newDistributor;
    }

    /// @notice Set the token to use for CCIP message fees.
    /// @dev Only callable by the current admin.
    /// @param _newFeeToken Set a new fee token (LINK, wrapped native or a native token).
    function setFeeToken(address _newFeeToken) external onlyAdmin {
        feeToken = _newFeeToken;
    }

    /// @notice Set the maximum gas to be used by the _ccipReceive function override on L2.
    ///         Unused gas will not be refunded.
    /// @dev Only callable by the current admin.
    /// @param _newGasLimit Set a new L2 gas limit.
    function setL2GasLimit(uint256 _newGasLimit) external onlyAdmin {
        l2GasLimitFee = _newGasLimit;
    }

    /* Gauge actions */
    /// @notice Send reward tokens to the L2 gauge.
    /// @dev This function approves the router to spend DFX tokens, calculates fees, and triggers a cross-chain token send.
    /// @param _amount Amount of DFX tokens to send as reward.
    /// @return bytes32 ID of the CCIP message that was sent.
    function _notifyReward(uint256 _amount) internal returns (bytes32) {
        startEpochTime = block.timestamp;

        // Max approve spending of rewards tokens by router
        if (IERC20(DFX).allowance(address(this), address(router)) < _amount) {
            IERC20(DFX).approve(address(router), type(uint256).max);
        }

        Client.EVM2AnyMessage memory message = _buildCcipMessage(destination, DFX, _amount, feeToken);
        uint256 fees = router.getFee(destinationChain, message);

        // When fee token is set, send messages across CCIP using token. Otherwise,
        // use the native gas token
        bytes32 messageId;
        if (feeToken != address(0)) {
            if (fees > IERC20(feeToken).balanceOf(address(this))) {
                revert NotEnoughBalance(IERC20(feeToken).balanceOf(address(this)), fees);
            }
            // Max approve spending of gas tokens by router
            if (IERC20(feeToken).allowance(address(this), address(router)) < fees) {
                IERC20(feeToken).approve(address(router), type(uint256).max);
            }
            messageId = router.ccipSend(destinationChain, message);
        } else {
            if (fees > address(this).balance) {
                revert NotEnoughBalance(address(this).balance, fees);
            }
            messageId = router.ccipSend{value: fees}(destinationChain, message);
        }

        // Emit an event with message details
        emit MessageSent(messageId, destinationChain, destination, DFX, _amount, feeToken, fees);
        return messageId;
    }

    function notifyReward(uint256 _amount) external onlyDistributor returns (bytes32) {
        bytes32 messageId = _notifyReward(_amount);
        return messageId;
    }

    function notifyReward(address, uint256 _amount) external onlyDistributor returns (bytes32) {
        bytes32 messageId = _notifyReward(_amount);
        return messageId;
    }

    /* CCIP */
    /// @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for tokens transfer.
    /// @param _receiver The address of the receiver.
    /// @param _token The token to be transferred.
    /// @param _amount The amount of the token to be transferred.
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCcipMessage(address _receiver, address _token, uint256 _amount, address _feeTokenAddress)
        internal
        view
        returns (Client.EVM2AnyMessage memory)
    {
        // Set the token amounts
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({token: _token, amount: _amount});
        tokenAmounts[0] = tokenAmount;
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: "", // No data
            tokenAmounts: tokenAmounts, // The amount and type of token being transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit to 0 as we are not sending any data and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: l2GasLimitFee, strict: false})
                ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _feeTokenAddress
        });
        return evm2AnyMessage;
    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is transferred to the contract without any data.
    receive() external payable {}

    /* Admin */
    /// @notice Withdraw ERC20 tokens accidentally sent to the contract.
    /// @dev Only callable by the admin.
    /// @param _beneficiary Address to send the tokens to.
    /// @param _token Address of the token to withdraw.
    /// @param _amount Amount of the token to withdraw.
    function emergencyWithdraw(address _beneficiary, address _token, uint256 _amount) external onlyAdmin {
        IERC20(_token).transfer(_beneficiary, _amount);
    }

    /// @notice Withdraw native Ether accidentally sent to the contract.
    /// @dev Only callable by the admin.
    /// @param _beneficiary Address to send the Ether to.
    /// @param _amount Amount of Ether to withdraw.
    function emergencyWithdrawNative(address _beneficiary, uint256 _amount) external onlyAdmin {
        (bool sent,) = _beneficiary.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}