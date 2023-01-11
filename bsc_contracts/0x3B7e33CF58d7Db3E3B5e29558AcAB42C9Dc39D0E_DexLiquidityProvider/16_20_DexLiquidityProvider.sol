// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./DexBase.sol";


interface IDexLiquidityProvider {

    function swapRequest(bytes calldata message, bytes[] calldata signature) external payable;

    function settle(string calldata quoteId) external payable;

    function decline(string calldata quoteId) external;

    function calculateCompensate(address user, string[] memory idArray) external view returns (uint256); 

    function compensate(string[] memory idArray) external;
}


contract DexLiquidityProvider is DexBase, IDexLiquidityProvider, ReentrancyGuardUpgradeable {

    using ECDSA for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(string => QuoteInfo) private quoteStorage;

    address public backSigner;

    event QuoteAccepted(address indexed user, string quoteId, QuoteInfo quoteInfo);
    event QuoteRemoved(address indexed user, string quoteId);
    event SettlementDone(address indexed user, string quoteId, address asset, uint256 amount);
    event SettlementDecline(address indexed user, string quoteId, address asset, uint256 amount);
    event CompensateDone(string[] idArray);
    event BackSignerSet(address indexed newSigner);

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

    function setBackSigner(address newSigner) external onlyOwner {
        backSigner = newSigner;
        emit BackSignerSet(backSigner);
    }

    function quoteQuery(string memory quoteId) external view returns (QuoteInfo memory info) {
        return quoteStorage[quoteId];
    }

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
        require(params.compensateToken == secure.compensateToken(), "DexLiquidityProvider: not the same compensate token");

        secure.frozePending(lpOut, params.compensateAmount);
        verifyPairWhitelist(lpOut, params.fromAsset, params.toAsset);
        // do transfer
        if (params.fromAsset == BNB) {
            require(msg.value == params.fromAmount, "DexLiquidityProvider: msg value is not equal to fromAmount");
        } else {
            IERC20Upgradeable(params.fromAsset).safeTransferFrom(msg.sender, address(this), params.fromAmount);
        }

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
        require(quoteStorage[quoteId].lpOut == msg.sender, "settlement error, wrong liquidity provider");
        require(quoteStorage[quoteId].status == OrderStatus.PENDING, "settlement error, status is not active");
        require(quoteStorage[quoteId].tradeExpireAt >= block.timestamp, "settlement error, trade expired");
        address user = quoteStorage[quoteId].user;
        address asset = quoteStorage[quoteId].toAsset;
        uint256 settleAmount = quoteStorage[quoteId].toAmount;
        secure.freePending(quoteStorage[quoteId].lpOut, quoteStorage[quoteId].compensateAmount);
               
        if (asset == BNB) {
            require(msg.value == settleAmount, "settle error, msg value is not equal to settleAmount");
            _safeTransferETH(user, settleAmount);
        } else {
            IERC20Upgradeable(asset).safeTransferFrom(msg.sender, user, settleAmount);
        }
        _safeTransferAsset(quoteStorage[quoteId].fromAsset, quoteStorage[quoteId].lpIn, quoteStorage[quoteId].fromAmount);
        _removeRequest(quoteId);
        emit SettlementDone(user, quoteId, asset, settleAmount);
    }

    function decline(string calldata quoteId) external nonReentrant onlyLiquidityProvider {
        require(quoteStorage[quoteId].lpOut == msg.sender, "decline error, wrong liquidity provider");
        require(quoteStorage[quoteId].status == OrderStatus.PENDING, "decline error, status is not active");
        address user = quoteStorage[quoteId].user;
        address asset = quoteStorage[quoteId].fromAsset;
        uint256 fromAmount = quoteStorage[quoteId].fromAmount;
       
        _safeTransferAsset(asset, user, fromAmount);
        // compensate
        secure.compensateChange(quoteStorage[quoteId].lpOut, quoteStorage[quoteId].compensateAmount);
        _safeTransferAsset(secure.compensateToken(), user, quoteStorage[quoteId].compensateAmount);

        _declineRequest(quoteId);
        emit SettlementDecline(user, quoteId, asset, fromAmount);
    }

    function calculateCompensate(address user_, string[] memory idArray) public view returns (uint256) {
        uint256 amount = 0;
        for (uint i = 0; i < idArray.length; i++) {
            string memory id = idArray[i];
            if (quoteStorage[id].user != address(0) && quoteStorage[id].user == user_) {
                if (block.timestamp > quoteStorage[id].tradeExpireAt && quoteStorage[id].status == OrderStatus.PENDING) {
                    amount = amount + quoteStorage[id].compensateAmount;
                }
            }
        }
        return amount;
    }

    function compensate(string[] memory idArray) external nonReentrant {
        uint256 amount = calculateCompensate(msg.sender, idArray);
        require(amount > 0, "DexLiquidityProvider: compensate amount should above zero.");
        // remove quotations and 
        for (uint i = 0; i < idArray.length; i++) {
            string memory id = idArray[i];
            if (quoteStorage[id].user != address(0) && quoteStorage[id].user == msg.sender) {
                if (block.timestamp > quoteStorage[id].tradeExpireAt && quoteStorage[id].status == OrderStatus.PENDING) {
                    secure.compensateChange(quoteStorage[id].lpOut, quoteStorage[id].compensateAmount);
                    _safeTransferAsset(quoteStorage[id].fromAsset, quoteStorage[id].user, quoteStorage[id].fromAmount);
                    _declineRequest(id);
                }
            }
        }
        _safeTransferAsset(secure.compensateToken(), msg.sender, amount);
        emit CompensateDone(idArray);
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