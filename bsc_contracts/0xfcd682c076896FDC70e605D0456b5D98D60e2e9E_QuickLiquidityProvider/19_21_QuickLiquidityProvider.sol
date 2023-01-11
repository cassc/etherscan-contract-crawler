// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./DexBase.sol";
import "./VaultPool.sol";

interface IQuickLiquidityProvider {

    function swapRequest(bytes calldata message, bytes[] calldata signature) external payable;

    function settle(string calldata quoteId) external payable;

    function batchSettle(string[] calldata idArray) external payable;

    function vaultQuery(address token) external view returns (uint256);
    
}

contract QuickLiquidityProvider is DexBase, IQuickLiquidityProvider, ReentrancyGuardUpgradeable {

    using ECDSA for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint private _timeout;

    mapping(string => QuoteInfo) private quoteStorage;
 
    VaultPool public vault; 

    address public backSigner;
    
    event QuoteAccepted(address indexed user, string quoteId, QuoteInfo quoteInfo);
    event QuoteRemoved(address indexed user, string quoteId);
    event SettlementDone(address indexed user, string quoteId, address asset, uint256 amount);
    event SettlementDecline(address indexed user, string quoteId, address asset, uint256 amount);
    event FinalSettlementDone(address indexed user, string quoteId, address asset, uint256 amount);
    event BackSignerSet(address indexed newSigner);

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

    function setBackSigner(address newSigner) external onlyOwner {
        backSigner = newSigner;
        emit BackSignerSet(backSigner);
    }

    function quoteQuery(string memory quoteId) external view returns (QuoteInfo memory info) {
        return quoteStorage[quoteId];
    }

    function vaultQuery(address token) external view returns (uint256 amount) {
        return vault.query(token);
    }

    function addVault(address token_, uint256 amount_) external payable nonReentrant onlyOwner {
        _transferInVault(msg.sender, token_, amount_);
    }

    function removeVault(address token_, uint256 amount_) external nonReentrant onlyOwner {
        _transferOutVault(msg.sender, token_, amount_);
    }

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
        require(params.compensateToken == secure.compensateToken(), "QuickLiquidityProvider: not the same compensate token");

        secure.frozePending(lpOut, params.compensateAmount);
        verifyPairWhitelist(lpOut, params.fromAsset, params.toAsset);
        // do transfer

        _transferInVault(msg.sender, params.fromAsset, params.fromAmount);
        _transferOutVault(msg.sender, params.toAsset, params.toAmount);

        quoteStorage[quoteId].user = msg.sender;
        quoteStorage[quoteId].lpIn = params.lpIn;
        quoteStorage[quoteId].lpOut = lpOut;
        //quoteStorage[quoteId].lpSigner = lpSigner;
        quoteStorage[quoteId].quoteId = quoteId;
        quoteStorage[quoteId].status = OrderStatus.PENDING;
        quoteStorage[quoteId].fromAsset = params.fromAsset;
        quoteStorage[quoteId].toAsset = params.toAsset;
        quoteStorage[quoteId].fromAmount = params.fromAmount;
        quoteStorage[quoteId].toAmount = params.toAmount;
        quoteStorage[quoteId].tradeExpireAt = params.tradeCompleteDeadline;
        //quoteStorage[quoteId].compensateToken = params.compensateToken;
        quoteStorage[quoteId].compensateAmount = params.compensateAmount;

        emit QuoteAccepted(msg.sender, quoteId, quoteStorage[quoteId]);
    }

    function settle(string calldata quoteId) external payable nonReentrant onlyLiquidityProvider {
        _settle(quoteId);
    }

    function batchSettle(string[] calldata idArray) external payable nonReentrant onlyLiquidityProvider {
        for (uint i = 0; i < idArray.length; i++) {
            _settle(idArray[i]);
        }
    }

    function _settle(string calldata quoteId) internal {
        require(quoteStorage[quoteId].lpOut == msg.sender, "settlement error, wrong liquidity provider");
        require(quoteStorage[quoteId].status == OrderStatus.PENDING, "settlement error, status is not active");
        address user = quoteStorage[quoteId].user;
        address asset = quoteStorage[quoteId].toAsset;
        uint256 settleAmount = quoteStorage[quoteId].toAmount;
        secure.freePending(quoteStorage[quoteId].lpOut, quoteStorage[quoteId].compensateAmount);

        _transferInVault(msg.sender, asset, settleAmount);
        _transferOutVault(quoteStorage[quoteId].lpIn, quoteStorage[quoteId].fromAsset, quoteStorage[quoteId].fromAmount);

        _removeRequest(quoteId);
        emit SettlementDone(user, quoteId, asset, settleAmount);
    }

    function compensate(string[] memory idArray) external nonReentrant onlyOwner {
        for (uint i = 0; i < idArray.length; i++) {
            string memory quoteId = idArray[i];
            require(quoteStorage[quoteId].status == OrderStatus.PENDING, "compensate error, status is not active");
            require(quoteStorage[quoteId].tradeExpireAt < block.timestamp, "compensate error, trade not expired");
            secure.compensateChange(quoteStorage[quoteId].lpOut, quoteStorage[quoteId].compensateAmount);
            IERC20Upgradeable(secure.compensateToken()).safeIncreaseAllowance(address(vault), quoteStorage[quoteId].compensateAmount);       // dex -> vault approve
            vault.addVault(secure.compensateToken(), quoteStorage[quoteId].compensateAmount);
            quoteStorage[quoteId].compensateAmount = 0;
        }
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
        quoteStorage[quoteId].status = OrderStatus.FINISH;
    }

    function _declineRequest(string memory quoteId) internal {
        quoteStorage[quoteId].status = OrderStatus.DECLINE;
    }

    function _source(bytes memory message, bytes memory signature) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message)));
        return ECDSA.recover(hash, signature);
    }

    function blockchain() external view returns (uint256) {
        return block.chainid;
    }

    function version() external pure returns (uint256) {
        return 10003;
    }

}