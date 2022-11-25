// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IWD.sol";
import "./BaseERC721.sol";

contract WD is BaseERC721, IWD {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // sbtId -> TxData
    mapping(uint256 => TxData[]) private _txsData;
    // sbtId -> Collection
    mapping(uint256 => Collection) private _collectionDetails;
    // sbtId -> hashTransaction
    mapping(uint256 => EnumerableSet.Bytes32Set) private _txsHashes;
    // sbtId -> paymentToken -> value
    mapping(uint256 => mapping(address => uint256)) private _unpaidTotalFee;
    // sbtId -> payment tokens
    mapping(uint256 => EnumerableSet.AddressSet) private _paymentTokens;
    // seller -> collection -> nftId -> sbtId
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _sbtId;

    function collectionDetails(uint256 sbtId_) external view returns (Collection memory) {
        return _collectionDetails[sbtId_];
    }

    function hashesCount(uint256 nftId_) external view returns (uint256) {
        return _txsHashes[nftId_].length();
    }

    function hasPaymentToken(uint256 sbtId_, address collection_) external view returns (bool) {
        return _paymentTokens[sbtId_].contains(collection_);
    }

    function hasTxHash(uint256 id_, bytes32 hash_) external view returns (bool) {
        return _txsHashes[id_].contains(hash_);
    }

    function paymentTokensCount(uint256 sbtId_) external view returns (uint256) {
        return _paymentTokens[sbtId_].length();
    }

    function paymentTokenByIndex(uint256 sbtId_, uint256 index_) external view returns (address) {
        return _paymentTokens[sbtId_].at(index_);
    }

    function sbtId(
        address seller_,
        address collection_,
        uint256 id_
    ) external view returns (uint256) {
        return _sbtId[seller_][collection_][id_];
    }

    function txHashByIndex(uint256 id_, uint256 index_) external view returns (bytes32) {
        return _txsHashes[id_].at(index_);
    }

    function txsDataCount(uint256 sbtId_) external view returns (uint256) {
        return _txsData[sbtId_].length;
    }

    function txHashesCount(uint256 id_) external view returns (uint256) {
        return _txsHashes[id_].length();
    }

    function txsData(
        uint256 sbtId_,
        uint256 offset_,
        uint256 limit_
    ) external view returns (TxData[] memory txs_) {
        TxData[] memory txsData_ = _txsData[sbtId_];
        uint256 txsCount_ = txsData_.length;
        if (offset_ >= txsCount_) return new TxData[](0);
        uint256 to = offset_ + limit_;
        if (txsCount_ < to) to = txsCount_;
        txs_ = new TxData[](to - offset_);
        for (uint256 i = 0; i < txs_.length; i++) txs_[i] = txsData_[offset_ + i];
    }

    function unpaidTotalFee(uint256 sbtId_, address token_) external view returns (uint256) {
        return _unpaidTotalFee[sbtId_][token_];
    }

    constructor(string memory baseTokenURI_) BaseERC721(baseTokenURI_) {
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    function setUnpaidFee(
        string[] memory tokenURI_,
        address[] memory collections_,
        uint256[] memory ids_,
        TxData[] memory txs_
    ) external onlyRole(OPERATOR_ROLE) {
        for (uint256 i = 0; i < collections_.length; i++) {
            uint256 sbtId_ = _sbtId[txs_[i].seller][collections_[i]][ids_[i]];
            if (_txsHashes[sbtId_].contains(txs_[i].hash)) continue;
            if (sbtId_ == 0) sbtId_ = mint(txs_[i].seller, tokenURI_[i]);
            if (_sbtId[txs_[i].seller][collections_[i]][ids_[i]] > 0) {
                _collectionDetails[sbtId_] = Collection(txs_[i].token, ids_[i]);
            }
            _txsHashes[sbtId_].add(txs_[i].hash);
            _txsData[sbtId_].push(txs_[i]);
            _unpaidTotalFee[sbtId_][txs_[i].token] += txs_[i].fee;
            _paymentTokens[sbtId_].add(txs_[i].token);
        }
    }

    function closeUnpaidFee(uint256[] memory sbtIds_) external payable {
        require(sbtIds_.length > 0, "Invalid params length");
        uint256 value_ = msg.value;
        for (uint256 i = 0; i < sbtIds_.length; i++) {
            if (_txsData[sbtIds_[i]].length == 0) continue;
            TxData memory txData_ = _txsData[sbtIds_[i]][0];
            for (uint256 j = 0; j < _paymentTokens[sbtIds_[i]].length(); j++) {
                address token_ = _paymentTokens[sbtIds_[i]].at(j);
                uint256 fee_ = _unpaidTotalFee[sbtIds_[i]][token_];
                if (token_ == address(0)) {
                    require(value_ >= fee_, "Value is not positive");
                    payable(txData_.creator).transfer(fee_);
                    value_ -= fee_;
                } else {
                    IERC20 paymentToken = IERC20(token_);
                    paymentToken.transferFrom(txData_.seller, txData_.creator, fee_);
                }
                delete _unpaidTotalFee[sbtIds_[i]][_paymentTokens[sbtIds_[i]].at(j)];
            }
            delete _txsHashes[sbtIds_[i]];
            delete _txsData[sbtIds_[i]];
            delete _collectionDetails[sbtIds_[i]];
            delete _paymentTokens[sbtIds_[i]];
            burn(txData_.seller, sbtIds_[i]);
        }
    }
}