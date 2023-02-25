// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IGaiaInterchange.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract GaiaInterchange is IGaiaInterchange, Ownable, Multicall {
    using Address for address payable;
    using SafeERC20 for *;

    IERC20G public immutable GAIA;
    mapping(address => NFTInfo) internal _nftInfo;

    address public treasury;
    uint256 public feeRate; //out of 10000

    constructor(address gaia, address _treasury, uint256 _feeRate) {
        GAIA = IERC20G(gaia);
        _setTreasury(_treasury);
        _setFeeRate(_feeRate);
    }

    // ownership functions
    function emergencyWithdraw(TokenType[] calldata tokenTypes, bytes[] calldata data) external onlyOwner {
        uint256 length = tokenTypes.length;
        if (length != data.length) revert LengthNotEqual();

        for (uint256 i = 0; i < length; ++i) {
            TokenType t = tokenTypes[i];
            if (t == TokenType.ERC721) {
                (address token, uint256 tokenId) = abi.decode(data[i], (address, uint256));
                IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);
            } else {
                (address token, uint256 amount) = abi.decode(data[i], (address, uint256));
                uint256 balance = IERC20(token).balanceOf(address(this));
                if (amount > balance) amount = balance;
                if (amount == 0) revert AmountZero();
                IERC20(token).safeTransfer(msg.sender, amount);
            }
        }

        emit EmergencyWithdraw(tokenTypes, data);
    }

    function setNFTInfo(address[] calldata nfts, NFTInfo[] calldata info) external onlyOwner {
        uint256 length = nfts.length;
        if (length != info.length) revert LengthNotEqual();

        for (uint256 i; i < length; ++i) {
            address nft = nfts[i];
            if (_nftInfo[nft].price != 0) revert PriceAlreadySettled();
            _nftInfo[nft] = info[i];
            emit SetNFTInfo(nft, info[i]);
        }
    }

    function setTreasury(address _treasury) external onlyOwner {
        _setTreasury(_treasury);
    }

    function setFeeRate(uint256 _rate) external onlyOwner {
        _setFeeRate(_rate);
    }

    // internal functions
    function _setTreasury(address _treasury) internal {
        if (treasury == _treasury) revert Unchanged();
        if (_treasury == address(0)) revert AddressZero();
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    function _setFeeRate(uint256 _rate) internal {
        if (feeRate == _rate) revert Unchanged();
        if (_rate > 10000) revert OutOfRange();
        feeRate = _rate;
        emit SetFeeRate(_rate);
    }

    function _transferFee(uint256 priceToTreasury) internal {
        address _treasury = treasury;
        GAIA.safeTransfer(_treasury, priceToTreasury);
        emit TrasferFee(_treasury, priceToTreasury);
    }

    // view functions
    function nftInfo(address nft) external view returns (NFTInfo memory) {
        return _nftInfo[nft];
    }

    // external functions
    function buyNFT(address nft, uint256 id, address nftTo) external {
        if (nft == address(0)) revert AddressZero();
        if (nftTo == address(0)) nftTo = msg.sender;

        NFTInfo memory t = _nftInfo[nft];
        uint256 price = t.price;
        if (price == 0) revert InvalidNFT();
        GAIA.safeTransferFrom(msg.sender, address(this), price);
        if (t.nftType == NFTType.MINTABLE) {
            IERC721G(nft).mint(nftTo, id);
        } else {
            IERC721(nft).safeTransferFrom(address(this), nftTo, id);
        }
        emit BuyNFT(nft, id, nftTo, t.nftType, price);
    }

    function buyNFTBatch(address nft, uint256[] calldata ids, address nftTo) external {
        if (nft == address(0)) revert AddressZero();
        if (nftTo == address(0)) nftTo = msg.sender;

        NFTInfo memory t = _nftInfo[nft];
        uint256 price = t.price;
        if (price == 0) revert InvalidNFT();

        uint256 amount = ids.length;
        if (amount == 0) revert AmountZero();

        uint256 totalPrice = price * amount;

        GAIA.safeTransferFrom(msg.sender, address(this), totalPrice);
        if (t.nftType == NFTType.MINTABLE) {
            IERC721G(nft).mintBatch(nftTo, ids);
        } else {
            IERC721G(nft).batchTransferFrom(address(this), nftTo, ids);
        }
        emit BuyNFTBatch(nft, ids, nftTo, t.nftType, totalPrice);
    }

    function sellNFT(address nft, uint256 id, address priceTo) external {
        if (nft == address(0)) revert AddressZero();
        if (priceTo == address(0)) priceTo = msg.sender;

        NFTInfo memory t = _nftInfo[nft];
        uint256 totalPrice = t.price;
        if (totalPrice == 0) revert InvalidNFT();

        if (t.nftType == NFTType.MINTABLE) {
            if (IERC721G(nft).ownerOf(id) != msg.sender) revert Unauthorized();
            IERC721G(nft).burn(id);
        } else {
            IERC721(nft).transferFrom(msg.sender, address(this), id);
        }
        uint256 priceToTreasury = (totalPrice * feeRate) / 10000;
        _transferFee(priceToTreasury);
        GAIA.safeTransfer(priceTo, totalPrice - priceToTreasury);

        emit SellNFT(nft, id, priceTo, t.nftType, totalPrice);
    }

    function sellNFTBatch(address nft, uint256[] calldata ids, address priceTo) external {
        if (nft == address(0)) revert AddressZero();
        if (priceTo == address(0)) priceTo = msg.sender;

        NFTInfo memory t = _nftInfo[nft];
        uint256 price = t.price;
        if (price == 0) revert InvalidNFT();

        uint256 amount = ids.length;
        if (amount == 0) revert AmountZero();

        uint256 totalPrice = price * amount;

        if (t.nftType == NFTType.MINTABLE) IERC721G(nft).burnBatch(msg.sender, ids);
        else IERC721G(nft).batchTransferFrom(msg.sender, address(this), ids);

        uint256 priceToTreasury = (totalPrice * feeRate) / 10000;
        _transferFee(priceToTreasury);
        GAIA.safeTransfer(priceTo, totalPrice - priceToTreasury);

        emit SellNFTBatch(nft, ids, priceTo, t.nftType, totalPrice);
    }
}