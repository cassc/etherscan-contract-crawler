// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CCIP Sender
 * @author DFX Finance
 * @notice Sends rewards to configured L2 destinations using Chainlink router
 */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

contract CcipSender is Initializable {
    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance to cover the fees.

    // The address of the DFX reward token
    address public immutable DFX;
    // Instance of CCIP Router
    IRouterClient router;

    // The address with administrative privileges over this contract
    address public admin;

    struct Destination {
        address receiver;
        uint64 chainSelector;
    }

    struct ChainFee {
        // The token used for paying fees in cross-chain interactions
        address feeToken;
        // The gas price for the _ccipReceive function on the L2
        uint256 gasLimitFee;
    }

    // Destination chain addresses
    mapping(address => Destination) public destinations;
    mapping(uint64 => ChainFee) public chainFees;

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

    /// @dev Modifier that checks whether the caller is admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    /// @notice Contract constructor
    /// @param _DFX Address of the DFX reward token
    constructor(address _DFX) initializer {
        DFX = _DFX;
    }

    /// @notice Initialize the contract
    /// @param _router Address of the CCIP Router contract
    /// @param _admin Address with administrative privileges
    function initialize(address _router, address _admin) public {
        // router = IRouterClient(_router);
        // admin = _admin;

        // // Max approve spending of rewards tokens by sender
        // IERC20(DFX).approve(address(_router), type(uint256).max);
    }

    function relayReward(uint256 amount) public returns (bytes32) {
        IERC20(DFX).transferFrom(msg.sender, address(this), amount);

        Destination memory destination = destinations[msg.sender];
        require(destination.receiver != address(0), "No L2 destination");

        ChainFee memory chainFee = chainFees[destination.chainSelector];
        require(chainFee.gasLimitFee != 0, "No minimum gas fee");

        Client.EVM2AnyMessage memory message = _buildCcipMessage(destination.receiver, DFX, amount, chainFee);
        uint256 fees = router.getFee(destination.chainSelector, message);

        // When fee token is set, send messages across CCIP using token. Otherwise,
        // use the native gas token
        bytes32 messageId;
        if (chainFee.feeToken != address(0)) {
            if (fees > IERC20(chainFee.feeToken).balanceOf(address(this))) {
                revert NotEnoughBalance(IERC20(chainFee.feeToken).balanceOf(address(this)), fees);
            }
            // Max approve spending of gas tokens by router
            if (IERC20(chainFee.feeToken).allowance(address(this), address(router)) < fees) {
                IERC20(chainFee.feeToken).approve(address(router), type(uint256).max);
            }
            messageId = router.ccipSend(destination.chainSelector, message);
        } else {
            if (fees > address(this).balance) {
                revert NotEnoughBalance(address(this).balance, fees);
            }
            messageId = router.ccipSend{value: fees}(destination.chainSelector, message);
        }

        // Emit an event with message details
        emit MessageSent(
            messageId, destination.chainSelector, destination.receiver, DFX, amount, chainFee.feeToken, fees
        );
        return messageId;
    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is transferred to the contract without any data.
    receive() external payable {}

    /* CCIP */
    /// @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for tokens transfer.
    /// @param _receiver The address of the receiver.
    /// @param _token The token to be transferred.
    /// @param _amount The amount of the token to be transferred.
    /// @param _chainFee The ChainFee object for fees. Set address(0) for native gas.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCcipMessage(address _receiver, address _token, uint256 _amount, ChainFee memory _chainFee)
        internal
        pure
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
                Client.EVMExtraArgsV1({gasLimit: _chainFee.gasLimitFee, strict: false})
                ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _chainFee.feeToken
        });
        return evm2AnyMessage;
    }

    /* Admin */
    /// @notice Set a new admin for the contract.
    /// @dev Only callable by the current admin.
    /// @param _newAdmin Address of the new admin.
    function updateAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    /// @notice Add a new L2 destination address
    /// @param rootGauge Address of the root gauge on the L2 chain
    /// @param receiver Address of the receiver on the L2 chain
    /// @param chainSelector Selector of the destination L2 chain
    function setL2Destination(address rootGauge, address receiver, uint64 chainSelector) public onlyAdmin {
        destinations[rootGauge] = Destination(receiver, chainSelector);
    }

    /// @notice Set the maximum gas to be used by the _ccipReceive function override on L2.
    ///         Unused gas will not be refunded.
    /// @dev Only callable by the current admin.
    /// @param _newGasLimit Set a new L2 gas token and limit.
    function setL2Gas(uint64 _chainSelector, address _feeToken, uint256 _newGasLimit) external onlyAdmin {
        chainFees[_chainSelector] = ChainFee(_feeToken, _newGasLimit);
    }

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