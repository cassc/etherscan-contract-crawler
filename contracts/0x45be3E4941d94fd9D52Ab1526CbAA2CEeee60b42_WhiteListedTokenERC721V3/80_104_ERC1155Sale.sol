// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./ERC1155SaleNonceHolder.sol";
import "../tokens/v1/HasSecondarySaleFees.sol";
import "../proxy/TransferProxy.sol";
import "../proxy/ServiceFeeProxy.sol";
import "../tge/interfaces/IBEP20.sol";
import "../managers/TradeTokenManager.sol";
import "../managers/NftTokenManager.sol";
import "../libs/RoyaltyLibrary.sol";
import "../service_fee/RoyaltiesStrategy.sol";
import "../interfaces/ICreator.sol";

import "./VipPrivatePublicSaleInfo.sol";

contract ERC1155Sale is ReentrancyGuard, RoyaltiesStrategy, VipPrivatePublicSaleInfo {
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
        address buyer,
        uint256 value
    );    

    bytes constant EMPTY = "";
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
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
        uint256 _selling,
        uint256 _buying,
        bytes memory _signature
    ) public payable nonReentrant {

        bytes32 saleId = getID(_owner, _token, _tokenId);

        // clean up saleInfo
        if(!whitelistNeeded(saleId) && saleInfo[saleId].vipSaleDate >= 0) {
            delete saleInfo[saleId];
        }

        require(
            IERC1155(_token).supportsInterface(_INTERFACE_ID_ERC1155),
            "ERC1155Sale: Invalid NFT"
        );

        if (_royaltyToken != address(0)) {
            require(
                IERC1155(_royaltyToken).supportsInterface(_INTERFACE_ID_ROYALTY_V2),
                "ERC1155Sale: Invalid royalty contract"
            );
            require(
                IRoyalty(_royaltyToken).getTokenContract() == _token,
                "ERC1155Sale: Royalty Token address does not match buy token"
            );
        }

        require(whitelisted(saleId, msg.sender), "You should be whitelisted and sale should have started");

        require(
            IERC1155(_token).balanceOf(_owner, _tokenId) >= _buying,
            "ERC1155Sale: Owner doesn't enough tokens"
        );

        uint256 receiveAmount;
        if (_payToken == address(0)) {
            receiveAmount = msg.value;
        } else {
            require(TradeTokenManager(tradeTokenManager).supportToken(_payToken) == true, "ERC721Sale: Pay Token is not allowed");
            receiveAmount = IBEP20(_payToken).allowance(msg.sender, address(this));
        }

        uint256 price = receiveAmount.mul(10 ** 4).div(ServiceFeeProxy(serviceFeeProxy).getBuyServiceFeeBps(msg.sender).add(10 ** 4)).div(_buying);

        uint256 nonce = verifySignature(
            _token,
            _tokenId,
            _payToken,
            _owner,
            _selling,
            price,
            _signature
        );
        verifyOpenAndModifyState(
            _token,
            _tokenId,
            _owner,
            nonce,
            _selling,
            _buying
        );

        TransferProxy(transferProxy).erc1155safeTransferFrom(
            _token,
            _owner,
            msg.sender,
            _tokenId,
            _buying,
            EMPTY
        );

        if (_royaltyToken != address(0)) {
            _distributeProfit(_royaltyToken, _tokenId, _payToken, _owner, price.mul(_buying), receiveAmount);
        } else {
            _distributeProfit(_token, _tokenId, _payToken, _owner, price.mul(_buying), receiveAmount);
        }
        emit Buy(_token, _tokenId, _owner, _payToken, price, msg.sender, _buying);
    }

    function _distributeProfit(
        address _token,
        uint256 _tokenId,
        address _payToken,
        address payable _owner,
        uint256 _totalPrice,
        uint256 _receiveAmount
    ) internal {
        bool isSecondarySale = _checkSecondarySale(_token, _tokenId, _owner);
        uint256 sellerServiceFeeBps = ServiceFeeProxy(serviceFeeProxy).getSellServiceFeeBps(_owner, isSecondarySale);
        address payable serviceFeeRecipient = ServiceFeeProxy(serviceFeeProxy).getServiceFeeRecipient();
        uint256 sellerServiceFee = _totalPrice.mul(sellerServiceFeeBps).div(10 ** 4);
        /*
           * The sellerReceiveAmount is on sale price minus seller service fee minus buyer service fee
           * This make sures we have enough balance even the royalties is 100%
        */
        uint256 sellerReceiveAmount = _totalPrice.sub(sellerServiceFee);
        uint256 royalties;
        if (
            IERC165(_token).supportsInterface(_INTERFACE_ID_FEES)
            || IERC165(_token).supportsInterface(_INTERFACE_ID_ROYALTY)
            || IERC165(_token).supportsInterface(_INTERFACE_ID_ROYALTY_V2)
        )
            royalties = _payOutRoyaltiesByStrategy(_token, _tokenId, _payToken, _msgSender(), sellerReceiveAmount, isSecondarySale);

        sellerReceiveAmount = sellerReceiveAmount.sub(royalties);
        if (_payToken == address(0)) {
            _owner.transfer(sellerReceiveAmount);
            serviceFeeRecipient.transfer(sellerServiceFee.add(_receiveAmount.sub(_totalPrice)));
        } else {
            IBEP20(_payToken).transferFrom(_msgSender(), _owner, sellerReceiveAmount);
            IBEP20(_payToken).transferFrom(_msgSender(), serviceFeeRecipient, sellerServiceFee.add(_receiveAmount.sub(_totalPrice)));
        }
    }

    function _checkSecondarySale(address _token, uint256 _tokenId, address _seller) internal returns (bool){
        if (IERC165(_token).supportsInterface(type(ICreator).interfaceId)) {
            address creator = ICreator(_token).getCreator(_tokenId);
            return (creator != _seller);
        } else {
            return true;
        }
    }

    function cancel(address token, uint256 tokenId) public {
        uint256 nonce = ERC1155SaleNonceHolder(nonceHolder).getNonce(token, tokenId, msg.sender);
        ERC1155SaleNonceHolder(nonceHolder).setNonce(token, tokenId, msg.sender, nonce.add(1));

        emit CloseOrder(token, tokenId, msg.sender, nonce.add(1));
    }

    function verifySignature(
        address _token,
        uint256 _tokenId,
        address _payToken,
        address payable _owner,
        uint256 _selling,
        uint256 _price,
        bytes memory _signature
    ) internal view returns (uint256 nonce) {
        nonce = ERC1155SaleNonceHolder(nonceHolder).getNonce(_token, _tokenId, _owner);
        address owner;

        if (_payToken == address(0)) {
            owner = keccak256(abi.encodePacked(_token, _tokenId, _price, _selling, nonce))
            .toEthSignedMessageHash()
            .recover(_signature);
        } else {
            owner = keccak256(abi.encodePacked(_token, _tokenId, _payToken, _price, _selling, nonce))
            .toEthSignedMessageHash()
            .recover(_signature);
        }

        require(
            owner == _owner,
            "ERC1155Sale: Incorrect signature"
        );
    }

    function verifyOpenAndModifyState(
        address _token,
        uint256 _tokenId,
        address payable _owner,
        uint256 _nonce,
        uint256 _selling,
        uint256 _buying
    ) internal {
        uint256 comp = ERC1155SaleNonceHolder(nonceHolder)
        .getCompleted(_token, _tokenId, _owner, _nonce)
        .add(_buying);
        require(comp <= _selling);
        ERC1155SaleNonceHolder(nonceHolder).setCompleted(_token, _tokenId, _owner, _nonce, comp);

        if (comp == _selling) {
            ERC1155SaleNonceHolder(nonceHolder).setNonce(_token, _tokenId, _owner, _nonce.add(1));
            emit CloseOrder(_token, _tokenId, _owner, _nonce.add(1));
        }
    }
}