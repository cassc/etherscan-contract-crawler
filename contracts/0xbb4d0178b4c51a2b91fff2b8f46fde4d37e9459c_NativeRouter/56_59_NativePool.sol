// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {INativePool} from "./interfaces/INativePool.sol";
import {INativeRouter} from "./interfaces/INativeRouter.sol";
import {INativeTreasury} from "./interfaces/INativeTreasury.sol";
import {IWETH9} from "./libraries/IWETH9.sol";
import {Orders} from "./libraries/Order.sol";
import {Blacklistable} from "./Blacklistable.sol";
import {Registry} from "./Registry.sol";
import {NativeRouter} from "./NativeRouter.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/FullMath.sol";
import "./libraries/NoDelegateCallUpgradable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./storage/NativePoolStorage.sol";

contract NativePool is
    INativePool,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    NoDelegateCallUpgradable,
    Blacklistable,
    UUPSUpgradeable,
    NativePoolStorage
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IWETH9;
    uint256 public constant FIXED_PRICE_MODEL_ID = 99;
    uint256 public constant PMM_PRICE_MODEL_ID = 100;
    uint256 public constant CONSTANT_SUM_PRICE_MODEL_ID = 0;
    uint256 public constant UNISWAP_V2_PRICE_MODEL_ID = 1;
    uint256 internal constant TEN_THOUSAND_DENOMINATOR = 10000;
    // keccak256("Order(uint256 id,address signer,address buyer,address seller,address buyerToken,address sellerToken,uint256 buyerTokenAmount,uint256 sellerTokenAmount,uint256 deadlineTimestamp,address caller,bytes16 quoteId)");
    bytes32 private constant ORDER_SIGNATURE_HASH = 0xcdd3cf1659a8da07564b163a4df90f66944547e93f0bb61ba676c459a2db4e20;

    modifier onlyRouter() {
        require(msg.sender == router, "Message sender should only be the router");
        _;
    }

    modifier onlyNotPmm() {
        require(!isPmm, "Not allowed to call this function when PMM is used");
        _;
    }

    modifier onlyPrivateTreasury() {
        require(!isPublicTreasury, "only private treasury is allowed for this operation");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(NewPoolConfig calldata poolConfig, address _pricingModelRegistry) external override initializer {
        __EIP712_init("native pool", "1");
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
        __NoDelegateCall_init();
        require(poolConfig.treasuryAddress != address(0), "treasury address specified should not be zero address");
        require(
            poolConfig.poolOwnerAddress != address(0),
            "treasuryOwner address specified should not be zero address"
        );
        require(poolConfig.signerAddress != address(0), "signer address specified should not be zero address");
        require(
            _pricingModelRegistry != address(0),
            "pricingModelRegistry address specified should not be zero address"
        );
        treasury = poolConfig.treasuryAddress;
        treasuryOwner = poolConfig.poolOwnerAddress;
        isSigner[poolConfig.signerAddress] = true;
        pricingModelRegistry = _pricingModelRegistry;
        setRouter(poolConfig.routerAddress);
        executeUpdatePairs(poolConfig.fees, poolConfig.tokenAs, poolConfig.tokenBs, poolConfig.pricingModelIds);
        poolFactory = msg.sender;
        isTreasuryContract = poolConfig.isTreasuryContract;
        isPublicTreasury = poolConfig.isPublicTreasury;

        emit SetTreasury(treasury);
        emit SetTreasuryOwner(treasuryOwner);
        emit AddSigner(poolConfig.signerAddress);
    }

    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == poolFactory, "only PoolFactory can call this");
    }

    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

    function setRouter(address _router) internal {
        require(_router != address(0), "router address specified should not be zero address");
        require(router == address(0), "router address is already set");
        router = _router;
        emit SetRouter(router);
    }

    function isOnChainPricing() public view returns (bool) {
        if (isPmm || pairCount == 0) {
            return false;
        } else {
            // should only have 1 pair
            address tokenA = tokenAs[0];
            address tokenB = tokenBs[0];
            Pair storage pair = pairs[tokenA][tokenB];
            return
                pair.pricingModelId == CONSTANT_SUM_PRICE_MODEL_ID ||
                pair.pricingModelId == UNISWAP_V2_PRICE_MODEL_ID;
        }
    }

    function setPauser(address _pauser) external onlyOwner {
        pauser = _pauser;
    }

    modifier onlyOwnerOrPauserOrPoolFactory() {
        if (msg.sender != owner() && msg.sender != pauser && msg.sender != poolFactory) {
            revert onlyOwnerOrPauserOrPoolFactoryCanCall();
        }
        _;
    }

    function pause() external onlyOwnerOrPauserOrPoolFactory {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addSigner(address _signer) external override onlyOwner whenNotPaused {
        require(!isSigner[_signer], "Signer is already added");
        isSigner[_signer] = true;
        emit AddSigner(_signer);
    }

    function removeSigner(address _signer) external override onlyOwner whenNotPaused {
        require(isSigner[_signer], "Signer has not added");
        isSigner[_signer] = false;
        emit RemoveSigner(_signer);
    }

    function swap(
        bytes memory order,
        bytes calldata signature,
        uint256 flexibleAmount,
        address recipient,
        bytes calldata callback
    ) external override nonReentrant whenNotPaused onlyRouter returns (int256, int256) {
        Orders.Order memory _order = abi.decode(order, (Orders.Order));
        if (!isOnChainPricing()) {
            require(verifySignature(_order, signature), "Signature is invalid");
        }
        require(_order.deadlineTimestamp > block.timestamp, "Order is expired");
        require(!nonceMapping[_order.caller][_order.id], "Nonce already used");
        nonceMapping[_order.caller][_order.id] = true;

        require(pairExist(_order.sellerToken, _order.buyerToken), "Pair not exist");
        require(flexibleAmount != 0, "Flexible amount cannot be 0");
        require(!blacklisted[_order.caller], "Account is blacklisted");

        uint256 buyerTokenAmount;
        uint256 sellerTokenAmount;
        uint256 pricingModelId;

        pricingModelId = getPairPricingModel(_order.sellerToken, _order.buyerToken);
        {
            (buyerTokenAmount, sellerTokenAmount) = calculateTokenAmount(
                flexibleAmount,
                _order,
                pricingModelId
            );
        }
        {
            (int256 amount0Delta, int256 amount1Delta) = executeSwap(
                SwapParam({
                    buyerTokenAmount: buyerTokenAmount,
                    sellerTokenAmount: sellerTokenAmount,
                    _order: _order,
                    recipient: recipient,
                    callback: callback,
                    pricingModelId: pricingModelId
                })
            );
            uint256 fee = getPairFee(_order.sellerToken, _order.buyerToken);
            if (amount0Delta < 0) {
                emit Swap(
                    _order.caller,
                    recipient,
                    _order.sellerToken,
                    _order.buyerToken,
                    amount1Delta,
                    amount0Delta,
                    FullMath.mulDivRoundingUp(uint256(amount1Delta), fee, TEN_THOUSAND_DENOMINATOR),
                    _order.quoteId
                );
            } else {
                emit Swap(
                    _order.caller,
                    recipient,
                    _order.sellerToken,
                    _order.buyerToken,
                    amount0Delta,
                    amount1Delta,
                    FullMath.mulDivRoundingUp(uint256(amount0Delta), fee, TEN_THOUSAND_DENOMINATOR),
                    _order.quoteId
                );
            }
            if (isTreasuryContract) {
                INativeTreasury(treasury).syncReserve();
            }
            return (amount0Delta, amount1Delta);
        }
    }

    function pairExist(address tokenIn, address tokenOut) public view returns (bool exist) {
        (address token0, address token1) = tokenIn < tokenOut
            ? (tokenIn, tokenOut)
            : (tokenOut, tokenIn);
        return pairs[token0][token1].isExist;
    }

    function getTokenAs() public view returns (address[] memory) {
        return tokenAs;
    }

    function getTokenBs() public view returns (address[] memory) {
        return tokenBs;
    }

    function getPairPricingModel(
        address tokenIn,
        address tokenOut
    ) public view returns (uint256 pricingModelId) {
        require(pairExist(tokenIn, tokenOut), "Pair not exist");
        (address token0, address token1) = tokenIn < tokenOut
            ? (tokenIn, tokenOut)
            : (tokenOut, tokenIn);
        return pairs[token0][token1].pricingModelId;
    }

    function getPairFee(address tokenIn, address tokenOut) public view returns (uint256 fee) {
        require(pairExist(tokenIn, tokenOut), "Pair not exist");
        (address token0, address token1) = tokenIn < tokenOut
            ? (tokenIn, tokenOut)
            : (tokenOut, tokenIn);
        return pairs[token0][token1].fee;
    }

    function executeUpdatePairs(
        uint256[] memory _fees,
        address[] memory _tokenAs,
        address[] memory _tokenBs,
        uint256[] memory _pricingModelIds
    ) private {
        require(
            _fees.length == _tokenAs.length &&
                _fees.length == _tokenBs.length &&
                _fees.length == _pricingModelIds.length,
            "Pair array length mismatch"
        );
        for (uint i = 0; i < _fees.length; ) {
            require(_tokenAs[i] != _tokenBs[i], "Identical addresses");
            require(_fees[i] <= 10000, "Fee should be between 0 and 10k basis points");
            (address token0, address token1) = _tokenAs[i] < _tokenBs[i]
                ? (_tokenAs[i], _tokenBs[i])
                : (_tokenBs[i], _tokenAs[i]);

            require(token0 != address(0), "Zero address in pair");

            bool isPairExist = pairExist(token0, token1);

            if (isPmm) {
                require(
                    _pricingModelIds[i] == PMM_PRICE_MODEL_ID,
                    "Can only add PMM pairs to pool using PMM"
                );
            } else {
                require(
                    pairCount == 0 || isPairExist,
                    "Can not have more than 1 pair for non PMM pool"
                );
            }

            uint256 pricingModelIdOld = 0;
            uint256 feeOld = 0;

            if (!isPairExist) {
                tokenAs.push(token0);
                tokenBs.push(token1);
                pairCount++;
            } else {
                pricingModelIdOld = pairs[token0][token1].pricingModelId;
                feeOld = pairs[token0][token1].fee;
            }
            pairs[token0][token1] = Pair({
                fee: _fees[i],
                isExist: true,
                pricingModelId: _pricingModelIds[i]
            });
            if (!isPmm && _pricingModelIds[i] == PMM_PRICE_MODEL_ID) {
                isPmm = true;
            }

            emit UpdatePair(
                token0,
                token1,
                feeOld,
                _fees[i],
                pricingModelIdOld,
                _pricingModelIds[i]
            );
            unchecked {
                i++;
            }
        }
    }

    function updatePairs(
        uint256[] calldata _fees,
        address[] calldata _tokenAs,
        address[] calldata _tokenBs,
        uint256[] calldata _pricingModelIds
    ) public whenNotPaused onlyPrivateTreasury {
        require(msg.sender == treasuryOwner, "Unauthorized to whitelist pairs");
        executeUpdatePairs(_fees, _tokenAs, _tokenBs, _pricingModelIds);
    }

    function removePair(uint256 removingIdx) public whenNotPaused {
        require(removingIdx < pairCount, "removePair: index out of range");
        require(removingIdx < tokenAs.length, "removePair: index out of range");
        require(msg.sender == treasuryOwner, "Unauthorized to whitelist pairs");
        address token0 = tokenAs[removingIdx];
        address token1 = tokenBs[removingIdx];
        require(pairExist(token0, token1), "Pair not exist");

        delete pairs[token0][token1];
        tokenAs[removingIdx] = tokenAs[tokenAs.length - 1];
        tokenAs.pop();
        tokenBs[removingIdx] = tokenBs[tokenBs.length - 1];
        tokenBs.pop();
        pairCount--;

        emit RemovePair(token0, token1);
    }

    function getAmountOut(
        uint256 amountIn,
        address _tokenIn,
        address _tokenOut
    ) public view returns (uint amountOut) {
        uint256 pricingModelId = getPairPricingModel(_tokenIn, _tokenOut);
        require(
            pricingModelId != FIXED_PRICE_MODEL_ID && pricingModelId != PMM_PRICE_MODEL_ID,
            "Off-chain pricing unsupported"
        );
        Registry registry = Registry(pricingModelRegistry);

        address tokenIn = _tokenIn;
        address tokenOut = _tokenOut;

        uint256 fee = getPairFee(tokenIn, tokenOut);

        return
            registry.getAmountOut(
                amountIn,
                fee,
                pricingModelId,
                treasury,
                tokenIn,
                tokenOut,
                isTreasuryContract
            );
    }

    function getPricingModelRegistry() public view returns (address) {
        return pricingModelRegistry;
    }

    // private methods
    function calculateTokenAmount(
        uint256 flexibleAmount,
        Orders.Order memory _order,
        uint256 pricingModelId
    ) private view returns (uint256, uint256) {
        uint256 buyerTokenAmount;
        uint256 sellerTokenAmount;

        sellerTokenAmount = flexibleAmount >= _order.sellerTokenAmount
            ? _order.sellerTokenAmount
            : flexibleAmount;

        if (pricingModelId != FIXED_PRICE_MODEL_ID && pricingModelId != PMM_PRICE_MODEL_ID) {
            buyerTokenAmount = getAmountOut(
                sellerTokenAmount,
                _order.sellerToken,
                _order.buyerToken
            );
        } else {
            require(
                _order.sellerTokenAmount > 0 && _order.buyerTokenAmount > 0,
                "Non-zero amount required"
            );

            buyerTokenAmount = FullMath.mulDiv(
                sellerTokenAmount,
                _order.buyerTokenAmount,
                _order.sellerTokenAmount
            );
        }
        require(buyerTokenAmount > 0 && sellerTokenAmount > 0, "Non-zero amount required");

        return (buyerTokenAmount, sellerTokenAmount);
    }

    function executeSwap(SwapParam memory swapParam) private returns (int256, int256) {
        // Transfer token from treasury to user / router
        executeSwapFromTreasury(swapParam.buyerTokenAmount, swapParam._order, swapParam.recipient);
        // Transfer token from user / router, to pool, then to treasury
        return
            executeSwapToTreasury(
                swapParam._order,
                swapParam.sellerTokenAmount,
                swapParam.buyerTokenAmount,
                swapParam.callback
            );
    }

    // internal methods
    function getMessageHash(Orders.Order memory _order) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encode(
                ORDER_SIGNATURE_HASH,
                _order.id,
                _order.signer,
                _order.buyer,
                _order.seller,
                _order.buyerToken,
                _order.sellerToken,
                _order.buyerTokenAmount,
                _order.sellerTokenAmount,
                _order.deadlineTimestamp,
                _order.caller,
                _order.quoteId
            )
        );
        return hash;
    }

    function verifySignature(
        Orders.Order memory _order,
        bytes calldata signature
    ) internal view returns (bool) {
        require(isSigner[_order.signer], "Signer is invalid");
        bytes32 digest = _hashTypedDataV4(getMessageHash(_order));

        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature);
        return _order.signer == recoveredSigner;
    }

    function executeSwapFromTreasury(
        uint256 amount,
        Orders.Order memory _order,
        address recipient
    ) internal {
        address buyerToken = _order.buyerToken;
        uint256 treasuryBalanceInitial = IERC20Upgradeable(buyerToken).balanceOf(address(treasury));
        require(treasuryBalanceInitial >= amount, "Insufficient fund in treasury");

        TransferHelper.safeTransferFrom(_order.buyerToken, treasury, recipient, amount);

        uint256 treasuryBalanceFinal = IERC20Upgradeable(buyerToken).balanceOf(address(treasury));
        require((treasuryBalanceInitial - treasuryBalanceFinal) == amount, "Swap amount not match");
    }

    function executeSwapToTreasury(
        Orders.Order memory _order,
        uint256 sellerTokenAmount,
        uint256 buyerTokenAmount,
        bytes memory callback
    ) internal returns (int256, int256) {
        require(
            sellerTokenAmount <= uint256(type(int256).max),
            "sellerTokenAmount is too large and would cause an overflow error"
        );
        require(
            buyerTokenAmount <= uint256(type(int256).max),
            "buyerTokenAmount is too large and would cause an overflow error"
        );
        int256 outputSellerTokenAmount = int256(sellerTokenAmount);
        int256 outputBuyerTokenAmount = -1 * int256(buyerTokenAmount);
        address sellerToken = _order.sellerToken;
        uint256 treasuryBalanceInitial = IERC20Upgradeable(sellerToken).balanceOf(
            address(treasury)
        );
        uint256 treasuryBalanceFinal;

        INativeRouter(msg.sender).swapCallback(
            outputBuyerTokenAmount,
            outputSellerTokenAmount,
            callback
        );
        TransferHelper.safeTransfer(sellerToken, treasury, sellerTokenAmount);
        treasuryBalanceFinal = IERC20Upgradeable(sellerToken).balanceOf(address(treasury));

        require(
            (treasuryBalanceFinal - treasuryBalanceInitial) == sellerTokenAmount,
            "Swap amount not match"
        );

        return (outputBuyerTokenAmount, outputSellerTokenAmount);
    }
}