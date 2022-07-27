// $$\   $$\                     $$\                                 $$$$$$$\                      $$\
// $$ |  $$ |                    $$ |                                $$  __$$\                     $$ |
// $$ |  $$ |$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$\  $$$$$$$\        $$ |  $$ | $$$$$$\   $$$$$$\  $$ |
// $$$$$$$$ |$$ |  $$ |$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\       $$$$$$$  |$$  __$$\ $$  __$$\ $$ |
// $$  __$$ |$$ |  $$ |$$ /  $$ |$$ |  $$ |$$$$$$$$ |$$ |  $$ |      $$  ____/ $$ /  $$ |$$ /  $$ |$$ |
// $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$   ____|$$ |  $$ |      $$ |      $$ |  $$ |$$ |  $$ |$$ |
// $$ |  $$ |\$$$$$$$ |$$$$$$$  |$$ |  $$ |\$$$$$$$\ $$ |  $$ |      $$ |      \$$$$$$  |\$$$$$$  |$$ |
// \__|  \__| \____$$ |$$  ____/ \__|  \__| \_______|\__|  \__|      \__|       \______/  \______/ \__|
//           $$\   $$ |$$ |
//           \$$$$$$  |$$ |
//            \______/ \__|
//
// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./metatx/ERC2771ContextUpgradeable.sol";
import "../security/Pausable.sol";
import "./structures/TokenConfig.sol";
import "./interfaces/IExecutorManager.sol";
import "./interfaces/ILiquidityProviders.sol";
import "../interfaces/IERC20Permit.sol";
import "./interfaces/ITokenManager.sol";
import "./interfaces/ISwapAdaptor.sol";

contract LiquidityPool is
    Initializable,
    ReentrancyGuardUpgradeable,
    Pausable,
    OwnableUpgradeable,
    ERC2771ContextUpgradeable
{
    address private constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant BASE_DIVISOR = 10000000000; // Basis Points * 100 for better accuracy
    uint256 private constant TOKEN_PRICE_BASE_DIVISOR = 10**28;

    uint256 public baseGas;

    IExecutorManager private executorManager;
    ITokenManager public tokenManager;
    ILiquidityProviders public liquidityProviders;

    struct PermitRequest {
        uint256 nonce;
        uint256 expiry;
        bool allowed;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(bytes32 => bool) public processedHash;
    mapping(address => uint256) public gasFeeAccumulatedByToken;

    // Gas fee accumulated by token address => executor address
    mapping(address => mapping(address => uint256)) public gasFeeAccumulated;

    // Incentive Pool amount per token address
    mapping(address => uint256) public incentivePool;

    mapping(string => address) public swapAdaptorMap;

    event AssetSent(
        address indexed asset,
        uint256 indexed amount,
        uint256 indexed transferredAmount,
        address target,
        bytes depositHash,
        uint256 fromChainId,
        uint256 lpFee,
        uint256 transferFee,
        uint256 gasFee
    );
    event Received(address indexed from, uint256 indexed amount);
    event Deposit(
        address indexed from,
        address indexed tokenAddress,
        address indexed receiver,
        uint256 toChainId,
        uint256 amount,
        uint256 reward,
        string tag
    );
    event GasFeeWithdraw(address indexed tokenAddress, address indexed owner, uint256 indexed amount);
    event LiquidityProvidersChanged(address indexed liquidityProvidersAddress);
    event TokenManagerChanged(address indexed tokenManagerAddress);
    event BaseGasUpdated(uint256 indexed baseGas);
    event EthReceived(address, uint256);
    event DepositAndSwap(
        address indexed from,
        address indexed tokenAddress,
        address indexed receiver,
        uint256 toChainId,
        uint256 amount,
        uint256 reward,
        string tag,
        SwapRequest[] swapRequests
    );
    event SwapAdaptorChanged(string indexed name, address indexed liquidityProvidersAddress);
    event GasFeeCalculated(
        uint256 indexed gasUsed,
        uint256 indexed gasPrice,
        uint256 indexed nativeTokenPriceInTransferredToken,
        uint256 tokenGasBaseFee,
        uint256 gasFeeInTransferredToken
    );

    // MODIFIERS
    modifier onlyExecutor() {
        require(executorManager.getExecutorStatus(_msgSender()), "Only executor is allowed");
        _;
    }

    modifier onlyLiquidityProviders() {
        require(_msgSender() == address(liquidityProviders), "Only liquidityProviders is allowed");
        _;
    }

    modifier tokenChecks(address tokenAddress) {
        (, bool supportedToken, , , ) = tokenManager.tokensInfo(tokenAddress);
        require(supportedToken, "Token not supported");
        _;
    }

    function initialize(
        address _executorManagerAddress,
        address _pauser,
        address _trustedForwarder,
        address _tokenManager,
        address _liquidityProviders
    ) public initializer {
        require(_executorManagerAddress != address(0), "ExecutorManager cannot be 0x0");
        require(_trustedForwarder != address(0), "TrustedForwarder cannot be 0x0");
        require(_liquidityProviders != address(0), "LiquidityProviders cannot be 0x0");
        __ERC2771Context_init(_trustedForwarder);
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init(_pauser);
        executorManager = IExecutorManager(_executorManagerAddress);
        tokenManager = ITokenManager(_tokenManager);
        liquidityProviders = ILiquidityProviders(_liquidityProviders);
        baseGas = 21000;
    }

    function setSwapAdaptor(string calldata name, address _swapAdaptor) external onlyOwner {
        swapAdaptorMap[name] = _swapAdaptor;
        emit SwapAdaptorChanged(name, _swapAdaptor);
    }

    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _setTrustedForwarder(trustedForwarder);
    }

    function setLiquidityProviders(address _liquidityProviders) external onlyOwner {
        require(_liquidityProviders != address(0), "LiquidityProviders can't be 0");
        liquidityProviders = ILiquidityProviders(_liquidityProviders);
        emit LiquidityProvidersChanged(_liquidityProviders);
    }

    function setTokenManager(address _tokenManager) external onlyOwner {
        require(_tokenManager != address(0), "TokenManager can't be 0");
        tokenManager = ITokenManager(_tokenManager);
        emit TokenManagerChanged(_tokenManager);
    }

    function setBaseGas(uint128 gas) external onlyOwner {
        baseGas = gas;
        emit BaseGasUpdated(baseGas);
    }

    function getExecutorManager() external view returns (address) {
        return address(executorManager);
    }

    function setExecutorManager(address _executorManagerAddress) external onlyOwner {
        require(_executorManagerAddress != address(0), "Executor Manager cannot be 0");
        executorManager = IExecutorManager(_executorManagerAddress);
    }

    function getCurrentLiquidity(address tokenAddress) public view returns (uint256 currentLiquidity) {
        uint256 liquidityPoolBalance = liquidityProviders.getCurrentLiquidity(tokenAddress);

        currentLiquidity =
            liquidityPoolBalance -
            liquidityProviders.totalLPFees(tokenAddress) -
            gasFeeAccumulatedByToken[tokenAddress] -
            incentivePool[tokenAddress];
    }

    /**
     * @dev Function used to deposit tokens into pool to initiate a cross chain token transfer.
     * @param toChainId Chain id where funds needs to be transfered
     * @param tokenAddress ERC20 Token address that needs to be transfered
     * @param receiver Address on toChainId where tokens needs to be transfered
     * @param amount Amount of token being transfered
     */
    function depositErc20(
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string calldata tag
    ) public tokenChecks(tokenAddress) whenNotPaused nonReentrant {
        address sender = _msgSender();
        uint256 rewardAmount = _depositErc20(sender, toChainId, tokenAddress, receiver, amount);

        // Emit (amount + reward amount) in event
        emit Deposit(sender, tokenAddress, receiver, toChainId, amount + rewardAmount, rewardAmount, tag);
    }

    /**
     * @dev Function used to deposit tokens into pool to initiate a cross chain token swap And transfer .
     * @param toChainId Chain id where funds needs to be transfered
     * @param tokenAddress ERC20 Token address that needs to be transfered
     * @param receiver Address on toChainId where tokens needs to be transfered
     * @param amount Amount of token being transfered
     * @param tag Dapp unique identifier
     * @param swapRequest information related to token swap on exit chain
     */
    function depositAndSwapErc20(
        address tokenAddress,
        address receiver,
        uint256 toChainId,
        uint256 amount,
        string calldata tag,
        SwapRequest[] calldata swapRequest
    ) external tokenChecks(tokenAddress) whenNotPaused nonReentrant {
        uint256 totalPercentage = 0;
        {
            uint256 swapArrayLength = swapRequest.length;
            unchecked {
                for (uint256 index = 0; index < swapArrayLength; ++index) {
                    totalPercentage += swapRequest[index].percentage;
                }
            }
        }

        require(totalPercentage <= 100 * BASE_DIVISOR, "Total percentage cannot be > 100");
        address sender = _msgSender();
        uint256 rewardAmount = _depositErc20(sender, toChainId, tokenAddress, receiver, amount);
        // Emit (amount + reward amount) in event
        emit DepositAndSwap(
            sender,
            tokenAddress,
            receiver,
            toChainId,
            amount + rewardAmount,
            rewardAmount,
            tag,
            swapRequest
        );
    }

    function _depositErc20(
        address sender,
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount
    ) internal returns (uint256) {
        require(toChainId != block.chainid, "To chain must be different than current chain");
        require(tokenAddress != NATIVE, "wrong function");
        TokenConfig memory config = tokenManager.getDepositConfig(toChainId, tokenAddress);

        require(config.min <= amount && config.max >= amount, "Deposit amount not in Cap limit");
        require(receiver != address(0), "Receiver address cannot be 0");
        require(amount != 0, "Amount cannot be 0");

        uint256 rewardAmount = getRewardAmount(amount, tokenAddress);
        if (rewardAmount != 0) {
            incentivePool[tokenAddress] = incentivePool[tokenAddress] - rewardAmount;
        }
        liquidityProviders.increaseCurrentLiquidity(tokenAddress, amount);
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(tokenAddress), sender, address(this), amount);
        return rewardAmount;
    }

    function getRewardAmount(uint256 amount, address tokenAddress) public view returns (uint256 rewardAmount) {
        uint256 currentLiquidity = getCurrentLiquidity(tokenAddress);
        uint256 providedLiquidity = liquidityProviders.getSuppliedLiquidityByToken(tokenAddress);
        if (currentLiquidity < providedLiquidity) {
            uint256 liquidityDifference = providedLiquidity - currentLiquidity;
            if (amount >= liquidityDifference) {
                rewardAmount = incentivePool[tokenAddress];
            } else {
                // Multiply by 10000000000 to avoid 0 reward amount for small amount and liquidity difference
                rewardAmount = (amount * incentivePool[tokenAddress] * 10000000000) / liquidityDifference;
                rewardAmount = rewardAmount / 10000000000;
            }
        }
    }

    /**
     * DAI permit and Deposit.
     */
    function permitAndDepositErc20(
        address tokenAddress,
        address receiver,
        uint256 amount,
        uint256 toChainId,
        PermitRequest calldata permitOptions,
        string calldata tag
    ) external {
        IERC20Permit(tokenAddress).permit(
            _msgSender(),
            address(this),
            permitOptions.nonce,
            permitOptions.expiry,
            permitOptions.allowed,
            permitOptions.v,
            permitOptions.r,
            permitOptions.s
        );
        depositErc20(toChainId, tokenAddress, receiver, amount, tag);
    }

    /**
     * EIP2612 and Deposit.
     */
    function permitEIP2612AndDepositErc20(
        address tokenAddress,
        address receiver,
        uint256 amount,
        uint256 toChainId,
        PermitRequest calldata permitOptions,
        string calldata tag
    ) external {
        IERC20Permit(tokenAddress).permit(
            _msgSender(),
            address(this),
            amount,
            permitOptions.expiry,
            permitOptions.v,
            permitOptions.r,
            permitOptions.s
        );
        depositErc20(toChainId, tokenAddress, receiver, amount, tag);
    }

    /**
     * @dev Function used to deposit native token into pool to initiate a cross chain token transfer.
     * @param receiver Address on toChainId where tokens needs to be transfered
     * @param toChainId Chain id where funds needs to be transfered
     */
    function depositNative(
        address receiver,
        uint256 toChainId,
        string calldata tag
    ) external payable whenNotPaused nonReentrant {
        uint256 rewardAmount = _depositNative(receiver, toChainId);
        emit Deposit(_msgSender(), NATIVE, receiver, toChainId, msg.value + rewardAmount, rewardAmount, tag);
    }

    function depositNativeAndSwap(
        address receiver,
        uint256 toChainId,
        string calldata tag,
        SwapRequest[] calldata swapRequest
    ) external payable whenNotPaused nonReentrant {
        uint256 totalPercentage = 0;
        {
            uint256 swapArrayLength = swapRequest.length;
            unchecked {
                for (uint256 index = 0; index < swapArrayLength; ++index) {
                    totalPercentage += swapRequest[index].percentage;
                }
            }
        }

        require(totalPercentage <= 100 * BASE_DIVISOR, "Total percentage cannot be > 100");

        uint256 rewardAmount = _depositNative(receiver, toChainId); // TODO: check if need to pass msg.value
        emit DepositAndSwap(
            _msgSender(),
            NATIVE,
            receiver,
            toChainId,
            msg.value + rewardAmount,
            rewardAmount,
            tag,
            swapRequest
        );
    }

    function _depositNative(address receiver, uint256 toChainId) internal returns (uint256) {
        require(toChainId != block.chainid, "To chain must be different than current chain");
        require(
            tokenManager.getDepositConfig(toChainId, NATIVE).min <= msg.value &&
                tokenManager.getDepositConfig(toChainId, NATIVE).max >= msg.value,
            "Deposit amount not in Cap limit"
        );
        require(receiver != address(0), "Receiver address cannot be 0");
        require(msg.value != 0, "Amount cannot be 0");

        uint256 rewardAmount = getRewardAmount(msg.value, NATIVE);
        if (rewardAmount != 0) {
            incentivePool[NATIVE] = incentivePool[NATIVE] - rewardAmount;
        }
        liquidityProviders.increaseCurrentLiquidity(NATIVE, msg.value);
        return rewardAmount;
    }

    function sendFundsToUser(
        address tokenAddress,
        uint256 amount,
        address payable receiver,
        bytes calldata depositHash,
        uint256 tokenGasPrice,
        uint256 fromChainId
    ) external nonReentrant onlyExecutor whenNotPaused {
        uint256 initialGas = gasleft();
        TokenConfig memory config = tokenManager.getTransferConfig(tokenAddress);
        require(config.min <= amount && config.max >= amount, "Withdraw amount not in Cap limit");
        require(receiver != address(0), "Bad receiver address");

        (bytes32 hashSendTransaction, bool status) = checkHashStatus(tokenAddress, amount, receiver, depositHash);

        require(!status, "Already Processed");
        processedHash[hashSendTransaction] = true;

        // uint256 amountToTransfer, uint256 lpFee, uint256 transferFeeAmount, uint256 gasFee
        uint256[4] memory transferDetails = getAmountToTransfer(initialGas, tokenAddress, amount, tokenGasPrice);

        liquidityProviders.decreaseCurrentLiquidity(tokenAddress, transferDetails[0]);

        if (tokenAddress == NATIVE) {
            (bool success, ) = receiver.call{value: transferDetails[0]}("");
            require(success, "Native Transfer Failed");
        } else {
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(tokenAddress), receiver, transferDetails[0]);
        }

        emit AssetSent(
            tokenAddress,
            amount,
            transferDetails[0],
            receiver,
            depositHash,
            fromChainId,
            transferDetails[1],
            transferDetails[2],
            transferDetails[3]
        );
    }

    /**
     * @dev Internal function to calculate amount of token that needs to be transfered afetr deducting all required fees.
     * Fee to be deducted includes gas fee, lp fee and incentive pool amount if needed.
     * @param initialGas Gas provided initially before any calculations began
     * @param tokenAddress Token address for which calculation needs to be done
     * @param amount Amount of token to be transfered before deducting the fee
     * @param tokenGasPrice Gas price in the token being transfered to be used to calculate gas fee
     * @return [ amountToTransfer, lpFee, transferFeeAmount, gasFee ]
     */
    function getAmountToTransfer(
        uint256 initialGas,
        address tokenAddress,
        uint256 amount,
        uint256 tokenGasPrice
    ) internal returns (uint256[4] memory) {
        TokenInfo memory tokenInfo = tokenManager.getTokensInfo(tokenAddress);
        uint256 transferFeePerc = _getTransferFee(tokenAddress, amount, tokenInfo);
        uint256 lpFee;
        if (transferFeePerc > tokenInfo.equilibriumFee) {
            // Here add some fee to incentive pool also
            lpFee = (amount * tokenInfo.equilibriumFee) / BASE_DIVISOR;
            unchecked {
                incentivePool[tokenAddress] += (amount * (transferFeePerc - tokenInfo.equilibriumFee)) / BASE_DIVISOR;
            }
        } else {
            lpFee = (amount * transferFeePerc) / BASE_DIVISOR;
        }
        uint256 transferFeeAmount = (amount * transferFeePerc) / BASE_DIVISOR;

        liquidityProviders.addLPFee(tokenAddress, lpFee);

        uint256 totalGasUsed = initialGas + tokenInfo.transferOverhead + baseGas - gasleft();

        uint256 gasFee = totalGasUsed * tokenGasPrice;
        gasFeeAccumulatedByToken[tokenAddress] += gasFee;
        gasFeeAccumulated[tokenAddress][_msgSender()] += gasFee;
        uint256 amountToTransfer = amount - (transferFeeAmount + gasFee);
        return [amountToTransfer, lpFee, transferFeeAmount, gasFee];
    }

    function sendFundsToUserV2(
        address tokenAddress,
        uint256 amount,
        address payable receiver,
        bytes calldata depositHash,
        uint256 nativeTokenPriceInTransferredToken,
        uint256 fromChainId,
        uint256 tokenGasBaseFee
    ) external nonReentrant onlyExecutor whenNotPaused {
        uint256[4] memory transferDetails = _calculateAmountAndDecreaseAvailableLiquidity(
            tokenAddress,
            amount,
            receiver,
            depositHash,
            nativeTokenPriceInTransferredToken,
            tokenGasBaseFee
        );
        if (tokenAddress == NATIVE) {
            (bool success, ) = receiver.call{value: transferDetails[0]}("");
            require(success, "Native Transfer Failed");
        } else {
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(tokenAddress), receiver, transferDetails[0]);
        }

        emit AssetSent(
            tokenAddress,
            amount,
            transferDetails[0],
            receiver,
            depositHash,
            fromChainId,
            transferDetails[1],
            transferDetails[2],
            transferDetails[3]
        );
    }

    function swapAndSendFundsToUser(
        address tokenAddress,
        uint256 amount,
        address payable receiver,
        bytes calldata depositHash,
        uint256 nativeTokenPriceInTransferredToken,
        uint256 tokenGasBaseFee,
        uint256 fromChainId,
        uint256 swapGasOverhead,
        SwapRequest[] calldata swapRequests,
        string memory swapAdaptor
    ) external nonReentrant onlyExecutor whenNotPaused {
        require(swapRequests.length > 0, "Wrong method call");
        require(swapAdaptorMap[swapAdaptor] != address(0), "Swap adaptor not found");

        uint256[4] memory transferDetails = _calculateAmountAndDecreaseAvailableLiquidity(
            tokenAddress,
            amount,
            receiver,
            depositHash,
            nativeTokenPriceInTransferredToken,
            tokenGasBaseFee
        );

        if (tokenAddress == NATIVE) {
            (bool success, ) = swapAdaptorMap[swapAdaptor].call{value: transferDetails[0]}("");
            require(success, "Native Transfer to Adaptor Failed");
            ISwapAdaptor(swapAdaptorMap[swapAdaptor]).swapNative(transferDetails[0], receiver, swapRequests);
        } else {
            {
                uint256 gasBeforeApproval = gasleft();
                SafeERC20Upgradeable.safeApprove(
                    IERC20Upgradeable(tokenAddress),
                    address(swapAdaptorMap[swapAdaptor]),
                    0
                );
                SafeERC20Upgradeable.safeApprove(
                    IERC20Upgradeable(tokenAddress),
                    address(swapAdaptorMap[swapAdaptor]),
                    transferDetails[0]
                );

                swapGasOverhead += (gasBeforeApproval - gasleft());
            }
            {
                uint256 swapGasFee = calculateGasFee(
                    tokenAddress,
                    nativeTokenPriceInTransferredToken,
                    swapGasOverhead,
                    0,
                    _msgSender()
                );
                transferDetails[0] -= swapGasFee; // Deduct swap gas fee from amount to be sent
                transferDetails[3] += swapGasFee; // Add swap gas fee to gas fee
            }

            ISwapAdaptor(swapAdaptorMap[swapAdaptor]).swap(tokenAddress, transferDetails[0], receiver, swapRequests);
        }

        emit AssetSent(
            tokenAddress,
            amount,
            transferDetails[0],
            receiver,
            depositHash,
            fromChainId,
            transferDetails[1],
            transferDetails[2],
            transferDetails[3]
        );
    }

    function _calculateAmountAndDecreaseAvailableLiquidity(
        address tokenAddress,
        uint256 amount,
        address payable receiver,
        bytes calldata depositHash,
        uint256 nativeTokenPriceInTransferredToken,
        uint256 tokenGasBaseFee
    ) internal returns (uint256[4] memory) {
        uint256 initialGas = gasleft();
        TokenConfig memory config = tokenManager.getTransferConfig(tokenAddress);
        require(config.min <= amount && config.max >= amount, "Withdraw amount not in Cap limit");
        require(receiver != address(0), "Bad receiver address");
        (bytes32 hashSendTransaction, bool status) = checkHashStatus(tokenAddress, amount, receiver, depositHash);

        require(!status, "Already Processed");
        processedHash[hashSendTransaction] = true;
        // uint256 amountToTransfer, uint256 lpFee, uint256 transferFeeAmount, uint256 gasFee
        uint256[4] memory transferDetails = getAmountToTransferV2(
            initialGas,
            tokenAddress,
            amount,
            nativeTokenPriceInTransferredToken,
            tokenGasBaseFee
        );

        liquidityProviders.decreaseCurrentLiquidity(tokenAddress, transferDetails[0]);

        return transferDetails;
    }

    /**
     * @dev Internal function to calculate amount of token that needs to be transfered afetr deducting all required fees.
     * Fee to be deducted includes gas fee, lp fee and incentive pool amount if needed.
     * @param initialGas Gas provided initially before any calculations began
     * @param tokenAddress Token address for which calculation needs to be done
     * @param amount Amount of token to be transfered before deducting the fee
     * @param nativeTokenPriceInTransferredToken Price of native token in terms of the token being transferred (multiplied base div), used to calculate gas fee
     * @return [ amountToTransfer, lpFee, transferFeeAmount, gasFee ]
     */
    function getAmountToTransferV2(
        uint256 initialGas,
        address tokenAddress,
        uint256 amount,
        uint256 nativeTokenPriceInTransferredToken,
        uint256 tokenGasBaseFee
    ) internal returns (uint256[4] memory) {
        TokenInfo memory tokenInfo = tokenManager.getTokensInfo(tokenAddress);
        uint256 transferFeePerc = _getTransferFee(tokenAddress, amount, tokenInfo);
        uint256 lpFee;
        if (transferFeePerc > tokenInfo.equilibriumFee) {
            // Here add some fee to incentive pool also
            lpFee = (amount * tokenInfo.equilibriumFee) / BASE_DIVISOR;
            unchecked {
                incentivePool[tokenAddress] += (amount * (transferFeePerc - tokenInfo.equilibriumFee)) / BASE_DIVISOR;
            }
        } else {
            lpFee = (amount * transferFeePerc) / BASE_DIVISOR;
        }
        uint256 transferFeeAmount = (amount * transferFeePerc) / BASE_DIVISOR;

        liquidityProviders.addLPFee(tokenAddress, lpFee);

        uint256 totalGasUsed = initialGas + tokenInfo.transferOverhead + baseGas - gasleft();
        uint256 gasFee = calculateGasFee(
            tokenAddress,
            nativeTokenPriceInTransferredToken,
            totalGasUsed,
            tokenGasBaseFee,
            _msgSender()
        );
        require(transferFeeAmount + gasFee <= amount, "Insufficient funds to cover transfer fee");
        unchecked {
            uint256 amountToTransfer = amount - (transferFeeAmount + gasFee);
            return [amountToTransfer, lpFee, transferFeeAmount, gasFee];
        }
    }

    function calculateGasFee(
        address tokenAddress,
        uint256 nativeTokenPriceInTransferredToken,
        uint256 gasUsed,
        uint256 tokenGasBaseFee,
        address sender
    ) internal returns (uint256) {
        uint256 gasFee = (gasUsed * nativeTokenPriceInTransferredToken * tx.gasprice) /
            TOKEN_PRICE_BASE_DIVISOR +
            tokenGasBaseFee;
        emit GasFeeCalculated(gasUsed, tx.gasprice, nativeTokenPriceInTransferredToken, tokenGasBaseFee, gasFee);

        gasFeeAccumulatedByToken[tokenAddress] += gasFee;
        gasFeeAccumulated[tokenAddress][sender] += gasFee;
        return gasFee;
    }

    function _getTransferFee(
        address tokenAddress,
        uint256 amount,
        TokenInfo memory tokenInfo
    ) private view returns (uint256) {
        uint256 currentLiquidity = getCurrentLiquidity(tokenAddress);
        uint256 providedLiquidity = liquidityProviders.getSuppliedLiquidityByToken(tokenAddress);

        uint256 resultingLiquidity = currentLiquidity - amount;

        // We return a constant value in excess state
        if (resultingLiquidity > providedLiquidity) {
            return tokenManager.excessStateTransferFeePerc(tokenAddress);
        }

        // Fee is represented in basis points * 10 for better accuracy
        uint256 numerator = providedLiquidity * providedLiquidity * tokenInfo.equilibriumFee * tokenInfo.maxFee; // F(max) * F(e) * L(e) ^ 2
        uint256 denominator = tokenInfo.equilibriumFee *
            providedLiquidity *
            providedLiquidity +
            (tokenInfo.maxFee - tokenInfo.equilibriumFee) *
            resultingLiquidity *
            resultingLiquidity; // F(e) * L(e) ^ 2 + (F(max) - F(e)) * L(r) ^ 2

        uint256 fee;
        if (denominator == 0) {
            fee = 0;
        } else {
            fee = numerator / denominator;
        }
        return fee;
    }

    function getTransferFee(address tokenAddress, uint256 amount) external view returns (uint256) {
        return _getTransferFee(tokenAddress, amount, tokenManager.getTokensInfo(tokenAddress));
    }

    function checkHashStatus(
        address tokenAddress,
        uint256 amount,
        address payable receiver,
        bytes calldata depositHash
    ) public view returns (bytes32 hashSendTransaction, bool status) {
        hashSendTransaction = keccak256(abi.encode(tokenAddress, amount, receiver, keccak256(depositHash)));

        status = processedHash[hashSendTransaction];
    }

    function withdrawErc20GasFee(address tokenAddress) external onlyExecutor whenNotPaused nonReentrant {
        require(tokenAddress != NATIVE, "Can't withdraw native token fee");
        // uint256 gasFeeAccumulated = gasFeeAccumulatedByToken[tokenAddress];
        uint256 _gasFeeAccumulated = gasFeeAccumulated[tokenAddress][_msgSender()];
        require(_gasFeeAccumulated != 0, "Gas Fee earned is 0");
        gasFeeAccumulatedByToken[tokenAddress] = gasFeeAccumulatedByToken[tokenAddress] - _gasFeeAccumulated;
        gasFeeAccumulated[tokenAddress][_msgSender()] = 0;
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(tokenAddress), _msgSender(), _gasFeeAccumulated);
        emit GasFeeWithdraw(tokenAddress, _msgSender(), _gasFeeAccumulated);
    }

    function withdrawNativeGasFee() external onlyExecutor whenNotPaused nonReentrant {
        uint256 _gasFeeAccumulated = gasFeeAccumulated[NATIVE][_msgSender()];
        require(_gasFeeAccumulated != 0, "Gas Fee earned is 0");
        gasFeeAccumulatedByToken[NATIVE] = gasFeeAccumulatedByToken[NATIVE] - _gasFeeAccumulated;
        gasFeeAccumulated[NATIVE][_msgSender()] = 0;
        (bool success, ) = payable(_msgSender()).call{value: _gasFeeAccumulated}("");
        require(success, "Native Transfer Failed");

        emit GasFeeWithdraw(address(this), _msgSender(), _gasFeeAccumulated);
    }

    function transfer(
        address _tokenAddress,
        address receiver,
        uint256 _tokenAmount
    ) external whenNotPaused onlyLiquidityProviders nonReentrant {
        require(receiver != address(0), "Invalid receiver");
        if (_tokenAddress == NATIVE) {
            require(address(this).balance >= _tokenAmount, "ERR__INSUFFICIENT_BALANCE");
            (bool success, ) = receiver.call{value: _tokenAmount}("");
            require(success, "ERR__NATIVE_TRANSFER_FAILED");
        } else {
            IERC20Upgradeable baseToken = IERC20Upgradeable(_tokenAddress);
            require(baseToken.balanceOf(address(this)) >= _tokenAmount, "ERR__INSUFFICIENT_BALANCE");
            SafeERC20Upgradeable.safeTransfer(baseToken, receiver, _tokenAmount);
        }
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    receive() external payable {
        emit EthReceived(_msgSender(), msg.value);
    }
}