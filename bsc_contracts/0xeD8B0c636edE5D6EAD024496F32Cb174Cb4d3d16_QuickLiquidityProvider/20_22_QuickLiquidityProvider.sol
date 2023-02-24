// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {VaultPool} from "./VaultPool.sol";
import {IQuickLiquidityProvider} from "./interface/IQuickLiquidityProvider.sol";
import {DexBase, ISBT721, SecurePool, QuoteInfo, OrderStatus, CompensateStatus, QuoteParameters, QuoteInfoV2} from "./DexBase.sol";

contract QuickLiquidityProvider is DexBase, IQuickLiquidityProvider, ReentrancyGuardUpgradeable {
    using ECDSA for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Not used. Remove in V2
    uint private _timeout;

    // The map used to storage all quotes
    mapping(string => QuoteInfo) private quoteStorage;
 
    // Platform vault pool
    VaultPool public vault; 

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
     * Query the history quote by quote id
     *
     * @param token The vault token address.
     */
    function vaultQuery(address token) external view returns (uint256 amount) {
        return vault.query(token);
    }
    
    function initialize(address owner_, address babToken_, bool babSwitch_, address secure_, address vault_) public payable initializer {
        _init(owner_, babToken_, babSwitch_, secure_, vault_);
    }

    function _init(address owner_, address babToken_, bool babSwitch_, address secure_, address vault_) internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
        _init_unchained(owner_, babToken_, babSwitch_, secure_, vault_);
    }

    function _init_unchained(address owner_, address babToken_, bool babSwitch_, address secure_, address vault_) internal onlyInitializing {
        require(owner_ != address(0), "QuickLiquidityProvider: owner is the zero address");
        _owner = owner_;
        babToken = ISBT721(babToken_);
        babSwitch = babSwitch_;
        secure = SecurePool(payable(secure_));
        vault = VaultPool(payable(vault_));
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
        emit BackSignerSet(newSigner);
    }

    /**
     * @notice
     * Deposit to vault pool
     *
     * @param token_ The vault token address
     * @param amount_ The amount to deposit
     */
    function addVault(address token_, uint256 amount_) external payable nonReentrant onlyOwner {
        _transferInVault(msg.sender, token_, amount_);
    }

    /**
     * @notice
     * Withdrawl from valut pool
     *
     * @param token_ The vault token address
     * @param amount_ The amount to withdraw
     */
    function removeVault(address token_, uint256 amount_) external nonReentrant onlyOwner {
        _transferOutVault(msg.sender, token_, amount_);
    }

    /**
     * @notice
     * Swap request. Only the BABT holder can send swap request.
     *
     * @param message Encoded quote info.
     * @param signature The signatures. 0: Signature signed by liquidity provider. 1: Signature signed by platform signer.
     */
    function swapRequest(bytes calldata message, bytes[] calldata signature) external payable nonReentrant onlyBabtUser isCircuitBreaker {
        require(signature.length == 2, 'QuickLiquidityProvider: wrong signature length');
        address signer = _source(message, signature[0]);
        address signer2 = _source(message, signature[1]);
        QuoteParameters memory params = abi.decode(message, (QuoteParameters));
        string memory quoteId = params.quoteId;
        require(params.mode == 0, 'QuickLiquidityProvider: wrong settlement mode');
        require(params.chainid == block.chainid, 'QuickLiquidityProvider: blockchain id');
        require(liquidityProviderMap[params.lpIn] != address(0), 'QuickLiquidityProvider: invalid liquidity provider');
        require(params.fromAsset != params.toAsset, "QuickLiquidityProvider: fromAsset should not the same with toAsset");
        address lpOut = liquidityProviderMap[params.lpIn];
        address lpSigner = liquidityProviderSigner[lpOut];
        require(params.quoteConfirmDeadline >= block.timestamp, 'QuickLiquidityProvider: EXPIRED');
        require(signer == lpSigner, "QuickLiquidityProvider: invalid signer");
        require(signer2 == backSigner, "QuickLiquidityProvider: invalid platform signer");
        require(quoteStorage[quoteId].user == address(0), "QuickLiquidityProvider: duplicate quoteId");
        require(quoteHash[quoteId].quoteHash == 0, "QuickLiquidityProvider: duplicate quoteId");
        require(params.compensateToken == secure.compensateToken(), "QuickLiquidityProvider: not the same compensate token");

        secure.frozePending(lpOut, params.compensateAmount);
        verifyPairWhitelist(lpOut, params.fromAsset, params.toAsset);
        // do transfer

        _transferInVault(msg.sender, params.fromAsset, params.fromAmount);
        _transferOutVault(msg.sender, params.toAsset, params.toAmount);

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
     * @param quoteId The quote id to settle. The quote must be PENDING.
     */
    function settle(string calldata quoteId, QuoteInfo calldata quote) external payable nonReentrant onlyLiquidityProvider {
        _settle(quoteId, quote);
    }

    /**
    * @notice
    * Batch settle quotes by liquidity provider
    *
    * @param idArray The quote ids. The quote must be PENDING.
     */
    function batchSettle(string[] calldata idArray, QuoteInfo[] calldata quotes) external payable nonReentrant onlyLiquidityProvider {
        require(idArray.length == quotes.length, "QuickLiquidityProvider: Quote size not match");
        uint256 len = idArray.length;
        for (uint256 i; i < len; i++) {
            _settle(idArray[i], quotes[i]);
        }
    }

    /**
     * @notice
     * For unsettled orders, the platform can get compensation from liquidity providers
     *
     * @param idArray The quote ids,
     */
    function compensate(string[] memory idArray, QuoteInfo[] memory quotes) external nonReentrant onlyOwner {
        require(idArray.length == quotes.length, "QuickLiquidityProvider: Quote size not match");
        uint256 len = idArray.length;
        for (uint256 i; i < len; i++) {
            string memory quoteId = idArray[i];
            require(keccak256(abi.encode(quotes[i])) == quoteHash[quoteId].quoteHash, "hash not match");
            require(quoteHash[quoteId].status == OrderStatus.PENDING, "compensate error, status is not active");
            require(quoteHash[quoteId].compensateStatus == CompensateStatus.NO, "compensate error, already compensate before");
            require(quotes[i].tradeExpireAt < block.timestamp, "compensate error, trade not expired");
            secure.compensateChange(quotes[i].lpOut, quotes[i].compensateAmount);
            IERC20Upgradeable(secure.compensateToken()).safeIncreaseAllowance(address(vault), quotes[i].compensateAmount);       // dex -> vault approve
            vault.addVault(secure.compensateToken(), quotes[i].compensateAmount);
            _compensateRequest(quoteId);
        }
    } 

    function _settle(string calldata quoteId, QuoteInfo calldata quote) internal {
        require(keccak256(abi.encode(quote)) == quoteHash[quoteId].quoteHash, "settlement error, hash not match");
        require(quote.lpOut == msg.sender, "settlement error, wrong liquidity provider");
        require(quoteHash[quoteId].status == OrderStatus.PENDING, "settlement error, status is not active");
        address user = quote.user;
        address asset = quote.toAsset;
        uint256 settleAmount = quote.toAmount;
        if (quoteHash[quoteId].compensateStatus == CompensateStatus.NO) {
            secure.freePending(quote.lpOut, quote.compensateAmount);
        }

        _transferInVault(msg.sender, asset, settleAmount);
        _transferOutVault(quote.lpIn, quote.fromAsset, quote.fromAmount);

        _removeRequest(quoteId);
        emit SettlementDone(user, quoteId, asset, settleAmount);
    }

    function _transferInVault(address from, address token_, uint256 amount_) internal {
        if (token_ == BNB) {
            vault.addVault{value: amount_}(token_, amount_);   // dex -> vault
        } else {
            IERC20Upgradeable(token_).safeTransferFrom(from, address(this), amount_); // user -> dex
            IERC20Upgradeable(token_).safeIncreaseAllowance(address(vault), amount_);       // dex -> vault approve
            vault.addVault(token_, amount_);
        }
    }

    function _transferOutVault(address to, address token_, uint256 amount_) internal {
        if (token_ == BNB) {
            vault.removeVault(token_, amount_);
            _safeTransferETH(to, amount_);
        } else {
            vault.removeVault(token_, amount_);
            IERC20Upgradeable(token_).safeTransfer(to, amount_);
        }      
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
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message)));
        return ECDSA.recover(hash, signature);
    }
}