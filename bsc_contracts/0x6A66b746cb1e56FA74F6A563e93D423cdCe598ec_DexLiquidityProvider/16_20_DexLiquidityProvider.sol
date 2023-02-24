// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {IDexLiquidityProvider, QuoteInfo} from "./interface/IDexLiquidityProvider.sol";
import {DexBase, ISBT721, SecurePool, OrderStatus, CompensateStatus, QuoteParameters, QuoteInfoV2} from "./DexBase.sol";

contract DexLiquidityProvider is DexBase, IDexLiquidityProvider, ReentrancyGuardUpgradeable {
    using ECDSA for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // The map used to storage all quotes
    mapping(string => QuoteInfo) private quoteStorage;

    // Platform signer
    address public backSigner;

    mapping(string => QuoteInfoV2) private quoteHash;

    /**
     * @notice
     * The current chain id
     */
    function blockchain() external view returns (uint256) {
        return block.chainid;
    }

    /**
     * @notice
     * Mark as contract version
     */
    function version() external pure returns (uint256) {
        return 10005;
    }

    /**
     * @notice
     * Query the history quote by quote id
     *
     * @param quoteId The quote id.
     */
    function quoteQuery(string memory quoteId) external view returns (QuoteInfo memory info) {
        return quoteStorage[quoteId];
    }

    function quoteV2Query(string memory quoteId) external view returns (QuoteInfoV2 memory info) {
        return quoteHash[quoteId];
    }

    /**
     * @notice
     * Calculate the eligible compensate amount of user
     *
     * @param user The user wallet address
     * @param idArray Quote ids
     */
    function calculateCompensate(address user, string[] memory idArray, QuoteInfo[] memory quotes) external view returns (uint256 amount) {
        if (idArray.length != quotes.length) {
            return amount;
        }
        uint256 len = idArray.length;
        for (uint256 i; i < len; i++) {
            string memory id = idArray[i];
            require(keccak256(abi.encode(quotes[i])) == quoteHash[id].quoteHash, "hash not match");
            if (quotes[i].user == user) {
                if (block.timestamp > quotes[i].tradeExpireAt && quoteHash[id].status == OrderStatus.PENDING) {
                    amount += quotes[i].compensateAmount;
                }
            }
        }
    }

    function initialize(address owner_, address babToken_, bool babSwitch_, address securePool_) public payable initializer {
        _init(owner_, babToken_, babSwitch_, securePool_);
    }

    function _init(address owner_, address babToken_, bool babSwitch_, address securePool_) internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
        _init_unchained(owner_, babToken_, babSwitch_, securePool_);
    }

    function _init_unchained(address owner_, address babToken_, bool babSwitch_, address securePool_) internal onlyInitializing {
        require(owner_ != address(0), "DexLiquidityProvider: owner is the zero address");
        _owner = owner_;
        babToken = ISBT721(babToken_);
        babSwitch = babSwitch_;
        secure = SecurePool(payable(securePool_));
        circuitBreaker = false;
    }

    receive() external payable {
    }

    /**
     * @notice
     * Set platform signer
     *
     * @param newSigner The new signer. No-zero address required.
     */
    function setBackSigner(address newSigner) external onlyOwner {
        backSigner = newSigner;
        emit BackSignerSet(backSigner);
    }

    /**
     * @notice
     * Swap request. Only the BABT holder can send swap request.
     *
     * @param message Encoded quote info.
     * @param signature The signatures. 0: Signature signed by liquidity provider. 1: Signature signed by platform signer.
     */
    function swapRequest(bytes calldata message, bytes[] calldata signature) external payable nonReentrant onlyBabtUser isCircuitBreaker {
        require(signature.length == 2, 'DexLiquidityProvider: wrong signature length');
        address signer = _source(message, signature[0]);
        address signer2 = _source(message, signature[1]);
        QuoteParameters memory params = abi.decode(message, (QuoteParameters));
        string memory quoteId = params.quoteId;
        require(params.mode == 1, 'DexLiquidityProvider: wrong settlement mode');
        require(params.chainid == block.chainid, 'DexLiquidityProvider: blockchain id');
        require(liquidityProviderMap[params.lpIn] != address(0), 'DexLiquidityProvider: invalid liquidity provider');
        require(params.fromAsset != params.toAsset, "DexLiquidityProvider: fromAsset should not the same with toAsset");
        address lpOut = liquidityProviderMap[params.lpIn];
        address lpSigner = liquidityProviderSigner[lpOut];
        require(params.quoteConfirmDeadline >= block.timestamp, 'DexLiquidityProvider: EXPIRED');
        require(signer == lpSigner, "DexLiquidityProvider: invalid signer");
        require(signer2 == backSigner, "DexLiquidityProvider: invalid platform signer");
        require(quoteStorage[quoteId].user == address(0), "DexLiquidityProvider: duplicate quoteId");
        require(quoteHash[quoteId].quoteHash == 0, "DexLiquidityProvider: duplicate quoteId");
        require(params.compensateToken == secure.compensateToken(), "DexLiquidityProvider: not the same compensate token");

        secure.frozePending(lpOut, params.compensateAmount);
        verifyPairWhitelist(lpOut, params.fromAsset, params.toAsset);
        // do transfer
        if (params.fromAsset == BNB) {
            require(msg.value == params.fromAmount, "DexLiquidityProvider: msg value is not equal to fromAmount");
        } else {
            IERC20Upgradeable(params.fromAsset).safeTransferFrom(msg.sender, address(this), params.fromAmount);
        }

        QuoteInfo memory info = QuoteInfo({
            user: msg.sender,
            lpIn: params.lpIn,
            lpOut: lpOut,
            lpSigner: lpSigner,
            quoteId: quoteId,
            status: OrderStatus.PENDING,
            fromAsset: params.fromAsset,
            toAsset: params.toAsset,
            fromAmount: params.fromAmount,
            toAmount: params.toAmount,
            tradeExpireAt: params.tradeCompleteDeadline,
            compensateToken: params.compensateToken,
            compensateAmount: params.compensateAmount
        });
        quoteHash[quoteId] = QuoteInfoV2({
            quoteHash: keccak256(abi.encode(info)),
            status: OrderStatus.PENDING,
            compensateStatus: CompensateStatus.NO
        });
        emit QuoteAccepted(msg.sender, quoteId, info);
    }

    /**
     * @notice
     * Settle quote by liquidity provider
     *
     * @param quoteId The quote id to settle. The quote must be PENDING
     */
    function settle(string calldata quoteId, QuoteInfo calldata quote) external payable nonReentrant onlyLiquidityProvider {
        require(keccak256(abi.encode(quote)) == quoteHash[quoteId].quoteHash, "Settlement error, hash not match");
        require(quote.lpOut == msg.sender, "settlement error, wrong liquidity provider");
        require(quoteHash[quoteId].status == OrderStatus.PENDING, "settlement error, status is not active");
        require(quote.tradeExpireAt >= block.timestamp, "settlement error, trade expired");
        address user = quote.user;
        address asset = quote.toAsset;
        uint256 settleAmount = quote.toAmount;
        secure.freePending(quote.lpOut, quote.compensateAmount);
               
        if (asset == BNB) {
            require(msg.value == settleAmount, "settle error, msg value is not equal to settleAmount");
            _safeTransferETH(user, settleAmount);
        } else {
            IERC20Upgradeable(asset).safeTransferFrom(msg.sender, user, settleAmount);
        }
        _safeTransferAsset(quote.fromAsset, quote.lpIn, quote.fromAmount);
        _removeRequest(quoteId);

        emit SettlementDone(user, quoteId, asset, settleAmount);
    }

    /**
     * @notice
     * Decline quote by liquidity provider. The 1% value of from token will be deducted and paid as compensation to the user
     *
     * @param quoteId The quote id to decline.
     */
    function decline(string calldata quoteId, QuoteInfo calldata quote) external nonReentrant onlyLiquidityProvider {
        require(keccak256(abi.encode(quote)) == quoteHash[quoteId].quoteHash, "Decline error, hash not match");
        require(quote.lpOut == msg.sender, "Decline error, wrong liquidity provider");
        require(quoteHash[quoteId].status == OrderStatus.PENDING, "Decline error, status is not active");
        address user = quote.user;
        address asset = quote.fromAsset;
        uint256 fromAmount = quote.fromAmount;
       
        _safeTransferAsset(asset, user, fromAmount);
        // compensate
        secure.compensateChange(quote.lpOut, quote.compensateAmount);
        _safeTransferAsset(secure.compensateToken(), user, quote.compensateAmount);
        _declineRequest(quoteId);

        emit SettlementDecline(user, quoteId, asset, fromAmount);
    }

    /**
     * @notice
     * Compensate for expired quotes
     *
     * @param idArray Eligible quote ids
     */
    function compensate(string[] memory idArray, QuoteInfo[] calldata quotes) external nonReentrant {
        uint256 amount = 0;
        require(idArray.length == quotes.length, "DexLiquidityProvider: Quote size not match");
        // remove quotations and 
        uint256 len = idArray.length;
        for (uint256 i; i < len; i++) {
            string memory id = idArray[i];
            require(keccak256(abi.encode(quotes[i])) == quoteHash[id].quoteHash, "hash not match");
            require(quoteHash[id].status == OrderStatus.PENDING, "compensate error, status is not active");
            require(quoteHash[id].compensateStatus == CompensateStatus.NO, "compensate error, already compensate before");
            require(quotes[i].tradeExpireAt < block.timestamp, "compensate error, trade not expired");
            require(quotes[i].user == msg.sender, "compensate error, wrong sender");
            secure.compensateChange(quotes[i].lpOut, quotes[i].compensateAmount);
            _safeTransferAsset(quotes[i].fromAsset, quotes[i].user, quotes[i].fromAmount);
            _declineRequest(id);
            _compensateRequest(id);
            amount += quotes[i].compensateAmount;
        }
        _safeTransferAsset(secure.compensateToken(), msg.sender, amount);

        emit CompensateDone(idArray);
    }

    function _removeRequest(string memory quoteId) internal {
        quoteHash[quoteId].status = OrderStatus.FINISH;
    }

    function _declineRequest(string memory quoteId) internal {
        quoteHash[quoteId].status = OrderStatus.DECLINE;
    }

    function _compensateRequest(string memory quoteId) internal {
        quoteHash[quoteId].compensateStatus = CompensateStatus.YES;
    }

    function _source(bytes memory message, bytes memory signature) internal pure returns (address) {
        return ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message))), signature);
    }

}