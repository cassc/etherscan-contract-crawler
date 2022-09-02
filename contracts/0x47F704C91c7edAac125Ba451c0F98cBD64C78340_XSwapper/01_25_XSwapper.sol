// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.2;

import { Address } from "Address.sol";
import "AccessControlUpgradeable.sol";
import "UUPSUpgradeable.sol";
import "PausableUpgradeable.sol";
import "ERC20.sol";
import "ECDSA.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";

import "Supervisor.sol";
import "IDexAggregatorAdaptor.sol";
import "IYPoolVault.sol";


/// @title XSwapper contract
/// @notice Users call `swap` to swap asset to specified bridgeable asset and then initiate a cross-chain swap request.
/// YPool workers call `closeSwap` to complete a cross-chain swap, `claim` & `batchClaim` to claim the credit back.
/// YPool validators call `lockCloseSwap` & `refund` to lock the swap and refund asset back to user if no applicable
/// liquidity or a YPool worker sent an invalidated closeSwap tx.
/// - "User" and "Account" refer to the same thing
/// - "fromChain" and "source chain" refer to the same thing
/// - "toChain" and "target chain" refer to the same thing
/// - "XYChain" and "Settlement chain" refer to the same thing
contract XSwapper is AccessControlUpgradeable, UUPSUpgradeable, PausableUpgradeable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    /* ========== STRUCTURE ========== */

    // Status of a swap request (on source chain)
    enum RequestStatus { Open, Closed }
    // Result of a swap when it's closed (on target chain)
    enum CloseSwapResult { NonSwapped, Success, Failed, Locked }
    // Type of how the asset is transferred when the swap is completed
    enum CompleteSwapType { Claimed, FreeClaimed, Refunded }

    // Fees settings on each chain
    // Fee is calculated as `inputAmount * FeeStructure.rate / (10 ** FeeStructure.decimals)`
    struct FeeStructure {
        bool isSet;
        uint256 gas;
        uint256 min;
        uint256 max;
        uint256 rate;
        uint256 decimals;
    }

    // Info of a swap request
    struct SwapRequest {
        uint32 toChainId;
        uint256 swapId;
        address receiver;
        address sender;
        uint256 YPoolTokenAmount;
        uint256 xyFee;
        uint256 gasFee;
        IERC20 YPoolToken;
        RequestStatus status;
    }

    // Info of an expecting swap on target chain of a swap request
    struct ToChainDescription {
        uint32 toChainId;
        IERC20 toChainToken;
        uint256 expectedToChainTokenAmount;
        uint32 slippage;
    }

    /* ========== STATE VARIABLES ========== */

    // Roles
    bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");
    bytes32 public constant ROLE_STAFF = keccak256("ROLE_STAFF");
    bytes32 public constant ROLE_YPOOL_WORKER = keccak256("ROLE_YPOOL_WORKER");

    // Mapping of YPool token to its max amount in a single swap
    mapping (address => uint256) public maxYPoolTokenSwapAmount;

    // A contract that supervises each refund and claim by providing signatures
    Supervisor public supervisor;
    // A referenced address of native currency
    address public constant ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // Id of the current chain
    uint32 public chainId;
    // Next available id of a swap request
    // Note: the value is monotonically increasing as there MUST NOT exist swap requests with same Id
    // Note: swapId must be set to start accepting swap requests.
    uint256 public swapId;
    // The starting swap Id of the XSwapper
    // Note: It is immutable after setting startSwapId
    uint256 public startSwapId;
    // Note: swapIdIsSet should only be set to True and freeze once in function `setStartSwapId`
    bool public swapIdIsSet;
    // Accept swap requests or not
    bool public acceptSwapRequest;
    // Close status of each swap
    mapping (bytes32 => bool) everClosed;

    // Supported YPool tokens
    mapping (address => bool) public YPoolSupportedToken;
    // YPoolVault of a YPoolSupportedToken
    mapping (address => address) public YPoolVaults;
    // Whitelist of AggregatorAdaptors
    mapping (address => bool) public isWhitelistedAggregatorAdaptor;
    // SwapValidator contract on XYChain that validates a `closeSwap` transaction
    // Note: this contract does not exist on periphery chains so its address is used only for signature verification purpose in `claim` and `batchClaim`
    address public swapValidatorXYChain;

    // Fees setting of a supported token on each chain
    mapping (bytes32 => FeeStructure) public feeStructures;
    // All swap requests initiated by users
    mapping (uint256 => SwapRequest) public swapRequests;

    receive() external payable {}
    function _authorizeUpgrade(address) internal override onlyRole(ROLE_OWNER) {}

    /// @notice Initialize XSwapper
    /// @param owner The owner address
    /// @param manager The manager address
    /// @param staff The staff address
    /// @param worker The swap worker address
    /// @param _supervisor The supervisor contract address
    /// @param _chainId The chain ID
    function initialize(address owner, address manager, address staff, address worker, address _supervisor, uint32 _chainId) initializer public {
        require(Address.isContract(_supervisor), "ERR_SUPERVISOR_NOT_CONTRACT");
        supervisor = Supervisor(_supervisor);
        chainId = _chainId;
        acceptSwapRequest = false;

        // Validate chainId
        uint256 _realChainId;
        assembly {
            _realChainId := chainid()
        }
        require(_chainId == _realChainId, "ERR_WRONG_CHAIN_ID");

        _setRoleAdmin(ROLE_OWNER, ROLE_OWNER);
        _setRoleAdmin(ROLE_MANAGER, ROLE_OWNER);
        _setRoleAdmin(ROLE_STAFF, ROLE_OWNER);
        _setRoleAdmin(ROLE_YPOOL_WORKER, ROLE_OWNER);
        _setupRole(ROLE_OWNER, owner);
        _setupRole(ROLE_MANAGER, manager);
        _setupRole(ROLE_STAFF, staff);
        _setupRole(ROLE_YPOOL_WORKER, worker);
    }

    /* ========== MODIFIERS ========== */

    modifier acceptSwap() {
        require(acceptSwapRequest, "ERR_NOT_ACCEPTING_SWAP_REQUESTS");
        _;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Get the XY protocol fee setting of `_token` on chain `_toChainId`
    /// @param _toChainId Chain Id of the periphery chain
    /// @param _token YPool token
    function _getFeeStructure(uint32 _toChainId, address _token) private view returns (FeeStructure memory) {
        bytes32 universalTokenId = keccak256(abi.encodePacked(_toChainId, _token));
        return feeStructures[universalTokenId];
    }

    function _safeTransferAsset(address receiver, IERC20 token, uint256 amount) private {
        if (address(token) == ETHER_ADDRESS) {
            payable(receiver).transfer(amount);
        } else {
            token.safeTransfer(receiver, amount);
        }
    }

    function _safeTransferFromAsset(IERC20 fromToken, address from, uint256 amount) private {
        if (address(fromToken) == ETHER_ADDRESS)
            require(msg.value == amount, "ERR_INVALID_AMOUNT");
        else {
            uint256 _fromTokenBalance = getTokenBalance(fromToken, address(this));
            fromToken.safeTransferFrom(from, address(this), amount);
            require(getTokenBalance(fromToken, address(this)) - _fromTokenBalance == amount, "ERR_INVALID_AMOUNT");
        }
    }

    /// @notice Check whether the swap amount reaches the threshold or not
    /// @param _toChainId Chain Id of the target chain
    /// @param token YPool token
    /// @param amount Swap amount
    /// @dev A swap could be closed by YPool worker on target chain or get refunded on source chain, i.e., this chain,
    /// therefore, we require the `amount` not only be GTE the fee on target chain but also on source chain
    function _checkMinimumSwapAmount(uint32 _toChainId, IERC20 token, uint256 amount) private view returns (bool) {
        FeeStructure memory feeStructure = _getFeeStructure(_toChainId, address(token));
        require(feeStructure.isSet, "ERR_FEE_NOT_SET");
        uint256 minToChainFee = feeStructure.min;  // closeSwap

        feeStructure = _getFeeStructure(chainId, address(token));
        require(feeStructure.isSet, "ERR_FEE_NOT_SET");
        uint256 minFromChainFee = feeStructure.min;  // refund

        return amount >= max(minToChainFee, minFromChainFee);
    }

    /// @notice Calculate the XY protocol fee and gas fee
    /// @param _chainId Chain Id of the periphery chain
    /// @param token YPool token
    /// @param amount YPool token amount
    function _calculateFee(uint32 _chainId, IERC20 token, uint256 amount) private view returns (uint256 xyFee, uint256 gasFee) {
        FeeStructure memory feeStructure = _getFeeStructure(_chainId, address(token));
        require(feeStructure.isSet, "ERR_FEE_NOT_SET");

        xyFee = amount * feeStructure.rate / (10 ** feeStructure.decimals);
        xyFee = min(max(xyFee, feeStructure.min), feeStructure.max);
        gasFee = feeStructure.gas;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Get a certain swap request
    /// @dev TODO: Though swapRequests is a public mapping, here we keep getSwapRequest for those applications that need this interface. Should be removed since next upgrade.
    /// @param _swapId Swap Id of a swap request
    function getSwapRequest(uint256 _swapId) external view returns (SwapRequest memory) {
        return swapRequests[_swapId];
    }

    /// @notice Get the XY protocol fee setting of `_token` on chain `_toChainId`
    /// @param _chainId Chain Id of the periphery chain
    /// @param _token YPool token
    function getFeeStructure(uint32 _chainId, address _token) external view returns (FeeStructure memory) {
        FeeStructure memory feeStructure = _getFeeStructure(_chainId, _token);
        require(feeStructure.isSet, "ERR_FEE_NOT_SET");
        return feeStructure;
    }

    /// @notice Check whether a swap is closed or not on this chain, assuming this chain is the target chain
    /// @param _chainId Chain Id of the source chain
    /// @param _swapId Swap Id of a swap request
    function getEverClosed(uint32 _chainId, uint256 _swapId) external view returns (bool) {
        bytes32 universalSwapId = keccak256(abi.encodePacked(_chainId, _swapId));
        return everClosed[universalSwapId];
    }

    /// @notice Get the token or native token balance of given account
    /// @param _token ERC20 token address or ETHER_ADDRESS which stands for native token
    /// @param _account YPool token
    function getTokenBalance(IERC20 _token, address _account) public view returns (uint256 balance) {
        balance = address(_token) == ETHER_ADDRESS ? _account.balance : _token.balanceOf(_account);
    }

    /* ========== RESTRICTED FUNCTIONS (OWNER) ========== */

    /// @notice Set start swapId
    /// @dev swapId can only be set once and before any swap request comes in
    /// @param _swapId Swap Id of a swap request
    function setStartSwapId(uint256 _swapId) external onlyRole(ROLE_OWNER) {
        require(!swapIdIsSet, "ERR_SWAP_ID_ALREADY_SET");
        swapIdIsSet = true;
        startSwapId = _swapId;
        swapId = _swapId;
        emit StartSwapIdSet(_swapId);
    }

    /// @notice Set YPoolVault and its token
    /// @param _supportedToken YPool token
    /// @param _vault Address of the YPoolVault
    /// @param _isSet To Add or to remove
    function setYPoolVault(address _supportedToken, address _vault, bool _isSet) external onlyRole(ROLE_OWNER) {
        if (_supportedToken != ETHER_ADDRESS) {
            require(Address.isContract(_supportedToken), "ERR_YPOOL_TOKEN_NOT_CONTRACT");
        }
        require(Address.isContract(_vault), "ERR_YPOOL_VAULT_NOT_CONTRACT");
        YPoolSupportedToken[_supportedToken] = _isSet;
        YPoolVaults[_supportedToken] = _vault;
        emit YPoolVaultSet(_supportedToken, _vault, _isSet);
    }

    /// @notice Rescue fund accidentally sent to this contract. Can not rescue YPool token
    /// @param tokens List of token address to rescue
    function rescue(IERC20[] memory tokens) external onlyRole(ROLE_OWNER) {
        for (uint256 i; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            require(!YPoolSupportedToken[address(token)], "ERR_CAN_NOT_RESCUE_YPOOL_TOKEN");
            uint256 _tokenBalance = token.balanceOf(address(this));
            token.safeTransfer(msg.sender, _tokenBalance);
        }
    }

    /* ========== RESTRICTED FUNCTIONS (MANAGER) ========== */

    /// @notice Set the maximum swap amount of a YPool token
    /// @param _supportedToken YPool token
    /// @param amount Maximum swap amount
    function setMaxYPoolTokenSwapAmount(address _supportedToken, uint256 amount) external onlyRole(ROLE_MANAGER) {
        require(YPoolSupportedToken[_supportedToken], "ERR_INVALID_YPOOL_TOKEN");
        maxYPoolTokenSwapAmount[_supportedToken] = amount;
    }

    /// @notice Set the dex aggregator
    /// @param _aggregatorAdaptor Address of the aggregator
    function setAggregatorAdaptor(address _aggregatorAdaptor, bool _isSet) external onlyRole(ROLE_MANAGER) {
        require(Address.isContract(_aggregatorAdaptor), "ERR_AGGREGATOR_ADAPTOR_NOT_CONTRACT");
        require(isWhitelistedAggregatorAdaptor[_aggregatorAdaptor] != _isSet, "ERR_ALREADY_SET");
        isWhitelistedAggregatorAdaptor[_aggregatorAdaptor] = _isSet;
        emit AggregatorAdaptorSet(_aggregatorAdaptor, _isSet);
    }

    /// @notice Pause the major functions
    function pause() external onlyRole(ROLE_MANAGER) {
        _pause();
    }

    /// @notice Unpause the major functions
    function unpause() external onlyRole(ROLE_MANAGER) {
        _unpause();
    }

    /// @notice Set to accept swap request or not
    function setAcceptSwapRequest(bool _isSet) external onlyRole(ROLE_MANAGER) {
        require(acceptSwapRequest != _isSet, "ERR_ALREADY_SET");
        acceptSwapRequest = _isSet;
        emit AcceptSwapRequestSet(_isSet);
    }

    /* ========== RESTRICTED FUNCTIONS (STAFF) ========== */

    /// @notice Set the XY protocol fee setting of `_token` on chain `_toChainId`
    /// @param _toChainId Chain Id of the periphery chain
    /// @param _supportedToken YPool token
    /// @param _gas Estimated gas fee of closeSwap/refund in form of YPool Token
    /// @param _min Minimum amount of the XY protocol fee of `_supportedToken`
    /// @param _max Maximum amount of the XY protocol fee of `_supportedToken`
    /// @param rate Fee rate of the XY protocol fee of `_supportedToken`
    /// @param decimals Decimals of `_rate`
    function setFeeStructure(uint32 _toChainId, address _supportedToken, uint256 _gas, uint256 _min, uint256 _max, uint256 rate, uint256 decimals) external onlyRole(ROLE_STAFF) {
        if (_supportedToken != ETHER_ADDRESS) {
            require(Address.isContract(_supportedToken), "ERR_YPOOL_TOKEN_NOT_CONTRACT");
        }
        require(_max > _min, "ERR_INVALID_MAX_MIN");
        require(_min >= _gas, "ERR_INVALID_MIN_GAS");
        bytes32 universalTokenId = keccak256(abi.encodePacked(_toChainId, _supportedToken));
        FeeStructure memory feeStructure = FeeStructure(true, _gas, _min, _max, rate, decimals);
        feeStructures[universalTokenId] = feeStructure;
        emit FeeStructureSet(_toChainId, _supportedToken, _gas, _min, _max, rate, decimals);
    }

    /// @notice Set the SwapValidator
    /// @param _swapValidatorXYChain Address of the SwapValidator on XY chain
    function setSwapValidatorXYChain(address _swapValidatorXYChain) external onlyRole(ROLE_STAFF) {
        swapValidatorXYChain = _swapValidatorXYChain;
        emit SwapValidatorXYChainSet(_swapValidatorXYChain);
    }

    /* ========== RESTRICTED FUNCTIONS (YPOOL_WORKER) ========== */

    /// @notice Fulfill a swap request for a user by YPool worker
    /// Closing a swap MUST be performed on target chain and only by YPool worker
    /// @dev swapDesc is the swap info for swapping on DEX on target chain, not the info of the swap request user initiated on source chain
    /// @param aggregatorAdaptor The address of the adaptor of the specific dex aggregator
    /// @param swapDesc Description of the swap on DEX, see IDexAggregatorAdaptor.SwapDescription
    /// @param aggregatorData Raw data consists of instructions to swap user's token for YPool token
    /// @param fromChainId Source chain id of the swap request
    /// @param fromSwapId Swap id of the swap request
    function closeSwap(
        address aggregatorAdaptor,
        IDexAggregatorAdaptor.SwapDescription calldata swapDesc,
        bytes memory aggregatorData,
        uint32 fromChainId,
        uint256 fromSwapId
    ) external payable whenNotPaused nonReentrant onlyRole(ROLE_YPOOL_WORKER) {
        require(YPoolSupportedToken[address(swapDesc.fromToken)], "ERR_INVALID_YPOOL_TOKEN");

        {
            bytes32 universalSwapId = keccak256(abi.encodePacked(fromChainId, fromSwapId));
            require(!everClosed[universalSwapId], "ERR_ALREADY_CLOSED");
            everClosed[universalSwapId] = true;
        }

        require(swapDesc.amount <= maxYPoolTokenSwapAmount[address(swapDesc.fromToken)], "ERR_EXCEED_MAX_SWAP_AMOUNT");
        IYPoolVault(YPoolVaults[address(swapDesc.fromToken)]).transferToSwapper(swapDesc.fromToken, swapDesc.amount);

        uint256 toTokenAmountOut;
        CloseSwapResult swapResult;
        if (swapDesc.toToken == swapDesc.fromToken) {
            toTokenAmountOut = swapDesc.amount;
            swapResult = CloseSwapResult.NonSwapped;
        } else {
            require(isWhitelistedAggregatorAdaptor[aggregatorAdaptor], "ERR_INVALID_AGGREGATOR_ADAPTOR");
            uint256 value = (address(swapDesc.fromToken) == ETHER_ADDRESS) ? swapDesc.amount : 0;
            // If the swapDesc.toToken doest not consist of balanceOf, considered as swap failed
            try this.getTokenBalance(swapDesc.toToken, swapDesc.receiver) returns (uint256 balance) {
                toTokenAmountOut = balance;
                if (address(swapDesc.fromToken) != ETHER_ADDRESS) swapDesc.fromToken.safeApprove(aggregatorAdaptor, swapDesc.amount);
                try IDexAggregatorAdaptor(aggregatorAdaptor).swap{value: value}(swapDesc, aggregatorData) {
                    if (address(swapDesc.fromToken) != ETHER_ADDRESS) swapDesc.fromToken.safeApprove(aggregatorAdaptor, 0);
                    toTokenAmountOut = getTokenBalance(swapDesc.toToken, swapDesc.receiver) - toTokenAmountOut;
                    swapResult = CloseSwapResult.Success;
                } catch {
                    swapResult = CloseSwapResult.Failed;
                }
                if (address(swapDesc.fromToken) != ETHER_ADDRESS) swapDesc.fromToken.safeApprove(aggregatorAdaptor, 0);
            } catch {
                swapResult = CloseSwapResult.Failed;
            }
        }
        if (swapResult != CloseSwapResult.Success) {
            _safeTransferAsset(swapDesc.receiver, swapDesc.fromToken, swapDesc.amount);
        }
        emit CloseSwapCompleted(swapResult, fromChainId, fromSwapId);
        emit SwappedForUser(aggregatorAdaptor, swapDesc.fromToken, swapDesc.amount, swapDesc.toToken, toTokenAmountOut, swapDesc.receiver);
    }

    /* ========== RESTRICTED FUNCTIONS (SIGNATURE REQUIRED) ========== */

    /// @notice Claim the asset of a swap request on source chain after YPool worker `closeSwap` on target chain, by providing signatures of validators
    /// Claiming MUST be performed on source chain
    /// @dev Signatures from validators are first sent to SwapValidator contract on Settlement chain to validate a swap request. Then the signatures can be reused here to approve the claim
    /// @param _swapId Swap id of the swap request
    /// @param signatures Signatures of validators
    function claim(uint256 _swapId, bytes[] memory signatures) external whenNotPaused {
        require(startSwapId <= _swapId && _swapId < swapId, "ERR_INVALID_SWAPID");
        require(swapRequests[_swapId].status != RequestStatus.Closed, "ERR_ALREADY_CLOSED");
        swapRequests[_swapId].status = RequestStatus.Closed;

        bytes32 sigId = keccak256(abi.encodePacked(supervisor.VALIDATE_SWAP_IDENTIFIER(), address(this), address(swapValidatorXYChain), chainId, _swapId));
        bytes32 sigIdHash = sigId.toEthSignedMessageHash();
        supervisor.checkSignatures(sigIdHash, signatures);

        SwapRequest memory request = swapRequests[_swapId];
        IYPoolVault yPoolVault = IYPoolVault(YPoolVaults[address(request.YPoolToken)]);
        uint256 value = (address(request.YPoolToken) == ETHER_ADDRESS) ? request.YPoolTokenAmount : 0;
        if (address(request.YPoolToken) != ETHER_ADDRESS) {
            request.YPoolToken.safeApprove(address(yPoolVault), request.YPoolTokenAmount);
        }
        yPoolVault.receiveAssetFromSwapper{value: value}(request.YPoolToken, request.YPoolTokenAmount, request.xyFee, request.gasFee);

        emit SwapCompleted(CompleteSwapType.Claimed, request);
    }

    /// @notice Claim the asset of multiple swap requests on source chain after YPool worker `closeSwap` on eacg target chain, by providing signatures of validators
    /// Claiming MUST be performed on source chain
    /// @dev YPool token of the swap request MUST be the same
    /// @dev Validators sign to the array of swap ids, which is different from signing for `claim`
    /// @param _swapIds Swap ids of the swap requests
    /// @param _YPoolToken Y Pool token
    /// @param signatures Signatures of validators
    function batchClaim(uint256[] calldata _swapIds, address _YPoolToken, bytes[] memory signatures) external whenNotPaused {
        require(YPoolSupportedToken[_YPoolToken], "ERR_INVALID_YPOOL_TOKEN");
        bytes32 sigId = keccak256(abi.encodePacked(supervisor.BATCH_CLAIM_IDENTIFIER(), address(this), address(swapValidatorXYChain), chainId, _swapIds));
        bytes32 sigIdHash = sigId.toEthSignedMessageHash();
        supervisor.checkSignatures(sigIdHash, signatures);

        IERC20 YPoolToken = IERC20(_YPoolToken);
        uint256 totalClaimedAmount;
        uint256 totalXYFee;
        uint256 totalGasFee;
        uint256 _startSwapId = startSwapId;
        for (uint256 i; i < _swapIds.length; i++) {
            uint256 _swapId = _swapIds[i];
            require(_startSwapId <= _swapId && _swapId < swapId, "ERR_INVALID_SWAPID");
            SwapRequest memory request = swapRequests[_swapId];
            require(request.status != RequestStatus.Closed, "ERR_ALREADY_CLOSED");
            require(request.YPoolToken == YPoolToken, "ERR_WRONG_YPOOL_TOKEN");
            totalClaimedAmount += request.YPoolTokenAmount;
            totalXYFee += request.xyFee;
            totalGasFee += request.gasFee;
            swapRequests[_swapId].status = RequestStatus.Closed;
            emit SwapCompleted(CompleteSwapType.FreeClaimed, request);
        }

        IYPoolVault yPoolVault = IYPoolVault(YPoolVaults[_YPoolToken]);
        uint256 value = (_YPoolToken == ETHER_ADDRESS) ? totalClaimedAmount : 0;
        if (_YPoolToken != ETHER_ADDRESS) {
            YPoolToken.safeApprove(address(yPoolVault), totalClaimedAmount);
        }
        yPoolVault.receiveAssetFromSwapper{value: value}(YPoolToken, totalClaimedAmount, totalXYFee, totalGasFee);
    }

    /// @notice Lock an expired swap request by providing signatures of validators
    /// Locking a swap MUST be performed on target chain to prevent YPool worker from closing an expired swap request
    /// @dev Signature collector collects signature from different validators off-chain and call this function
    /// @param fromChainId Source chain id of the swap request
    /// @param fromSwapId Swap id of the swap request
    /// @param signatures Signatures of validators
    function lockCloseSwap(uint32 fromChainId, uint256 fromSwapId, bytes[] memory signatures) external whenNotPaused {
        bytes32 universalSwapId = keccak256(abi.encodePacked(fromChainId, fromSwapId));
        require(!everClosed[universalSwapId], "ERR_ALREADY_CLOSED");
        bytes32 sigId = keccak256(abi.encodePacked(supervisor.LOCK_CLOSE_SWAP_AND_REFUND_IDENTIFIER(), address(this), fromChainId, fromSwapId));
        bytes32 sigIdHash = sigId.toEthSignedMessageHash();
        supervisor.checkSignatures(sigIdHash, signatures);

        everClosed[universalSwapId] = true;
        emit CloseSwapCompleted(CloseSwapResult.Locked, fromChainId, fromSwapId);
    }

    /// @notice Refund user if a swap request is expired or invalidated by providing signatures of validators
    /// A portion of refund will be taken away as gas fee compensation to execute the refund
    /// Refund MUST be performed on source chain
    /// @param _swapId Swap id of the swap request
    /// @param gasFeeReceiver Address that receives gas fees
    /// @param signatures Signatures of validators
    function refund(uint256 _swapId, address gasFeeReceiver, bytes[] memory signatures) external whenNotPaused {
        require(_swapId < swapId, "ERR_INVALID_SWAPID");
        require(swapRequests[_swapId].status != RequestStatus.Closed, "ERR_ALREADY_CLOSED");
        swapRequests[_swapId].status = RequestStatus.Closed;

        bytes32 sigId = keccak256(abi.encodePacked(supervisor.LOCK_CLOSE_SWAP_AND_REFUND_IDENTIFIER(), address(this), chainId, _swapId, gasFeeReceiver));
        bytes32 sigIdHash = sigId.toEthSignedMessageHash();
        supervisor.checkSignatures(sigIdHash, signatures);

        SwapRequest memory request = swapRequests[_swapId];
        (, uint256 refundGasFee) = _calculateFee(chainId, request.YPoolToken, request.YPoolTokenAmount);
        _safeTransferAsset(request.sender, request.YPoolToken, request.YPoolTokenAmount - refundGasFee);
        _safeTransferAsset(gasFeeReceiver, request.YPoolToken, refundGasFee);

        emit SwapCompleted(CompleteSwapType.Refunded, request);
    }

    /* ========== WRITE FUNCTIONS ========== */

    /// @notice This functions is called by user to initiate a swap. User swaps his/her token for YPool token on this chain and provide info for the swap on target chain. A swap request will be created for each swap.
    /// @dev swapDesc is the swap info for swapping on DEX on this chain, not the swap request
    /// @param aggregatorAdaptor The address of the adaptor of the specific dex aggregator
    /// @param swapDesc Description of the swap on DEX, see IDexAggregatorAdaptor.SwapDescription
    /// @param aggregatorData Raw data consists of instructions to swap user's token for YPool token
    /// @param toChainDesc Description of the swap on target chain, see ToChainDescription
    function swap(
        address aggregatorAdaptor,
        IDexAggregatorAdaptor.SwapDescription memory swapDesc,
        bytes memory aggregatorData,
        ToChainDescription calldata toChainDesc
    ) external payable acceptSwap whenNotPaused nonReentrant {
        require(swapIdIsSet, "ERR_SWAP_ID_NOT_SET");
        address receiver = swapDesc.receiver;
        IERC20 fromToken = swapDesc.fromToken;
        IERC20 YPoolToken = swapDesc.toToken;
        require(YPoolSupportedToken[address(YPoolToken)], "ERR_INVALID_YPOOL_TOKEN");

        uint256 fromTokenAmount = swapDesc.amount;
        uint256 yBalance;
        _safeTransferFromAsset(fromToken, msg.sender, fromTokenAmount);
        if (fromToken == YPoolToken) {
            yBalance = fromTokenAmount;
        } else {
            require(isWhitelistedAggregatorAdaptor[aggregatorAdaptor], "ERR_INVALID_AGGREGATOR_ADAPTOR");
            yBalance = getTokenBalance(YPoolToken, address(this));
            swapDesc.receiver = address(this);
            if (address(fromToken) != ETHER_ADDRESS) fromToken.safeApprove(aggregatorAdaptor, fromTokenAmount);
            IDexAggregatorAdaptor(aggregatorAdaptor).swap{value: msg.value}(swapDesc, aggregatorData);
            if (address(fromToken) != ETHER_ADDRESS) fromToken.safeApprove(aggregatorAdaptor, 0);
            yBalance = getTokenBalance(YPoolToken, address(this)) - yBalance;
        }
        require(_checkMinimumSwapAmount(toChainDesc.toChainId, YPoolToken, yBalance), "ERR_NOT_ENOUGH_SWAP_AMOUNT");
        require(yBalance <= maxYPoolTokenSwapAmount[address(YPoolToken)], "ERR_EXCEED_MAX_SWAP_AMOUNT");

        // Calculate XY fee and gas fee for closeSwap on toChain
        // NOTE: XY fee already includes gas fee and gas fee is computed here only for bookkeeping purpose
        (uint256 xyFee, uint256 closeSwapGasFee) = _calculateFee(toChainDesc.toChainId, YPoolToken, yBalance);
        SwapRequest memory request = SwapRequest(toChainDesc.toChainId, swapId, receiver, msg.sender, yBalance, xyFee, closeSwapGasFee, YPoolToken, RequestStatus.Open);
        swapRequests[swapId] = request;
        emit SwapRequested(swapId++, aggregatorAdaptor, toChainDesc, fromToken, YPoolToken, yBalance, receiver, xyFee, closeSwapGasFee);
    }

    /* ========== EVENTS ========== */

    // Owner events
    event StartSwapIdSet(uint256 _swapId);
    event FeeStructureSet(uint32 _toChainId, address _YPoolToken, uint256 _gas, uint256 _min, uint256 _max, uint256 _rate, uint256 _decimals);
    event YPoolVaultSet(address _supportedToken, address _vault, bool _isSet);
    event AggregatorAdaptorSet(address _aggregator, bool _isSet);
    event SwapValidatorXYChainSet(address _swapValidatorXYChain);
    event AcceptSwapRequestSet(bool _isSet);
    // Swap events
    event SwapRequested(uint256 _swapId, address indexed _aggregatorAdaptor, ToChainDescription _toChainDesc, IERC20 _fromToken, IERC20 indexed _YPoolToken, uint256 _YPoolTokenAmount, address _receiver, uint256 _xyFee, uint256 _gasFee);
    event SwapCompleted(CompleteSwapType _closeType, SwapRequest _swapRequest);
    event CloseSwapCompleted(CloseSwapResult _swapResult, uint32 _fromChainId, uint256 _fromSwapId);
    event SwappedForUser(address indexed _aggregatorAdaptor, IERC20 indexed _fromToken, uint256 _fromTokenAmount, IERC20 _toToken, uint256 _toTokenAmountOut, address _receiver);
}