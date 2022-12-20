// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IThorchainRouter.sol";
import "../../interfaces/IRangoMessageReceiver.sol";

/// @title The base contract that RangoV1 and all its parents inherit to support refund, on-chain swap, and DEX whitelisting
/// @author Uchiha Sasuke
/// @notice It contains storage for whitelisted contracts, refund ERC20 and native tokens and on-chain swap
contract BaseProxyContract is PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address payable constant ETH = payable(0x0000000000000000000000000000000000000000);

    /// @notice The maximum possible percent of fee that Rango will receive from user times 10,000, so 300 = 3%
    /// @dev The real fee is calculated by smart routing off-chain, this field only limits the value to prevent mis-calculations
    uint constant MAX_FEE_PERCENT_x_10000 = 300;

    /// @notice The maximum possible percent of fee that third-party dApp will receive from user times 10,000, so 300 = 3%
    /// @dev The real fee is calculated by smart routing off-chain, this field only limits the value to prevent mis-calculations
    uint constant MAX_AFFILIATE_PERCENT_x_10000 = 300;

    using SafeMathUpgradeable for uint;

    /// @dev keccak256("exchange.rango.baseproxycontract")
    bytes32 internal constant BASE_PROXY_CONTRACT_NAMESPACE = hex"c23df90b6466cfd0cbf4f6a578f167d2f60ed56371b4746a3c5973c8543f4fd9";

    struct BaseProxyStorage {
        address payable feeContractAddress;
        address WETH;
        mapping (address => bool) whitelistContracts;
    }

    /// @notice Rango received a fee reward
    /// @param token The address of received token, ZERO address for native
    /// @param wallet The address of receiver wallet
    /// @param amount The amount received as fee
    event FeeReward(address token, address wallet, uint amount);

    /// @notice Some money is sent to dApp wallet as affiliate reward
    /// @param token The address of received token, ZERO address for native
    /// @param wallet The address of receiver wallet
    /// @param amount The amount received as fee
    event AffiliateReward(address token, address wallet, uint amount);

    /// @notice A call to another dex or contract done and here is the result
    /// @param target The address of dex or contract that is called
    /// @param success A boolean indicating that the call was success or not
    /// @param returnData The response of function call
    event CallResult(address target, bool success, bytes returnData);

    /// @notice Output amount of a dex calls is logged
    /// @param _token The address of output token, ZERO address for native
    /// @param amount The amount of output
    event DexOutput(address _token, uint amount);

    /// @notice The output money (ERC20/Native) is sent to a wallet
    /// @param _token The token that is sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address
    event SendToken(address _token, uint256 _amount, address _receiver);

    /// @notice Notifies that a new contract is whitelisted
    /// @param _factory The address of the contract
    event ContractWhitelisted(address _factory);

    /// @notice Notifies that a new contract is blacklisted
    /// @param _factory The address of the contract
    event ContractBlacklisted(address _factory);

    /// @notice Notifies that Rango's fee receiver address updated
    /// @param _oldAddress The previous fee wallet address
    /// @param _newAddress The new fee wallet address
    event FeeContractAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Notifies that admin manually refunded some money
    /// @param _token The address of refunded token, 0x000..00 address for native token
    /// @param _amount The amount that is refunded
    event Refunded(address _token, uint _amount);

    /// @notice The requested call data which is computed off-chain and passed to the contract
    /// @param target The dex contract address that should be called
    /// @param callData The required data field that should be give to the dex contract to perform swap
    struct Call { address spender; address payable target; bytes callData; }

    /// @notice General swap request which is given to us in all relevant functions
    /// @param fromToken The source token that is going to be swapped (in case of simple swap or swap + bridge) or the briding token (in case of solo bridge)
    /// @param toToken The output token of swapping. This is the output of DEX step and is also input of bridging step
    /// @param amountIn The amount of input token to be swapped
    /// @param feeIn The amount of fee charged by Rango
    /// @param affiliateIn The amount of fee charged by affiliator dApp
    /// @param affiliatorAddress The wallet address that the affiliator fee should be sent to
    struct SwapRequest {
        address fromToken;
        address toToken;
        uint amountIn;
        uint feeIn;
        uint affiliateIn;
        address payable affiliatorAddress;
    }

    /// @notice Adds a contract to the whitelisted DEXes that can be called
    /// @param _factory The address of the DEX
    function addWhitelist(address _factory) public onlyOwner {
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();
        baseStorage.whitelistContracts[_factory] = true;

        emit ContractWhitelisted(_factory);
    }

    /// @notice Adds a list of contracts to the whitelisted DEXes that can be called
    /// @param _factories The addresses of the DEXes
    function addWhitelists(address[] calldata _factories) external onlyOwner {
        for (uint i = 0; i < _factories.length; i++)
            addWhitelist(_factories[i]);
    }

    /// @notice Removes a contract from the whitelisted DEXes
    /// @param _factory The address of the DEX or dApp
    function removeWhitelist(address _factory) external onlyOwner {
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();

        require(baseStorage.whitelistContracts[_factory], 'Factory not found');
        delete baseStorage.whitelistContracts[_factory];

        emit ContractBlacklisted(_factory);
    }

    /// @notice Sets the wallet that receives Rango's fees from now on
    /// @param _address The receiver wallet address
    function updateFeeContractAddress(address payable _address) external onlyOwner {
        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();

        address oldAddress = baseProxyStorage.feeContractAddress;
        baseProxyStorage.feeContractAddress = _address;

        emit FeeContractAddressUpdated(oldAddress, _address);
    }

    /// @notice Transfers an ERC20 token from this contract to msg.sender
    /// @dev This endpoint is to return money to a user if we didn't handle failure correctly and the money is still in the contract
    /// @dev Currently the money goes to admin and they should manually transfer it to a wallet later
    /// @param _tokenAddress The address of ERC20 token to be transferred
    /// @param _amount The amount of money that should be transfered
    function refund(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20Upgradeable ercToken = IERC20Upgradeable(_tokenAddress);
        uint balance = ercToken.balanceOf(address(this));
        require(balance >= _amount, "Insufficient balance");

        SafeERC20Upgradeable.safeTransfer(ercToken, msg.sender, _amount);

        emit Refunded(_tokenAddress, _amount);
    }

    /// @notice Transfers the native token from this contract to msg.sender
    /// @dev This endpoint is to return money to a user if we didn't handle failure correctly and the money is still in the contract
    /// @dev Currently the money goes to admin and they should manually transfer it to a wallet later
    /// @param _amount The amount of native token that should be transfered
    function refundNative(uint256 _amount) external onlyOwner {
        uint balance = address(this).balance;
        require(balance >= _amount, "Insufficient balance");

        _sendToken(ETH, _amount, msg.sender, true, false);

        emit Refunded(ETH, _amount);
    }

    function onChainSwapsPreBridge(
        address _bridgeProxy,
        SwapRequest memory request,
        Call[] calldata calls,
        uint extraFee
    ) internal returns (uint out, uint value) {
        require(_bridgeProxy != ETH, 'Bridge proxy address in Rango contract not set');

        bool isNative = request.fromToken == ETH;
        uint minimumRequiredValue = (isNative ? request.feeIn + request.affiliateIn + request.amountIn : 0) + extraFee;
        require(msg.value >= minimumRequiredValue, 'Send more ETH to cover input amount + fee');

        (, out) = onChainSwapsInternal(request, calls);
        if (request.toToken != ETH)
            approve(request.toToken, _bridgeProxy, out);

        value = (request.toToken == ETH ? (out > 0 ? out : request.amountIn) : 0) + extraFee;
        return (out, value);
    }

    /// @notice Internal function to compute output amount of DEXes
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @return The response of all DEX calls and the output amount of the whole process
    function onChainSwapsInternal(SwapRequest memory request, Call[] calldata calls) internal returns (bytes[] memory, uint) {

        uint toBalanceBefore = getBalanceOf(request.toToken);
        uint fromBalanceBefore = getBalanceOf(request.fromToken);

        bytes[] memory result = callSwapsAndFees(request, calls);

        uint toBalanceAfter = getBalanceOf(request.toToken);
        uint fromBalanceAfter = getBalanceOf(request.fromToken);

        if (request.fromToken != ETH)
            require(fromBalanceAfter >= fromBalanceBefore, 'Source token balance on contract must not decrease after swap');
        else
            require(fromBalanceAfter >= fromBalanceBefore - msg.value, 'Source token balance on contract must not decrease after swap');

        uint secondaryBalance;
        if (calls.length > 0) {
            require(toBalanceAfter - toBalanceBefore > 0, "No balance found after swaps");

            secondaryBalance = toBalanceAfter - toBalanceBefore;
            emit DexOutput(request.toToken, secondaryBalance);
        } else {
            secondaryBalance = toBalanceAfter > toBalanceBefore ? toBalanceAfter - toBalanceBefore : request.amountIn;
        }

        return (result, secondaryBalance);
    }

    /// @notice Private function to handle fetching money from wallet to contract, reduce fee/affiliate, perform DEX calls
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @dev It checks the whitelisting of all DEX addresses + having enough msg.value as input
    /// @dev It checks the max threshold for fee/affiliate
    /// @return The bytes of all DEX calls response
    function callSwapsAndFees(SwapRequest memory request, Call[] calldata calls) private returns (bytes[] memory) {
        bool isSourceNative = request.fromToken == ETH;
        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();
        
        // validate
        require(baseProxyStorage.feeContractAddress != ETH, "Fee contract address not set");

        for(uint256 i = 0; i < calls.length; i++) {
            require(baseProxyStorage.whitelistContracts[calls[i].spender], "Contract spender not whitelisted");
            require(baseProxyStorage.whitelistContracts[calls[i].target], "Contract target not whitelisted");
        }

        // Get all the money from user
        uint totalInputAmount = request.feeIn + request.affiliateIn + request.amountIn;
        if (isSourceNative)
            require(msg.value >= totalInputAmount, "Not enough ETH provided to contract");

        // Check max fee/affiliate is respected
        uint maxFee = totalInputAmount * MAX_FEE_PERCENT_x_10000 / 10000;
        uint maxAffiliate = totalInputAmount * MAX_AFFILIATE_PERCENT_x_10000 / 10000;
        require(request.feeIn <= maxFee, 'Requested fee exceeded max threshold');
        require(request.affiliateIn <= maxAffiliate, 'Requested affiliate reward exceeded max threshold');

        // Transfer from wallet to contract
        if (!isSourceNative) {
            for(uint256 i = 0; i < calls.length; i++) {
                approve(request.fromToken, calls[i].spender, totalInputAmount);
            }

            uint balanceBefore = getBalanceOf(request.fromToken);
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(request.fromToken), msg.sender, address(this), totalInputAmount);
            uint balanceAfter = getBalanceOf(request.fromToken);

            if(balanceAfter > balanceBefore && balanceAfter - balanceBefore < totalInputAmount)
                revert("Deflationary tokens are not supported by Rango contract");
        }

        // Get Platform fee
        if (request.feeIn > 0) {
            _sendToken(request.fromToken, request.feeIn, baseProxyStorage.feeContractAddress, isSourceNative, false);
            emit FeeReward(request.fromToken, baseProxyStorage.feeContractAddress, request.feeIn);
        }

        // Get affiliator fee
        if (request.affiliateIn > 0) {
            require(request.affiliatorAddress != ETH, "Invalid affiliatorAddress");
            _sendToken(request.fromToken, request.affiliateIn, request.affiliatorAddress, isSourceNative, false);
            emit AffiliateReward(request.fromToken, request.affiliatorAddress, request.affiliateIn);
        }

        bytes[] memory returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = isSourceNative
                ? calls[i].target.call{value: request.amountIn}(calls[i].callData)
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
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(token), to, 0);
        SafeERC20Upgradeable.safeIncreaseAllowance(IERC20Upgradeable(token), to, value);
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
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();
        emit SendToken(_token, _amount, _receiver);

        if (_nativeOut) {
            if (_withdraw) {
                require(_token == baseStorage.WETH, "token mismatch");
                IWETH(baseStorage.WETH).withdraw(_amount);
            }
            _sendNative(_receiver, _amount);
        } else {
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_token), _receiver, _amount);
        }
    }

    /// @notice An internal function to send native token to a contract or wallet
    /// @param _receiver The address that will receive the native token
    /// @param _amount The amount of the native token that should be sent
    function _sendNative(address _receiver, uint _amount) internal {
        (bool sent, ) = _receiver.call{value: _amount}("");
        require(sent, "failed to send native");
    }


    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getBaseProxyContractStorage() internal pure returns (BaseProxyStorage storage s) {
        bytes32 namespace = BASE_PROXY_CONTRACT_NAMESPACE;
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
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function getBalanceOf(address token) internal view returns (uint) {
        IERC20Upgradeable ercToken = IERC20Upgradeable(token);
        return token == ETH ? address(this).balance : ercToken.balanceOf(address(this));
    }
}