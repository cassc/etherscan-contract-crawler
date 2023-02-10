// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "./Collection.sol";

contract Marketplace is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum TokenType {ERC1155, ERC721, ERC721Deprecated}

    struct nftToken {
        address collection;
        uint256 id;
        TokenType tokenType;
    }

    struct Position {
        nftToken nft;
        uint256 amount;
        uint256 price;
        address owner;
        address currency;
    }

    struct PositionSaleInfo {
        address collection;
        TokenType tokenType;
        uint256 id;
        uint256 amount;
        uint256 price;
        address currency;
    }

    struct Fees {
        address recipient;
        uint256 amount;
    }

    mapping(uint256 => Position) public positions;
    mapping(address => Fees) public collectionFees;
    uint256 public positionsCount;
    address public marketplaceBeneficiaryAddress;
    uint256 public marketplaceBeneficiaryFee;
    uint256 public marketplaceBuyerFee;
    uint256 public marketplaceSellerFee;
    mapping(address => mapping(uint256 => bool)) private isForSale; //isForSale[collection][id]
    mapping(uint256 => bool) public soldWithFiat;

    event NewPosition(
        address indexed owner,
        uint256 indexed id,
        address collection,
        uint256 token,
        uint256 amount,
        uint256 price,
        address currency
    );
    event Buy(
        address owner,
        address buyer,
        uint256 position,
        address indexed collection,
        uint256 indexed token,
        uint256 amount,
        uint256 price,
        address currency
    );
    event Cancel(address owner, uint256 position);

    function __Marketplace_init() public initializer {
        __Ownable_init();

        marketplaceBeneficiaryAddress = msg.sender;

        positionsCount = 0;
        marketplaceBuyerFee = 300;
        marketplaceSellerFee = 0;
    }

    function changeMarketplaceBeneficiary(
        address _marketplaceBeneficiaryAddress
    ) external onlyOwner {
        marketplaceBeneficiaryAddress = _marketplaceBeneficiaryAddress;
    }

    function changeMarketplaceBuyerFee(
        uint256 _marketplaceBuyerFee
    ) external onlyOwner {
        require(_marketplaceBuyerFee < 10000, "MP: Wrong amount");
        marketplaceBuyerFee = _marketplaceBuyerFee;
    }

    function changeMarketplaceSellerFee(
        uint256 _marketplaceSellerFee
    ) external onlyOwner {
        require(_marketplaceSellerFee < 10000, "MP: Wrong amount");
        marketplaceSellerFee = _marketplaceSellerFee;
    }

    function addCollectionFee(
        address _collection,
        address _recipient,
        uint256 _fee
    ) external onlyOwner {
        require(_fee < 10000, "MP: Wrong amount");
        collectionFees[_collection] = Fees(
            _recipient,
            _fee
        );
    }

    function putBunchOnSale(PositionSaleInfo[] calldata list) external {
        for(uint256 _index = 0; _index < list.length; _index++) {
            PositionSaleInfo memory data = list[_index];
            putOnSale(data.collection, data.tokenType, data.id, data.amount, data.price, data.currency);
        }
    }

    function putOnSale(
        address _collection,
        TokenType _tokenType,
        uint256 _id,
        uint256 _amount,
        uint256 _price,
        address _currency
    ) public {
        if (_tokenType == TokenType.ERC1155) {
            require(
                Collection(_collection).creators(_id) != address(0),
                "Wrong token id"
            );
            require(
                IERC1155Upgradeable(_collection).balanceOf(msg.sender, _id) >= _amount,
                "Wrong amount"
            );
        } else {
            require(
                (IERC721Upgradeable(_collection).ownerOf(_id) == msg.sender) &&
                (_amount == 1),
                "Wrong amount"
            );
        }
        require(!isForSale[_collection][_id], "This NFT is already for sale");

        positions[positionsCount] = Position(
            nftToken(_collection, _id, _tokenType),
            _amount,
            _price,
            msg.sender,
            _currency
        );

        isForSale[_collection][_id] = true;

        emit NewPosition(
            msg.sender,
            positionsCount,
            _collection,
            _id,
            _amount,
            _price,
            _currency
        );

        positionsCount++;
    }

    function cancel(uint256 _id) external {
        require(msg.sender == positions[_id].owner, "MP: Access denied");
        positions[_id].amount = 0;
        isForSale[positions[_id].nft.collection][positions[_id].nft.id] = false;

        emit Cancel(msg.sender, _id);
    }

    function buy(
        uint256 _position,
        uint256 _amount,
        address _buyer,
        bytes calldata _data
    ) external payable {
        Position memory position = positions[_position];
        require(position.amount >= _amount, "MP: Wrong amount");

        _transferWithFees(_position, _amount);

        if (_buyer == address(0)) {
            _buyer = msg.sender;
        }
        if (position.nft.tokenType == TokenType.ERC1155) {
            IERC1155Upgradeable(position.nft.collection).safeTransferFrom(
                position.owner,
                _buyer,
                position.nft.id,
                _amount,
                _data
            );
        } else if (position.nft.tokenType == TokenType.ERC721) {
            require(_amount == 1, "Wrong amount");
            IERC721Upgradeable(position.nft.collection).safeTransferFrom(
                position.owner,
                _buyer,
                position.nft.id
            );
        } else if (position.nft.tokenType == TokenType.ERC721Deprecated) {
            require(_amount == 1, "Wrong amount");
            IERC721Upgradeable(position.nft.collection).transferFrom(
                position.owner,
                _buyer,
                position.nft.id
            );
        }
        
        isForSale[position.nft.collection][position.nft.id] = false;

        emit Buy(
            position.owner,
            _buyer,
            _position,
            position.nft.collection,
            position.nft.id,
            _amount,
            position.price,
            position.currency
        );
    }

    function buyWithFiat(
        uint256 _position,
        address _buyer,
        address _owner,
        uint256 _amount,
        bytes calldata _data
    ) external onlyOwner {
        require(_buyer != address(0), "Buyer can't be zero address");
        Position storage position = positions[_position];
        require(position.owner == _owner, "Not the owner of the NFT");

        if (position.nft.tokenType == TokenType.ERC1155) {
            IERC1155Upgradeable(position.nft.collection).safeTransferFrom(
                position.owner,
                _buyer,
                position.nft.id,
                _amount,
                _data
            );
        } else if (position.nft.tokenType == TokenType.ERC721) {
            require(_amount == 1, "Wrong amount");
            IERC721Upgradeable(position.nft.collection).safeTransferFrom(
                position.owner,
                _buyer,
                position.nft.id
            );
        } else if (position.nft.tokenType == TokenType.ERC721Deprecated) {
            require(_amount == 1, "Wrong amount");
            IERC721Upgradeable(position.nft.collection).transferFrom(
                position.owner,
                _buyer,
                position.nft.id
            );
        }
        
        isForSale[position.nft.collection][position.nft.id] = false;
        soldWithFiat[_position] = true;
        position.amount = position.amount.sub(_amount);

        emit Buy(
            position.owner,
            _buyer,
            _position,
            position.nft.collection,
            position.nft.id,
            _amount,
            position.price,
            position.currency
        );
    }

    function getSellerProfit(uint256 _position) public view returns(uint256, address) {
        Position memory position = positions[_position];
        uint256 price = position.price;
        uint256 sellerProfit = price - _calculatePercentage(price, marketplaceSellerFee);
        return (sellerProfit, position.currency);
    }

    function _transferWithFees(
        uint256 _position,
        uint256 _amount
    ) internal {
        Position storage position = positions[_position];
        uint256 price = position.price.mul(_amount);
        uint256 marketplaceProfit = _calculatePercentage(price, marketplaceBuyerFee.add(marketplaceSellerFee));
        uint256 sellerProfit = price - _calculatePercentage(price, marketplaceSellerFee);
        uint256 total = price + _calculatePercentage(price, marketplaceBuyerFee);

        if (position.currency == address(0)) {
            require(msg.value >= total, "Insufficient balance");
            uint256 returnBack = msg.value.sub(total);
            if (returnBack > 0) {
                payable(msg.sender).transfer(returnBack);
            }
        }

        if (marketplaceProfit > 0) {
            _transfer(
                marketplaceBeneficiaryAddress,
                position.currency,
                marketplaceProfit
            );
        }

        _transfer(position.owner, position.currency, sellerProfit);

        position.amount = position.amount.sub(_amount);
    }

    function _transfer(
        address _to,
        address _currency,
        uint256 _amount
    ) internal {
        if (_currency == address(0)) {
            payable(_to).transfer(_amount);
        } else {
            IERC20Upgradeable(_currency).transferFrom(msg.sender, _to, _amount);
        }
    }

    function _calculatePercentage(uint256 _amount, uint256 _fee)
    internal
    pure
    returns (uint256)
    {
        return _amount.mul(_fee).div(10000);
    }
}