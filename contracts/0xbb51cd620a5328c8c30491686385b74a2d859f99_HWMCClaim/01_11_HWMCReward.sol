// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HWMCClaim is Pausable, Ownable {

    using SafeMath for uint;
    event Received(address, uint);

    ERC20 public usdtAddress = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 public wbtcAddress = ERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);  

   struct Reward {
        uint256  airDropId ;
        uint256 eachUSDT;
        uint256 remUSDT;
        uint256 totalUSDT;
        uint256 eachwBTC;
        uint256 remwBTC;
        uint256 totalwBTC;
        mapping(uint256=>bool) claimedRewards;
    }
     
    mapping(uint256=>Reward) public Rewards;
    mapping(uint256=>bool) public blacklistIds;


    bool public claimEnabled = false;
    uint256 public airDropIdNo = 0;
    uint256 totalRemUSDT = 0;
    uint256 totalRemwBTC = 0;


    constructor() {}

    // Function to start the claim
    function startClaim() public onlyOwner whenNotPaused {
        airDropIdNo++;
        require(!claimEnabled,"Claim Disabled");
        require(usdtAddress.balanceOf(address(this))>0 && wbtcAddress.balanceOf(address(this))>0, "Reward tokens must not be 0");

        uint256 totalUSDT = usdtAddress.balanceOf(address(this)) - totalRemUSDT;
        uint256 totalwBTC = wbtcAddress.balanceOf(address(this)) - totalRemwBTC;

            //Each Matic for Current Drop
        uint256 eachUSDT = totalUSDT / 9999;
        uint256 eachwBTC = totalwBTC / 9999;

           Reward storage newAirdrop = Rewards[airDropIdNo];
           
            newAirdrop.airDropId= airDropIdNo;
            newAirdrop.eachUSDT= eachUSDT;
            newAirdrop.totalUSDT= totalUSDT;
            newAirdrop.eachwBTC= eachwBTC;
            newAirdrop.totalwBTC= totalwBTC;
        
        claimEnabled = true;

    }

    //Stop Function should be executed before next Reward
    function stopClaim () public onlyOwner {

       
        Rewards[airDropIdNo].remUSDT = usdtAddress.balanceOf(address(this)) - totalRemUSDT;
        Rewards[airDropIdNo].remwBTC = wbtcAddress.balanceOf(address(this)) - totalRemwBTC;

         totalRemUSDT= 0;
         totalRemwBTC= 0;

          for (uint i=1 ;i<=airDropIdNo;i++){
            totalRemUSDT+=Rewards[i].remUSDT;
            totalRemwBTC+=Rewards[i].remwBTC;
        }
        
        claimEnabled = false;
    }

    // Claim the reward Manually parameters{_nftId: Array of NFT IDs for which reward needs to be claimed, _dropId: Airdrop ID }
    function claimReward (uint256[] memory _nftId, uint256 _dropId)  public {
     
         uint256 totalClaimUSDT=0;
         uint256 totalClaimwBTC=0;

        for(uint i = 0 ; i<_nftId.length; i++) {

            address isOwner = IERC721(0xba72b008D53D3E65f6641e1D63376Be2F9C1aD05).ownerOf(_nftId[i]);
            require(isOwner == msg.sender);
            require(_nftId[i]>=1 || _nftId[i]<=9999, "Id must be between 1-9999");
            require(!Rewards[_dropId].claimedRewards[_nftId[i]], "Already Claimed");
            require(!blacklistIds[_nftId[i]], "This NFT is Black Listed");
    
           Rewards[_dropId].claimedRewards[_nftId[i]] = true;

           totalClaimUSDT+=Rewards[_dropId].eachUSDT; //Sum of All the USDT Rewards
           totalClaimwBTC+=Rewards[_dropId].eachwBTC;


        }

        usdtAddress.transfer(msg.sender,totalClaimUSDT);
        wbtcAddress.transfer(msg.sender,totalClaimwBTC);


        if(airDropIdNo>1 && _dropId <airDropIdNo){
            Rewards[_dropId].remUSDT -= totalClaimUSDT;
            Rewards[_dropId].remwBTC -= totalClaimwBTC;
        }  
      
        
        
    }

    //is an NFT id claimed for particular Reward
    function isClaimed(uint256 _nftId, uint256 _dropId) public view returns (bool) {
      if(Rewards[_dropId].claimedRewards[_nftId]){
            return true;
        }
    return false;
}

    function setUnsetBlacklistIds(uint256[] memory _nftId, bool _status) public onlyOwner{
        for(uint i = 0 ; i<_nftId.length; i++) {
            blacklistIds[_nftId[i]] = _status;
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    function withdraw() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
        usdtAddress.transfer(msg.sender,usdtAddress.balanceOf(address(this)));
        wbtcAddress.transfer(msg.sender,wbtcAddress.balanceOf(address(this)));
    }


}