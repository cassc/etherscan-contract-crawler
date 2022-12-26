// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {INewDefinaCard} from "./WorldCupPoolInterface.sol";

contract WorldCupPool is
    Initializable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bool public claimableActive;

    INewDefinaCard public definaCard;

    //prize pool currency address
    address public prizePoolTokenAddress;

    //credits payment currency
    address public creditPaymentCurrency;

    //Each Hero's owner
    mapping(uint256 => address) public nftOwnedBy;


    // Bet for group stage

    // Total number of Games
    uint256 public constant totalMatches = 64;

    // Initial credits for each address
    uint256 public constant initCredit = 500;

    // consume 100 credits for each bet
    uint256 public constant consumeCreditEachBet = 100;

    // the cost of buying credits
    uint256 public constant creditCost = 10**18; // 1 credit = 1 fina

    // All group match and final match betting addresses
    address[] public allMatchBettingAddresses;

    // Top 3 addresses
    address[3] public leaderboardUsers;

    // Is in leaderboard
    mapping(address => bool) public isInLeaderboard;

    // Total credit - top 3 addresses credit
    uint256 public totalWinCredits;

    // group match prize pool
    uint256 public prizePool;

    struct MatchInfo{
        uint256 countryHomeId; // countryHome
        uint256 countryAwayId; // countryAway
        uint256 betEndTime; // Bet end time
        uint256 result; // result (0,1,2,3)
    }
    mapping(uint256 => MatchInfo) public allMatches;

    struct MatchCountryInfo{
        string countryName;
        uint256[] heroId;
        uint256[] heroRarity;
    }
    mapping(uint256 => MatchCountryInfo) public allMatchCountries;

    struct UserBetInfo{
        uint256 credits; // general credits
        uint256 winCredits; // reward credits
        uint256[] tokenIdList;
        uint256[] tokenIdListFinal;
        mapping(uint256 => uint256[4]) bets;
        mapping(uint256 => uint256) betsClaimed;
        bool activated;
    }
    mapping(address => UserBetInfo) public userMatchBets; // user => BetInfo
    mapping(uint256 => uint256) public tokenClaimedCredits;


    //Each Hero reward ratio based on FIFA ranking
    mapping(uint256 => uint256) public heroRewardRatio; // heroId => rewardRatio

    //Each Hero reward ratio based on it's rarity (SS-X)
    mapping(uint256 => uint256) public heroRarityRewardRatio;

    //Ending time of final betting
    uint256 public finalRankingBetEndTime;

    //Each hero id represented country id
    mapping(uint256 => uint256) public finalMatchHeroToCountry; // heroId => countryId

    constructor() {}

    function initialize() external virtual initializer {
        __WorldCupPool_init();
    }

    function __WorldCupPool_init() internal {
        __Ownable_init();
        finalRankingBetEndTime = 1667833200;
    }

    modifier whenClaimableActive() {
        require(claimableActive, "Claimable state is not active");
        _;
    }

    modifier onlyEOA() {
        require(_msgSender() == tx.origin, "WorldCupPool: not eoa");
        _;
    }

    function setFinalMatchHeroToCountry(uint256[] calldata _heroId, uint256[] calldata _countryId) external onlyOwner {
        for (uint256 i = 0; i < _heroId.length; ++i) {
            finalMatchHeroToCountry[_heroId[i]] = _countryId[i];
        }
    }

//    function setFinalMatchCountryInfo(uint256[] calldata _countryId, string[] calldata _representCountryName) external onlyOwner {
//        // 2 countries will be repeated
//        for (uint256 i = 0; i < _countryId.length; ++i) {
//            finalMatchCountries[_countryId[i]] = _representCountryName[i];
//        }
//    }

    // this function is to set ranking results for top 16 teams
    function setRewardRatio(
        uint256[] calldata _worldCupRankingByHeroId,
        uint256[] calldata _rewardRatioTier,
        uint256[] calldata _heroRarityRewardRatio
    ) external onlyOwner {
        // set this to true allows user to claim their reward
        // and they can no longer stake any nft
        for(uint256 i = 0; i < _worldCupRankingByHeroId.length; ++i) {
            uint256 heroId = _worldCupRankingByHeroId[i];
            uint256 rewardRatio = _rewardRatioTier[i];
            heroRewardRatio[heroId] = rewardRatio;
        }
        // set hero rarity ratio
        for(uint256 i = 0; i < _heroRarityRewardRatio.length; ++i){
            heroRarityRewardRatio[i+5]=_heroRarityRewardRatio[i];
        }
    }

    function betFinalMatch(uint256[] calldata _tokenIds) external onlyEOA {
        require(block.timestamp < finalRankingBetEndTime , "World cup final ranking betting has ended");

        UserBetInfo storage userBet = userMatchBets[_msgSender()];
        if(!userBet.activated){
            userBet.credits = initCredit;
            userBet.activated = true;
            allMatchBettingAddresses.push(_msgSender());
        }
        uint256 consumeCredits = consumeCreditEachBet * _tokenIds.length;
        require(
            userBet.credits + userBet.winCredits >= consumeCredits,
            "Insufficient user credits"
        );

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            uint256 heroId = definaCard.heroIdMap(_tokenIds[i]);
            uint256 rarity = definaCard.rarityMap(_tokenIds[i]);
            require(
                (finalMatchHeroToCountry[heroId]!=0)&&(rarity>=5),
                "This hero cannot be used for final match bet"
            );
            definaCard.safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
            nftOwnedBy[_tokenIds[i]] = _msgSender();
            userBet.tokenIdListFinal.push(_tokenIds[i]);
        }

        // deduct credits (100 per bet)
        if(userBet.credits < consumeCredits){
            totalWinCredits -= (consumeCredits - userBet.credits);
            userBet.winCredits -= (consumeCredits - userBet.credits);
            userBet.credits = 0;
        }else{
            userBet.credits -= consumeCredits;
        }
    }

    function setInitContract(
        address definaCardAddress,
        address _creditPaymentCurrency,
        address prizePoolTokenAddress_
    ) external onlyOwner {
        definaCard = INewDefinaCard(definaCardAddress);
        creditPaymentCurrency = _creditPaymentCurrency;
        prizePoolTokenAddress = prizePoolTokenAddress_;
    }

    function setMatchInfo(
        uint256[] calldata _matchId,
        uint256[] calldata _countryHomeId,
        uint256[] calldata _countryAwayId,
        uint256[] calldata _betEndTime
    ) external onlyOwner {
        for (uint256 i = 0; i < _matchId.length; ++i) {
            MatchInfo storage allMatch = allMatches[_matchId[i]];
            allMatch.countryHomeId = _countryHomeId[i];
            allMatch.countryAwayId = _countryAwayId[i];
            allMatch.betEndTime = _betEndTime[i];
            allMatch.result = 0;
        }
    }

    function setMatchResult(
        uint256[] calldata _matchId,
        uint256[] calldata _result
    ) external onlyOwner {
        for (uint256 i = 0; i < _matchId.length; ++i) {
            MatchInfo storage allMatch = allMatches[_matchId[i]];
            require(block.timestamp > allMatch.betEndTime + 90 * 60, "Match is not ended");
            allMatch.result = _result[i];
        }
    }

    function setMatchCountryInfo(
        uint256[] calldata _countryId,
        string[] calldata _representCountryName,
        uint256[] calldata _heroId,
        uint256[] calldata _heroRarity
    ) external onlyOwner {
        // 6 countries will be repeated
        require(_heroId.length == 38, "Country list length should be equal to 38!");
        for (uint256 i = 0; i < _heroId.length; ++i) {
            MatchCountryInfo storage matchCountry = allMatchCountries[_countryId[i]];
            matchCountry.countryName = _representCountryName[i];
            matchCountry.heroId.push(_heroId[i]);
            matchCountry.heroRarity.push(_heroRarity[i]);
        }
    }

    function setFinalRankingBetEndTime(uint256 _finalRankingBetEndTime) external onlyOwner{
        finalRankingBetEndTime = _finalRankingBetEndTime;
    }

    function resetMatchCountries() external onlyOwner {
        for (uint256 i = 1; i <= 38; ++i) {
            MatchCountryInfo storage matchCountry = allMatchCountries[i];
            delete matchCountry.countryName;
            delete matchCountry.heroId;
            delete matchCountry.heroRarity;
        }
    }

    function getCountryHeroes(uint256 _countryId) public view returns(uint256[] memory, uint256[] memory){
        MatchCountryInfo storage matchCountry = allMatchCountries[_countryId];
        uint256[] storage heroIdList = matchCountry.heroId;
        uint256[] storage heroRarityList = matchCountry.heroRarity;
        return (heroIdList, heroRarityList);
    }

    function getAllMatchResults() public view returns(uint256[64] memory){
        uint256[64] memory allMatchResults;
        for (uint256 i = 0; i < 64; ++i) {
            MatchInfo storage matchInfo = allMatches[i+1];
            allMatchResults[i] = matchInfo.result;
        }
        return allMatchResults;
    }
    function getUserBetTokenList(address user, bool isFinal) public view returns(uint256[] memory){
        UserBetInfo storage userBet = userMatchBets[user];
        if(isFinal) return userBet.tokenIdListFinal;
        return userBet.tokenIdList;
    }
    function getUserBetsByMatchId(address user, uint256 matchId) public view returns(uint256[4] memory){
        UserBetInfo storage userBet = userMatchBets[user];
        uint256[4] memory bets = userBet.bets[matchId];
        return bets;
    }
    function getUserBetsAll(address user) public view returns(uint256[4][64] memory){
        uint256[4][64] memory allBets;
        uint256[4] memory bets;
        for(uint256 _matchId=1; _matchId<=64; ++_matchId){
            UserBetInfo storage userBet = userMatchBets[user];
            bets = userBet.bets[_matchId];
            allBets[_matchId-1] = bets;
        }
        return allBets;
    }
    function getUserBetsAllClaimed(address user) public view returns(uint256[64] memory){
        uint256[64] memory betsClaimed;
        for(uint256 _matchId=1; _matchId<=64; ++_matchId){
            UserBetInfo storage userBet = userMatchBets[user];
            betsClaimed[_matchId-1] = userBet.betsClaimed[_matchId];
        }
        return betsClaimed;
    }

    function betByMatchId(
        uint256[] calldata _tokenIds,
        uint256[] calldata _matchIds,
        uint256[] calldata _isDraw)
    external onlyEOA {
        UserBetInfo storage userBet = userMatchBets[_msgSender()];
        if(!userBet.activated){
            userBet.credits = initCredit;
            userBet.activated = true;
            allMatchBettingAddresses.push(_msgSender());
        }
        uint256 consumeCredits = consumeCreditEachBet * _tokenIds.length;
        require(userBet.credits + userBet.winCredits >= consumeCredits, "Insufficient user credits");
        for (uint256 i = 0; i < _tokenIds.length; ++i) {

            bool betHomeCountry = _betByMatchId(_tokenIds[i], _matchIds[i]);
            // Home vs Away
            // betResults: 0=> none; 1=>HomeWin, 2=>AwayWin, 3=>Draw
            uint256[4] storage bet = userBet.bets[_matchIds[i]];
            if(_matchIds[i]>48){
                require(_isDraw[i]==0, "Final match cannot be draw");
            }
            if(_isDraw[i]==1){
                ++bet[3];
            }else if(betHomeCountry){
                ++bet[1];
            }else{
                ++bet[2];
            }
            nftOwnedBy[_tokenIds[i]] = _msgSender();

            // transfer card to contract address
            definaCard.safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
            userBet.tokenIdList.push(_tokenIds[i]);
        }

        // deduct credits (100 per bet)
        if(userBet.credits < consumeCredits){
            totalWinCredits -= (consumeCredits - userBet.credits);
            userBet.winCredits -= (consumeCredits - userBet.credits);
            userBet.credits = 0;
        }else{
            userBet.credits -= consumeCredits;
        }
    }

    function _betByMatchId(uint256 _tokenId, uint256 _matchId) private view returns (bool){
        uint256 heroId = definaCard.heroIdMap(_tokenId); // 下注的 heroId
        uint256 rarity = definaCard.rarityMap(_tokenId); // 下注的 rarity

        MatchInfo storage matchInfo = allMatches[_matchId];
        require(block.timestamp < matchInfo.betEndTime, "This Match bet is ended");
        MatchCountryInfo storage country1 = allMatchCountries[matchInfo.countryHomeId];
        uint256[] storage matchHeroId1 = country1.heroId;
        uint256[] storage matchHeroRarity1 = country1.heroRarity; // 获得本场比赛的HomeCountry 的 heroId 和 rarity

        MatchCountryInfo storage country2 = allMatchCountries[matchInfo.countryAwayId];
        uint256[] storage matchHeroId2 = country2.heroId;
        uint256[] storage matchHeroRarity2 = country2.heroRarity; // 获得本场比赛的AwayCountry 的 heroId 和 rarity

        bool betHomeCountry;
        bool betAwayCountry;
        if(matchHeroId1.length == 1){
            betHomeCountry = (heroId==matchHeroId1[0] && rarity==matchHeroRarity1[0]);
        }else{
            betHomeCountry = (heroId==matchHeroId1[0] && rarity==matchHeroRarity1[0]) || (heroId==matchHeroId1[1] && rarity==matchHeroRarity1[1]);
        }
        if(matchHeroId2.length == 1){
            betAwayCountry = (heroId==matchHeroId2[0] && rarity==matchHeroRarity2[0]);
        }else{
            betAwayCountry = (heroId==matchHeroId2[0] && rarity==matchHeroRarity2[0]) || (heroId==matchHeroId2[1] && rarity==matchHeroRarity2[1]);
        }

        require(betHomeCountry || betAwayCountry, "The betting hero is not in the match");
        return betHomeCountry;
    }

    // backend calculation
    function getMatchBettingAddresses() public view returns(address[] memory){
        return allMatchBettingAddresses;
    }

    function setLeaderboard(
        address[3] calldata _leaderboard,
        uint256 _prizePool) external onlyOwner{

        for(uint i=0; i<3; ++i){
            isInLeaderboard[_leaderboard[i]] = true;
        }
        leaderboardUsers = _leaderboard;
//        totalWinCredits -= _leaderboardTotalCredits;
        prizePool = _prizePool;
    }

    function getUserUnclaimedCredits(address user) public view returns(uint256){
        uint256 unClaimedCredits;
        UserBetInfo storage userBet = userMatchBets[user];
        for(uint256 _matchId=1; _matchId<=totalMatches; ++_matchId) {
            MatchInfo storage allMatch = allMatches[_matchId];
            if(userBet.betsClaimed[_matchId] == 0){
                unClaimedCredits += userBet.bets[_matchId][allMatch.result] * consumeCreditEachBet * 2;
            }
        }
        if(heroRarityRewardRatio[9] != 0){
            uint256[] memory _tokenIds = userBet.tokenIdListFinal;
            for (uint256 i = 0; i < _tokenIds.length; ++i) {
                if(tokenClaimedCredits[_tokenIds[i]] == 0){
                    uint256 rarity = definaCard.rarityMap(_tokenIds[i]);
                    uint256 heroId = definaCard.heroIdMap(_tokenIds[i]);
                    unClaimedCredits += consumeCreditEachBet * heroRewardRatio[heroId] * heroRarityRewardRatio[rarity];
                }
            }
        }
        return unClaimedCredits;
    }

    function claimMatchBetCreditsAll() public onlyEOA {
        for(uint _matchId=1; _matchId<=totalMatches; ++_matchId) {
            claimBetCreditsByMatchId(_matchId);
        }
        if(heroRarityRewardRatio[9] != 0){
            claimFinalMatchBetCredits();
        }
    }

    function claimBetCreditsByMatchId(uint256 _matchId) public onlyEOA {
        require(!claimableActive, "Credits not claimable");
//        require(allMatches[_matchId].result != 0, "Match Result is not revealed");
        if(allMatches[_matchId].result != 0){
            UserBetInfo storage userBet = userMatchBets[_msgSender()];
            if(userBet.betsClaimed[_matchId] == 0){
                uint256 credits = userBet.bets[_matchId][allMatches[_matchId].result] * consumeCreditEachBet * 2;
                userBet.winCredits += credits;
                totalWinCredits += credits;
                userBet.betsClaimed[_matchId] = credits;
            }
        }
    }

    function claimFinalMatchBetCredits() public onlyEOA {
        UserBetInfo storage userBet = userMatchBets[_msgSender()];
        uint256[] memory _tokenIds = userBet.tokenIdListFinal;
        claimFinalMatchBetCreditsByTokenIds(_tokenIds);
    }

    function claimFinalMatchBetCreditsByTokenIds(uint256[] memory _tokenIds) public onlyEOA {
        require(!claimableActive, "Credits not claimable");
        UserBetInfo storage userBet = userMatchBets[_msgSender()];
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            require(nftOwnedBy[_tokenIds[i]]==_msgSender(), "NFT is not owned by sender");
            if(tokenClaimedCredits[_tokenIds[i]] == 0){
                uint256 rarity = definaCard.rarityMap(_tokenIds[i]);
                uint256 heroId = definaCard.heroIdMap(_tokenIds[i]);
                uint256 credits = consumeCreditEachBet * heroRewardRatio[heroId] * heroRarityRewardRatio[rarity];
                userBet.winCredits += credits;
                totalWinCredits += credits;
                tokenClaimedCredits[_tokenIds[i]] = credits;
            }
        }
    }

    function getFinalMatchBetCreditsByTokenIds(uint256[] memory _tokenIds) public view returns(uint256) {
        uint256 credits;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            if(tokenClaimedCredits[_tokenIds[i]] == 0){
                uint256 rarity = definaCard.rarityMap(_tokenIds[i]);
                uint256 heroId = definaCard.heroIdMap(_tokenIds[i]);
                credits += consumeCreditEachBet * heroRewardRatio[heroId] * heroRarityRewardRatio[rarity];
            }
        }
        return credits;
    }

    function claimMatchBetReward() external whenClaimableActive onlyEOA {
//        claimMatchBetCreditsAll();
        UserBetInfo storage userBet = userMatchBets[_msgSender()];

        for (uint256 i = 0; i < userBet.tokenIdList.length; ++i) {
            uint tokenId = userBet.tokenIdList[i];
            require(_msgSender() == nftOwnedBy[tokenId], "_msgSender() is not the owner");
            // transfer hero back to user
            definaCard.safeTransferFrom(address(this), _msgSender(), tokenId);
        }
        for (uint256 i = 0; i < userBet.tokenIdListFinal.length; ++i) {
            uint tokenId = userBet.tokenIdListFinal[i];
            require(_msgSender() == nftOwnedBy[tokenId], "_msgSender() is not the owner");
            // transfer hero back to user
            definaCard.safeTransferFrom(address(this), _msgSender(), tokenId);
        }
        uint256 userPrize;
        if(isInLeaderboard[_msgSender()]){
            if(_msgSender()==leaderboardUsers[0]){
                userPrize = prizePool * 12 / 100;
            }else if(_msgSender()==leaderboardUsers[1]){
                userPrize = prizePool * 5 / 100;
            }else{
                userPrize = prizePool * 3 / 100;
            }
        }
        userPrize += prizePool / 2 * userBet.winCredits / totalWinCredits;

        if (prizePoolTokenAddress == address(0)) {
            payable(_msgSender()).transfer(userPrize);
        } else {
            IERC20 token = IERC20(prizePoolTokenAddress);
            token.transfer(_msgSender(), userPrize);
        }
    }

    function setClaimableActive(bool isActive) external onlyOwner{
        claimableActive = isActive;
    }

    function buyCredits(uint256 amount) external onlyEOA {
        IERC20Upgradeable token = IERC20Upgradeable(creditPaymentCurrency);
        token.safeTransferFrom(_msgSender(), address(this), amount * creditCost);
        UserBetInfo storage userBet = userMatchBets[_msgSender()];
        if(!userBet.activated){
            userBet.credits = initCredit;
            userBet.activated = true;
            allMatchBettingAddresses.push(_msgSender());
        }
        userBet.credits += amount;
    }

    function pullFunds(address tokenAddress_) external onlyOwner {
        if (tokenAddress_ == address(0)) {
            payable(_msgSender()).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(tokenAddress_);
            token.transfer(_msgSender(), token.balanceOf(address(this)));
        }
    }

    function topUpPrizePool() external payable{}

}