// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./interfaces/IDiscountDB.sol";

contract DiscountDBV0 is Ownable, IDiscountDB {
    mapping(address => uint16) public userDiscountRate; //out of 10000
    mapping(address => uint16) public nftDiscountRate;

    function updateNFTDiscountRate(address[] calldata nfts, uint16[] calldata dcRates) external onlyOwner {
        require(nfts.length == dcRates.length, "LENGTH_NOT_EQUAL");
        for (uint256 i = 0; i < nfts.length; i++) {
            require(dcRates[i] <= 10000, "OUT_OF_RANGE");
            nftDiscountRate[nfts[i]] = dcRates[i];
            emit UpdateNFTDiscountRate(nfts[i], dcRates[i]);
        }
    }

    function updateUserDiscountRate(address[] calldata users, uint16[] calldata dcRates) external onlyOwner {
        require(users.length == dcRates.length, "LENGTH_NOT_EQUAL");
        for (uint256 i = 0; i < users.length; i++) {
            require(dcRates[i] <= 10000, "OUT_OF_RANGE");
            userDiscountRate[users[i]] = dcRates[i];
            emit UpdateUserDiscountRate(users[i], dcRates[i]);
        }
    }

    function getDiscountRate(address target, bytes calldata data) external view returns (uint16 discountRate) {
        uint16 _userDcRate = userDiscountRate[target];
        uint16 _nftDcRate = _getNFTDiscountRate(target, data);
        discountRate = _userDcRate > _nftDcRate ? _userDcRate : _nftDcRate;
    }

    function _getNFTDiscountRate(address target, bytes calldata data) private view returns (uint16 _nftDiscountRate) {
        if (data.length > 0) {
            address nft = abi.decode(data, (address));
            if (nft != address(0)) {
                _nftDiscountRate = nftDiscountRate[nft];
                if (_nftDiscountRate == 0) return 0;
                require(IERC721(nft).balanceOf(target) > 0, "NOT_NFT_HOLDER");
            }
        }
    }
}