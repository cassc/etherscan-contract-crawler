//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./matchContract.sol";
import "./SFPCollection.sol";


contract SFPVesting is Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    uint slicePeriod;
    uint timeUnit;
    MatchContract matchContractInstance ;
    SFPCollection public nftAddress;
    address public admin;

    struct claimSchedule {
        bool initialized;
        uint totalEligible;
		uint totalClaimed;
		uint remainingBalTokens;
		uint lastClaimedAt;
    }


    modifier onlyOwnerAndAdmin() {
        require(owner() == _msgSender() || _msgSender() == admin, "Ownable: caller is not the owner or admin");
        _;
    }

    mapping(uint => mapping( uint => claimSchedule))  public nftData;

    ERC20 private _token;

    constructor (address _nftAddress, address _matchContractAddress ,address token_) {

        require(token_ != address(0x0));
        _token = ERC20(token_);
        slicePeriod = 1;
        timeUnit = 86400;
        nftAddress = SFPCollection(address(_nftAddress));
        matchContractInstance = MatchContract(address(_matchContractAddress));
        setAdmin(_msgSender());
    
    }
    
    
    function getToken()
    external
    view
    returns(address){
        return address(_token);
    }

    function setAdmin(address _adminAddress) public onlyOwnerAndAdmin {
        admin = _adminAddress;
    }

    function setToken(address token_) public onlyOwnerAndAdmin{
        _token = ERC20(token_);
    }

    function withdraw(uint256 amount)
        public
        nonReentrant
        onlyOwnerAndAdmin{
        _token.safeTransfer(owner(), amount);
    }

    function setSlicePeriod (uint _data) public onlyOwnerAndAdmin{
        slicePeriod = _data;
    }

    function getSlicePeriod () public view returns(uint _slicePeriod){
        return slicePeriod;
    }

    function setTimeUnit(uint _unit) public onlyOwnerAndAdmin{
        timeUnit = _unit;
    }

    function getTimeUnit() public view returns(uint _timeUnit){
        return timeUnit;
    }

    function getNftBalance(address _account) public view returns(uint256) {
        return (nftAddress.balanceOf(_account));
    }

    function setNftAddress(ERC721Upgradeable _nftAddress) public onlyOwnerAndAdmin{
        nftAddress = SFPCollection(address(_nftAddress));
    }
    
    function setMatchAddress(MatchContract _matchContractAddress) public onlyOwnerAndAdmin{    
       matchContractInstance = MatchContract(address(_matchContractAddress));
    }

    function getMatchContractAddress() public view returns (MatchContract _contract){
        return matchContractInstance;
    }

    function getNftIds(address _account) public view returns(uint256[] memory _nftIds){
        return nftAddress.getNftIdsByWallet(_account);
    }

    function getCountryIds(uint _nftId) public view returns(uint _countryIds){
        return(nftAddress.getCountryIdsByNftId(_nftId));
    }

    function getMatchData(uint8 _matchId) public view returns(uint _startTime,uint256 _tokenAmount){

        (,,,,uint startTime,uint tokenAmount) =  matchContractInstance.matchesInfo(_matchId);
        return (startTime,tokenAmount);
    }

    function getCurrentTime()
        internal
        virtual
        view
        returns(uint256){
        return block.timestamp;
    }

    function getMatchIdByNftId(uint _nftId) public view returns(uint256[] memory _matchId,uint _length){
        uint countryId = getCountryIds(_nftId);
        return (matchContractInstance.getMatchesOfCountry(countryId),matchContractInstance.getMatchesOfCountry(countryId).length);
    }

    function claimMatchTokens(uint _nftId,uint8 _matchId) public {

        uint _totalAmount;
        uint256 _amount ;
        (uint _startTime,uint _tokenAmount)= getMatchData(_matchId);
        if(_startTime < getCurrentTime()){

            if(!nftData[_nftId][_matchId].initialized){

                nftData[_nftId][_matchId] = claimSchedule({

                    initialized:true,
                    totalEligible:_tokenAmount,
                    totalClaimed:0,
                    remainingBalTokens:0,
                    lastClaimedAt:_startTime

                    });
                }
                _amount= getClaimableAmount(_nftId,_matchId);

                if(_amount>0){
                    
                    _totalAmount = _totalAmount.add(_amount);
                    nftData[_nftId][_matchId].lastClaimedAt=getCurrentTime();
                    nftData[_nftId][_matchId].totalClaimed=nftData[_nftId][_matchId].totalClaimed.add(_amount.div(getDecimal()));
                    nftData[_nftId][_matchId].remainingBalTokens=nftData[_nftId][_matchId].totalEligible.sub(nftData[_nftId][_matchId].totalClaimed);

                }
            }
        
        address nftOwner = nftAddress.ownerOf(_nftId);
        require(nftOwner == _msgSender(),"caller is not the owner "); 
        _token.safeTransfer(nftOwner, _amount);
    }

    function claim(uint _nftId) public{

        require(getNftBalance(_msgSender())>0,"Caller does not have Nft balance");
        (uint[] memory matchIds,uint length) = getMatchIdByNftId(_nftId);
        uint _totalAmount =0;
        for(uint8 i=0;i<length;i++){
            
            uint8 _matchId = uint8(matchIds[i]);
            (uint _startTime,uint _tokenAmount)= getMatchData(_matchId);
            if(_startTime < getCurrentTime()){
                    
                if(!nftData[_nftId][_matchId].initialized){

                    nftData[_nftId][_matchId] = claimSchedule({
                        initialized:true,
                        totalEligible:_tokenAmount,
                        totalClaimed:0,
                        remainingBalTokens:0,
                        lastClaimedAt:_startTime
                    });
                }
                (uint256 _amount)= getClaimableAmount(_nftId, _matchId);

                if(_amount>0){
                    
                    _totalAmount = _totalAmount.add(_amount);
                    nftData[_nftId][_matchId].lastClaimedAt=getCurrentTime();
                    nftData[_nftId][_matchId].totalClaimed=nftData[_nftId][_matchId].totalClaimed.add(_amount.div(getDecimal()));
                    nftData[_nftId][_matchId].remainingBalTokens=nftData[_nftId][_matchId].totalEligible.sub(nftData[_nftId][_matchId].totalClaimed);

                }
            }
        }
        address nftOwner = nftAddress.ownerOf(_nftId);
        require(_totalAmount>0,"amount must be greater than zero");
        require(nftOwner == _msgSender(),"caller is not the owner ");
        _token.safeTransfer(nftOwner, _totalAmount);

    }

    function getDecimal() view public returns(uint){
        uint _decimal = (10**_token.decimals());
        return _decimal;
    }

    function getClaimableAmount(uint _nftId,uint8 _matchId) internal view returns(uint _claimAmount) {

        uint256 timeLeft = 0;
        uint slicePeriodSeconds = slicePeriod * timeUnit;
        uint256 totalVestingDays = matchContractInstance.getVestingDays();
        uint256 claimAmount =0;
        uint256 _amount =0;


        if(!nftData[_nftId][_matchId].initialized){

            (uint _startTime,uint _tokenAmount)= getMatchData(_matchId);
            if(getCurrentTime()< _startTime){
                return 0;
            }
            if(getCurrentTime()>_startTime){
                timeLeft = getCurrentTime().sub(_startTime);
                
            }else{
                timeLeft =  _startTime.sub(getCurrentTime());
            }
            _amount = _tokenAmount;
            claimAmount =0;

            if(timeLeft/slicePeriodSeconds > 0){
                claimAmount = ((_amount*slicePeriod*getDecimal())/totalVestingDays)*(timeLeft/slicePeriodSeconds) ;
            }
            
            if(claimAmount > _amount*getDecimal()){
                claimAmount = _amount;
                return (claimAmount*getDecimal());
            }

            return (claimAmount);

        }else{

            uint256 currentTime = getCurrentTime();
            uint _decimal = getDecimal();
            uint totalEligible = nftData[_nftId][_matchId].totalEligible * _decimal;
            uint lastClaimedAt = nftData[_nftId][_matchId].lastClaimedAt;
            if(currentTime>lastClaimedAt){
                timeLeft = currentTime.sub(lastClaimedAt);
            
            }else{
                timeLeft =  lastClaimedAt.sub(currentTime);
            }

            _amount = totalEligible;

            if(timeLeft/slicePeriodSeconds > 0){
                claimAmount = ((_amount*slicePeriod)/totalVestingDays)*(timeLeft/slicePeriodSeconds) ;
            }

            uint _lastReleaseAmount = nftData[_nftId][_matchId].totalClaimed*_decimal;

            uint256 temp = _lastReleaseAmount.add(claimAmount);

            if(temp > totalEligible){
                _amount = totalEligible.sub(_lastReleaseAmount);
                return (_amount);
            }
                return (claimAmount);

        }        
    }

    function getVestingInfo(uint _nftId,uint8 _matchId) public view returns(uint _totalEligible,uint _claimAmount,uint _totalClaimed,uint _remainingBalTokens,uint _lastClaimedAt){
        (uint _startTime,uint _tokenAmount)= getMatchData(_matchId);

        if(!nftData[_nftId][_matchId].initialized){
            return (getCurrentTime()< _startTime?0:_tokenAmount,getClaimableAmount(_nftId,_matchId).div(getDecimal()),0,getCurrentTime()< _startTime?0:_tokenAmount,0);
        }else{
            return (nftData[_nftId][_matchId].totalEligible,getClaimableAmount(_nftId,_matchId).div(getDecimal()),nftData[_nftId][_matchId].totalClaimed,nftData[_nftId][_matchId].remainingBalTokens,nftData[_nftId][_matchId].lastClaimedAt);
        }
    }

    function getTotalPendingClaims(uint _nftId) public view returns(uint _totalEligible,uint _totalPendingClaimAmount,uint _totalClaimed,uint _lockedAmount){

        (uint[] memory matchIds,uint length) = getMatchIdByNftId(_nftId);
        uint _totalAmount =0;
        _totalEligible = 0;
        _totalClaimed=0;
        for(uint8 i=0;i<length;i++){
            uint8 _matchId = uint8(matchIds[i]);
            (uint _startTime,uint _tokenAmount)= getMatchData(_matchId);
            _totalEligible +=getCurrentTime()< _startTime?0:_tokenAmount;
            (uint pendingClaims) = getClaimableAmount(_nftId,_matchId);
            _totalAmount += pendingClaims;
            _totalClaimed += nftData[_nftId][_matchId].totalClaimed;
        }
        _lockedAmount = _totalEligible -   (_totalAmount/getDecimal()+_totalClaimed);
        return (_totalEligible,_totalAmount/getDecimal(),_totalClaimed,_lockedAmount);
    }

}