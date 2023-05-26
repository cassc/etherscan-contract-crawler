// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


import "./Presale.sol";
import "./LaunchPadLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";


contract LaunchpadV2 is Ownable {
    
    using LaunchPadLib for *;

    uint public presaleCount = 0;
    uint public upfrontfee = 2 ether;
    uint8 public salesFeeInPercent = 2;

    address public uniswapV2Router02 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;    // BSC Mainnet router
    // address public uniswapV2Router02 = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;    // BSC Testnet router

    address public teamAddr = 0xaEEE930D7Dc148862051CC0F43114FedAbAF34BC;
    address public devAddr = 0x2a1706e0B87373445c500621a47cb26484D1DdfF;

    ////////////////////////////// MAPPINGS ///////////////////////////////////

    mapping(uint => address) public presaleRecordByID;
    mapping(address => address[]) private presaleRecordByToken;

    event PresaleCreated(uint id, address presaleAddress);

    ////////////////////////////// FUNCTIONS ///////////////////////////////////

    constructor(address _uniswapV2Router02, address _teamAddr, address _devAddr){
        uniswapV2Router02 = _uniswapV2Router02;
        teamAddr = _teamAddr;
        devAddr = _devAddr;
    }

    
    function createPresale(
        LaunchPadLib.TokenInfo memory _tokenInfo,
        LaunchPadLib.ParticipationCriteria memory _participationCriteria,
        LaunchPadLib.PresaleTimes memory _presaleTimes,
        LaunchPadLib.ContributorsVesting memory _contributorsVesting,
        LaunchPadLib.TeamVesting memory _teamVesting,
        LaunchPadLib.GeneralInfo memory _generalInfo
        ) public payable {


        if(_teamVesting.isEnabled){
            require(_teamVesting.vestingTokens > 0, "Vesting tokens should be more than zero");
        }

        require( 
            _participationCriteria.liquidity >= 20 && 
            _participationCriteria.liquidity <= 95 && 
            _presaleTimes.startedAt > block.timestamp && 
            _presaleTimes.expiredAt > _presaleTimes.startedAt, 
            "Liquidity or Times are invalid"
            );

        require(
            _participationCriteria.softCap > 0 && 
            _participationCriteria.softCap < _participationCriteria.hardCap && 
            _participationCriteria.softCap >= _participationCriteria.hardCap/2 && 
            _participationCriteria.minContribution > 0 && 
            _participationCriteria.minContribution < _participationCriteria.maxContribution,
            "Invalid hardcap/softcap or minContribution/maxContribution"
            );

        if(msg.sender != owner()) {
            require( msg.value >= upfrontfee, "Insufficient funds to start");
        }

        presaleCount++;
        
        LaunchPadLib.PresaleInfo memory _presaleInfo = LaunchPadLib.PresaleInfo(presaleCount, msg.sender, LaunchPadLib.PreSaleStatus.PENDING);

        Presale _presale = new Presale ( 
                _tokenInfo,
                _presaleInfo,
                _participationCriteria,
                _presaleTimes,
                _contributorsVesting,
                _teamVesting,
                _generalInfo,
                salesFeeInPercent,
                uniswapV2Router02
        );

        uint tokensForSale = (_participationCriteria.hardCap * _participationCriteria.presaleRate * 10**_tokenInfo.decimals) / 1 ether ;
        uint tokensForLP = (tokensForSale * _participationCriteria.liquidity) / 100;
        uint tokensForVesting = _teamVesting.vestingTokens * 10**_tokenInfo.decimals;
        uint totalTokens = tokensForSale + tokensForLP + tokensForVesting;

        IERC20(_tokenInfo.tokenAddress).transferFrom(msg.sender, address(_presale), totalTokens);
                   
        presaleRecordByToken[_tokenInfo.tokenAddress].push(address(_presale));
        presaleRecordByID[presaleCount] = address(_presale);

        emit PresaleCreated(presaleCount, address(_presale));

    }

    function getPresaleRecordsByToken(address _address) public view returns(address[] memory) {
        return presaleRecordByToken[_address];
    }

    function updateFees(uint _upfrontFee, uint8 _salesFeeInPercent) public onlyOwner {
        upfrontfee = _upfrontFee; 
        salesFeeInPercent = _salesFeeInPercent;
    }

    function withdrawBNBs() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0 , "nothing to withdraw");

        uint teamShare = (balance * 90) / 100;       

        (bool res1,) = payable(teamAddr).call{value: teamShare}("");
        require(res1, "cannot send team Share"); 


        (bool res2,) = payable(devAddr).call{value: balance - teamShare}("");
        require(res2, "cannot send devTeamShare"); 
    }
    
    function updateTeamAddress(address _address) public onlyOwner {
        teamAddr = _address;
    }

    function updateDevAddress(address _address) public {
        require(devAddr == address(msg.sender), "Only dev is allowed");
        devAddr = _address;
    }

    receive() external payable {}

}