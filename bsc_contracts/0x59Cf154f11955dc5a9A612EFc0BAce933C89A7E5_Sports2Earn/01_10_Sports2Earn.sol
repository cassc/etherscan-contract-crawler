//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

contract Sports2Earn is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using PRBMathUD60x18 for uint;

    IERC20Upgradeable public chipToken;

    // Banker start
    struct Gambling {
        uint[3] stakes;     // 0: aTeam 1:tie 2: bTeam
        uint aTeam;
        uint bTeam;
        uint startTime;
        uint bullseye;      // 0: aTeam 1:tie 2: bTeam
        bool isFinished;

        uint aTeamSpread;
        uint bTeamSpread;

        uint[3] odds;  // 0: aTeam 1:tie 2: bTeam

        uint maxPoolSize; //maximum pool size of one single gambling to control risk
    }

    struct League {
        string name;
        Gambling[] gamblings;
    }

    string[] teams;
    League[] leagues;

    // Investors bet
    struct Bet {
        uint leagueId;
        uint gamblingId;
        uint target;    // 0: aTeam 1:tie 2: bTeam
        uint stake;
        uint reward;
        bool isClaimed;
    }

    mapping(address => Bet[]) bets;

    //Referral ledger: Referrals -> (rewardsTotal, rewardsClaimed, parent, refereeCount) 
    struct Referral {
        uint rewardsTotal;
        uint rewardsClaimed; //how to restrict positive add only?
        address parent; //ADDRESS restrict only set once! Require parent == undef when update
        uint childenCount; 
    }

    mapping(address => Referral) referrals;


    uint decimals; //decimals = chipToken.decimals();
    // Winner Earnings Fee - only earnings apart, excluded principal
    uint earningsFeeBP;
    uint earningsFeeDP;
    uint referralRewardsFeeBP; //base point of the referral rewards for a parent could receive from each winning earning of its child. Setup in constructor, 150 means 150/10000=1.5%

    modifier onlyNotFinished(uint _leagueId, uint _gamblingId){
        require(leagues[_leagueId].gamblings[_gamblingId].isFinished == false, "This gambling has finished!");
        _;
    }

    function initialize(IERC20Upgradeable _chipToken, uint _earningsFeeBP, uint _referralRewardsFeeBP) initializer public {
        __Ownable_init();
        
        chipToken = _chipToken;
        earningsFeeBP = _earningsFeeBP;
        referralRewardsFeeBP = _referralRewardsFeeBP;

        earningsFeeDP = 10000;
    }

    function createLeague(string memory _name) external onlyOwner {
        leagues.push().name = _name;
    }

    function createTeam(string memory _name) external onlyOwner {
        teams.push(_name);
    }

    function setTeamName(uint _index, string calldata _name) external onlyOwner {
        teams[_index] = _name;
    }

    function setLeagueName(uint _index, string calldata _leagueName) external onlyOwner {
        leagues[_index].name = _leagueName;
    }

    function setStartTime(uint _leagueId, uint _gamblingId, uint _startTime) external onlyOwner onlyNotFinished(_leagueId, _gamblingId) {
        leagues[_leagueId].gamblings[_gamblingId].startTime = _startTime;
    }

    function setEarningsFeeBP(uint _earningsFeeBP) external onlyOwner {
        require(_earningsFeeBP < 10000, "setEarningsFeeBP: should be less than 10000!");
        earningsFeeBP = _earningsFeeBP;
    }

    function createGambling(uint _leagueId, uint _aTeam, uint _bTeam, uint _startTime, uint _aTeamSpread, uint _bTeamSpread, uint _aTeamOdds, uint _drawOdds, uint _bTeamOdds, uint _maxPoolSize) 
    external onlyOwner {
        require(_aTeamOdds >= 1*earningsFeeDP && _aTeamOdds <= 100*earningsFeeDP && _drawOdds >= 1*earningsFeeDP && _drawOdds <= 100*earningsFeeDP && _bTeamOdds >= 1*earningsFeeDP && _bTeamOdds <= 100*earningsFeeDP, "createGambling: Odds should be between 1 and 100!"); ///Odds no more than 10 to control risk///
        require(_maxPoolSize >= 10 && _maxPoolSize <= 4*1e18 , "createGambling: _maxPoolSize should be between 10 S2K and 4 BILLION S2K (ATTENTION: the decimal digits in this contract is 9)!");

        leagues[_leagueId].gamblings.push(Gambling({aTeam: _aTeam, bTeam: _bTeam, startTime: _startTime, bullseye: 99, stakes: [uint(0), 0, 0], isFinished: false, 
          aTeamSpread: _aTeamSpread, bTeamSpread: _bTeamSpread, 
          odds: [_aTeamOdds, _drawOdds, _bTeamOdds], 
          maxPoolSize: _maxPoolSize*1e18    //Add the 9 decimals here for future use of the maxPoolSize limit
        }));
    }

    function updateGambling(uint _leagueId, uint _gamblingId, uint _aTeam, uint _bTeam, uint _startTime, uint _aTeamSpread, uint _bTeamSpread, uint _aTeamOdds, uint _drawOdds, uint _bTeamOdds, uint _maxPoolSize) 
    external onlyOwner {
        require(_aTeamOdds >= 1*earningsFeeDP && _aTeamOdds <= 100*earningsFeeDP && _drawOdds >= 1*earningsFeeDP && _drawOdds <= 100*earningsFeeDP && _bTeamOdds >= 1*earningsFeeDP && _bTeamOdds <= 100*earningsFeeDP, "createGambling: Odds should be between 1 and 100!"); ///Odds no more than 10 to control risk///
        require(_maxPoolSize >= 10 && _maxPoolSize <= 4*1e18 , "createGambling: _maxPoolSize should be between 10 S2K and 4 BILLION S2K (ATTENTION: the decimal digits in this contract is 9)!");

        Gambling storage gambling = leagues[_leagueId].gamblings[_gamblingId];

        gambling.aTeam = _aTeam;        
        gambling.bTeam = _bTeam;
        gambling.startTime = _startTime;
        gambling.aTeamSpread = _aTeamSpread;
        gambling.bTeamSpread = _bTeamSpread;
        gambling.odds = [_aTeamOdds, _drawOdds, _bTeamOdds];
        gambling.maxPoolSize = _maxPoolSize*1e18;
    }

    function drawLottery(uint _leagueId, uint _gamblingId, uint _ballot) external onlyOwner onlyNotFinished(_leagueId, _gamblingId) {
        require(leagues[_leagueId].gamblings[_gamblingId].startTime < block.timestamp, "drawLottery: This gambling hasn't started yet!");
        require(_ballot == 0 || _ballot == 1 || _ballot == 2, "In drawLottery, Illegal!");

        leagues[_leagueId].gamblings[_gamblingId].bullseye = _ballot;
        leagues[_leagueId].gamblings[_gamblingId].isFinished = true;
    }

    function createBet(uint _leagueId, uint _gamblingId, uint _target, uint _stake, address _referParent) external onlyNotFinished(_leagueId, _gamblingId) { // _referParent DEFAULT VALUE SHOULD BE undef IN JAVASCRIPT IF NO REFERER
        require(leagues[_leagueId].gamblings[_gamblingId].startTime > block.timestamp, "createBet: This gambling has started!");
        require(_stake >= 10*1e18, "createBet: Minimum Bet $10 in 29 decimals!"); /////////NEED A BETTER WAY TO MULTIPLY THE UINT8 DECIMALS/////////
        require(_referParent != msg.sender, "createBet: You cannot invite yourself!");

        uint testTotalStake = _stake + leagues[_leagueId].gamblings[_gamblingId].stakes[0] + leagues[_leagueId].gamblings[_gamblingId].stakes[1] + leagues[_leagueId].gamblings[_gamblingId].stakes[2]; /////////USING 9 DECIMALS IN THIS CONTRACT/////////
        require(testTotalStake <= leagues[_leagueId].gamblings[_gamblingId].maxPoolSize, "createBet: This gambling reached the maxPoolSize!"); 

        Bet memory bet; 
        bet.leagueId = _leagueId;
        bet.gamblingId = _gamblingId;
        bet.target = _target;
        bet.stake = _stake;

        chipToken.safeTransferFrom(msg.sender, address(this), _stake);
        leagues[_leagueId].gamblings[_gamblingId].stakes[_target] += _stake;

        bets[msg.sender].push(bet);

        //CREAT Referral if parent not exist, and set parent only at the first time        
        if (referrals[msg.sender].parent == address(0x0)) {
            referrals[msg.sender].parent = _referParent;
            /* ////Each Get USD5 - DEACTIVATED////
            // referrals[msg.sender].rewardsTotal   += 5*1e18; //can set reward value into construct variable in future
            // referrals[_referParent].rewardsTotal += 5*1e18; 
            ////Each Get USD5 - DEACTIVATED//// */
            referrals[_referParent].childenCount ++ ;
        }
    }

    function claimBet(uint _leagueId, uint _gamblingId, uint _index) external {
        Gambling storage gambling = leagues[_leagueId].gamblings[_gamblingId];
        Bet storage bet = bets[msg.sender][_index];
        require(bet.target == gambling.bullseye && bet.leagueId == _leagueId && bet.gamblingId == _gamblingId && bet.isClaimed == false, "In claimBet, Illegal!");

        bet.isClaimed = true;
        (uint reward, uint fee) = _getPendingEarnings(gambling, bet);
        bet.reward = reward;
        
        chipToken.safeTransfer(msg.sender, bet.stake + bet.reward - fee);

        //AFTER A SUCCESSFUL CLAIM, THE PARENT OF THE USER WILL GET 1.5% OF THE WINNING REWARD, AS THE REFERRAL REWARD OF THE PARENT
        referrals[referrals[msg.sender].parent].rewardsTotal += reward.fromUint().mul(referralRewardsFeeBP.fromUint()).div(earningsFeeDP.fromUint()).toUint();
    }

    function claimRewards() external {   
        //require(); //MUST MAKE SURE ENOUGH MONEY IN THE CONTRACT
        //claim all remaining referral rewards of the msg.sender//
        chipToken.safeTransfer(msg.sender, referrals[msg.sender].rewardsTotal - referrals[msg.sender].rewardsClaimed);
        referrals[msg.sender].rewardsClaimed = referrals[msg.sender].rewardsTotal;
    }

    function setChipToken(IERC20Upgradeable _chipToken) external onlyOwner {
        chipToken = _chipToken;
    }

    // @param _index - the index of MyBets[]
    function getPendingEarnings(uint _leagueId, uint _gamblingId, uint _index) external view returns (uint, uint){
        Gambling storage gambling = leagues[_leagueId].gamblings[_gamblingId];
        Bet storage bet = bets[msg.sender][_index];
        require(bet.target == gambling.bullseye && bet.leagueId == _leagueId && bet.gamblingId == _gamblingId && bet.isClaimed == false, "In getPendingEarnings, Illegal!");

        return _getPendingEarnings(leagues[_leagueId].gamblings[_gamblingId], bets[msg.sender][_index]);
    }

    // @param _index - the index of MyBets[]
    function _getPendingEarnings(Gambling storage gambling, Bet storage bet) private view returns (uint, uint){
        uint reward = (bet.stake.fromUint()).mul(gambling.odds[bet.target].fromUint()).div(earningsFeeDP.fromUint()).toUint() - (bet.stake.fromUint()).toUint();
        uint fee = reward.fromUint().mul(earningsFeeBP.fromUint()).div(earningsFeeDP.fromUint()).toUint();
        return (reward, fee);
    }

    function getBets() external view returns (Bet[] memory) {
        return bets[msg.sender];
    }

    function getReferrals() external view returns (Referral memory) { /////////Get referrals struct of one specific msg.sender. Covers the functions of getPendingRewards
        return referrals[msg.sender];
    }

    function getTeams() external view returns (string[] memory) {
        return teams;
    }

    function getLeagues() external view returns (League[] memory) {
        return leagues;
    }

    function getLeague(uint _leagueId) external view returns (League memory) {
        return leagues[_leagueId];
    }
    
    function getGambling(uint _leagueId, uint _gamblingId) external view returns (Gambling memory) {
        Gambling storage gambling = leagues[_leagueId].gamblings[_gamblingId];

        return gambling;
    }

    function withdrawToken(uint _amount) external payable onlyOwner {
        chipToken.safeTransfer(owner(), _amount);
    }
}