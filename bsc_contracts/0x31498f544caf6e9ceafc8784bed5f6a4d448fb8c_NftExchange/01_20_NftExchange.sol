// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./ERC20TransferProxy.sol";
import "./TransferProxy.sol";
import "./ExchangeOrdersHolder.sol";
import "./ExchangeDomain.sol";
import "./ExchangeState.sol";
import "./TransferProxyForDeprecated.sol";

contract NftExchange is Initializable, OwnableUpgradeable, ExchangeDomain {
	
	bytes public constant SIGN_PREFIX = "\x19Ethereum Signed Message:\n32";
	
	using StringsUpgradeable for uint256;
    
	enum FeeSide {NONE, SELL, BUY}

    event Buy(
        address indexed sellToken, uint256 indexed sellTokenId, uint256 sellValue,
        address owner,
        address buyToken, uint256 buyTokenId, uint256 buyValue,
        address buyer,
        uint256 amount,
        uint256 salt
    );

    event Cancel(
        address indexed sellToken, uint256 indexed sellTokenId,
        address owner,
        address buyToken, uint256 buyTokenId,
        uint256 salt
    );
	
    uint256 private constant UINT256_MAX = 2 ** 256 - 1;

    address payable public beneficiary;
    address public buyerFeeSigner;

    TransferProxy public transferProxy;
    TransferProxyForDeprecated public transferProxyForDeprecated;
    ERC20TransferProxy public erc20TransferProxy;
    ExchangeState public state;
    ExchangeOrdersHolder public ordersHolder;
	
	function initialize(TransferProxy _transferProxy, TransferProxyForDeprecated _transferProxyForDeprecated, ERC20TransferProxy _erc20TransferProxy, ExchangeState _state,
        ExchangeOrdersHolder _ordersHolder, address payable _beneficiary, address _buyerFeeSigner) public virtual initializer {
		
		__Ownable_init();
		
		transferProxy = _transferProxy;
        transferProxyForDeprecated = _transferProxyForDeprecated;
        erc20TransferProxy = _erc20TransferProxy;
        state = _state;
        ordersHolder = _ordersHolder;
        beneficiary = _beneficiary;
        buyerFeeSigner = _buyerFeeSigner;
    }
	
	function setBeneficiary(address payable _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    function setBuyerFeeSigner(address newBuyerFeeSigner) external onlyOwner {
        buyerFeeSigner = newBuyerFeeSigner;
    }
	
	function exchange(
        Order calldata order,
        Sig calldata sig,
        uint buyerFee,
        Sig calldata buyerFeeSig,
        uint amount,
        address buyer
    ) payable external {
        _validateOrderSig(order, sig);
        _validateBuyerFeeSig(order, buyerFee, buyerFeeSig);
		
        uint paying = (order.buying * amount) / order.selling;
		
        _verifyOpenAndModifyOrderState(order.key, order.selling, amount);
		
        require(order.key.sellAsset.assetType != AssetType.ETH, "ETH is not supported on sell side"); //use wETH instead
		
        if (order.key.buyAsset.assetType == AssetType.ETH) {
            _validateEthTransfer(paying, buyerFee);
        }
		
        FeeSide feeSide = _getFeeSide(order.key.sellAsset.assetType, order.key.buyAsset.assetType);
		
		//gift to friend or initiator
        if (buyer == address(0x0)) {
            buyer = msg.sender;
        }
		
        //initiator always is buy side (taker)
        __transferWithFeesPossibility(order.key.sellAsset, amount, order.key.owner, buyer, feeSide == FeeSide.SELL, buyerFee, order.sellerFee, order.key.buyAsset); 
        __transferWithFeesPossibility(order.key.buyAsset, paying, msg.sender, order.key.owner, feeSide == FeeSide.BUY, order.sellerFee, buyerFee, order.key.sellAsset);
		
        _emitBuy(order, amount, buyer);
    }
	
	function _validateEthTransfer(uint value, uint buyerFee) internal view {
        uint256 buyerFeeValue = (value * buyerFee) / 10000;
        require(msg.value == value + buyerFeeValue, "msg.value is incorrect");
    }
	
	function cancel(OrderKey calldata key) external {
        require(key.owner == msg.sender, "not an owner");
        state.setCompleted(key, UINT256_MAX);
        emit Cancel(key.sellAsset.token, key.sellAsset.tokenId, msg.sender, key.buyAsset.token, key.buyAsset.tokenId, key.salt);
    }

    function _validateOrderSig(Order memory order, Sig memory sig) internal view {
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            require(ordersHolder.exists(order), "incorrect signature");
        } else {
            require(_recover(prepareMessage(order), sig.v, sig.r, sig.s) == order.key.owner, "incorrect signature");
        }
    }

    function _validateBuyerFeeSig(Order memory order, uint buyerFee, Sig memory sig) internal view {
        require(_recover(prepareBuyerFeeMessage(order, buyerFee), sig.v, sig.r, sig.s) == buyerFeeSigner, "incorrect buyer fee signature");
    }

    function prepareBuyerFeeMessage(Order memory order, uint fee) public pure returns (bytes32) {
        return (keccak256(abi.encode(order, fee)));
    }

    function prepareMessage(Order memory order) public pure returns (bytes32) {
        return (keccak256(abi.encode(order)));
    }

    function __transferWithFeesPossibility(Asset memory firstType, uint value, address from, address to, bool hasFee, uint256 sellerFee, uint256 buyerFee, Asset memory secondType) internal {
        if (!hasFee) {
            _transfer(firstType, value, from, to);
        } else {
            _transferWithFees(firstType, value, from, to, sellerFee, buyerFee, secondType);
        }
    }

    function _transfer(Asset memory asset, uint value, address from, address to) internal {
        if (asset.assetType == AssetType.ETH) {
            address payable toPayable = payable(to);
			//take note what if toPayable is contract address?
            toPayable.transfer(value);
        } else if (asset.assetType == AssetType.ERC20) {
            require(asset.tokenId == 0, "tokenId must be 0");
            erc20TransferProxy.erc20safeTransferFrom(IERC20Upgradeable(asset.token), from, to, value);
        } else if (asset.assetType == AssetType.ERC721) {
            require(value == 1, "value must be 1 for ERC-721");
            transferProxy.erc721safeTransferFrom(IERC721Upgradeable(asset.token), from, to, asset.tokenId);
        } else if (asset.assetType == AssetType.ERC721Deprecated) {
            require(value == 1, "value must be 1 for ERC-721");
            transferProxyForDeprecated.erc721TransferFrom(IERC721Upgradeable(asset.token), from, to, asset.tokenId);
        } else {
            transferProxy.erc1155safeTransferFrom(IERC1155Upgradeable(asset.token), from, to, asset.tokenId, value, "");
        }
    }

    function _transferWithFees(Asset memory firstType, uint value, address from, address to, uint256 sellerFee, uint256 buyerFee, Asset memory secondType) internal {
		
         uint restValue = _transferFeeToBeneficiary(firstType, from, value, sellerFee, buyerFee);
		
		//in metahorse, seller wont earn royalty fees
		secondType = secondType;
		
		address payable toPayable = payable(to);
        _transfer(firstType, restValue, from, toPayable);
    }

    function _transferFeeToBeneficiary(Asset memory asset, address from, uint total, uint sellerFee, uint buyerFee) internal returns (uint) {
        (uint restValue, uint sellerFeeValue) = _subFeeInBp(total, total, sellerFee);
        uint buyerFeeValue = (total * buyerFee) / 10000;
        uint beneficiaryFee = buyerFeeValue + sellerFeeValue;
        if (beneficiaryFee > 0) {
            _transfer(asset, beneficiaryFee, from, beneficiary);
        }
        return restValue;
    }

    function _emitBuy(Order memory order, uint amount, address buyer) internal {
        emit Buy(order.key.sellAsset.token, order.key.sellAsset.tokenId, order.selling,
            order.key.owner,
            order.key.buyAsset.token, order.key.buyAsset.tokenId, order.buying,
            buyer,
            amount,
            order.key.salt
        );
    }

    function _subFeeInBp(uint value, uint total, uint feeInBp) internal pure returns (uint newValue, uint realFee) {
        return _subFee(value, (total * feeInBp) / 10000);
    }

    function _subFee(uint value, uint fee) internal pure returns (uint newValue, uint realFee) {
        if (value > fee) {
            newValue = value - fee;
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }

    function _verifyOpenAndModifyOrderState(OrderKey memory key, uint selling, uint amount) internal {
        uint completed = state.getCompleted(key);
        uint newCompleted = completed + amount;
        require(newCompleted <= selling, "not enough stock of order for buying");
        state.setCompleted(key, newCompleted);
    }

    function _getFeeSide(AssetType sellType, AssetType buyType) internal pure returns (FeeSide) {
        if ((sellType == AssetType.ERC721 || sellType == AssetType.ERC721Deprecated) &&
            (buyType == AssetType.ERC721 || buyType == AssetType.ERC721Deprecated)) {
            return FeeSide.NONE;
        }
        if (uint(sellType) > uint(buyType)) {
            return FeeSide.BUY;
        }
        return FeeSide.SELL;
    }
	
	function _recover(bytes32 hashMsg, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
		return ecrecover(keccak256(abi.encodePacked(SIGN_PREFIX, hashMsg)), v, r, s);
    }

	//============
	//misc
	//============
	function version() public pure returns (string memory) {
		return "1.0";
	}
	
	receive() external payable{
		revert();
	}
	
	fallback() external payable{
		revert();
	}
}