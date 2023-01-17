// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NFTMarketplace is ReentrancyGuard, Ownable {
    using Address for address;

    struct FeeItem {
        address payable royaltyFeeAccount; // the account that recieves royalty fees
        uint256 royaltyFeePercent; // the royalty fee percentage on sales 1: 100, 50: 5000, 100: 10000
        uint256 marketFeePercent; // the fee percentage for market 1: 100, 50: 5000, 100: 10000
        address payable curator;
    }

    enum ListingStatus {
        Active,
        Sold,
        Cancelled
    }

    mapping(address => FeeItem) public _feeData;
    mapping(address => bytes32) private marketRegistrations;
    mapping(address => bool) public registrationStatus;

    address private deadAddress = 0x0000000000000000000000000000000000000000;
    bytes32 private nullBytes = 0x0000000000000000000000000000000000000000000000000000000000000000;

    event MarketRegistration(bytes32 registrationHash);

    event MarketFeeInfoUpdated(
        address nftContract,
        uint256 marketFeePercent,
        uint256 royaltyFeePercent,
        address royaltyFeeAccount,
        address curator
    );

    event MarketItemCancelled(
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        ListingStatus status
    );

    error BuyingNotAllowed();
    error RegisterContractNotAllowed();
    error CancelItemNotAllowed();
    error SetFeeNotAllowed();
    error BulkSaleNotAllowed();
    error TransferFailed();

    function _createMarketSale(
        address _nftContract,
        uint256 _tokenId,
        ListingStatus _status,
        address _seller,
        uint256 _price,
        bytes32 _conductKey
    ) internal {
        if (Address.isContract(_nftContract) == false) {
            revert BuyingNotAllowed();
        }
        if (_status != ListingStatus.Active) {
            revert BuyingNotAllowed();
        }
        if (_conductKey == nullBytes) {
            revert BuyingNotAllowed();
        }
        if (_conductKey != marketRegistrations[_nftContract]) {
            revert BuyingNotAllowed();
        }

        uint256 royaltyFeeAmount = (_feeData[_nftContract].royaltyFeePercent * _price) / 10000;
        uint256 marketFee = (_feeData[_nftContract].marketFeePercent * _price) / 10000;
        uint256 curatorFeeAmount = marketFee / 2;

        IERC721(_nftContract).transferFrom(_seller, msg.sender, _tokenId);

        _transfer(_seller, _price - royaltyFeeAmount - marketFee);
        _transfer(_feeData[_nftContract].royaltyFeeAccount, royaltyFeeAmount);

        if (_feeData[_nftContract].curator != deadAddress) {
            _transfer(_feeData[_nftContract].curator, curatorFeeAmount);
        }
    }

    function registerContractToMarket(address _nftContract) external {
        if (Address.isContract(_nftContract) == false || marketRegistrations[_nftContract] != nullBytes) {
            revert RegisterContractNotAllowed();
        }
        uint256 currTime = block.timestamp;
        bytes32 newHash = keccak256(abi.encode(_nftContract, currTime)); 
        marketRegistrations[_nftContract] = newHash;
        registrationStatus[_nftContract] = true;
        emit MarketRegistration(newHash);
    }

    function createBulkMarketSale(
        address[] calldata _nftContracts,
        uint256[] memory _tokenIds,
        ListingStatus[] calldata _status,
        address[] calldata _sellers,
        uint256[] calldata _prices,
        bytes32[] calldata _conductKeys
    ) external payable {
        uint256 index;
        uint256 sum;
        uint256 lengthPrices = _prices.length;
        uint256 lengthConductKey = _conductKeys.length;
        if (lengthConductKey != lengthPrices) {
            revert BulkSaleNotAllowed();
        }
        for (index; index < lengthPrices; index++) {
            sum += _prices[index];
        }
        if (sum != msg.value) {
            revert BulkSaleNotAllowed();
        }
        index = 0;
        for (index; index < lengthPrices; index++) {
            _createMarketSale(_nftContracts[index], _tokenIds[index], _status[index], _sellers[index], _prices[index], _conductKeys[index]);
        }
    }

    function cancelSale(
        address _nftContract,
        uint256 _tokenId,
        ListingStatus _status,
        address _seller,
        bytes32 _conductKey
    ) external nonReentrant {
        if (Address.isContract(_nftContract) == false) {
            revert CancelItemNotAllowed();
        }
        if (_status != ListingStatus.Active) {
            revert CancelItemNotAllowed();
        }
        if (msg.sender != _seller) {
            revert CancelItemNotAllowed();
        }
        if (_conductKey != marketRegistrations[_nftContract]) {
            revert CancelItemNotAllowed();
        }
        if (_conductKey == nullBytes) {
            revert CancelItemNotAllowed();
        }

        emit MarketItemCancelled(
            _nftContract,
            _tokenId,
            _seller,
            _seller,
            ListingStatus.Cancelled
        );
    }

    function setFeeInfo(
        address _nftContract,
        uint256 _marketFeePercent,
        uint256 _royaltyFeePercent,
        address _royaltyFeeAccount,
        address _curator
    ) external onlyOwner {
        uint256 temp = _royaltyFeePercent + _marketFeePercent;
        if (Address.isContract(_nftContract) == false) {
            revert SetFeeNotAllowed();
        }
        if (temp > 10000) {
            revert SetFeeNotAllowed();
        }
        _feeData[_nftContract].marketFeePercent = _marketFeePercent;
        _feeData[_nftContract].royaltyFeePercent = _royaltyFeePercent;
        _feeData[_nftContract].royaltyFeeAccount = payable(_royaltyFeeAccount);
        _feeData[_nftContract].curator = payable(_curator);

        emit MarketFeeInfoUpdated(
            _nftContract,
            _marketFeePercent,
            _royaltyFeePercent,
            _royaltyFeeAccount,
            _curator
        );
    }

    function withdraw() external payable onlyOwner {
        _transfer(msg.sender, address(this).balance);
    }

    function createMarketSale(
        address _nftContract,
        uint256 _tokenId,
        ListingStatus _status,
        address _seller,
        uint256 _price,
        bytes32 _conductKey
    ) public payable nonReentrant {
        if (msg.value == 0) {
            revert BuyingNotAllowed();
        }
        _createMarketSale(_nftContract, _tokenId, _status, _seller, _price, _conductKey);
    }

    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }
}