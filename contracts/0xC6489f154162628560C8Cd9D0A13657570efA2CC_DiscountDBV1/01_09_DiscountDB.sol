// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "./interfaces/IDiscountDB.sol";

contract DiscountDBV1 is Ownable, IDiscountDB {
    mapping(address => uint16) public userDiscountRate; //out of 10000
    mapping(address => uint16) public nftDiscountRate;
    mapping(address => mapping(uint256 => uint16)) public ERC1155DiscountRate;

    function updateNFTDiscountRate(address[] calldata nfts, uint16[] calldata dcRates) external onlyOwner {
        require(nfts.length == dcRates.length, "LENGTH_NOT_EQUAL");
        for (uint256 i = 0; i < nfts.length; ++i) {
            require(dcRates[i] <= 10000, "OUT_OF_RANGE");
            nftDiscountRate[nfts[i]] = dcRates[i];
            emit UpdateNFTDiscountRate(nfts[i], dcRates[i]);
        }
    }

    function updateERC1155DiscountRate(address[] calldata tokens, uint256[] calldata tokenIds, uint16[] calldata dcRates) external onlyOwner {
        uint256 length = tokens.length;
        require(length == tokenIds.length && length == dcRates.length, "LENGTH_NOT_EQUAL");
        for (uint256 i = 0; i < length; ++i) {
            require(dcRates[i] <= 10000, "OUT_OF_RANGE");
            ERC1155DiscountRate[tokens[i]][tokenIds[i]] = dcRates[i];
            emit UpdateERC1155DiscountRate(tokens[i], tokenIds[i] ,dcRates[i]);
        }
    }

    function updateUserDiscountRate(address[] calldata users, uint16[] calldata dcRates) external onlyOwner {
        require(users.length == dcRates.length, "LENGTH_NOT_EQUAL");
        for (uint256 i = 0; i < users.length; ++i) {
            require(dcRates[i] <= 10000, "OUT_OF_RANGE");
            userDiscountRate[users[i]] = dcRates[i];
            emit UpdateUserDiscountRate(users[i], dcRates[i]);
        }
    }

    function getDiscountRate(address target, bytes calldata data) external view returns (uint16 discountRate) {
        uint16 _userDcRate = userDiscountRate[target];
        uint16 _tokenDcRate = _getTokenDiscountRate(target, data);
        discountRate = _userDcRate > _tokenDcRate ? _userDcRate : _tokenDcRate;
    }

    function _getTokenDiscountRate(address target, bytes calldata data) private view returns (uint16 _dcRate) {
        if (data.length == 0) return 0;
        else if (data.length == 32) {
            address nft = abi.decode(data, (address));
            if (nft != address(0)) {
                _dcRate = nftDiscountRate[nft];
                if (_dcRate == 0) return 0;
                require(IERC721(nft).balanceOf(target) > 0, "NOT_NFT_HOLDER");
            }
        } else if (data.length == 64) {
            (address token1155, uint256 tokenId) = abi.decode(data, (address, uint256));
            if (token1155 != address(0)) {
                _dcRate = ERC1155DiscountRate[token1155][tokenId];
                if (_dcRate == 0) return 0;
                require(IERC1155(token1155).balanceOf(target, tokenId) > 0, "NOT_ERC1155_HOLDER");
            }
        } else revert("INVALID_DATA");
    }
}