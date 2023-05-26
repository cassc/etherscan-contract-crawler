// // SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "hardhat/console.sol";

import "./LaunchPadLib.sol";

contract Presale {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private whiteListedUsers;

    address immutable public master;
    uint8 public salesFeeInPercent;
    IUniswapV2Router02 public uniswapV2Router02;
    
    LaunchPadLib.TokenInfo public tokenInfo;
    LaunchPadLib.PresaleInfo public presaleInfo;

    LaunchPadLib.ParticipationCriteria public participationCriteria;
    LaunchPadLib.PresaleTimes public presaleTimes;

    LaunchPadLib.PresalectCounts public presaleCounts;
    LaunchPadLib.GeneralInfo public generalInfo;

    LaunchPadLib.ContributorsVesting public contributorsVesting;
    LaunchPadLib.TeamVesting public teamVesting;

    mapping(address => Participant) public participant;
    struct Participant {
        uint256 value;
        uint256 tokens;
        uint256 unclaimed;
    }


    mapping (uint => ContributorsVestingRecord) public contributorVestingRecord;
    uint public contributorCycles = 0;
    uint public finalizingTime;

    enum ReleaseStatus {UNRELEASED,RELEASED}
    mapping(uint => mapping(address => ReleaseStatus)) internal releaseStatus;
    struct ContributorsVestingRecord {
        uint cycle;
        uint releaseTime;
        uint tokensPC;
        uint percentageToRelease;
    }

    mapping (uint => TeamVestingRecord) public teamVestingRecord;
    uint public temaVestingCycles = 0;
    struct TeamVestingRecord {
        uint cycle;
        uint releaseTime;
        uint tokensPC;
        uint percentageToRelease;
        ReleaseStatus releaseStatus;
    }

    event ContributionsAdded(address contributor, uint amount, uint requestedTokens);
    event ContributionsRemoved(address contributor, uint amount);
    event Claimed(address contributor, uint value, uint tokens);
    event Finalized(uint8 status, uint finalizedTime);
    event SaleTypeChanged(uint8 _type, address _address, uint minimumTokens);

    modifier isPresaleActive() {
        require (block.timestamp >= presaleTimes.startedAt && block.timestamp < presaleTimes.expiredAt, "Presale is not active");
        if(presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.PENDING){
            presaleInfo.preSaleStatus = LaunchPadLib.PreSaleStatus.INPROGRESS;
            emit Finalized(uint8(LaunchPadLib.PreSaleStatus.INPROGRESS), 0);

        }
        require(presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.INPROGRESS, "Presale is not in progress");
        _;
    }

    modifier onlyPresaleOwner() {
        require(presaleInfo.presaleOwner == msg.sender, "Ownable: caller is not the owner of this presale");
        _;
    }

    modifier isPresaleEnded(){
        require (
            presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.SUCCEED || 
            presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.FAILED || 
            presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.CANCELED, 
            "Presale is not concluded yet"
        );
        _;
    }

    modifier isPresaleNotEnded() {
        require(
            presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.INPROGRESS || 
            presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.PENDING, 
            "Presale is not in progress"
        );
        _;
    }

    constructor (
        LaunchPadLib.TokenInfo memory _tokenInfo,
        LaunchPadLib.PresaleInfo memory _presaleInfo,
        LaunchPadLib.ParticipationCriteria memory _participationCriteria,
        LaunchPadLib.PresaleTimes memory _presaleTimes,
        LaunchPadLib.ContributorsVesting memory _contributorsVesting,
        LaunchPadLib.TeamVesting memory _teamVesting,
        LaunchPadLib.GeneralInfo memory _generalInfo,
        uint8 _salesFeeInPercent,
        address _uniswapV2Router02
    ){
        master = msg.sender;
        
        tokenInfo = _tokenInfo;
        presaleInfo = _presaleInfo;
        participationCriteria = _participationCriteria;
        
        presaleTimes = _presaleTimes;
        contributorsVesting = _contributorsVesting;
        
        teamVesting = _teamVesting;
        generalInfo = _generalInfo;

        salesFeeInPercent = _salesFeeInPercent;
        uniswapV2Router02 = IUniswapV2Router02(_uniswapV2Router02);

        if(_contributorsVesting.isEnabled){
            findContributorsVesting(_contributorsVesting);
        }

        if(_teamVesting.isEnabled){
            findTeamVesting(_teamVesting);
        }
    }

    function findContributorsVesting(LaunchPadLib.ContributorsVesting memory _contributorsVesting) internal {
            uint totalTokensPC = 100;
            uint initialReleasePC = _contributorsVesting.firstReleasePC;
            contributorVestingRecord[0] = ContributorsVestingRecord(
                0, 
                0, 
                totalTokensPC, 
                initialReleasePC
            );

            if(initialReleasePC < totalTokensPC){

                uint remaingTokenPC = totalTokensPC - initialReleasePC;
                contributorCycles = totalTokensPC / _contributorsVesting.eachCyclePC;
                uint assignedTokensPC;

                for(uint i = 1; i <= contributorCycles; i++ ){
                    uint cycleReleaseTime = _contributorsVesting.eachCycleDuration * ( i * 1 minutes );
                    contributorVestingRecord[i] = ContributorsVestingRecord(
                        i, 
                        cycleReleaseTime, 
                        remaingTokenPC, 
                        _contributorsVesting.eachCyclePC
                    );
                    assignedTokensPC += _contributorsVesting.eachCyclePC;
                }
                    // uint difference = totalTokensPC - assignedTokensPC;
                    contributorVestingRecord[contributorCycles].percentageToRelease += totalTokensPC - assignedTokensPC;
            }

    }

    function findTeamVesting(LaunchPadLib.TeamVesting memory _teamVesting) internal {
            
            uint totalLockedTokensPC = 100;
            uint initialReleasePC = _teamVesting.firstReleasePC;
            uint initialReleaseTime = _teamVesting.firstReleaseDelay * 1 minutes;
            teamVestingRecord[0] = TeamVestingRecord(
                0, 
                initialReleaseTime, 
                totalLockedTokensPC, 
                initialReleasePC,
                ReleaseStatus.UNRELEASED 
            );


            if(initialReleasePC < totalLockedTokensPC){
                uint remaingTokenPC = totalLockedTokensPC - initialReleasePC;
                temaVestingCycles = totalLockedTokensPC / _teamVesting.eachCyclePC;
                uint assignedTokensPC;

                for(uint i = 1; i <= temaVestingCycles; i++ ){

                    uint cycleReleaseTime = initialReleaseTime + _teamVesting.eachCycleDuration * ( i * 1 minutes );
                    teamVestingRecord[i] = TeamVestingRecord(
                        i, 
                        cycleReleaseTime, 
                        remaingTokenPC, 
                        _teamVesting.eachCyclePC,
                        ReleaseStatus.UNRELEASED
                    );
                    
                    assignedTokensPC += _teamVesting.eachCyclePC;
                }

                    // uint difference = totalLockedTokensPC - assignedTokensPC;
                    teamVestingRecord[temaVestingCycles].percentageToRelease += totalLockedTokensPC - assignedTokensPC;
            }
    }

    function contributeToSale() public payable isPresaleActive {

        uint allowed = participationCriteria.hardCap - presaleCounts.accumulatedBalance;

        Participant memory currentParticipant = participant[msg.sender];
        uint preveousContribution =  currentParticipant.value;
        uint contribution = msg.value;

        require(contribution <= allowed && contribution + preveousContribution <= participationCriteria.maxContribution , "contribution is not valid");

        if(currentParticipant.tokens == 0) {
            require(contribution >= (participationCriteria.minContribution), "too low contribution");
            presaleCounts.contributors++;
        }

        if(participationCriteria.presaleType == LaunchPadLib.PresaleType.WHITELISTED){
            require( isWhiteListed(msg.sender), "Only whitelisted users are allowed to participate");   
        }
        
        if(participationCriteria.presaleType == LaunchPadLib.PresaleType.TOKENHOLDERS){
            require(IERC20(participationCriteria.criteriaToken).balanceOf(msg.sender) >= participationCriteria.minCriteriaTokens, "You don't hold enough criteria tokens");
        }
        
        uint requestedTokens = (contribution * participationCriteria.presaleRate * 10**tokenInfo.decimals) / 1 ether;

        participant[msg.sender].tokens += requestedTokens;
        participant[msg.sender].unclaimed += requestedTokens;

        participant[msg.sender].value += contribution;
        presaleCounts.accumulatedBalance += contribution;

        emit ContributionsAdded(msg.sender, contribution, requestedTokens);

        
    }

    function emergencyWithdraw() public {

        require(presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.INPROGRESS, "Presale is not in progress");

        Participant memory currentParticipant = participant[msg.sender];
        require(currentParticipant.value > 0, "Nothing to withdraw");

        uint valueToReturn = (currentParticipant.value * 95) / 100;

        participant[msg.sender].value = 0;
        participant[msg.sender].tokens = 0;
        participant[msg.sender].unclaimed = 0;
        
        presaleCounts.accumulatedBalance -= currentParticipant.value;
        // presaleCounts.remainingTokensForSale = presaleCounts.remainingTokensForSale + currentParticipant.tokens;

        presaleCounts.contributors--;
        
        (bool res1,) = payable(msg.sender).call{value: valueToReturn}("");
        require(res1, "cannot refund to contributors"); 

        (bool res2,) = payable(master).call{value: currentParticipant.value - valueToReturn}("");
        require(res2, "cannot send devTeamShare"); 

        emit ContributionsRemoved(msg.sender, currentParticipant.value);

    }

    function finalizePresale() public onlyPresaleOwner isPresaleNotEnded {
        
        require (
            block.timestamp > presaleTimes.expiredAt ||
            presaleCounts.accumulatedBalance >= participationCriteria.hardCap,
            "Presale is not over yet"
        );
        
        
        if( presaleCounts.accumulatedBalance >= participationCriteria.softCap ){

            uint256 totalTokensSold = (presaleCounts.accumulatedBalance * participationCriteria.presaleRate * 10**tokenInfo.decimals) / 1 ether ;
            
            uint256 tokensToAddLiquidity = (totalTokensSold * participationCriteria.liquidity) / 100;
            
            uint256 revenueFromPresale = presaleCounts.accumulatedBalance;
            uint256 poolShareBNB = (revenueFromPresale * participationCriteria.liquidity) / 100;
            uint256 devTeamShareBNB = (revenueFromPresale * salesFeeInPercent) / 100;
            uint256 ownersShareBNB = revenueFromPresale - (poolShareBNB + devTeamShareBNB);

            (bool res1,) = payable(presaleInfo.presaleOwner).call{value: ownersShareBNB}("");
            require(res1, "cannot send devTeamShare"); 

            (bool res2,) = payable(master).call{value: devTeamShareBNB}("");
            require(res2, "cannot send devTeamShare"); 
            
            IERC20(tokenInfo.tokenAddress).approve(address(uniswapV2Router02), tokensToAddLiquidity);

            uniswapV2Router02.addLiquidityETH{value : poolShareBNB}(
                tokenInfo.tokenAddress,
                tokensToAddLiquidity,
                0,
                0,
                address(this),
                block.timestamp + 60
            );
               
                presaleInfo.preSaleStatus = LaunchPadLib.PreSaleStatus.SUCCEED;

                uint extraTokens = IERC20(tokenInfo.tokenAddress).balanceOf(address(this)) - totalTokensSold - teamVesting.vestingTokens*10**tokenInfo.decimals;
             
                withdrawExtraTokens(extraTokens);
                finalizingTime = block.timestamp;
                emit Finalized(uint8(LaunchPadLib.PreSaleStatus.SUCCEED), finalizingTime);

           
        }
        else {

            presaleInfo.preSaleStatus = LaunchPadLib.PreSaleStatus.FAILED;
            uint extraTokens = IERC20(tokenInfo.tokenAddress).balanceOf(address(this));
            
            withdrawExtraTokens(extraTokens);
            emit Finalized(uint8(LaunchPadLib.PreSaleStatus.FAILED), 0);

        }        
    }

    function withdrawExtraTokens(uint tokensToReturn) internal {

        if(tokensToReturn > 0){
            if(presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.FAILED || presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.CANCELED){
                bool tokenDistribution = IERC20(tokenInfo.tokenAddress).transfer(presaleInfo.presaleOwner, tokensToReturn);
                assert( tokenDistribution);
            }
            else if(participationCriteria.refundType == LaunchPadLib.RefundType.WITHDRAW ){
                bool tokenDistribution = IERC20(tokenInfo.tokenAddress).transfer(presaleInfo.presaleOwner, tokensToReturn);
                assert( tokenDistribution);
            }
            else{
                bool tokenDistribution = IERC20(tokenInfo.tokenAddress).transfer(0x000000000000000000000000000000000000dEaD , tokensToReturn);
                assert( tokenDistribution );
            }
        }

    }

    function claimTokensOrARefund() public isPresaleEnded {

        Participant memory _participant = participant[msg.sender];
        require(_participant.unclaimed > 0, "Nothing to claim");
 
        if (presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.SUCCEED) {

            if(!contributorsVesting.isEnabled){
                // participant[msg.sender].tokens = 0;
                // participant[msg.sender].value = 0;
                participant[msg.sender].unclaimed = 0;
                presaleCounts.claimsCount++;

                require(_participant.tokens > 0, "No tokens to claim");
                bool tokenDistribution = IERC20(tokenInfo.tokenAddress).transfer(msg.sender, _participant.tokens);
                require(tokenDistribution, "Unable to transfer tokens to the participant");

                emit Claimed(msg.sender, 0, _participant.tokens);

            }
            else {

                uint tokensLocked = _participant.tokens;
                uint tokensToRelease;

                for(uint i = 0; i<= contributorCycles; i++){
                    if(
                        block.timestamp >= (finalizingTime + contributorVestingRecord[i].releaseTime) && 
                        releaseStatus[finalizingTime + contributorVestingRecord[i].releaseTime][msg.sender] == ReleaseStatus.UNRELEASED
                        ){
                        tokensToRelease += (tokensLocked * contributorVestingRecord[i].tokensPC * contributorVestingRecord[i].percentageToRelease) / 10000;
                        releaseStatus[finalizingTime + contributorVestingRecord[i].releaseTime][msg.sender] = ReleaseStatus.RELEASED;

                        if(i == contributorCycles) {
                            // participant[msg.sender].value = 0;
                            // participant[msg.sender].tokens = 0;
                            presaleCounts.claimsCount++;
                        }
                    }
                }

                require(tokensToRelease > 0, "Nothing to unlock");
                participant[msg.sender].unclaimed -= tokensToRelease;

                require(
                    IERC20(tokenInfo.tokenAddress).transfer(msg.sender, tokensToRelease),
                    "Unable to transfer presale tokens to the presale owner"
                    );


                emit Claimed(msg.sender, 0, tokensToRelease);

            }
        }
        else {
            participant[msg.sender].tokens = 0;
            participant[msg.sender].value = 0;
            participant[msg.sender].unclaimed = 0;

            presaleCounts.claimsCount++;

            require(_participant.value > 0, "No amount to refund");
            bool refund = payable(msg.sender).send(_participant.value);
            require(refund, "Unable to refund amount to the participant");

            emit Claimed(msg.sender, _participant.value, 0);

        }

    }

    function chageSaleType(LaunchPadLib.PresaleType _type, address _address, uint minimumTokens) public onlyPresaleOwner {
        if(_type == LaunchPadLib.PresaleType.TOKENHOLDERS) {
            participationCriteria.presaleType = _type;
            participationCriteria.criteriaToken = _address;
            participationCriteria.minCriteriaTokens = minimumTokens;
        }
        else {
            participationCriteria.presaleType = _type;
        }

        emit SaleTypeChanged(uint8(_type), _address, minimumTokens);

    }

    function unlockTokens() public onlyPresaleOwner isPresaleEnded {

        // require(teamVesting.isEnabled, "No tokens were locked");

        uint tokensLocked = teamVesting.vestingTokens * 10**tokenInfo.decimals;
        uint tokensToRelease;

        for(uint i = 0; i<= temaVestingCycles; i++){            
            if(block.timestamp >= finalizingTime + teamVestingRecord[i].releaseTime && teamVestingRecord[i].releaseStatus == ReleaseStatus.UNRELEASED){
                    tokensToRelease += (tokensLocked * teamVestingRecord[i].tokensPC * teamVestingRecord[i].percentageToRelease) / 10000;
                    teamVestingRecord[i].releaseStatus = ReleaseStatus.RELEASED;
            }
        }

        require(tokensToRelease > 0, "Nothing to unlock");
        IERC20(tokenInfo.tokenAddress).transfer(msg.sender, tokensToRelease);

        // require(
        //     IERC20(tokenInfo.tokenAddress).transfer(msg.sender, tokensToRelease),
        //     "Unable to transfer presale tokens to the presale owner"
        //     );

        // emit TokensUnLocked(tokensToRelease);

    }

    function unlockLPTokens() public onlyPresaleOwner isPresaleEnded {

        address factory = IUniswapV2Router02(uniswapV2Router02).factory();
        address WBNBAddr = IUniswapV2Router02(uniswapV2Router02).WETH();

        address pairAddress = IUniswapV2Factory(factory).getPair(tokenInfo.tokenAddress, WBNBAddr);
        uint availableLP = IERC20(pairAddress).balanceOf(address(this));

        require(availableLP > 0, "Nothing to claim");
        require(block.timestamp >= finalizingTime + presaleTimes.lpLockupDuration, "Not unlocked yet");
        
        IERC20(pairAddress).transfer(presaleInfo.presaleOwner, availableLP);
        // bool res = IERC20(pairAddress).transfer(presaleInfo.presaleOwner, availableLP);
        // require(res, "Unable to transfer presale tokens to the presale owner");

        // emit LPTokensUnLocked(availableLP);


    }

    function isWhiteListed(address user) view public returns (bool){
        return EnumerableSet.contains(whiteListedUsers, user);
    }

    function whiteListUsers(address[] memory _addresses) public onlyPresaleOwner {
        for(uint i=0; i < _addresses.length; i++){
                EnumerableSet.add(whiteListedUsers, _addresses[i]); 
        }
    }

    function removeWhiteListUsers(address[] memory _addresses) public onlyPresaleOwner {
        for(uint i=0; i < _addresses.length; i++){
            EnumerableSet.remove(whiteListedUsers, _addresses[i]); 
        }
    }

    function getWhiteListUsers() public view returns (address[] memory) {
        return EnumerableSet.values(whiteListedUsers);
    }

    function cancelSale() public onlyPresaleOwner isPresaleNotEnded {
        presaleInfo.preSaleStatus = LaunchPadLib.PreSaleStatus.CANCELED;
        uint extraTokens = IERC20(tokenInfo.tokenAddress).balanceOf(address(this));
        withdrawExtraTokens(extraTokens);
        emit Finalized(uint8(LaunchPadLib.PreSaleStatus.CANCELED), 0);
    }

    function getContributorReleaseStatus(uint _time, address _address) public view returns(ReleaseStatus){
        return releaseStatus[_time][_address];
    }

    function updateGeneralInfo(LaunchPadLib.GeneralInfo memory _generalInfo) public onlyPresaleOwner {
        generalInfo = _generalInfo;
    }

}