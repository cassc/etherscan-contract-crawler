pragma solidity ^0.8.4;

import "./interfaces/ISocketRegistry.sol";
import "./utils/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract FeeRouter is Ownable,ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @notice Address used to identify if it is a native token transfer or not
     */
    address private constant NATIVE_TOKEN_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice variable for our registry contract, registry contract is responsible for redirecting to different bridges
     */
    ISocketRegistry public immutable socket;

    // Errors
    error IntegratorIdAlreadyRegistered();
    error TotalFeeAndPartsMismatch();
    error IntegratorIdNotRegistered();
    error FeeMisMatch();
    error NativeTransferFailed();
    error MsgValueMismatch();

    // MAX value of totalFeeInBps.
    uint16 immutable PRECISION = 10000;

    constructor(address _socketRegistry, address owner_) Ownable(owner_) {
        socket = ISocketRegistry(_socketRegistry);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Events ------------------------------------------------------------------------------------------------------->

    /**
     * @notice Event emitted when an integrator registers their fee config
     */
    event RegisterFee(
        uint16 integratorId,
        uint16 totalFeeInBps,
        uint16 part1,
        uint16 part2,
        uint16 part3,
        address feeTaker1,
        address feeTaker2,
        address feeTaker3
    );

    /**
     * @notice Event emitted when integrator fee config is updated
     */
    event UpdateFee(
        uint16 integratorId,
        uint16 totalFeeInBps,
        uint16 part1,
        uint16 part2,
        uint16 part3,
        address feeTaker1,
        address feeTaker2,
        address feeTaker3
    );

    /**
     * @notice Event emitted when fee in tokens are claimed
     */
    event ClaimFee(
        uint16 integratorId,
        address tokenAddress,
        uint256 amount,
        address feeTaker
    );

    /**
     * @notice Event emitted when call registry is successful
     */
    event BridgeSocket(
        uint16 integratorId,
        uint256 amount,
        address inputTokenAddress,
        uint256 toChainId,
        uint256 middlewareId,
        uint256 bridgeId,
        uint256 totalFee
    );

    /**
     * @notice Container for Fee Request
     * @member integratorId Id of the integrator registered in the fee config
     * @member inputAmount amount sent to the fee router.
     * @member UserRequest request that is passed on to the registry
     */
    struct FeeRequest {
        uint16 integratorId;
        uint256 inputAmount;
        ISocketRegistry.UserRequest userRequest;
    }

    /**
     * @notice Container for Fee Splits
     * @member feeTaker address of the entity who will claim the fee
     * @member partOfTotalFeesInBps part of total fees that the feeTaker can claim
     */
    struct FeeSplits {
        address feeTaker;
        uint16 partOfTotalFeesInBps;
    }

    /**
     * @notice Mapping of valid integrators
     */
    mapping(uint16 => bool) validIntegrators;

    /**
     * @notice Mapping of integrator Ids and the total fee that can be cut from the input amount
     */
    mapping(uint16 => uint16) totalFeeMap;
    /**
     * @notice Mapping of integrator Ids and FeeSplits. FeeSplits is an array with the max size of 3
     * The total fee can be at max split into 3 parts
     */
    mapping(uint16 => FeeSplits[3]) feeSplitMap;

    /**
     * @notice Mapping of integratorId and the earned fee per token
     */
    mapping(uint16 => mapping(address => uint256)) earnedTokenFeeMap;

    // CORE FUNCTIONS ------------------------------------------------------------------------------------------------------>

    /**
     * @notice Owner can register a fee config against an integratorId
     * @dev totalFeeInBps and the sum of feesplits should be exactly equal, feeSplits can have a max size of 3
     * @param integratorId id of the integrator
     * @param totalFeeInBps totalFeeInBps, the max value can be 10000
     * @param feeSplits array of FeeSplits
     */
    function registerFeeConfig(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) external onlyOwner {
        // Not checking for total fee in bps to be 0 as the total fee can be set to 0.
        if (validIntegrators[integratorId]) {
            revert IntegratorIdAlreadyRegistered();
        }

        uint16 x = feeSplits[0].partOfTotalFeesInBps +
            feeSplits[1].partOfTotalFeesInBps +
            feeSplits[2].partOfTotalFeesInBps;

        if (x != totalFeeInBps) {
            revert TotalFeeAndPartsMismatch();
        }

        totalFeeMap[integratorId] = totalFeeInBps;
        feeSplitMap[integratorId][0] = feeSplits[0];
        feeSplitMap[integratorId][1] = feeSplits[1];
        feeSplitMap[integratorId][2] = feeSplits[2];
        validIntegrators[integratorId] = true;
        _emitRegisterFee(integratorId, totalFeeInBps, feeSplits);
    }

    /**
     * @notice Owner can update the fee config against an integratorId
     * @dev totalFeeInBps and the sum of feesplits should be exactly equal, feeSplits can have a max size of 3
     * @param integratorId id of the integrator
     * @param totalFeeInBps totalFeeInBps, the max value can be 10000
     * @param feeSplits array of FeeSplits
     */
    function updateFeeConfig(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) external onlyOwner {
        if (!validIntegrators[integratorId]) {
            revert IntegratorIdNotRegistered();
        }

        uint16 x = feeSplits[0].partOfTotalFeesInBps +
            feeSplits[1].partOfTotalFeesInBps +
            feeSplits[2].partOfTotalFeesInBps;

        if (x != totalFeeInBps) {
            revert TotalFeeAndPartsMismatch();
        }

        totalFeeMap[integratorId] = totalFeeInBps;
        feeSplitMap[integratorId][0] = feeSplits[0];
        feeSplitMap[integratorId][1] = feeSplits[1];
        feeSplitMap[integratorId][2] = feeSplits[2];
        _emitUpdateFee(integratorId, totalFeeInBps, feeSplits);
    }

    /**
     * @notice Function that sends the claimed fee to the corresponding integrator config addresses
     * @dev native token address to be used to claim native token fee, if earned fee is 0, it will return
     * @param integratorId id of the integrator
     * @param tokenAddress address of the token to claim fee against
     */
    function claimFee(uint16 integratorId, address tokenAddress) external nonReentrant {
        uint256 earnedFee = earnedTokenFeeMap[integratorId][tokenAddress];
        FeeSplits[3] memory integratorFeeSplits = feeSplitMap[integratorId];
        earnedTokenFeeMap[integratorId][tokenAddress] = 0;

        if (earnedFee == 0) {
            return;
        }
        for (uint8 i = 0; i < 3; i++) {
            _calculateAndClaimFee(
                integratorId,
                earnedFee,
                integratorFeeSplits[i].partOfTotalFeesInBps,
                totalFeeMap[integratorId],
                integratorFeeSplits[i].feeTaker,
                tokenAddress
            );
        }
    }

    /**
     * @notice Function that calls the registry after verifying if the fee is correct
     * @dev userRequest amount should match the aount after deducting the fee from the input amount
     * @param _feeRequest feeRequest contains the integratorId, the input amount and the user request that is passed to socket registry
     */
    function callRegistry(FeeRequest calldata _feeRequest) external payable nonReentrant {
        if (!validIntegrators[_feeRequest.integratorId]) {
            revert IntegratorIdNotRegistered();
        }

        // Get approval and token addresses.
        (
            address approvalAddress,
            address inputTokenAddress
        ) = _getApprovalAndInputTokenAddress(_feeRequest.userRequest);

        // Calculate Amount to Send to Registry.
        uint256 amountToBridge = _getAmountForRegistry(
            _feeRequest.integratorId,
            _feeRequest.inputAmount
        );

        if (_feeRequest.userRequest.amount != amountToBridge) {
            revert FeeMisMatch();
        }

        // Call Registry
        if (inputTokenAddress == NATIVE_TOKEN_ADDRESS) {
            if (msg.value != _feeRequest.inputAmount) revert MsgValueMismatch();
            socket.outboundTransferTo{
                value: msg.value - (_feeRequest.inputAmount - amountToBridge)
            }(_feeRequest.userRequest);
        } else {
            _getUserFundsToFeeRouter(
                msg.sender,
                _feeRequest.inputAmount,
                inputTokenAddress
            );
            IERC20(inputTokenAddress).safeApprove(
                approvalAddress,
                amountToBridge
            );
            socket.outboundTransferTo{value: msg.value}(
                _feeRequest.userRequest
            );
        }

        // Update the earned fee for the token and integrator.
        _updateEarnedFee(
            _feeRequest.integratorId,
            inputTokenAddress,
            _feeRequest.inputAmount,
            amountToBridge
        );

        // Emit Bridge Event
        _emitBridgeSocket(_feeRequest, inputTokenAddress, amountToBridge);
    }

    // INTERNAL UTILITY FUNCTION ------------------------------------------------------------------------------------------------------>

    /**
     * @notice function that sends the earned fee depending on the inputs
     * @dev tokens will not be transferred to zero addresses, earned fee against an integrator id is divided into the splits configured
     * @param integratorId id of the integrator
     * @param earnedFee amount of tokens earned as fee
     * @param part part of the amount that needs to be claimed in bps
     * @param total totalfee in bps
     * @param feeTaker address that the earned fee will be sent to after calculation
     * @param tokenAddress address of the token for claiming fee
     */
    function _calculateAndClaimFee(
        uint16 integratorId,
        uint256 earnedFee,
        uint16 part,
        uint16 total,
        address feeTaker,
        address tokenAddress
    ) internal {
        if (feeTaker != address(0)) {
            uint256 amountToBeSent = (earnedFee * part) / total;
            emit ClaimFee(integratorId, tokenAddress, amountToBeSent, feeTaker);
            if (tokenAddress == NATIVE_TOKEN_ADDRESS) {
                (bool success, ) = payable(feeTaker).call{
                    value: amountToBeSent
                }("");
                if (!success) revert NativeTransferFailed();
                return;
            }
            IERC20(tokenAddress).safeTransfer(feeTaker, amountToBeSent);
        }
    }

    /**
     * @notice function that returns the approval address and the input token address
     * @dev approval address is needed to approve the bridge or middleware implementaton before calling socket registry
     * @dev input token address is needed to identify the token in which the fee is being deducted
     * @param userRequest socket registry's user request
     * @return (address, address) returns the approval address and the inputTokenAddress
     */
    function _getApprovalAndInputTokenAddress(
        ISocketRegistry.UserRequest calldata userRequest
    ) internal view returns (address, address) {
        if (userRequest.middlewareRequest.id == 0) {
            (address routeAddress, , ) = socket.routes(
                userRequest.bridgeRequest.id
            );
            return (routeAddress, userRequest.bridgeRequest.inputToken);
        } else {
            (address routeAddress, , ) = socket.routes(
                userRequest.middlewareRequest.id
            );
            return (routeAddress, userRequest.middlewareRequest.inputToken);
        }
    }

    /**
     * @notice function that transfers amount from the user to this contract.
     * @param user address of the user who holds the tokens
     * @param amount amount of tokens to transfer
     * @param tokenAddress address of the token being bridged
     */
    function _getUserFundsToFeeRouter(
        address user,
        uint256 amount,
        address tokenAddress
    ) internal {
        IERC20(tokenAddress).safeTransferFrom(user, address(this), amount);
    }

    /**
     * @notice function that returns an amount after deducting the fee
     * @param integratorId id of the integrator
     * @param amount input amount to this contract when calling the function callRegistry
     * @return uint256 returns the amount after deduciting the fee
     */
    function _getAmountForRegistry(uint16 integratorId, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return amount - ((amount * totalFeeMap[integratorId]) / PRECISION);
    }

    /**
     * @notice function that updated the earned fee against the integrator Id
     * @param integratorId id of the integrator
     * @param inputTokenAddress address of the token being bridged
     * @param amount input amount to this contract when calling the function callRegistry
     * @param registryAmount amount in user request that is passed on to registry
     */
    function _updateEarnedFee(
        uint16 integratorId,
        address inputTokenAddress,
        uint256 amount,
        uint256 registryAmount
    ) internal {
        earnedTokenFeeMap[integratorId][inputTokenAddress] =
            earnedTokenFeeMap[integratorId][inputTokenAddress] +
            amount -
            registryAmount;
    }

    /**
     * @notice function that emits the event BridgeSocket
     */
    function _emitBridgeSocket(
        FeeRequest calldata _feeRequest,
        address tokenAddress,
        uint256 registryAmount
    ) internal {
        emit BridgeSocket(
            _feeRequest.integratorId,
            _feeRequest.inputAmount,
            tokenAddress,
            _feeRequest.userRequest.toChainId,
            _feeRequest.userRequest.middlewareRequest.id,
            _feeRequest.userRequest.bridgeRequest.id,
            _feeRequest.inputAmount - registryAmount
        );
    }

    /**
     * @notice function that emits the event UpdateFee
     */
    function _emitUpdateFee(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) internal {
        emit UpdateFee(
            integratorId,
            totalFeeInBps,
            feeSplits[0].partOfTotalFeesInBps,
            feeSplits[1].partOfTotalFeesInBps,
            feeSplits[2].partOfTotalFeesInBps,
            feeSplits[0].feeTaker,
            feeSplits[1].feeTaker,
            feeSplits[2].feeTaker
        );
    }

    /**
     * @notice function that emits the event RegisterFee
     */
    function _emitRegisterFee(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) internal {
        emit RegisterFee(
            integratorId,
            totalFeeInBps,
            feeSplits[0].partOfTotalFeesInBps,
            feeSplits[1].partOfTotalFeesInBps,
            feeSplits[2].partOfTotalFeesInBps,
            feeSplits[0].feeTaker,
            feeSplits[1].feeTaker,
            feeSplits[2].feeTaker
        );
    }

    // VIEW FUNCTIONS --------------------------------------------------------------------------------------------------------->

    /**
     * @notice function that returns the amount in earned fee
     * @param integratorId id of the integrator
     * @param tokenAddress address of the token
     * @return uin256
     */
    function getEarnedFee(uint16 integratorId, address tokenAddress)
        public
        view
        returns (uint256)
    {
        return earnedTokenFeeMap[integratorId][tokenAddress];
    }

    /**
     * @notice function that returns if the integrator id is valid or not
     * @param integratorId id of the integrator
     * @return bool
     */
    function getValidIntegrator(uint16 integratorId)
        public
        view
        returns (bool)
    {
        return validIntegrators[integratorId];
    }

    /**
     * @notice function that returns the total fee in bps registered against the integrator id
     * @param integratorId id of the integrator
     * @return uint16
     */
    function getTotalFeeInBps(uint16 integratorId)
        public
        view
        returns (uint16)
    {
        return totalFeeMap[integratorId];
    }

    /**
     * @notice function that returns the FeeSplit array registered agains the integrator id
     * @param integratorId id of the integrator
     * @return feeSplits FeeSplits[3] - array of FeeSplits of size 3
     */
    function getFeeSplits(uint16 integratorId)
        public
        view
        returns (FeeSplits[3] memory feeSplits)
    {
        return feeSplitMap[integratorId];
    }

    // RESCUE FUNCTIONS ------------------------------------------------------------------------------------------------------>

    /**
     * @notice rescue function for emeregencies
     * @dev can only be called by the owner, should only be called during emergencies only
     * @param userAddress address of the user receiving funds
     * @param token address of the token being rescued
     * @param amount amount to be sent to the user
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice rescue function for emeregencies
     * @dev can only be called by the owner, should only be called during emergencies only
     * @param userAddress address of the user receiving funds
     * @param amount amount to be sent to the user
     */
    function rescueNative(address payable userAddress, uint256 amount)
        external
        onlyOwner
    {
        userAddress.transfer(amount);
    }
}