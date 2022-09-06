// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IEmber {

    struct Lending {
        address lenderAddress;
        address adapter;
        uint256 dailyRentPrice;
        uint256 stakedTill;
        uint256 tokenId;
    }


    struct Renting {
        address payable renterAddress;
        address nft;
        uint256 tokenId;
        uint256 rentedTill;
        uint256 rentedAt;
        uint256 rentDuration;
    }

    struct LendingRenting {
       Lending lending;
       Renting renting;
    }

    struct BorrowerProxy{
        bool newBorrower;
        address proxyAddress;
    }
    
    event Lent(
        address indexed nftAddress,
        address indexed lenderAddress,
        uint256 tokenId,
        uint256 lendingId, 
        uint256 dailyRentPrice,
        uint256 stakedTill,
        uint256 lentAt
    );

    event Rented(
        address indexed renterAddress,
        address indexed lenderAddress,
        address indexed nft,
        uint256 tokenId,
        uint256 lendingId,
        uint256 rentDuration,
        uint256 amountPaid,
        uint256 rentedAt
    );

    event LendingStopped(address msgSender, uint256 stoppedAt, address nft);

    function lend(
        address _nft,
        address _adapter, 
        uint256 _tokenId,
        uint256 _maxRentDuration,
        uint256 _dailyRentPrice
    ) external;

    
    function rent(
        address _nft,
        uint256 _tokenId,
        uint256 _lendingId,
        uint256 _rentDuration
    ) external payable returns(address);

    function stopLending(
        address _nft,
        uint256 _tokenId,
        uint256 _lendingId
    ) external;

    function checkProxy(address _borrower) external view returns(address);

    function getRentedTill(uint256 _lendingId) external view returns(uint256);

    function getStakedTill(uint256 _lendingId) external view returns(uint256);

    function getDailyRentCharges(uint256 _lendingId) external view returns(uint256);

    function getNFTAdapter(uint256 _lendingId) external view returns(address);

    function getNFTtokenID(uint256 _lendingId) external view returns(address, uint256);
}