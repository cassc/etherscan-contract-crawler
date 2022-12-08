// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Rescueable.sol";

interface IMintable {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

contract BomberzillaNFTSale is Rescueable {
    address public paymentRecipient;

    struct NFTSale {
        uint256 price;
        address paymentToken;
        bool mintable;
        bool resaleable;
    }

    // Mapping Collection => TokenId => Sale
    mapping(ERC1155Burnable => mapping(uint256 => NFTSale)) public nftSalesByAddressAndTokenId;
    bool public resaleEnabled = true;

    event NFTSaleAdded(
        IERC1155 indexed collection,
        uint256 indexed tokenId,
        uint256 price,
        address paymentToken,
        bool mintable,
        bool resaleable
    );
    event Resale(IERC1155 indexed collection, uint256 indexed tokenId, address indexed from, uint256 quantity);

    constructor(address _paymentRecipient) {
        paymentRecipient = _paymentRecipient;
    }

    function buy(
        ERC1155Burnable _collectionAddress,
        uint256 _tokenId,
        uint256 _quantity
    ) external payable {
        NFTSale memory sale = nftSalesByAddressAndTokenId[_collectionAddress][_tokenId];
        uint256 price = sale.price * _quantity;

        if (sale.paymentToken == address(0)) {
            require(msg.value == _quantity * sale.price, "Invalid ether amount");
        } else {
            IERC20(sale.paymentToken).transferFrom(msg.sender, paymentRecipient, price);
        }

        if (sale.mintable) {
            IMintable(address(_collectionAddress)).mint(msg.sender, _tokenId, _quantity, "");
        } else {
            IERC1155(address(_collectionAddress)).safeTransferFrom(address(this), msg.sender, _tokenId, _quantity, "");
        }
    }

    function addNFTSale(
        ERC1155Burnable _collection,
        uint256 _tokenId,
        uint256 _price,

        address _paymentToken,
        bool _mintable,
        bool _resaleable
    ) external onlyOwner {
        nftSalesByAddressAndTokenId[_collection][_tokenId] = NFTSale({
            price: _price,
            paymentToken: _paymentToken,
            mintable: _mintable,
            resaleable: _resaleable
        });

        emit NFTSaleAdded(_collection, _tokenId, _price, _paymentToken, _mintable, _resaleable);
    }

    function resale(
        ERC1155Burnable _collectionAddress,
        uint256 _tokenId,
        uint256 _quantity,
        address _from
    ) external onlyResaleEnabled {
        NFTSale memory sale = nftSalesByAddressAndTokenId[_collectionAddress][_tokenId];
        require(sale.resaleable, "Resale not allowed");
        uint256 cost = sale.price * _quantity;
        if (sale.paymentToken == address(0)) {
            payable(msg.sender).transfer(cost);
        } else {
            IERC20(sale.paymentToken).transfer(msg.sender, cost);
        }
        _collectionAddress.burn(_from, _tokenId, _quantity);
        emit Resale(_collectionAddress, _tokenId, _from, _quantity);
    }

    function setPaymentRecipient(address _paymentRecipient) external onlyOwner {
        paymentRecipient = _paymentRecipient;
    }

    modifier onlyResaleEnabled() {
        require(resaleEnabled, "BomberzillaGame: Resale is disabled");
        _;
    }
}