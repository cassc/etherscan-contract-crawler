// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/*

                                              !?JJJJJJJJJJJJJJJJJJJJ?7:         
                                            .?J???????????????????????J~        
                                           ^J??????????????????????????J7       
    .                                     ~J???????????????????????????7J?.     
   7G5!.                                 7J???????????????????????????????J:    
   .!PBP7.                             .?J7????????????????????????????????J~   
     .?GBP?:                          :J????????????????????????????????????J7  
       :JGBP?:                       ~J?????????????????????????????????????7J?.
         ^YGGGJ^           .::::::::7J???????????????????????J?????????????????J
          ^GGGGGY^         ?JJ????????????????????????????J?!: :Y??????????????Y
         ^5GGGGGGGY~        ^7J??7?????????????????????J?!:   ~J????????????7J?.
        !PGGGGGGGGGG5!.       .~?J??????????????????J?7^.   ^?J?????????????J7  
       ?GGGGGGGGGGGGGGP?:        :!?J?????????????J7~.    :7J??????????????J!   
     .YGGGGGGGGGGGGGGGGGPJ^        .~?J????????J?~.     .!J???????????????J^    
    ^5GGGGGGGGGGGGGGGGGGGGGY~         :!?J??J?!:       ~J??????????????7J?:     
   !PGGGGGGGGGGGGGGGGGGGGGGGG5!.        .^~~:        ^?J???????????????J7.      
  ?GGGGGGGGGGGGGGGGGGGGGGGGGGGGP?:                 :?J?7??????????????J!        
.JGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJ^              :YJ????????????????7^         
5GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGJ              ..................           
5GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGY              ..................           
.JGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG5!              .JJ????????????????7^         
  ?GGGGGGGGGGGGGGGGGGGGGGGGGGGGG5!.                .!J????????????????J!        
   !PGGGGGGGGGGGGGGGGGGGGGGGGG5!.        :~^.        .7J???????????????J7       
    ^5GGGGGGGGGGGGGGGGGGGGGGP7.       :!Y5PP5?^        :7J??????????????J?:     
     .YGGGGGGGGGGGGGGGGGGGP7.      .!J5PP5555PPY7:       :7J??????????????J^    
       ?GGGGGGGGGGGGGGGGP7.     .~J5PP5555555555P5J~.      ^?J?????????????J!   
        !PGGGGGGGGGGGGP7.    .~?5PP555555555555555PP5?^      ^?J????????????J7  
         ^5GGGGGGGGGP?:   .^?5PP555555555555555555555PPY!:     ^?J???????????J?.
          .?5PPGGGP?:    ~5PP555555PP555555555555555555PP5J~.    ~?J???????????Y
             .!GG?:      .:::::::::^?P55555555555555555555PP57^   .~J??????????J
            .JGJ:                    ~5P555555555555555555555PPY!.  .!J??????J?.
           !PY^                       :YP5555555555555555555555PP5?~. .!J???J7  
           !^                          .JP555555555555555555555555PPY7: .!??~   
                                         7P55555555555555555555555555P5J!.      
                                          ~5P55555555555555555555555555PP5J~.   
                                           ^5P5555555555555555555555555P7.^7J^  
                                            .JP5555555555555555555555P5~        
                                              !Y5PPPPPPPPPPPPPPPPPP55?:  

*/

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./OwnerWithdrawable.sol";

contract Presale is OwnerWithdrawable, ReentrancyGuard{
    using SafeERC20 for IERC20Metadata;

    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public totalTokensforSale;
    uint256 public rate;
    uint256 public vestingBeginTime;
    uint256 public totalTokensSold;
    uint256 public totalTokensAlloc;
    uint256 public saleTokenDec;

    address public immutable saleToken;

    //vestingPercent: Vesting percent for the allocated tokens in a round
    //lockingPeriod: locking period for the allocated tokens in a round
    struct VestingDetails{
        uint256 vestingPercent;
        uint256 lockingPeriod;
    }

    uint256 public currentRound = 1000;

    mapping (uint256 => VestingDetails) public roundDetails;

    //totalAmount: total tokens allocated in all the rounds
    //array storing the rounds participated by a user
    //Rounds::  0: PS1, 1: PS2, 2:INNOVATION, 3: TEAM, 4:MARKETING, 5: SEED
    //tokensPerRound: mapping to store the tokens allocated to the user in the specific round
    //monthlyVestingClaimed: stores the latest month when a user withdrew tokens in the specific round
    //tokensClaimed: stores the number of tokens claimed by the user in the specific round
    struct BuyerTokenDetails {
        uint256 totalAmount;
        uint256 []roundsParticipated;
        mapping(uint256 => uint256)tokensPerRound;
        mapping(uint256 => uint256)monthlyVestingClaimed;
        mapping(uint256 => uint256)tokensClaimed;
    }

    mapping(address => BuyerTokenDetails) public buyersAmount;

    constructor(address _saleTokenAddress, uint256[] memory _roundID, uint256[] memory _vestingPercent, uint256[] memory _lockingPeriod) ReentrancyGuard(){
        require(_saleTokenAddress != address(0), "Presale: Invalid Address");
        saleToken = _saleTokenAddress;
        saleTokenDec = IERC20Metadata(saleToken).decimals();
        setRoundDetails(_roundID, _vestingPercent, _lockingPeriod);
    }

    modifier saleStarted(){
    if(preSaleStartTime != 0){
        require(block.timestamp < preSaleStartTime || block.timestamp > preSaleEndTime, "PreSale: Sale has already started!");
    }
        _;
    }

    /// @dev modifier to check if the sale is active or not
    modifier saleDuration(){
        require(block.timestamp > preSaleStartTime, "Presale: Sale hasn't started");
        require(block.timestamp < preSaleEndTime, "PreSale: Sale has already ended");
        _;
    }

    /// @dev modifier to check if the Sale Duration and Locking periods are valid or not
    modifier saleValid(
    uint256 _preSaleStartTime, uint256 _preSaleEndTime
    ){
        require(block.timestamp < _preSaleStartTime, "PreSale: Invalid PreSale Date!");
        require(_preSaleStartTime < _preSaleEndTime, "PreSale: Invalid PreSale Dates!");
        _;
    }

    /// @notice Set round details like vesting percent per month, and locking period for different rounds. 
    /// @dev    Rounds::  0: PS1, 1: PS2, 2:INNOVATION, 3: TEAM, 4:MARKETING, 5: SEED
    /// @dev    Function is called in the constructor
    /// @param _roundID Array of Round ID's
    /// @param _vestingPercent Array of vesting percentage per month for the specific round
    /// @param _lockingPeriod Array of locking period's for each round
    function setRoundDetails(uint256[] memory _roundID, uint256[] memory _vestingPercent, uint256[] memory _lockingPeriod) internal {
        require(_roundID.length == _vestingPercent.length, "Redux: Length mismatch");
        require(_lockingPeriod.length == _vestingPercent.length, "Redux: Length mismatch");
        uint256 length = _roundID.length;
        // VestingDetails storage vestingInfo = 
        for(uint256 i = 0; i < length; i++){
            roundDetails[_roundID[i]] = VestingDetails(_vestingPercent[i], _lockingPeriod[i]);
        }
    }

    /// @notice Set sale token params when initializing a new round. Will not work if sale is already active.
    /// @dev    Can be called only twice for the two presale round requirements. Owner needs to approve presale contract to handle said number of tokens
    /// @param _totalTokensforSale The total tokens for sale in wei
    /// @param _rate The rate of each token in USD 
    /// @param _roundID The id for the specific presale round 
    function setSaleTokenParams(uint256 _totalTokensforSale, uint256 _rate, uint256 _roundID) external onlyOwner saleStarted {
        require(_rate != 0, "PreSale: Invalid Native Currency rate!");
        require(_roundID < 2, "Redux Presale: Round ID should be 0 or 1");
        currentRound = _roundID;
        rate = _rate;
        totalTokensforSale = _totalTokensforSale;
        totalTokensSold = 0;
        IERC20Metadata(saleToken).safeTransferFrom(msg.sender, address(this), totalTokensforSale);
    }

    /// @notice Set sale period for the ICO
    /// @dev    Cannot be called if sale is already active
    /// @param _preSaleStartTime Start time for the sale in unix format
    /// @param _preSaleEndTime End time for the sale in unix format
    function setSalePeriodParams(uint256 _preSaleStartTime, uint256 _preSaleEndTime) 
    external onlyOwner saleStarted saleValid(_preSaleStartTime, _preSaleEndTime){
        preSaleStartTime = _preSaleStartTime;
        preSaleEndTime = _preSaleEndTime;
    }

    /// @notice Call when vesting needs to start. Can be called only once
    /// @dev    Cannot be called if sale has not ended
    function setVestingPeriod() external onlyOwner{
        require(vestingBeginTime == 0, "Redux: Cannot set multiple times");
        require(preSaleEndTime !=0, "Redux: Sale not started");
        require(block.timestamp > preSaleEndTime, "Redux: Sale in progress");
        vestingBeginTime = block.timestamp;

    }

    /// @notice Calculate Redux token amount for said BNB amount
    /// @return Calculated Redux tokens in wei
    function getTokenAmount(uint256 amount) external view returns (uint256) {
        return amount*(10**saleTokenDec)/rate;
    }

    /// @notice Investor calls this to buy Redux tokens for BNB
    /// @param _isInnovation boolean to denote if this purchase falls under the innovation round
    function buyToken(bool _isInnovation) external payable saleDuration{
        uint256 saleTokenAmt;

        saleTokenAmt = (msg.value)*(10**saleTokenDec)/rate;
        require((totalTokensSold + saleTokenAmt) < totalTokensforSale, "PreSale: Total Token Sale Reached!");

        // Update Stats
        totalTokensSold += saleTokenAmt;
        BuyerTokenDetails storage buyerDetails = buyersAmount[msg.sender];        
        buyerDetails.totalAmount += saleTokenAmt;
        if(_isInnovation) {
          if(buyerDetails.tokensPerRound[2] == 0){
              buyerDetails.roundsParticipated.push(2);
              buyerDetails.monthlyVestingClaimed[2] = roundDetails[2].lockingPeriod-1;
          }
          buyerDetails.tokensPerRound[2] += saleTokenAmt;
        }
        else {
          if(buyerDetails.tokensPerRound[currentRound] == 0){
              buyerDetails.roundsParticipated.push(currentRound);
              buyerDetails.monthlyVestingClaimed[currentRound] = roundDetails[currentRound].lockingPeriod-1;

          }
          buyerDetails.tokensPerRound[currentRound] += saleTokenAmt;
        }
    }

    /// @notice Returns the amount of Redux tokens bought by an investor
    /// @param  _user The wallet address of the investor
    /// @return Redux tokens in wei
    function getTokensBought(address _user) external view returns(uint256) {
        return buyersAmount[_user].totalAmount;
    }

    /// @notice Returns the rounds that an investor has been a part of
    /// @param  _user The wallet address of the investor
    /// @return Array of round ID's
    function getRoundsParticipated(address _user) external view returns(uint256[] memory) {
        return buyersAmount[_user].roundsParticipated;
    }

    /// @notice Returns the amount of Redux tokens that an investor purchased in the specific round (denoted by roundID)
    /// @param  _user The wallet address of the investor
    /// @param  _roundID The specific Round ID
    /// @return Redux tokens in wei
    function getTokensPerRound(address _user, uint256 _roundID)external view returns(uint256){
        return buyersAmount[_user].tokensPerRound[_roundID];
    }

    /// @notice Returns the amount of Redux tokens that an investor has claimed from a specific round (denoted by roundID)
    /// @param  _user The wallet address of the investor
    /// @param  _roundID The specific Round ID
    /// @return Redux tokens in wei
    function getClaimedTokensPerRound(address _user, uint256 _roundID) external view returns(uint256) {
        return buyersAmount[_user].tokensClaimed[_roundID];
    }

    /// @notice Returns the number of month's vesting that has been claimed by a given investor for a given round (denoted by roundID)
    /// @param  _user The wallet address of the investor
    /// @param  _roundID The specific Round ID 
    /// @return Returns an integer (uint)
    function getMonthlyVestingClaimed(address _user, uint256 _roundID) external view returns(uint256) {
        return buyersAmount[_user].monthlyVestingClaimed[_roundID];
    }

    /// @notice Returns the total amount of Redux tokens that an investor has claimed so far from vesting. 
    /// @param  _user The wallet address of the investor
    /// @return Redux tokens in wei
    function getTotalClaimedTokens(address _user) external view returns(uint256) {
        uint256 tokensClaimed;

        for(uint256 i = 0; i<6; i++){
            tokensClaimed += buyersAmount[_user].tokensClaimed[i];
        }
        return tokensClaimed;
    }

    /// @notice Investor can call this to withdraw their share of tokens that are eligible fro withdrawal 
    /// @dev Modifier to take care of Reentrancy attacks is included
    function withdrawToken() external nonReentrant{
        uint256 tokensforWithdraw = getAllocation(msg.sender);
        address user = msg.sender;
        require(tokensforWithdraw > 0, "Redux Token Vesting: No $REDUX Tokens available for claim!");
        
        uint256 timeElapsed = (block.timestamp)-vestingBeginTime;
        uint256 boost;
        uint256 availableAllocation;
        uint256 availableTokens;

        uint256 round;
        uint256 tokenPerRound;
        BuyerTokenDetails storage buyerDetails = buyersAmount[user];        
        uint256 length = buyerDetails.roundsParticipated.length;
        for(uint256 i = 0; i < length; i++){
            round = buyerDetails.roundsParticipated[i];
            tokenPerRound = buyerDetails.tokensPerRound[round];

            if(timeElapsed/(30*24*60*60) >= roundDetails[round].lockingPeriod){

                boost = (timeElapsed/(30*24*60*60))-(buyerDetails.monthlyVestingClaimed[round]);
                availableAllocation = tokenPerRound*boost*(roundDetails[round].vestingPercent)/100;
                availableTokens = tokenPerRound-(buyerDetails.tokensClaimed[round]);
    
                buyerDetails.tokensClaimed[round] += availableAllocation > availableTokens ? availableTokens : availableAllocation;
                buyerDetails.monthlyVestingClaimed[round] = timeElapsed/(30*24*60*60);

            }
        }

        IERC20Metadata(saleToken).safeTransfer(msg.sender, tokensforWithdraw);

    }

    /// @notice Get investor's allocation that is available for withdrawal
    /// @param  user The wallet address of the investor
    /// @return Redux tokens in wei
    function getAllocation(address user) public view returns(uint256){

        require(vestingBeginTime != 0, "Redux: Vesting hasn't started for me");    

        uint256 timeElapsed = (block.timestamp)-vestingBeginTime;
        uint256 boost;
        uint256 availableAllocation;
        uint256 availableTokens;
        uint256 tokensAlloted;

        uint256 round;
        uint256 tokenPerRound;
        BuyerTokenDetails storage buyerDetails = buyersAmount[user];        
        
        for(uint256 i = 0; i < buyerDetails.roundsParticipated.length; i++){
            round = buyerDetails.roundsParticipated[i];
            tokenPerRound = buyerDetails.tokensPerRound[round];
            //check if lockingPeriod is inactive
            if(timeElapsed/(30*24*60*60) >= roundDetails[round].lockingPeriod){
                
                //boost: months available since last withdraw
                boost = (timeElapsed/(30*24*60*60))-(buyerDetails.monthlyVestingClaimed[round]);
                availableAllocation = tokenPerRound*boost*(roundDetails[round].vestingPercent)/100;
                availableTokens = tokenPerRound-(buyerDetails.tokensClaimed[round]);
                tokensAlloted += availableAllocation > availableTokens ? availableTokens : availableAllocation;

            }
        }
        return tokensAlloted;
    }

    /// @notice Owner can use this to externally set vesting for different investor's / wallets
    /// @param  _user Array of wallet addresses
    /// @param  _amount Array of amounts that need to be vested
    /// @param  _roundID Round ID in which the vesting falls
    function setExternalAllocation(address[] calldata _user, uint256[] calldata _amount, uint256 _roundID)external onlyOwner{

        uint256 totalTokens;
        require(_user.length == _amount.length, "Redux Token Vesting: user & amount arrays length mismatch");
        require(_roundID >2, "Redux: Id should be greater than 1");
        uint256 length = _user.length;
        for(uint256 i = 0; i < length; i+=1){
        BuyerTokenDetails storage buyerDetails = buyersAmount[_user[i]];        
            buyerDetails.totalAmount += _amount[i];
            if(buyerDetails.tokensPerRound[_roundID] == 0){
                buyerDetails.roundsParticipated.push(_roundID);
                buyerDetails.monthlyVestingClaimed[_roundID] = roundDetails[_roundID].lockingPeriod-1;
            }
            buyerDetails.tokensPerRound[_roundID] += _amount[i];
            totalTokens += _amount[i];
        }
        totalTokensAlloc += totalTokens;
        IERC20Metadata(saleToken).safeTransferFrom(msg.sender, address(this), totalTokens);
    }

    /// @notice Owner can use this to withdraw the leftover, unsold tokens from the ICO
    function withdrawUnsoldTokens() external saleStarted onlyOwner {
        uint256 tokens = IERC20Metadata(saleToken).balanceOf(address(this))-(totalTokensSold+totalTokensAlloc);
        IERC20Metadata(saleToken).safeTransfer(msg.sender, tokens);
    }

    /// @notice function to change the rate
    /// @param _rate The new rate 
    function changeRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }
}