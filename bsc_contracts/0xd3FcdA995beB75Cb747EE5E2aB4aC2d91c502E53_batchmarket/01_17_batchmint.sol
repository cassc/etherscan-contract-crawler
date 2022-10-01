// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ILazymint.sol";
import "./MarketContract.sol";
import "./AccessControl.sol";

/// @title Smartcontract batch auction and sales in marketplace
/// @notice This contract allows batchs of more than 2 sales or auctions to be executed in one transaction.
/// @author Mariano Salazar A.
contract batchmarket is AccessControl {
    error amountmustexceed1();
    error themetadatamusthaveatleast2urls();
    error nottheadmin();

    address public admin = 0x9B6029a309bC0A1B6ab9ACf962AfD90A8270900e;
    address public Market;
    NFTMarket market;

    constructor(address _market) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        Market = _market;
        market = NFTMarket(Market);
    }

    /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event SaleCreated(address owner);
    event MarketUpdated(address newmarketaddress);

    /*///////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    ///@dev Configuration parameters applicable to sales batchs:
    ///@dev --> _batchamount: number of auctions to be registered in the marketplace.
    ///@dev --> _baseUri: This is the address of the base IPFS with which the metadata will be loaded.
    ///@dev --> ERC20 Token for payment (if specified by the seller) : _erc20Token
    ///@dev --> buy now price : _buyNowPrice
    ///@dev --> the nft seller: msg.sender
    ///@dev --> The fee recipients & their respective percentages for a sucessful auction/sale
    function batchSales(
        uint256 _tokenId,
        uint256 _batchamount,
        string[] memory _baseUri,
        address _nftContractAddress,
        address _erc20Token,
        uint256 _buyNowPrice,
        address _nftSeller,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    ) public {
        if (_batchamount <= 1) {
            revert amountmustexceed1();
        }
        if (_baseUri.length < 2) {
            revert themetadatamusthaveatleast2urls();
        }
        string memory _metadata = "";

        uint256 total = _tokenId + _batchamount;
        uint256 index = 0;
        for (uint256 i = _tokenId; i < total; i = unsafei(i)) {
            _metadata = _baseUri[index];
            market.createSale(
                _nftContractAddress,
                _tokenId,
                _erc20Token,
                _buyNowPrice,
                _nftSeller,
                _feeRecipients,
                _feePercentages,
                true,
                _metadata
            );
            unchecked {
                ++index;
            }

            ++_tokenId;
        }
        emit SaleCreated(msg.sender);
    }

    function updateMarket(address _market) public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert nottheadmin();
        }
        Market = _market;
        market = NFTMarket(Market);

        emit MarketUpdated(_market);
    }

    function unsafei(uint256 _i) private pure returns (uint256) {
        unchecked {
            return _i + 1;
        }
    }
}