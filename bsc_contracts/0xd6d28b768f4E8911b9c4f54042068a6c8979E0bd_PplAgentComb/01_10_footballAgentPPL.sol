//SPDX-License-Identifier: Unlicense
    pragma solidity 0.8.4;

    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
    import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "hardhat/console.sol";



    contract PplAgentComb is Ownable {
        using SafeERC20 for IERC20;
        address public devAddress;
        uint256 public matchUpIndex = 0;
        uint256 public rewardInterest = 950;
        uint256 public devRewardInterest = 50;
        uint256 public agentRewardInterest1 = 10;
        uint256 public agentRewardInterest2 = 15;
        uint256 public agentRewardInterest3 = 20;
        uint256 public agentRewardInterest4 = 25;
        uint256 public agentRewardInterest5 = 30;
        uint256 public refundInterest = 999;
        uint256 public devRefundInterest = 1;
        address public tokenAddress;
        uint256 public totalFeesCharged;
        uint256 public totalRooms = 4;


        //Event
        event MatchUp(uint256 matchIndex, string stage, string team1, string team2, uint256 startTime, uint256 endTime);
        event PlaceGuess(address player, uint256 matchIndex, uint256 guessScore, uint256 guessAmount, uint256 level);
        event PlaceGuessAgent(address player, uint256 matchIndex, uint256 guessScore, uint256 guessAmount, address agent, uint256 level, uint256 room);
        event Claim(address player, uint256 matchIndex, uint256 level, string status, uint256 amount);
        event ClaimAgent(address player, uint256 matchIndex, address agent, string status, uint256 amount);
        event CreateAgentRoom(address agent, uint256 level, uint256 matchIndex);

        enum MatchStatus{DELAYED, ONGOING, COMPLETED, CANCELLED} 
        
        struct Guess{
            uint256 guessScore;
            uint256 guessAmount;
            bool hasUserGuessed;
        }

        struct Matchup{
            string stage;
            string team1;
            string team2;
            uint256 startTime;
            uint256 endTime;
            MatchStatus matchStatus;
        }

        struct Score{
            uint256 scoreTotal;
            bool hasGuessed;
        }

        struct User{
            uint256 personalMatchTotal;
            bool hasUserClaimed;
        }

        struct Agent{
            uint256 roomNum;
            uint256 level;
            bool hasCreated;
        }


        constructor(address _devAddress){
            devAddress = _devAddress;
            tokenAddress = 0x55d398326f99059fF775485246999027B3197955;
        }

        mapping(uint256=>uint256) public agentFeesCharged;
        mapping(uint256=>uint256) public resultList;
        mapping(address=>bool) public isAdmin;
        mapping(uint256=>Matchup) public matchUps;
        mapping(address=>mapping(uint256=>mapping(uint256=>Agent))) public agentInfo;
        mapping(uint256=>mapping(uint256=>uint256)) public matchTotalPool;
        mapping(uint256=>mapping(uint256=>mapping(uint256=>Score))) public scoreInfo;
        mapping(address=>mapping(uint256=>mapping(uint256=>User))) public userInfo;
        mapping(address=>mapping(uint256=>mapping(uint256=>mapping(uint256 =>Guess)))) public guessInfo;
        

        function createAgentRoom(address _agent, uint256 _level, uint256 _matchIndex) external {
            require(isAdmin[msg.sender], "unauthorized");
            require(_agent != address(0), "agent address cannot be zero address");
            require(_matchIndex < matchUpIndex,"invalid match");
            require(_level >= 1 && _level <= 5, "invalid level");
            require(!agentInfo[_agent][_level][_matchIndex].hasCreated, "room has already been created");

            agentInfo[_agent][_level][_matchIndex].hasCreated = true;
            agentInfo[_agent][_level][_matchIndex].roomNum = totalRooms;
            agentInfo[_agent][_level][_matchIndex].level = _level;
            totalRooms++;

            emit CreateAgentRoom(_agent, _level, _matchIndex);
        }

        function addAdmin(address _admin) external onlyOwner{
            require(!isAdmin[_admin],"admin existed");
            isAdmin[_admin] = true;
        }

        /* create match up
            condition
                * require admin to create the match up
            create and store new match up into the contract
        */
        function createMatchup(string memory _stage, string memory _team1, string memory _team2, uint256 _startTime, uint256 _endTime) external{
            require(isAdmin[msg.sender],"unauthorized!");
            Matchup storage matchUpStore = matchUps[matchUpIndex];
            matchUpStore.stage = _stage;
            matchUpStore.team1 = _team1;
            matchUpStore.team2 = _team2;
            matchUpStore.startTime = _startTime;
            matchUpStore.endTime = _endTime;
            matchUpStore.matchStatus = MatchStatus.ONGOING;
            matchUpIndex+=1;
            emit MatchUp(matchUpIndex - 1, _stage, _team1, _team2, _startTime, _endTime);
        }

        /* place match guess
            condition
                * require token is supported by the contract
                * require the match index is lower or equal than current match index
                * require the current timestamp is smaller than match end time
                * require the user current wallet balance have enough balance
                * require guess amount is bigger than 0 and fulfill the level cap (>=100e18 and <999e18)
            - create and store user guess for particular match up into the contract
            - update the current pool value for the match
            - update user had guessed the score for the match
            - update personal guess total for the match
        */


        //input zero address for public rooms
        function placeGuess(uint256 _matchUpIndex,uint256 _guessScore, uint256 _guessAmount, uint256 _level, address _agent) external {
            require(_matchUpIndex < matchUpIndex,"invalid match");
            require(block.timestamp < matchUps[_matchUpIndex].endTime, "Guessing phase has ended");
            require(IERC20(tokenAddress).balanceOf(msg.sender)>=_guessAmount,"insufficient wallet balance");
            require((_agent == address(0) && _level == 1 && _guessAmount>=(100e18) && _guessAmount<(999e18)) || 
                _agent == address(0) && (_level == 2 && _guessAmount>=(1000e18) && _guessAmount<(9999e18)) ||
                _agent == address(0) && (_level == 3 && _guessAmount>=(10000e18)) || 
                (agentInfo[_agent][_level][_matchUpIndex].level == 1 && _guessAmount>=(1000e18)) ||
                (agentInfo[_agent][_level][_matchUpIndex].level == 2 && _guessAmount>=(10000e18)) ||
                (agentInfo[_agent][_level][_matchUpIndex].level == 3 && _guessAmount>=(100000e18)) ||
                (agentInfo[_agent][_level][_matchUpIndex].level == 4 && _guessAmount>=(1000000e18)) ||
                (agentInfo[_agent][_level][_matchUpIndex].level == 5 && _guessAmount>=(10000000e18)),
                "invalid level, guessAmount, or agent");
            require(_agent == address(0) || agentInfo[_agent][_level][_matchUpIndex].hasCreated == true, "room was not created by admin");
            
            uint256 _room;
            if(_agent == address(0)){
                _room = _level;
            }
            else{
                _room = agentInfo[_agent][_level][_matchUpIndex].roomNum;
            }
            
            Guess storage guessStorage = guessInfo[msg.sender][_room][_matchUpIndex][_guessScore];
            guessStorage.guessScore = _guessScore;
            IERC20(tokenAddress).safeTransferFrom(msg.sender,address(this),_guessAmount);
            guessStorage.guessAmount += _guessAmount;
            scoreInfo[_room][_matchUpIndex][_guessScore].scoreTotal +=_guessAmount;
            userInfo[msg.sender][_room][_matchUpIndex].personalMatchTotal += _guessAmount;
            matchTotalPool[_room][_matchUpIndex] += _guessAmount;
            scoreInfo[_room][_matchUpIndex][_guessScore].hasGuessed = true;
            guessStorage.hasUserGuessed = true;
            if (_agent == address(0)){
                emit PlaceGuess(msg.sender, _matchUpIndex, _guessScore, _guessAmount, _level);
            } else {
                emit PlaceGuessAgent(msg.sender, _matchUpIndex, _guessScore, _guessAmount, _agent, _level, _room);
            }
            
        }

        /* update result
            condition
                * require admin to update the match up
                * require the match index is lower or equal than current match index
            - update result for the match
        */
        function updateResult(uint256 _matchUpIndex, uint256 _score) external{
            require(isAdmin[msg.sender],"unauthorzied");
            require(_matchUpIndex < matchUpIndex,"invalid match");
            resultList[_matchUpIndex] =_score;
            matchUps[_matchUpIndex].matchStatus = MatchStatus.COMPLETED;
        }

        function claim(uint256 _matchIndex, uint256 _level) external{
            require(matchUps[_matchIndex].matchStatus != MatchStatus.ONGOING, "Match is not completed");
            require(!userInfo[msg.sender][_level][_matchIndex].hasUserClaimed, "Amount has been claimed");
            require(_level == 1 || _level == 2 || _level == 3, "invalid level");
            MatchStatus matchStatus = matchUps[_matchIndex].matchStatus;
            uint256 resultScore = resultList[_matchIndex];
            uint256 devFee;
            uint256 claimAmount;
            string memory status;
            if (matchStatus == MatchStatus.DELAYED || matchStatus == MatchStatus.CANCELLED){
                claimAmount = (userInfo[msg.sender][_level][_matchIndex].personalMatchTotal * refundInterest) / 1000;
                IERC20(tokenAddress).safeTransfer(msg.sender, claimAmount);
                devFee = ((userInfo[msg.sender][_level][_matchIndex].personalMatchTotal * devRefundInterest ) / 1000);
                status = "CANCELLED";
            }
            else if ((!scoreInfo[_level][_matchIndex][resultScore].hasGuessed && matchStatus == MatchStatus.COMPLETED)){
                claimAmount = (userInfo[msg.sender][_level][_matchIndex].personalMatchTotal * rewardInterest) / 1000;
                IERC20(tokenAddress).safeTransfer(msg.sender, claimAmount);
                devFee = ((userInfo[msg.sender][_level][_matchIndex].personalMatchTotal * devRewardInterest ) / 1000);
                status = "TIE";
            }
            //check win condition, if there is someone who wins, scoreTotal will be > 0, no need to check for zero anymore
            else if (guessInfo[msg.sender][_level][_matchIndex][resultScore].hasUserGuessed && matchStatus == MatchStatus.COMPLETED) {
                Guess storage guessStorage = guessInfo[msg.sender][_level][_matchIndex][resultScore];
                claimAmount = (matchTotalPool[_level][_matchIndex] * rewardInterest *  guessStorage.guessAmount )/ (1000 * scoreInfo[_level][_matchIndex][resultScore].scoreTotal);
                IERC20(tokenAddress).safeTransfer(msg.sender, claimAmount);
                devFee = (matchTotalPool[_level][_matchIndex]* devRewardInterest *  guessStorage.guessAmount )/ (1000 * scoreInfo[_level][_matchIndex][resultScore].scoreTotal);
                status = "WIN";
            }
            else{
                return;
            }
            IERC20(tokenAddress).safeTransfer(devAddress, devFee);
            totalFeesCharged += devFee;
            userInfo[msg.sender][_level][_matchIndex].hasUserClaimed = true;

            emit Claim(msg.sender, _matchIndex, _level, status, claimAmount);
        }

        function claimAgent(uint256 _matchIndex, address _agent, uint256 _level) external{
            require(matchUps[_matchIndex].matchStatus != MatchStatus.ONGOING, "Match is not completed");
            uint256 _room = agentInfo[_agent][_level][_matchIndex].roomNum;
            require(!userInfo[msg.sender][_room][_matchIndex].hasUserClaimed, "Amount has been claimed");
            MatchStatus matchStatus = matchUps[_matchIndex].matchStatus;
            uint256 resultScore = resultList[_matchIndex];
            uint256 devFee;
            uint256 agentFee;
            uint256 agentRewardInterest;
            uint256 claimAmount;
            string memory status;
            if (_level == 1){
                agentRewardInterest = agentRewardInterest1;
            } 
            else if (_level == 2){
                agentRewardInterest = agentRewardInterest2;
            } 
            else if (_level == 3){
                agentRewardInterest = agentRewardInterest3;
            } 
            else if (_level == 4){
                agentRewardInterest = agentRewardInterest4;
            } 
            else {
                agentRewardInterest = agentRewardInterest5;
            }

            if (matchStatus == MatchStatus.DELAYED || matchStatus == MatchStatus.CANCELLED){
                claimAmount = (userInfo[msg.sender][_room][_matchIndex].personalMatchTotal * refundInterest) / 1000;
                IERC20(tokenAddress).safeTransfer(msg.sender, claimAmount);
                devFee = ((userInfo[msg.sender][_room][_matchIndex].personalMatchTotal * devRefundInterest ) / 1000);
                status = "CANCELLED";
            }

            else if (!scoreInfo[_room][_matchIndex][resultScore].hasGuessed && matchStatus == MatchStatus.COMPLETED){
                claimAmount = (userInfo[msg.sender][_room][_matchIndex].personalMatchTotal * rewardInterest) / 1000;
                IERC20(tokenAddress).safeTransfer(msg.sender, claimAmount);
                uint256 personalMatchTotal = userInfo[msg.sender][_room][_matchIndex].personalMatchTotal;
                agentFee = ((personalMatchTotal * agentRewardInterest ) / 1000);
                devFee = ((personalMatchTotal * (devRewardInterest - agentRewardInterest)) / 1000);
                status = "TIE";
            }
            //check win condition, if there is someone who wins, scoreTotal will be > 0, no need to check for zero anymore
            else if (guessInfo[msg.sender][_room][_matchIndex][resultScore].hasUserGuessed && matchStatus == MatchStatus.COMPLETED) {
                Guess storage guessStorage = guessInfo[msg.sender][_room][_matchIndex][resultScore];
                uint256 scoreTotal = scoreInfo[_room][_matchIndex][resultScore].scoreTotal;
                uint256 totalPool =  matchTotalPool[_room][_matchIndex];
                claimAmount = (totalPool * rewardInterest *  guessStorage.guessAmount )/ (1000 * scoreTotal);
                IERC20(tokenAddress).safeTransfer(msg.sender, claimAmount);
                agentFee = (totalPool * agentRewardInterest *  guessStorage.guessAmount )/ (1000 * scoreTotal);
                devFee = (totalPool * (devRewardInterest - agentRewardInterest) *  guessStorage.guessAmount )/ (1000 * scoreTotal);
                status = "WIN";
            }
            else{
                return;
            }
            IERC20(tokenAddress).safeTransfer(devAddress, devFee);
            IERC20(tokenAddress).safeTransfer(_agent, agentFee);
            totalFeesCharged += devFee;
            agentFeesCharged[_room] += agentFee;
            userInfo[msg.sender][_room][_matchIndex].hasUserClaimed = true;

            emit ClaimAgent(msg.sender, _matchIndex, _agent, status, claimAmount);
        }

        function viewGuessStatus(address _address, uint256 _matchIndex, uint256 _level, address _agent) public view returns (string memory) {
            require((agentInfo[_agent][_level][_matchIndex].hasCreated && (_level >= 1 && _level <= 5 )) || (_level >= 1 && _level <= 3 ), "invalid level or agent");
            uint256 resultScore = resultList[_matchIndex];
            uint256 _room;
            if(_agent == address(0)){
                _room = _level;
            }
            else{
                _room = agentInfo[_agent][_level][_matchIndex].roomNum;
            }
            if (matchUps[_matchIndex].matchStatus == MatchStatus.CANCELLED || 
                matchUps[_matchIndex].matchStatus == MatchStatus.DELAYED){
                return "CANCELLED";
            }
            if (matchUps[_matchIndex].matchStatus != MatchStatus.COMPLETED){
                return "PENDING";
            }
            if (!scoreInfo[_room][_matchIndex][resultScore].hasGuessed){
                return "TIE";
            }
            if (guessInfo[_address][_room][_matchIndex][resultScore].hasUserGuessed) {
                return "WIN";
            }
            return "LOSE";
        }


        function setMatchStatus(uint256 _matchIndex, MatchStatus _status) external{
            require(isAdmin[msg.sender],"unauthorzied");
            matchUps[_matchIndex].matchStatus = _status;
        }

        function getMatchTotal(uint256 _matchIndex, uint256 _level, address _agent) public view returns (uint){
            uint256 _room;
            if(_agent == address(0)){
                _room = _level;
            }
            else{
                _room = agentInfo[_agent][_level][_matchIndex].roomNum;
            }
            return matchTotalPool[_room][_matchIndex];
        }

        function getUserInfo(address _player, uint256 _matchIndex, uint256 _level, address _agent) public view returns (User memory){
            uint256 _room;
            if(_agent == address(0)){
                _room = _level;
            }
            else{
                _room = agentInfo[_agent][_level][_matchIndex].roomNum;
            }
            return userInfo[_player][_room][_matchIndex];
        }

        function getGuess(address _player, uint256 _matchUpIndex, uint256 result, uint256 _level, address _agent) public view returns (Guess memory){
            uint256 _room;
            if(_agent == address(0)){
                _room = _level;
            }
            else{
                _room = agentInfo[_agent][_level][_matchUpIndex].roomNum;
            }
            return guessInfo[_player][_room][_matchUpIndex][result];
        }

        function editEndTime(uint256 _matchIndex, uint256 _endtime) external{
            require(isAdmin[msg.sender],"unauthorzied");
            matchUps[_matchIndex].endTime = _endtime;
        }

        function setDevAddress(address _devAddress)external onlyOwner{
            devAddress = _devAddress;
        }

    function setTokenAddress(address _tokenAddress)external onlyOwner{
            tokenAddress = _tokenAddress;
        }

    }