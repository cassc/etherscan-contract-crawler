// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './cryptohinadolls.sol';
import './whitelist.sol';

contract CHDNFTMarketplace is AccessControl {

    struct preSaleData {
        uint256 startTime;
        uint256 endTime;
        uint256 startId;
        uint256 endId;
        address whiteListAddress;
    }

    mapping (uint256 => preSaleData) public presaleDatas;
    address nftAddress;
    mapping (uint256 => bool) public presaleFinished;
    uint256 salesPrice = 0.01 ether;
    address ownerAddress;
    uint256 presaleCounter;
    address receiveAddress = payable(0x8406B19D6e8A39134723F023Cb75a6d21D02F919);

    constructor(address _nftAddress, address _whitelistAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        nftAddress = _nftAddress;
        ownerAddress = msg.sender;
        presaleDatas[++presaleCounter] = preSaleData(1677466800, 1677510000, 0, 174, _whitelistAddress);
    }

    function setSaleData(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startId,
        uint256 _endId,
        address _whiteList
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(presaleDatas[presaleCounter].endTime < _startTime);
        presaleDatas[++presaleCounter] = preSaleData(_startTime, _endTime, _startId, _endId, _whiteList);
    }

    function changeSalesData(
        uint256 _presaleTime,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startId,
        uint256 _endId,
        address _whiteList
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_presaleTime <= presaleCounter);
        presaleDatas[_presaleTime] = preSaleData(_startTime, _endTime, _startId, _endId, _whiteList);
    }

    function changeNFTPrice(uint256 _price) public onlyRole(DEFAULT_ADMIN_ROLE) {
        salesPrice = _price;
    }

    function changeReceiveAddress(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        receiveAddress = _address;
    }

    function sellNFT(uint256 _offerId, uint256 _salesTime) public payable {
        require(msg.value == salesPrice, "The price for all approved NFTs is 0.025 ether.");
        require(block.timestamp >= presaleDatas[_salesTime].startTime, "before presale time");
        require(block.timestamp <= presaleDatas[_salesTime].endTime, "after presale time");
        require(_offerId >= presaleDatas[_salesTime].startId, "NFT is not selling");
        require(_offerId <= presaleDatas[_salesTime].endId, "NFT is not selling");
        require(presaleFinished[_offerId] == false, "NFT is already sold");
        require(whiteList(presaleDatas[_salesTime].whiteListAddress).checkWhiteListRemainAmount(msg.sender) >= 1);
        presaleFinished[_offerId] = true;
        whiteList(presaleDatas[_salesTime].whiteListAddress).addWhiteListUsed(msg.sender);
        CryptoHinaDolls(nftAddress).transferFrom(ownerAddress, msg.sender, _offerId);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(receiveAddress).transfer(address(this).balance);
    }

    function checkPrementEnablePeriod(uint256 _time) public view returns(bool) {
        if(block.timestamp >= presaleDatas[_time].startTime && block.timestamp <= presaleDatas[_time].endTime) {
            return true;
        } else {
            return false;
        }
    }

    function checkPrementEnablePeriodBool() public view returns(bool) {
        for (uint256 i = 1; i <= presaleCounter; i++) {
            if (
                block.timestamp >= presaleDatas[i].startTime &&
                block.timestamp <= presaleDatas[i].endTime
            ) {
                return true;
            } else if (
                i == presaleCounter
            ) {
                return false;
            } else {
                continue;
            }
        }
    }

    function checkPrementEnablePeriod2() public view returns(uint256) {
        bool result;
        for (uint256 i = 1; result == true || i <= presaleCounter; i++){
            if(
                block.timestamp >= presaleDatas[i].startTime &&
                block.timestamp <= presaleDatas[i].endTime
            ) {
                return i;
            } else if(
                i == presaleCounter
            ) {
                return 0;
            } else {
                continue;
            }
        }
    }

    function checkPresaleCounter() public view returns(uint256) {
        return presaleCounter;
    }

    function checkPresaleData(uint256 time) public view returns(preSaleData memory) {
        return presaleDatas[time];
    }

    function checkPresaleDatasStartTime(uint256 _time) public view returns(uint256) {
        return presaleDatas[_time].startTime;
    }

    function checkPresaleDatasEndTime(uint256 _time) public view returns(uint256) {
        return presaleDatas[_time].endTime;
    }

    function checkPresaleDatasStartId(uint256 _time) public view returns(uint256) {
        return presaleDatas[_time].startId;
    }
    
    function checkPresaleDatasEndId(uint256 _time) public view returns(uint256) {
        return presaleDatas[_time].endId;
    }

}