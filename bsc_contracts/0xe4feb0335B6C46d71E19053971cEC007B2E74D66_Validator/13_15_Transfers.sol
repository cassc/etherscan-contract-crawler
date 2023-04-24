// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {IPool} from "./interfaces/IPool.sol";
import {Types} from "./libraries/Types.sol";

/**
 * @author Jonatã Oliveira
 * @title Transfers
 * @dev Transfer functions (fees, royalties and others).
 */
contract Transfers is Initializable {
    using SafeMath for uint256;

    IFeeManager private _feeManager;
    IPool private _pool;

    function __Transfers_init(address _feeManager_, address _pool_) internal onlyInitializing {
        _feeManager = IFeeManager(_feeManager_);
        _pool = IPool(_pool_);
    }

    /**
     * @dev Transfer platform fee, royalty and seller amount
     * @param _collection address of the token collection
     * @param _token_id the token id
     * @param _to receiver address
     * @param _currency currency address
     * @param _price token price
     */
    function _transferFeesAndFunds(address _collection, uint256 _token_id, address _currency, address _to, uint256 _price) internal {
        (address royaltyAddress, uint256 royaltyAmount) = getRoyalty(_collection, _token_id, _price);
        uint256 feeAmount = _feeManager.getFeeAmount(_collection, _price);
        uint256 sellerAmount = _price.sub(feeAmount).sub(royaltyAmount);

        if (_currency != address(0)) {
            IERC20 token = IERC20(_currency);
            // Retrieve the fee amount to platform
            require(token.transfer(_feeManager.getReceiver(), feeAmount), "Transfer Fee error");

            // Pay royalty amount (if exists)
            if (royaltyAddress != address(0) && royaltyAmount > 0) {
                require(token.transfer(royaltyAddress, royaltyAmount), "Transfer Royalty error");
            }

            // Pay value to the seller
            require(token.transfer(_to, sellerAmount), "Transfer Seller error");
        } else {
            // Retrieve the fee amount to platform
            (bool fs, ) = payable(_feeManager.getReceiver()).call{value: feeAmount}("");
            require(fs, "Fail: Platform");

            // Pay royalty amount (if exists)
            if (royaltyAddress != address(0) && royaltyAmount > 0) {
                (bool hs, ) = payable(royaltyAddress).call{value: royaltyAmount}("");
                require(hs, "Fail: Royalties");
            }

            // Pay value to the seller
            (bool os, ) = payable(_to).call{value: sellerAmount}("");
            require(os, "Fail: Seller");
        }
    }

    /**
     * @dev Transfer platform fee, royalty and seller amount
     * @param _collection address of the token collection
     * @param _token_id the token id
     * @param _from buyer address
     * @param _to seller address
     * @param _price price
     */
    function _transferFeesAndFundsPool(address _collection, uint256 _token_id, address _from, address _to, uint256 _price) internal {
        (address royaltyAddress, uint256 royaltyAmount) = getRoyalty(_collection, _token_id, _price);
        uint256 feeAmount = _feeManager.getFeeAmount(_collection, _price);
        uint256 sellerAmount = _price.sub(feeAmount).sub(royaltyAmount);

        // Retrieve the fee amount to platform
        if (feeAmount > 0) {
            require(_pool.safeWithdraw(_from, _feeManager.getReceiver(), feeAmount), "Transfer Fee error");
        }
        // Pay royalty amount (if exists)
        if (royaltyAddress != address(0) && royaltyAmount > 0) {
            require(_pool.safeWithdraw(_from, royaltyAddress, royaltyAmount), "Transfer Fee error");
        }
        // Pay value to the seller
        require(_pool.safeWithdraw(_from, _to, sellerAmount), "Transfer Seller error");
    }

    /**
     * @dev Transfer ERC-721 NFT
     * @param collection address of the token collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     */
    function _transferNFT(address collection, address from, address to, uint256 tokenId) internal {
        if (IERC165(collection).supportsInterface(0x80ac58cd)) {
            IERC721(collection).safeTransferFrom(from, to, tokenId);
        } else {
            revert("Invalid contract");
        }
    }

    /**
     * @dev Get the ERC-2981 token royalties
     * @param _collection collection address
     * @param _id token id
     * @param _price token price
     * @return royalty (receiver address and amount)
     */
    function getRoyalty(address _collection, uint256 _id, uint256 _price) internal returns (address, uint256) {
        if (_feeManager.getRoyaltiesEnabled()) {
            try IERC2981(_collection).royaltyInfo(_id, _price) returns (address receiver, uint256 amount) {
                uint16 _percentage = _feeManager.getRoyaltyPercentage();
                uint16 _divider = _feeManager.divider();

                return (receiver, amount.mul(_percentage).div(_divider));
            } catch {
                return (address(0), 0);
            }
        }
        return (address(0), 0);
    }
}