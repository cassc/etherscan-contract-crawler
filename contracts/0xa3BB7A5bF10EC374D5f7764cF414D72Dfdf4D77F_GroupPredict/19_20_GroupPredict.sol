// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "./interface/IGroupNFT.sol";

contract GroupPredict is Ownable, ReentrancyGuard, Pausable {

    uint8 public constant TEAM_COUNT = 32;

    IGroupNFT public GroupNFT;
    ERC20PresetMinterPauser public NFTBToken;
    uint256 private _rewardAmount;

    enum GameResult { None, Win, Draw, Lose }

    struct Game {
        uint8 homeTeam;
        uint8 awayTeam;
        uint256 deadline;
        uint8 homeScore;
        uint8 awayScore;
        GameResult result;
    }

    // game id => Game info
    mapping(uint8 => Game) public _games;
    uint8[] public _endGames;

    // game id => count
    mapping(uint8 => uint256) public _gameWinPredictCount;
    mapping(uint8 => uint256) public _gameDrawPredictCount;
    mapping(uint8 => uint256) public _gameLosePredictCount;

    struct Predict {
        uint8 gameId;
        uint256 time;
        GameResult result;
        uint256 count;
        address userAddr;
        uint256[] tokenIds;
        bool isClaimed;
    }
    // global predict id
    uint256 public _predictId;
    // token id => predict id
    mapping(uint256 => uint256) public _tokenPredictInfos;
    // predict id => predict info
    mapping(uint256 => Predict) public _predictInfos;
    // user address => predict ids
    mapping(address => uint256[]) public _userPredicts;

    struct PredictResult {
        uint256 id;
        uint256 time;
        uint8 homeTeamId;
        uint8 awayTeamId;
        uint8 homeScore;
        uint8 awayScore;
        GameResult result;
        GameResult finalResult;
        uint256 count;
        uint256 reward;
        bool isClaimed;
        uint256[] tokenIds;
    }

    modifier isNotContract() {
        require(msg.sender == tx.origin, "Sender is not EOA");
        _;
    }

    constructor(
        IGroupNFT nft,
        ERC20PresetMinterPauser token,
        uint256 rewardAmt
    ) {
        GroupNFT = nft;
        NFTBToken = token;
        _rewardAmount = rewardAmt;
    }

    /**
        ****************************************
        Game predict functions
        ****************************************
    */

    function predict(
        uint8 gameId,
        uint256[] memory tokenIds,
        /*uint256[] memory homeTeamTokenIds,
        uint256[] memory awayTeamTokenIds,*/
        GameResult result
    ) external nonReentrant whenNotPaused isNotContract {
        /*require(
            homeTeamTokenIds.length == awayTeamTokenIds.length,
            "invalid parameters"
        );*/
        require(
            result != GameResult.None,
            "invalid result"
        );
        require(
            _games[gameId].deadline > 0 && _games[gameId].deadline >= block.timestamp,
            "game not exists or game already stop predicting"
        );

        _predictId++;
        uint256 count = tokenIds.length;
        _predictInfos[_predictId] = Predict({
            gameId: gameId,
            time: block.timestamp,
            result: result,
            count: count,
            userAddr: msg.sender,
            tokenIds: new uint256[](0),
            isClaimed: false
        });
        for (uint256 i = 0; i < count; i++) {
            /*require(GroupNFT.ownerOf(homeTeamTokenIds[i]) == msg.sender
                && GroupNFT.ownerOf(awayTeamTokenIds[i]) == msg.sender, "msg.sender not own the token");
            require(_tokenPredictInfos[homeTeamTokenIds[i]] == 0
                && _tokenPredictInfos[awayTeamTokenIds[i]] == 0, "token already be predicted");*/
            require(GroupNFT.ownerOf(tokenIds[i]) == msg.sender, "msg.sender not own the token");
            require(_tokenPredictInfos[tokenIds[i]] == 0, "token already be predicted");

            /*uint8 homeTeam = uint8(homeTeamTokenIds[i] % TEAM_COUNT);
            uint8 awayTeam = uint8(awayTeamTokenIds[i] % TEAM_COUNT);
            require(homeTeam == _games[gameId].homeTeam && awayTeam == _games[gameId].awayTeam, "token not game team");*/
            uint8 teamId = uint8(tokenIds[i] % TEAM_COUNT);
            require(teamId == _games[gameId].homeTeam || teamId == _games[gameId].awayTeam, "token not game team");

            /*_tokenPredictInfos[homeTeamTokenIds[i]] = _predictId;
            _tokenPredictInfos[awayTeamTokenIds[i]] = _predictId;
            _predictInfos[_predictId].tokenIds.push(homeTeamTokenIds[i]);
            _predictInfos[_predictId].tokenIds.push(awayTeamTokenIds[i]);

            GroupNFT.lock(homeTeamTokenIds[i]);
            GroupNFT.lock(awayTeamTokenIds[i]);*/
            _tokenPredictInfos[tokenIds[i]] = _predictId;
            _predictInfos[_predictId].tokenIds.push(tokenIds[i]);

            GroupNFT.lock(tokenIds[i]);
        }

        _userPredicts[msg.sender].push(_predictId);

        if (result == GameResult.Win) {
            _gameWinPredictCount[gameId] = _gameWinPredictCount[gameId] + count;
        } else if (result == GameResult.Draw) {
            _gameDrawPredictCount[gameId] = _gameDrawPredictCount[gameId] + count;
        } else if (result == GameResult.Lose) {
            _gameLosePredictCount[gameId] = _gameLosePredictCount[gameId] + count;
        }
    }

    function claim(uint256 predictId) external nonReentrant whenNotPaused isNotContract {
        require(_predictInfos[predictId].result != GameResult.None, "predict not exist");
        require(!_predictInfos[predictId].isClaimed, "already claimed");
        require(_predictInfos[predictId].userAddr == msg.sender, "predict is not owned by user");

        if (_predictInfos[predictId].result == _games[_predictInfos[predictId].gameId].result) {
            NFTBToken.mint(msg.sender, _rewardAmount * _predictInfos[predictId].count);
        }
        _predictInfos[predictId].isClaimed = true;
        for (uint256 j = 0; j < _predictInfos[predictId].tokenIds.length; j++) {
            _tokenPredictInfos[_predictInfos[predictId].tokenIds[j]] = 0;
            GroupNFT.unlock(_predictInfos[predictId].tokenIds[j]);
        }
    }

    /**
        ****************************************
        Query functions
        ****************************************
    */

    function getUserNFTByTeamAndNotPredicted(
        address userAddr,
        uint8 team
    ) external view returns (uint256[] memory) {
        require(team < TEAM_COUNT, "invalid parameter");
        uint256 balance = GroupNFT.balanceOf(userAddr);
        uint256 index;
        uint256[] memory tmp = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = GroupNFT.tokenOfOwnerByIndex(userAddr, i);
            if (tokenId % TEAM_COUNT == team && _tokenPredictInfos[tokenId] == 0) {
                tmp[index] = tokenId;
                index++;
            }
        }

        if (index == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokenIds = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokenIds[i] = tmp[i];
        }

        return tokenIds;
    }

    function getUserNFTByGameAndNotPredicted(
        address userAddr,
        uint8 gameId
    ) external view returns (uint256[] memory) {
        require(_games[gameId].deadline > 0, "game not exist");
        uint256 balance = GroupNFT.balanceOf(userAddr);
        uint256 index;
        uint256[] memory tmp = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = GroupNFT.tokenOfOwnerByIndex(userAddr, i);
            if ((tokenId % TEAM_COUNT == _games[gameId].homeTeam
                    || tokenId % TEAM_COUNT == _games[gameId].awayTeam)
                && _tokenPredictInfos[tokenId] == 0) {
                tmp[index] = tokenId;
                index++;
            }
        }

        if (index == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokenIds = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokenIds[i] = tmp[i];
        }

        return tokenIds;
    }

    function getTotalPredictCountByGame(uint8 gameId) public view returns (uint256) {
        return _gameWinPredictCount[gameId] + _gameDrawPredictCount[gameId] + _gameLosePredictCount[gameId];
    }

    function getRewardAmount() external view returns (uint256) {
        return _rewardAmount;
    }

    function getGameByIds(uint8[] memory gameIds) external view returns (Game[] memory, uint256[] memory) {
        Game[] memory games = new Game[](gameIds.length);
        uint256[] memory counts = new uint256[](gameIds.length);
        for (uint256 i = 0; i < gameIds.length; i++) {
            games[i] = _games[gameIds[i]];
            counts[i] = getTotalPredictCountByGame(gameIds[i]);
        }
        return (games, counts);
    }

    function getPredictsByUser(
        address userAddr,
        uint256 pageNum,
        uint256 pageSize
    ) external view returns (uint256, PredictResult[] memory) {
        uint256 total = _userPredicts[userAddr].length;

        uint256 start = (pageNum - 1) * pageSize;
        uint256 end = pageNum * pageSize;
        if (start > total) {
            return (total, new PredictResult[](0));
        }
        if (end > total) {
            end = total;
        }

        PredictResult[] memory results = new PredictResult[](end - start);
        for (uint256 i = start; i < end; i++) {
            Predict memory predict = _predictInfos[_userPredicts[userAddr][i]];
            PredictResult memory result;
            result.id = _userPredicts[userAddr][i];
            result.time = predict.time;
            result.homeTeamId = _games[predict.gameId].homeTeam;
            result.awayTeamId = _games[predict.gameId].awayTeam;
            result.homeScore = _games[predict.gameId].homeScore;
            result.awayScore = _games[predict.gameId].awayScore;
            result.result = predict.result;
            result.finalResult = _games[predict.gameId].result;
            result.count = predict.count;
            if (predict.result == result.finalResult) {
                result.reward = _rewardAmount * predict.count;
            }
            result.isClaimed = predict.isClaimed;
            result.tokenIds = predict.tokenIds;
            results[i - start] = result;
        }
        return (total, results);
    }

    function getEndGameList() external view returns(uint8[] memory) {
        return _endGames;
    }

    function getUnclaimedAmount(address userAddr) external view returns(uint256) {
        uint256 amount_;

        for (uint256 i = 0; i < _userPredicts[userAddr].length; i++) {
            uint256 predictId_ = _userPredicts[userAddr][i];
            if (_predictInfos[predictId_].result == _games[_predictInfos[predictId_].gameId].result && !_predictInfos[predictId_].isClaimed) {
                amount_ = amount_ + _predictInfos[predictId_].count * _rewardAmount;
            }
        }

        return amount_;
    }

    /**
        ****************************************
        Admin setting functions
        ****************************************
    */

    function setGames(
        uint8[] memory ids,
        uint8[] memory homeTeams,
        uint8[] memory awayTeams,
        uint256[] memory deadlines
    ) external onlyOwner {
        require(
            ids.length == homeTeams.length &&
            ids.length == awayTeams.length &&
            ids.length == deadlines.length,
            "invalid parameters"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            require(homeTeams[i] < TEAM_COUNT && awayTeams[i] < TEAM_COUNT, "invalid parameters");
            _games[ids[i]] = Game({
                homeTeam: homeTeams[i],
                awayTeam: awayTeams[i],
                deadline: deadlines[i],
                homeScore: 0,
                awayScore: 0,
                result: GameResult.None
            });
        }
    }

    function setResults(
        uint8[] memory ids,
        uint8[] memory homeScores,
        uint8[] memory awayScores,
        GameResult[] memory results
    ) external onlyOwner {
        require(
            ids.length == results.length &&
            ids.length == homeScores.length &&
            ids.length == awayScores.length,
            "invalid parameters");
        for (uint256 i = 0; i < ids.length; i++) {
            require(_games[ids[i]].deadline > 0, "game not exists");
            _games[ids[i]].awayScore = awayScores[i];
            _games[ids[i]].homeScore = homeScores[i];
            _games[ids[i]].result = results[i];
            if (results[i] != GameResult.None) {
                _endGames.push(ids[i]);
            }
        }
    }

    function addEndGames(uint8[] memory ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            require(_games[ids[i]].deadline > 0, "game not exists");
            _endGames.push(ids[i]);
        }
    }

    function removeEndGames(uint256 index) external onlyOwner {
        require(index < _endGames.length, "invalid index");
        _endGames[index] = _endGames[_endGames.length - 1];
        _endGames.pop();
    }

    function setRewardAmount(uint256 amount) external onlyOwner {
        _rewardAmount = amount;
    }

    /**
        ****************************************
        Private functions
        ****************************************
    */

}