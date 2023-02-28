// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IRango.sol";

/// @title BaseSwapper
/// @author 0xiden
/// @notice library to provide swap functionality
library LibSwapper {

    /// @dev keccak256("exchange.rango.library.swapper")
    bytes32 internal constant BASE_SWAPPER_NAMESPACE = hex"43da06808a8e54e76a41d6f7b48ddfb23969b1387a8710ef6241423a5aefe64a";

    address payable constant ETH = payable(0x0000000000000000000000000000000000000000);

    struct BaseSwapperStorage {
        address payable feeContractAddress;
        address WETH;
        mapping(address => bool) whitelistContracts;
        mapping(address => mapping(bytes4 => bool)) whitelistMethods;
    }

    /// @notice Emitted if any fee transfer was required
    /// @param token The address of received token, address(0) for native
    /// @param affiliatorAddress The address of affiliate wallet
    /// @param platformFee The amount received as platform fee
    /// @param destinationExecutorFee The amount received to execute transaction on destination (only for cross chain txs)
    /// @param affiliateFee The amount received by affiliate
    /// @param dAppTag Optional identifier to make tracking easier.
    event FeeInfo(
        address token,
        address indexed affiliatorAddress,
        uint platformFee,
        uint destinationExecutorFee,
        uint affiliateFee,
        uint16 indexed dAppTag
    );

    /// @notice A call to another dex or contract done and here is the result
    /// @param target The address of dex or contract that is called
    /// @param success A boolean indicating that the call was success or not
    /// @param returnData The response of function call
    event CallResult(address target, bool success, bytes returnData);

    /// @notice A swap request is done and we also emit the output
    /// @param requestId Optional parameter to make tracking of transaction easier
    /// @param fromToken Input token address to be swapped from
    /// @param toToken Output token address to be swapped to
    /// @param amountIn Input amount of fromToken that is being swapped
    /// @param dAppTag Optional identifier to make tracking easier
    /// @param outputAmount The output amount of the swap, measured by the balance change before and after the swap
    /// @param receiver The address to receive the output of swap. Can be address(0) when swap is before a bridge action
    event RangoSwap(
        address indexed requestId,
        address fromToken,
        address toToken,
        uint amountIn,
        uint minimumAmountExpected,
        uint16 indexed dAppTag,
        uint outputAmount,
        address receiver
    );

    /// @notice Output amount of a dex calls is logged
    /// @param _token The address of output token, ZERO address for native
    /// @param amount The amount of output
    event DexOutput(address _token, uint amount);

    /// @notice The output money (ERC20/Native) is sent to a wallet
    /// @param _token The token that is sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address
    event SendToken(address _token, uint256 _amount, address _receiver);


    /// @notice Notifies that Rango's fee receiver address updated
    /// @param _oldAddress The previous fee wallet address
    /// @param _newAddress The new fee wallet address
    event FeeContractAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Notifies that WETH address is updated
    /// @param _oldAddress The previous weth address
    /// @param _newAddress The new weth address
    event WethContractAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Notifies that admin manually refunded some money
    /// @param _token The address of refunded token, 0x000..00 address for native token
    /// @param _amount The amount that is refunded
    event Refunded(address _token, uint _amount);

    /// @notice The requested call data which is computed off-chain and passed to the contract
    /// @dev swapFromToken and amount parameters are only helper params and the actual amount and
    /// token are set in callData
    /// @param spender The contract which the approval is given to if swapFromToken is not native.
    /// @param target The dex contract address that should be called
    /// @param swapFromToken Token address of to be used in the swap.
    /// @param amount The amount to be approved or native amount sent.
    /// @param callData The required data field that should be give to the dex contract to perform swap
    struct Call {
        address spender;
        address payable target;
        address swapFromToken;
        address swapToToken;
        bool needsTransferFromUser;
        uint amount;
        bytes callData;
    }

    /// @notice General swap request which is given to us in all relevant functions
    /// @param requestId The request id passed to make tracking transactions easier
    /// @param fromToken The source token that is going to be swapped (in case of simple swap or swap + bridge) or the briding token (in case of solo bridge)
    /// @param toToken The output token of swapping. This is the output of DEX step and is also input of bridging step
    /// @param amountIn The amount of input token to be swapped
    /// @param platformFee The amount of fee charged by platform
    /// @param destinationExecutorFee The amount of fee required for relayer execution on the destination
    /// @param affiliateFee The amount of fee charged by affiliator dApp
    /// @param affiliatorAddress The wallet address that the affiliator fee should be sent to
    /// @param minimumAmountExpected The minimum amount of toToken expected after executing Calls
    /// @param dAppTag An optional parameter
    struct SwapRequest {
        address requestId;
        address fromToken;
        address toToken;
        uint amountIn;
        uint platformFee;
        uint destinationExecutorFee;
        uint affiliateFee;
        address payable affiliatorAddress;
        uint minimumAmountExpected;
        uint16 dAppTag;
    }

    /// @notice initializes the base swapper and sets the init params (such as Wrapped token address)
    /// @param _weth Address of wrapped token (WETH, WBNB, etc.) on the current chain
    function setWeth(address _weth) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();
        address oldAddress = baseStorage.WETH;
        baseStorage.WETH = _weth;
        require(_weth != address(0), "Invalid WETH!");
        emit WethContractAddressUpdated(oldAddress, _weth);
    }

    /// @notice Sets the wallet that receives Rango's fees from now on
    /// @param _address The receiver wallet address
    function updateFeeContractAddress(address payable _address) internal {
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        address oldAddress = baseSwapperStorage.feeContractAddress;
        baseSwapperStorage.feeContractAddress = _address;

        emit FeeContractAddressUpdated(oldAddress, _address);
    }

    /// Whitelist ///

    /// @notice Adds a contract to the whitelisted DEXes that can be called
    /// @param contractAddress The address of the DEX
    function addWhitelist(address contractAddress) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();
        baseStorage.whitelistContracts[contractAddress] = true;
    }

    /// @notice Adds a method of contract to the whitelisted DEXes that can be called
    /// @param contractAddress The address of the DEX
    /// @param methodIds The method of the DEX
    function addMethodWhitelists(address contractAddress, bytes4[] calldata methodIds) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        baseStorage.whitelistContracts[contractAddress] = true;
        for (uint i = 0; i < methodIds.length; i++)
            baseStorage.whitelistMethods[contractAddress][methodIds[i]] = true;
    }

    /// @notice Adds a method of contract to the whitelisted DEXes that can be called
    /// @param contractAddress The address of the DEX
    /// @param methodId The method of the DEX
    function addMethodWhitelist(address contractAddress, bytes4 methodId) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        baseStorage.whitelistContracts[contractAddress] = true;
        baseStorage.whitelistMethods[contractAddress][methodId] = true;
    }

    /// @notice Removes a contract from the whitelisted DEXes
    /// @param contractAddress The address of the DEX or dApp
    function removeWhitelist(address contractAddress) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        require(baseStorage.whitelistContracts[contractAddress], 'Contract not found');
        delete baseStorage.whitelistContracts[contractAddress];
    }

    /// @notice Removes a method of contract from the whitelisted DEXes
    /// @param contractAddress The address of the DEX or dApp
    /// @param methodId The method of the DEX
    function removeMethodWhitelist(address contractAddress, bytes4 methodId) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        require(baseStorage.whitelistMethods[contractAddress][methodId], 'Contract not found');
        delete baseStorage.whitelistMethods[contractAddress][methodId];
    }

    function onChainSwapsPreBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        uint extraFee
    ) internal returns (uint out) {

        bool isNative = request.fromToken == ETH;
        uint minimumRequiredValue = (isNative ? request.platformFee + request.affiliateFee + request.amountIn + request.destinationExecutorFee : 0) + extraFee;
        require(msg.value >= minimumRequiredValue, 'Send more ETH to cover input amount + fee');

        (, out) = onChainSwapsInternal(request, calls, extraFee);
        // when there is a bridge after swap, set the receiver in swap event to address(0)
        emitSwapEvent(request, out, ETH);

        return out;
    }

    /// @notice Internal function to compute output amount of DEXes
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @param extraNativeFee The amount of native tokens to keep and not return to user as excess amount.
    /// @return The response of all DEX calls and the output amount of the whole process
    function onChainSwapsInternal(
        SwapRequest memory request,
        Call[] calldata calls,
        uint256 extraNativeFee
    ) internal returns (bytes[] memory, uint) {

        uint toBalanceBefore = getBalanceOf(request.toToken);
        uint fromBalanceBefore = getBalanceOf(request.fromToken);
        uint256[] memory initialBalancesList = getInitialBalancesList(calls);

        // transfer tokens from user for SwapRequest and Calls that require transfer from user.
        transferTokensFromUserForSwapRequest(request);
        transferTokensFromUserForCalls(calls);

        bytes[] memory result = callSwapsAndFees(request, calls);

        // check if any extra tokens were taken from contract and return excess tokens if any.
        returnExcessAmounts(request, calls, initialBalancesList);

        // get balance after returning excesses.
        uint fromBalanceAfter = getBalanceOf(request.fromToken);

        // check over-expense of fromToken and return excess if any.
        if (request.fromToken != ETH) {
            require(fromBalanceAfter >= fromBalanceBefore, "Source token balance on contract must not decrease after swap");
            if (fromBalanceAfter > fromBalanceBefore)
                _sendToken(request.fromToken, fromBalanceAfter - fromBalanceBefore, msg.sender);
        }
        else {
            require(fromBalanceAfter >= fromBalanceBefore - msg.value, "Source token balance on contract must not decrease after swap");
            // When we are keeping extraNativeFee for bridgingFee, we should consider it in calculations.
            if (fromBalanceAfter > fromBalanceBefore - msg.value + extraNativeFee)
                _sendToken(request.fromToken, fromBalanceAfter + msg.value - fromBalanceBefore - extraNativeFee, msg.sender);
        }

        uint toBalanceAfter = getBalanceOf(request.toToken);

        uint secondaryBalance = toBalanceAfter - toBalanceBefore;
        require(secondaryBalance >= request.minimumAmountExpected, "Output is less than minimum expected");

        return (result, secondaryBalance);
    }

    /// @notice Private function to handle fetching money from wallet to contract, reduce fee/affiliate, perform DEX calls
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @dev It checks the whitelisting of all DEX addresses + having enough msg.value as input
    /// @return The bytes of all DEX calls response
    function callSwapsAndFees(SwapRequest memory request, Call[] calldata calls) private returns (bytes[] memory) {
        bool isSourceNative = request.fromToken == ETH;
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        for (uint256 i = 0; i < calls.length; i++) {
            require(baseSwapperStorage.whitelistContracts[calls[i].spender], "Contract spender not whitelisted");
            require(baseSwapperStorage.whitelistContracts[calls[i].target], "Contract target not whitelisted");
            bytes4 sig = bytes4(calls[i].callData[: 4]);
            require(baseSwapperStorage.whitelistMethods[calls[i].target][sig], "Unauthorized call data!");
        }

        // Get Platform fee
        bool hasPlatformFee = request.platformFee > 0;
        bool hasDestExecutorFee = request.destinationExecutorFee > 0;
        bool hasAffiliateFee = request.affiliateFee > 0;
        if (hasPlatformFee || hasDestExecutorFee) {
            require(baseSwapperStorage.feeContractAddress != ETH, "Fee contract address not set");
            _sendToken(request.fromToken, request.platformFee + request.destinationExecutorFee, baseSwapperStorage.feeContractAddress, isSourceNative, false);
        }

        // Get affiliate fee
        if (hasAffiliateFee) {
            require(request.affiliatorAddress != ETH, "Invalid affiliatorAddress");
            _sendToken(request.fromToken, request.affiliateFee, request.affiliatorAddress, isSourceNative, false);
        }

        // emit Fee event
        if (hasPlatformFee || hasDestExecutorFee || hasAffiliateFee) {
            emit FeeInfo(
                request.fromToken,
                request.affiliatorAddress,
                request.platformFee,
                request.destinationExecutorFee,
                request.affiliateFee,
                request.dAppTag
            );
        }

        // Execute swap Calls
        bytes[] memory returnData = new bytes[](calls.length);
        address tmpSwapFromToken;
        for (uint256 i = 0; i < calls.length; i++) {
            tmpSwapFromToken = calls[i].swapFromToken;
            bool isTokenNative = tmpSwapFromToken == ETH;
            if (isTokenNative == false)
                approve(tmpSwapFromToken, calls[i].spender, calls[i].amount);

            (bool success, bytes memory ret) = isTokenNative
            ? calls[i].target.call{value : calls[i].amount}(calls[i].callData)
            : calls[i].target.call(calls[i].callData);

            emit CallResult(calls[i].target, success, ret);
            if (!success)
                revert(_getRevertMsg(ret));
            returnData[i] = ret;
        }

        return returnData;
    }

    /// @notice Approves an ERC20 token to a contract to transfer from the current contract
    /// @param token The address of an ERC20 token
    /// @param to The contract address that should be approved
    /// @param value The amount that should be approved
    function approve(address token, address to, uint value) internal {
        SafeERC20.safeApprove(IERC20(token), to, 0);
        SafeERC20.safeIncreaseAllowance(IERC20(token), to, value);
    }

    function _sendToken(address _token, uint256 _amount, address _receiver) internal {
        (_token == ETH) ? _sendNative(_receiver, _amount) : SafeERC20.safeTransfer(IERC20(_token), _receiver, _amount);
    }

    function sumFees(IRango.RangoBridgeRequest memory request) internal pure returns (uint256) {
        return request.platformFee + request.affiliateFee + request.destinationExecutorFee;
    }

    function sumFees(SwapRequest memory request) internal pure returns (uint256) {
        return request.platformFee + request.affiliateFee + request.destinationExecutorFee;
    }

    function collectFees(IRango.RangoBridgeRequest memory request) internal {
        // Get Platform fee
        bool hasPlatformFee = request.platformFee > 0;
        bool hasDestExecutorFee = request.destinationExecutorFee > 0;
        bool hasAffiliateFee = request.affiliateFee > 0;
        bool hasAnyFee = hasPlatformFee || hasDestExecutorFee || hasAffiliateFee;
        if (!hasAnyFee) {
            return;
        }
        bool isSourceNative = request.token == ETH;
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        if (hasPlatformFee || hasDestExecutorFee) {
            require(baseSwapperStorage.feeContractAddress != ETH, "Fee contract address not set");
            _sendToken(request.token, request.platformFee + request.destinationExecutorFee, baseSwapperStorage.feeContractAddress, isSourceNative, false);
        }

        // Get affiliate fee
        if (hasAffiliateFee) {
            require(request.affiliatorAddress != ETH, "Invalid affiliatorAddress");
            _sendToken(request.token, request.affiliateFee, request.affiliatorAddress, isSourceNative, false);
        }

        // emit Fee event
        emit FeeInfo(
            request.token,
            request.affiliatorAddress,
            request.platformFee,
            request.destinationExecutorFee,
            request.affiliateFee,
            request.dAppTag
        );
    }

    function collectFeesFromSender(IRango.RangoBridgeRequest memory request) internal {
        // Get Platform fee
        bool hasPlatformFee = request.platformFee > 0;
        bool hasDestExecutorFee = request.destinationExecutorFee > 0;
        bool hasAffiliateFee = request.affiliateFee > 0;
        bool hasAnyFee = hasPlatformFee || hasDestExecutorFee || hasAffiliateFee;
        if (!hasAnyFee) {
            return;
        }
        bool isSourceNative = request.token == ETH;
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        if (hasPlatformFee || hasDestExecutorFee) {
            require(baseSwapperStorage.feeContractAddress != ETH, "Fee contract address not set");
            if (isSourceNative)
                _sendToken(request.token, request.platformFee + request.destinationExecutorFee, baseSwapperStorage.feeContractAddress, isSourceNative, false);
            else
                SafeERC20.safeTransferFrom(
                    IERC20(request.token),
                    msg.sender,
                    baseSwapperStorage.feeContractAddress,
                    request.platformFee + request.destinationExecutorFee
                );
        }

        // Get affiliate fee
        if (hasAffiliateFee) {
            require(request.affiliatorAddress != ETH, "Invalid affiliatorAddress");
            if (isSourceNative)
                _sendToken(request.token, request.affiliateFee, request.affiliatorAddress, isSourceNative, false);
            else
                SafeERC20.safeTransferFrom(
                    IERC20(request.token),
                    msg.sender,
                    request.affiliatorAddress,
                    request.affiliateFee
                );
        }

        // emit Fee event
        emit FeeInfo(
            request.token,
            request.affiliatorAddress,
            request.platformFee,
            request.destinationExecutorFee,
            request.affiliateFee,
            request.dAppTag
        );
    }

    /// @notice An internal function to send a token from the current contract to another contract or wallet
    /// @dev This function also can convert WETH to ETH before sending if _withdraw flat is set to true
    /// @dev To send native token _nativeOut param should be set to true, otherwise we assume it's an ERC20 transfer
    /// @param _token The token that is going to be sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address or contract
    /// @param _nativeOut means the output is native token
    /// @param _withdraw If true, indicates that we should swap WETH to ETH before sending the money and _nativeOut must also be true
    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _nativeOut,
        bool _withdraw
    ) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();
        emit SendToken(_token, _amount, _receiver);

        if (_nativeOut) {
            if (_withdraw) {
                require(_token == baseStorage.WETH, "token mismatch");
                IWETH(baseStorage.WETH).withdraw(_amount);
            }
            _sendNative(_receiver, _amount);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), _receiver, _amount);
        }
    }

    /// @notice An internal function to send native token to a contract or wallet
    /// @param _receiver The address that will receive the native token
    /// @param _amount The amount of the native token that should be sent
    function _sendNative(address _receiver, uint _amount) internal {
        (bool sent,) = _receiver.call{value : _amount}("");
        require(sent, "failed to send native");
    }


    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getBaseSwapperStorage() internal pure returns (BaseSwapperStorage storage s) {
        bytes32 namespace = BASE_SWAPPER_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }

    /// @notice To extract revert message from a DEX/contract call to represent to the end-user in the blockchain
    /// @param _returnData The resulting bytes of a failed call to a DEX or contract
    /// @return A string that describes what was the error
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
        // All that remains is the revert string
    }

    function getBalanceOf(address token) internal view returns (uint) {
        return token == ETH ? address(this).balance : IERC20(token).balanceOf(address(this));
    }

    /// @notice Fetches the balances of swapToTokens.
    /// @dev this fetches the balances for swapToToken of swap Calls. If native eth is received, the balance has already increased so we subtract msg.value.
    function getInitialBalancesList(Call[] calldata calls) internal view returns (uint256[] memory) {
        uint callsLength = calls.length;
        uint256[] memory balancesList = new uint256[](callsLength);
        address token;
        for (uint256 i = 0; i < callsLength; i++) {
            token = calls[i].swapToToken;
            balancesList[i] = getBalanceOf(token);
            if (token == ETH)
                balancesList[i] -= msg.value;
        }
        return balancesList;
    }

    /// This function transfers tokens from users based on the SwapRequest, it transfers amountIn + fees.
    function transferTokensFromUserForSwapRequest(SwapRequest memory request) private {
        uint transferAmount = request.amountIn + sumFees(request);
        if (request.fromToken != ETH)
            SafeERC20.safeTransferFrom(IERC20(request.fromToken), msg.sender, address(this), transferAmount);
        else
            require(msg.value >= transferAmount);
    }

    /// This function iterates on calls and if needsTransferFromUser, transfers tokens from user
    function transferTokensFromUserForCalls(Call[] calldata calls) private {
        uint callsLength = calls.length;
        Call calldata call;
        address token;
        for (uint256 i = 0; i < callsLength; i++) {
            call = calls[i];
            token = call.swapFromToken;
            if (call.needsTransferFromUser && token != ETH)
                SafeERC20.safeTransferFrom(IERC20(call.swapFromToken), msg.sender, address(this), call.amount);
        }
    }

    /// @dev returns any excess token left by the contract.
    /// We iterate over `swapToToken`s because each swapToToken is either the request.toToken or is the output of
    /// another `Call` in the list of swaps which itself either has transferred tokens from user,
    /// or is a middle token that is the output of another `Call`.
    function returnExcessAmounts(
        SwapRequest memory request,
        Call[] calldata calls,
        uint256[] memory initialBalancesList) internal {
        uint excessAmountToToken;
        address tmpSwapToToken;
        uint currentBalanceTo;
        for (uint256 i = 0; i < calls.length; i++) {
            tmpSwapToToken = calls[i].swapToToken;
            currentBalanceTo = getBalanceOf(tmpSwapToToken);
            excessAmountToToken = currentBalanceTo - initialBalancesList[i];
            if (excessAmountToToken > 0 && tmpSwapToToken != request.toToken) {
                _sendToken(tmpSwapToToken, excessAmountToToken, msg.sender);
            }
        }
    }

    function emitSwapEvent(SwapRequest memory request, uint output, address receiver) internal {
        emit RangoSwap(
            request.requestId,
            request.fromToken,
            request.toToken,
            request.amountIn,
            request.minimumAmountExpected,
            request.dAppTag,
            output,
            receiver
        );
    }
}