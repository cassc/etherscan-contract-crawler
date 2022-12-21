// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NFTMarketplace is ReentrancyGuard, Ownable {
    using ERC165Checker for address;
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
    event MarketItemSold(
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        ListingStatus status
    );

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

    function registerContractToMarket(address _nftContract) external {
        require(Address.isContract(_nftContract), "The address must be the NFT contract.");
        require(marketRegistrations[_nftContract] == nullBytes, "The contract is already registered.");
        uint256 currTime = block.timestamp;
        bytes32 newHash = keccak256(abi.encode(_nftContract, currTime)); 
        marketRegistrations[_nftContract] = newHash;
        registrationStatus[_nftContract] = true;
        emit MarketRegistration(newHash);
    }

    function createBulkMarketSale(
        address[] calldata _nftContracts,
        uint256[] memory _tokenIds,
        ListingStatus[] memory _status,
        address[] calldata _sellers,
        uint256[] calldata _prices,
        bytes32[] calldata _conductKeys
    ) external payable {
        require(_conductKeys.length == _prices.length, "Please input the same length's info");
        uint256 index;
        uint256 sum = 0;
        for (index = 0; index < _prices.length; index++) {
            sum += _prices[index];
        }
        require(sum == msg.value, "Please input correct sum of prices.");
        for (index = 0; index < _nftContracts.length; index++) {
            createMarketSale(_nftContracts[index], _tokenIds[index], _status[index], _sellers[index], _prices[index], _conductKeys[index]);
        }
    }

    function cancelSale(
        address _nftContract,
        uint256 _tokenId,
        ListingStatus _status,
        address _seller,
        bytes32 _conductKey
    ) external nonReentrant {
        require(Address.isContract(_nftContract), "The address must be the NFT contract.");
        require(_conductKey == marketRegistrations[_nftContract] && _conductKey != nullBytes , "Invalid key.");
        require(msg.sender == _seller, "Caller is not the owner of item.");
        require(_status == ListingStatus.Active, "Item is not listed.");

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
        require(Address.isContract(_nftContract), "The address must be the NFT contract.");
        require(_royaltyFeePercent + _marketFeePercent <= 10000, "The sum of fees already exceeded.");
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
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(
            success,
            "Withdrawal could not be processed."
        );
    }

    function createMarketSale(
        address _nftContract,
        uint256 _tokenId,
        ListingStatus _status,
        address _seller,
        uint256 _price,
        bytes32 _conductKey
    ) public payable nonReentrant {
        require(Address.isContract(_nftContract), "The address must be the NFT contract.");
        require(msg.value > 0, "Please submit the price correctly.");
        require(_conductKey == marketRegistrations[_nftContract] && _conductKey != nullBytes , "Invalid key.");
        require(_status == ListingStatus.Active, "Buying is not allowed.");

        uint256 royaltyFeeAmount = (_feeData[_nftContract].royaltyFeePercent * _price) / 10000;
        uint256 marketFee = (_feeData[_nftContract].marketFeePercent * _price) / 10000;
        uint256 curatorFeeAmount = marketFee / 2;

        IERC721(_nftContract).transferFrom(_seller, msg.sender, _tokenId);
        // transfer the (item price - royalty amount - fee amount) to the seller
        (bool successSeller, ) = payable(_seller).call{
            value: _price - royaltyFeeAmount - marketFee
        }("");
        require(
            successSeller,
            "Transfer to seller failed"
        );
        (bool successFee, ) = payable(_feeData[_nftContract].royaltyFeeAccount).call{
            value: royaltyFeeAmount
        }("");
        require(
            successFee,
            "Transfer to royalty failed"
        );
        if (_feeData[_nftContract].curator != deadAddress) {
            (bool successCurator, ) = payable(_feeData[_nftContract].curator).call{
                value: curatorFeeAmount
            }("");
            require(
                successCurator,
                "Transfer to Curator failed"
            );
        }

        emit MarketItemSold(
            _nftContract,
            _tokenId,
            _seller,
            msg.sender,
            _price,
            ListingStatus.Sold
        );
    }
}