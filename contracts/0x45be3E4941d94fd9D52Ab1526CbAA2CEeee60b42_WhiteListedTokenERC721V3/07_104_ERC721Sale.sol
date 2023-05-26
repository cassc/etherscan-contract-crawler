// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import "../proxy/TransferProxy.sol";
import "../proxy/ServiceFeeProxy.sol";
import "./ERC721SaleNonceHolder.sol";
import "../tokens/v1/HasSecondarySaleFees.sol";
import "../tokens/HasSecondarySale.sol";
import "../tge/interfaces/IBEP20.sol";
import "../managers/TradeTokenManager.sol";
import "../managers/NftTokenManager.sol";
import "../libs/RoyaltyLibrary.sol";
import "../service_fee/RoyaltiesStrategy.sol";
import "./VipPrivatePublicSaleInfo.sol";

contract ERC721Sale is ReentrancyGuard, RoyaltiesStrategy, VipPrivatePublicSaleInfo {
    using ECDSA for bytes32;
    using RoyaltyLibrary for RoyaltyLibrary.Strategy;

    event CloseOrder(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 nonce
    );
    event Buy(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        address payToken,
        uint256 price,
        address buyer
    );

    bytes constant EMPTY = "";
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_HAS_SECONDARY_SALE = 0x5595380a;
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    bytes4 private constant _INTERFACE_ID_ROYALTY = 0x7b296bd9;
    bytes4 private constant _INTERFACE_ID_ROYALTY_V2 = 0x9e4a83d4;

    address public transferProxy;
    address public serviceFeeProxy;
    address public nonceHolder;
    address public tradeTokenManager;

    constructor(
        address _transferProxy,
        address _nonceHolder,
        address _serviceFeeProxy,
        address _tradeTokenManager
    ) public {
        transferProxy = _transferProxy;
        nonceHolder = _nonceHolder;
        serviceFeeProxy = _serviceFeeProxy;
        tradeTokenManager = _tradeTokenManager;
    }

    function buy(
        address _token,
        address _royaltyToken,
        uint256 _tokenId,
        address _payToken,
        address payable _owner,
        bytes memory _signature
    ) public payable nonReentrant {
        
        bytes32 saleId = getID(_owner, _token, _tokenId);

        // clean up saleInfo
        if(!whitelistNeeded(saleId) && saleInfo[saleId].vipSaleDate >= 0) {
            delete saleInfo[saleId];
        }

        require(
            IERC721(_token).supportsInterface(_INTERFACE_ID_ERC721),
            "ERC721Sale: Invalid NFT"
        );

        if (_royaltyToken != address(0)) {
            require(
                IERC721(_royaltyToken).supportsInterface(_INTERFACE_ID_ROYALTY_V2),
                "ERC721Sale: Invalid royalty contract"
            );
            require(
                IRoyalty(_royaltyToken).getTokenContract() == _token,
                "ERC721Sale: Royalty Token address does not match buy token"
            );
        }

        require(whitelisted(saleId, msg.sender), "You should be whitelisted and sale should have started");

        require(
            IERC721(_token).ownerOf(_tokenId) == _owner,
            "ERC721Sale: Seller is not the owner of the token"
        );

        uint256 receiveAmount;
        if (_payToken == address(0)) {
            receiveAmount = msg.value;
        } else {
            require(TradeTokenManager(tradeTokenManager).supportToken(_payToken) == true, "ERC721Sale: Pay Token is not allowed");
            receiveAmount = IBEP20(_payToken).allowance(_msgSender(), address(this));
        }

        uint256 price = receiveAmount.mul(10 ** 4).div(ServiceFeeProxy(serviceFeeProxy).getBuyServiceFeeBps(_msgSender()).add(10000));

        uint256 nonce = verifySignature(
            _token,
            _tokenId,
            _payToken,
            _owner,
            price,
            _signature
        );
        verifyOpenAndModifyState(_token, _tokenId, _owner, nonce);
        if (_royaltyToken != address(0)) {
            _distributeProfit(_royaltyToken, _tokenId, _payToken, _owner, price, receiveAmount);
        } else {
            _distributeProfit(_token, _tokenId, _payToken, _owner, price, receiveAmount);
        }

        TransferProxy(transferProxy).erc721safeTransferFrom(_token, _owner, _msgSender(), _tokenId);

        emit Buy(_token, _tokenId, _owner, _payToken, price, _msgSender());
    }

    function _distributeProfit(
        address _token,
        uint256 _tokenId,
        address _payToken,
        address payable _owner,
        uint256 _totalPrice,
        uint256 _receiveAmount
    ) internal {
        bool supportSecondarySale = IERC165(_token).supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE);
        address payable serviceFeeRecipient = ServiceFeeProxy(serviceFeeProxy).getServiceFeeRecipient();
        uint256 sellerServiceFee;
        uint256 sellerReceiveAmount;
        uint256 royalties;
        if (supportSecondarySale) {
            bool isSecondarySale = HasSecondarySale(_token).checkSecondarySale(_tokenId);
            uint256 sellerServiceFeeBps = ServiceFeeProxy(serviceFeeProxy).getSellServiceFeeBps(_owner, isSecondarySale);
            sellerServiceFee = _totalPrice.mul(sellerServiceFeeBps).div(10 ** 4);
            sellerReceiveAmount = _totalPrice.sub(sellerServiceFee);
            /*
               * The sellerReceiveAmount is on sale price minus seller service fee minus buyer service fee
               * This make sures we have enough balance even the royalties is 100%
            */
            if (
                IERC165(_token).supportsInterface(_INTERFACE_ID_FEES)
                || IERC165(_token).supportsInterface(_INTERFACE_ID_ROYALTY)
                || IERC165(_token).supportsInterface(_INTERFACE_ID_ROYALTY_V2)
            )
                royalties = _payOutRoyaltiesByStrategy(_token, _tokenId, _payToken, _msgSender(), sellerReceiveAmount, isSecondarySale);
            sellerReceiveAmount = sellerReceiveAmount.sub(royalties);
            HasSecondarySale(_token).setSecondarySale(_tokenId);
        } else {
            // default to second sale if it's random 721 token
            uint256 sellerServiceFeeBps = ServiceFeeProxy(serviceFeeProxy).getSellServiceFeeBps(_owner, true);
            sellerServiceFee = _totalPrice.mul(sellerServiceFeeBps).div(10 ** 4);
            sellerReceiveAmount = _totalPrice.sub(sellerServiceFee);
        }
        if (_payToken == address(0)) {
            _owner.transfer(sellerReceiveAmount);
            serviceFeeRecipient.transfer(sellerServiceFee.add(_receiveAmount.sub(_totalPrice)));
        } else {
            IBEP20(_payToken).transferFrom(_msgSender(), _owner, sellerReceiveAmount);
            IBEP20(_payToken).transferFrom(_msgSender(), serviceFeeRecipient, sellerServiceFee.add(_receiveAmount.sub(_totalPrice)));
        }
    }

    function cancel(address token, uint256 tokenId) public {
        uint256 nonce = ERC721SaleNonceHolder(nonceHolder).getNonce(token, tokenId, _msgSender());
        ERC721SaleNonceHolder(nonceHolder).setNonce(token, tokenId, _msgSender(), nonce.add(1));

        emit CloseOrder(token, tokenId, _msgSender(), nonce.add(1));
    }

    function verifySignature(
        address _token,
        uint256 _tokenId,
        address _payToken,
        address payable _owner,
        uint256 _price,
        bytes memory _signature
    ) internal view returns (uint256 nonce) {
        nonce = ERC721SaleNonceHolder(nonceHolder).getNonce(_token, _tokenId, _owner);
        address owner;
        if (_payToken == address(0)) {
            owner = keccak256(abi.encodePacked(_token, _tokenId, _price, nonce)).toEthSignedMessageHash().recover(_signature);
        } else {
            owner = keccak256(abi.encodePacked(_token, _tokenId, _payToken, _price, nonce)).toEthSignedMessageHash().recover(_signature);
        }
        require(
            owner == _owner,
            "ERC721Sale: Incorrect signature"
        );
    }

    function verifyOpenAndModifyState(
        address _token,
        uint256 _tokenId,
        address _owner,
        uint256 _nonce
    ) internal {
        ERC721SaleNonceHolder(nonceHolder).setNonce(_token, _tokenId, _owner, _nonce.add(1));
        emit CloseOrder(_token, _tokenId, _owner, _nonce.add(1));
    }
}