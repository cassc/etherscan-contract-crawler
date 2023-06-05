//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IPublicSale {
    /// @dev set changeTONOwner
    function changeTONOwner(
        address _address
    ) external; 

    /// @dev set the allsetting
    /// @param _Tier _Tier[0~3] : set the sTOS Tier standard, _Tier[4~7] : set the Tier percents
    /// @param _amount _amount[0] : Round1 Sale Amount, _amount[1] : Round2 Sale Amount, _amount[2] : saleToken Price, _amount[3] : TON Price, _amount[4] : hardcap amount, _amount[5] : ton to tos %
    /// @param _time _time[0] : sTOS snapshot time, _time[1] : whitelist startTime, _time[2] : whitelist endTime, _time[3] : round1 sale startTime, _time[4] : round1 sale endTime, _time[5] : round2 deposit startTime, _time[6] : round2 deposit endTime, _time[7] : totalClaimCounts
    /// @param _claimTimes _claimTimes[] : claim time array
    /// @param _claimPercents _claimPercents[] : claim percents array (this is need sum 100)
    function setAllsetting(
        uint256[8] calldata _Tier,
        uint256[6] calldata _amount,
        uint256[8] calldata _time,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimPercents
    ) external;
    
    /// @dev set snapshot
    /// @param _snapshot _snapshot timestamp
    function setSnapshot(uint256 _snapshot) external;

    /// @dev set information related to exclusive sale
    /// @param _startAddWhiteTime start time of addwhitelist
    /// @param _endAddWhiteTime end time of addwhitelist
    /// @param _startExclusiveTime start time of exclusive sale
    /// @param _endExclusiveTime start time of exclusive sale
    function setExclusiveTime(
        uint256 _startAddWhiteTime,
        uint256 _endAddWhiteTime,
        uint256 _startExclusiveTime,
        uint256 _endExclusiveTime
    ) external;

    /// @dev set information related to open sale
    /// @param _startDepositTime start time of deposit
    /// @param _endDepositTime end time of deposit
    function setOpenTime(
        uint256 _startDepositTime,
        uint256 _endDepositTime
    ) external;

    /// @dev set information related to open sale
    /// @param _claimCounts totalClaimCounts from this contract
    /// @param _claimTimes claim time array
    /// @param _claimPercents claim percents array (this is need sum 100)
    function setEachClaim(
        uint256 _claimCounts,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimPercents
    ) external;

    /// @dev set information related to tier and tierPercents
    /// @param _tier[4] sTOS condition setting
    /// @param _tierPercent[4] tier proportion setting
    function setAllTier(
        uint256[4] calldata _tier,
        uint256[4] calldata _tierPercent
    ) external;

    /// @dev set information related to tier
    /// @param _tier1 tier1 condition of STOS hodings
    /// @param _tier2 tier2 condition of STOS hodings
    /// @param _tier3 tier3 condition of STOS hodings
    /// @param _tier4 tier4 condition of STOS hodings
    function setTier(
        uint256 _tier1,
        uint256 _tier2,
        uint256 _tier3,
        uint256 _tier4
    ) external;

    /// @dev set information related to tier proportion for exclusive sale
    /// @param _tier1 tier1 proportion (If it is 6%, enter as 600 -> To record up to the 2nd decimal point)
    /// @param _tier2 tier2 proportion
    /// @param _tier3 tier3 proportion
    /// @param _tier4 tier4 proportion
    function setTierPercents(
        uint256 _tier1,
        uint256 _tier2,
        uint256 _tier3,
        uint256 _tier4
    ) external;

    /// @dev set information related to saleAmount and tokenPrice
    /// @param _expectAmount[2] saleAmount setting
    /// @param _priceAmount[2] tokenPrice setting
    function setAllAmount(
        uint256[2] calldata _expectAmount,
        uint256[2] calldata _priceAmount
    ) external;

    /// @dev set information related to sale amount
    /// @param _totalExpectSaleAmount expected amount of exclusive sale
    /// @param _totalExpectOpenSaleAmount expected amount of open sale
    function setSaleAmount(
        uint256 _totalExpectSaleAmount,
        uint256 _totalExpectOpenSaleAmount
    ) external;

    /// @dev set information related to token price
    /// @param _saleTokenPrice the sale token price
    /// @param _payTokenPrice  the funding(pay) token price
    function setTokenPrice(uint256 _saleTokenPrice, uint256 _payTokenPrice)
        external;

    /// @dev set information related to token price
    /// @param _hardcapAmount the sale token price
    /// @param _changePercent  the funding(pay) token price
    function setHardcap (
        uint256 _hardcapAmount,
        uint256 _changePercent
    ) external;

    /// @dev view totalExpectOpenSaleAmount
    function totalExpectOpenSaleAmountView()
        external
        view
        returns(uint256);

    /// @dev view totalRound1NonSaleAmount
    function totalRound1NonSaleAmount() 
        external 
        view 
        returns(uint256);

    /// @dev calculate the sale Token amount
    /// @param _amount th amount
    function calculSaleToken(uint256 _amount) external view returns (uint256);

    /// @dev calculate the pay Token amount
    /// @param _amount th amount
    function calculPayToken(uint256 _amount) external view returns (uint256);

    /// @dev calculate the tier
    /// @param _address user address
    function calculTier(address _address) external view returns (uint256);

    /// @dev calculate the tier's amount
    /// @param _address user address
    function calculTierAmount(address _address) external view returns (uint256);

    /// @dev calculate the open sale amount
    /// @param _account user address
    /// @param _amount  amount
    function calculOpenSaleAmount(address _account, uint256 _amount)
        external
        view
        returns (uint256);

    /// @dev calculate the open sale amount
    /// @param _account user address
    function calculClaimAmount(address _account, uint256 _period)
        external
        view
        returns (uint256 _reward, uint256 _totalClaim, uint256 _refundAmount);


    /// @dev view totalSaleUserAmount
    function totalSaleUserAmount(address user) 
        external 
        view 
        returns (uint256 _realPayAmount, uint256 _realSaleAmount, uint256 _refundAmount);

    /// @dev view openSaleUserAmount
    function openSaleUserAmount(address user) 
        external 
        view 
        returns (uint256 _realPayAmount, uint256 _realSaleAmount, uint256 _refundAmount);
    
    /// @dev view totalOpenSaleAmount
    function totalOpenSaleAmount() 
        external 
        view 
        returns (uint256);

    /// @dev view totalOpenPurchasedAmount
    function totalOpenPurchasedAmount() 
        external
        view 
        returns (uint256);

    /// @dev execute add whitelist
    function addWhiteList() external;

    /// @dev execute exclusive sale
    /// @param _sender user address
    /// @param _amount  amount
    function exclusiveSale(address _sender,uint256 _amount) external;

    /// @dev execute deposit
    /// @param _sender user address
    /// @param _amount  amount
    function deposit(address _sender,uint256 _amount) external;

    /// @dev execute the claim
    function claim() external;

    /// @dev execute the claim
    function depositWithdraw() external;

    function _decodeApproveData(
        bytes memory data
    ) external pure returns (uint256 approveData);

    function _toWAD(uint256 v) external pure returns (uint256);

}