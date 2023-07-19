// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// import "hardhat/console.sol";
import {IERC20} from  "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract SoonVesting is Ownable,ReentrancyGuard{
    using SafeERC20 for IERC20;
    address public constant SOON_TOKEN = 0x574D22E2555cAc0ce71e44778f6De2e7487aE229;

    //storge
    // The amount of the token could be vested to the account.
    // I.e how many token totally could be vested/released by this contract to the account.
    mapping (address => uint256) private _userTotalRelease;

    // How many token has been claimed from the account.
    // The user may have claimed many times in the past but the success criteria is that
    // if there are released/vested but not claimed token.
    mapping (address => uint256) private _userWithdrawed;

    // The release/vesting is linear and the uint indicates how many times the contract could vest token to account. 
    // This is fixed all time.
    mapping (address => uint256) private _userReleaseTimes;

    // The timestamp in seconds that the vesting/release starts.
    mapping (address => uint256) private _userReleaseStartTime;

    // The release/vesting in linear and this's the interval in seconds between each vesting/release.
    mapping (address => uint256) private _userReleaseIntervalTime;

    // Whether the address is revoked or not.
    // Token unvested for an account could be revoked by owner. The revoked token is sent back to the owner's address.
    // For example: An account is rewarded 1000 token and at sometime it has 400 vested/released and 600 unvest/locked.
    // and somehow the address's private key is leaked and we are asked to revoke the 600 unvested/locked token to make sure the asset is safe for our investors.
    // WE WILL NOT REVOKE ANY token for any address except this is requested by known private investors and the requestor's identity will be strictly verified.
    mapping (address => bool) public _revoked;

    //event
    // The release/vesting policy is set up.
    // Including the amount of total vesting/release, total vesting times, vesting interval, vesting start time in seconds.
    event ReleaseSeted(address account,uint256 userTotalRelease,uint256 userReleaseTimes,uint256 userReleaseIntervalTime,uint256 userReleaseStartTime);

    // The user/account claimed all vested/released tokens.
    event Claimed(address account,uint256 userTotalRelease,uint256 totalWithdrawed,uint256 claimed);

    // The release/vesting process is started.
    event ReleaseStarted(address account, uint256 startTime);

    // The unvested token is revoked by owner.
    event Revoke(address account, uint256 RevokeNum,uint256 userTotalRelease);



    modifier releaseUnSeted(address addr) {
        require(_userTotalRelease[addr] == 0);
        require(_userWithdrawed[addr] == 0);
        require(_userReleaseTimes[addr] == 0);
        require(_userReleaseIntervalTime[addr] == 0);
        require(_revoked[addr] == false);
        _;
    }

    modifier releaseSeted(address addr)
    {
        require(_userTotalRelease[addr] > 0);
        require(_userReleaseTimes[addr] > 0);
        require(_userReleaseIntervalTime[addr] > 0);
        require(_revoked[addr] == false);
        _;
    }


    constructor() {
        _SetRelease(0xC3C3474724A964933e058a5faE3573d67ABC426D,560000000*(10**18),60,86400*30,1686240000);
        _SetRelease(0x225213188e68FFfda4ECd711e23CFE63201341b8,150000000*(10**18),60,86400*30,1686240000);
        _SetRelease(0x6D023296951644442d45B0aB0697fb7E8e7E1751,100000000*(10**18),48,86400*30,1717862400);
        _SetRelease(0x51bD5538411A3294EEc79E2314FeA494D2e6B96F,30000000*(10**18),60,86400*30,1686240000);
        _SetRelease(0x13D8954281BD9E288Ad2693dA71E88f13C20B40F,113100000*(10**18),12,86400*30,1691510400);
        _SetRelease(0x9ba3498c893b6E1528EbD4638b4541aa77524b5e,500000*(10**18),12,86400*30,1691510400);
        _SetRelease(0x5bA0e51E94cB0DDa9D65DCc07314ae0c5332b323,1000000*(10**18),12,86400*30,1691510400);
        _SetRelease(0xFF23c1390758f765a7CE28415DDADb1D128e5F58,2000000*(10**18),12,86400*30,1691510400);
        _SetRelease(0xA7e1D0Bb0E443c13c3872561DE1943ad055084B0,2000000*(10**18),12,86400*30,1691510400);
        _SetRelease(0x95EF65C5c6feC0FdB66a3d4d5F929f9083d92160,250000*(10**18),12,86400*30,1691510400);
        _SetRelease(0x1d8f650DA2E87f50FFF7ba89ddfB530eA386A1f7,1000000*(10**18),12,86400*30,1691510400);
        _SetRelease(0x8A125F171E7ABb5899A705BD11B48263e7992A76,150000*(10**18),12,86400*30,1691510400);
    }

    // view

    function getReleaseDetail (address account) public view returns(uint256,uint256,uint256,uint256,uint256,bool){
        return (_userTotalRelease[account],_userWithdrawed[account],_userReleaseTimes[account],_userReleaseIntervalTime[account],_userReleaseStartTime[account],_revoked[account]);
    }


    function AmountOfTokenPerRelease(address account) public view returns(uint256) {
        return _userTotalRelease[account]/_userReleaseTimes[account];
    }

    // Get the earliest time to claim all vested/released token.
    // When user claims, the user will claim all vested/released token available in the contract.
    // If the user has not claimed for a longtime, the user could claim all released immediately.
    // If the user has been aggressively claiming all the time, the earliest time to claim is the next release time.
    function GetEarliestTimeToClaimVested(address account) public view returns(uint256){
        uint256 userReleaseStartTime = _userReleaseStartTime[account];
        uint256 userWithdrawed = _userWithdrawed[account];
        uint256 userTotalRelease = _userTotalRelease[account];
        uint256 userReleaseTimes = _userReleaseTimes[account];
        uint256 userReleaseIntervalTime = _userReleaseIntervalTime[account];
        return userReleaseStartTime + userWithdrawed/(userTotalRelease/userReleaseTimes) * userReleaseIntervalTime;
    }
    //external

    function SetRelease(address account_,uint256 userTotalRelease_,uint256 userReleaseTimes_,uint256 userReleaseIntervalTime_,uint256 userReleaseStartTime_) external onlyOwner releaseUnSeted(account_) {
       require(account_!=address(0),"account error");
       require(userTotalRelease_>0,"userTotalRelease_ <= 0");
       require(userReleaseTimes_>0,"userReleaseTimes <= 0");
       require(userReleaseIntervalTime_>0,"userReleaseIntervalTime <= 0");
       require(userReleaseStartTime_>0,"userReleaseStartTime_ <= 0");
       _SetRelease(account_,userTotalRelease_,userReleaseTimes_,userReleaseIntervalTime_,userReleaseStartTime_);
       
    }


    function _SetRelease(address account_,uint256 userTotalRelease_,uint256 userReleaseTimes_,uint256 userReleaseIntervalTime_,uint256 userReleaseStartTime_) private {
      
        _userWithdrawed[account_] = 0;
        _userTotalRelease[account_] = userTotalRelease_;
        _userReleaseTimes[account_] = userReleaseTimes_;
        _userReleaseIntervalTime[account_] = userReleaseIntervalTime_;
        _userReleaseStartTime[account_] = userReleaseStartTime_;

        emit ReleaseSeted(account_ ,userTotalRelease_,userReleaseTimes_,userReleaseIntervalTime_,userReleaseStartTime_);
    }

    



    // function startRelease(address[] memory accounts) external onlyOwner returns(bool){
    //     require(accounts.length>0,"length = 0");
    //     for(uint256 i=0;i<accounts.length;++i){
    //         require(accounts[i]!=address(0),"address error");
    //         //require(_userReleaseStartTime[accounts[i]]==0,"StartTime has set");
    //         _userReleaseStartTime[accounts[i]] = block.timestamp;
    //         emit ReleaseStarted(accounts[i],block.timestamp);
    //     }
    //     return true;
    // }

    function revoke(address account) external onlyOwner releaseSeted(account) returns(bool){
        require(account!=address(0),"address error");
        uint256 userTotalRelease = _userTotalRelease[account];
        uint256 userWithdrawed = _userWithdrawed[account];
        //uint256 userReleaseIntervalTime = _userReleaseIntervalTime[account];

        //require(block.timestamp > userReleaseStartTime, "can not revoke because the vesting started");

        // Amount of token per released.
       // uint256 amountOfTokenPerRelease = AmountOfTokenPerRelease(account);

        // how many times has the account vested.
        // This could be equal or greater than the actual maximum vesting times.
        // uint256 releasedTimes = (block.timestamp - userReleaseStartTime) / userReleaseIntervalTime + 1;
        
        // If total released calculated is greater than total release set, which means the vesting process has been ended.
        // uint256 totalReleased = amountOfTokenPerRelease * releasedTimes;
        // if(totalReleased > userTotalRelease){
        //     totalReleased = userTotalRelease;
        // }

        // We only revoke unvested token if necessary.
        uint256 revokeNum = userTotalRelease - userWithdrawed;
        IERC20(SOON_TOKEN).safeTransfer(_msgSender(),revokeNum);
        _revoked[account] = true;
        emit Revoke(account,revokeNum,userTotalRelease);
        return true;
       
    }

    function claim() external nonReentrant releaseSeted(_msgSender()){
        uint256 userReleaseStartTime = _userReleaseStartTime[_msgSender()];
        uint256 userWithdrawed = _userWithdrawed[_msgSender()];
        uint256 userTotalRelease = _userTotalRelease[_msgSender()];
        uint256 userReleaseIntervalTime = _userReleaseIntervalTime[_msgSender()];
        require(userReleaseStartTime>0 && block.timestamp > userReleaseStartTime,"Release not started");
        require(userTotalRelease > userWithdrawed,"All release & withdrawed");
        require(block.timestamp > GetEarliestTimeToClaimVested(_msgSender()),"Release time not yet reached");

        uint256 amountOfTokenPerRelease = AmountOfTokenPerRelease(_msgSender());

        // how many times has the account vested.
        // This could be equal or greater than the actual maximum vesting times.
        uint256 releasedTimes = (block.timestamp - userReleaseStartTime) / userReleaseIntervalTime + 1;

        uint256 totalReleased = amountOfTokenPerRelease * releasedTimes;

        //If _userTotalRelease/userReleaseTimes is indivisible,  Ensure that all tokens can be claimed for the last time
        if(totalReleased + 10 > userTotalRelease){
            totalReleased = userTotalRelease;
        }

        require(totalReleased > userWithdrawed, "No available vested tokens could be claimed");
        
        // The amount be able to claim at this moment calling claim().
        uint256 _tokenToClaim = totalReleased - userWithdrawed;
        IERC20(SOON_TOKEN).safeTransfer(_msgSender(),_tokenToClaim);

        _userWithdrawed[_msgSender()] = totalReleased; 
        emit Claimed(_msgSender(), userTotalRelease, totalReleased, _tokenToClaim);

    }

}
