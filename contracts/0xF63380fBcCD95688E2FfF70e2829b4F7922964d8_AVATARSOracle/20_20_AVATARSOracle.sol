pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import "../lib/helpers/Errors.sol";
import "../lib/helpers/StringUtils.sol";
import "../lib/helpers/BytesUtils.sol";
import "../interfaces/ICallback.sol";

contract AVATARSOracle is ReentrancyGuard, Ownable, ChainlinkClient {
    event RequestFulfilled(bytes32 indexed requestId, bytes[] indexed data);
    event RequestFulfilledData(bytes32 indexed requestId, bytes indexed data);

    using Chainlink for Chainlink.Request;
    using CBORChainlink for BufferChainlink.buffer;
    struct GameCreate {
        uint32 gameId;
        uint40 startTime;
        string homeTeam;
        string awayTeam;
    }

    struct GameResolve {
        uint32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        string status;
    }

    struct Game {
        uint32 gameId;
        uint40 startTime;
        string homeTeam;
        string awayTeam;
        uint8 homeScore;
        uint8 awayScore;
        string status;
    }

    address public _admin;
    address public _be;
    address public _callbackAddress;

    mapping(bytes32 => bytes[]) public requestIdGames;
    mapping(bytes32 => bytes) public requestIdGamesData;
    mapping(uint32 => Game) public games;


    /**
     * @notice Initialize the link token and target oracle
     *
     * Mumbai polygon Testnet details:
     * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     ** - Any API
     * Oracle: 0xeE3BC809fFa9BB32A88d39d40DF6425d5d712B16
     * jobId: ef28cb879c2741f8b98fb686d26bad86
     * jobId bytes32: 
     ** - Enetpulse Sports Data Oracle
     * Oracle: 0xd5821b900e44db9490da9b09541bbd027fBecF4E
     * jobId: d110b5c4b83d42dca20e410ac537cd94
     * jobId bytes32: 0x6431313062356334623833643432646361323065343130616335333763643934
     *
     *
     * Ethereum Mainnet details:
     * Link Token: 0x514910771af9ca656af840dff83e8264ecf986ca
     * Oracle: 0x262aBFeD55b03A41451e16E4591837E7A7af04d3
     * jobId: ef28cb879c2741f8b98fb686d26bad86
     * jobId bytes32: 
     ** - Enetpulse Sports Data Oracle
     * Oracle: 0x6A9e45568261c5e0CBb1831Bd35cA5c4b70375AE (Chainlink DevRel)
     * jobId: 5dd848c329e8444f8241a1bea4fcadb7
     * jobId bytes32: 0x3564643834386333323965383434346638323431613162656134666361646237
     */
    constructor (address admin, address be, address LINK_TOKEN, address ORACLE) {
        _admin = admin;
        _be = be;

        // init for oracle
        setChainlinkToken(LINK_TOKEN);
        setChainlinkOracle(ORACLE);
    }

    function changeAdmin(address newAdm) external {
        require(msg.sender == _admin && newAdm != address(0) && _admin != newAdm, Errors.ONLY_ADMIN_ALLOWED);
        _admin = newAdm;
    }

    function changeBE(address be) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _be = be;
    }

    function changeOracle(address oracle) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        setChainlinkOracle(oracle);
    }

    function changeLINKToken(address LINK_TOKEN) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        setChainlinkToken(LINK_TOKEN);
    }

    function changeCallbackAddress(address add) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _callbackAddress = add;
    }

    /**
     * @notice Stores, from any API, the scheduled games.
     * @param requestId the request ID for fulfillment.
     * @param gameData the games data is resolved.
     */
    function fulfill(bytes32 requestId, bytes memory gameData) public recordChainlinkFulfillment(requestId) {
        emit RequestFulfilledData(requestId, gameData);

        requestIdGamesData[requestId] = gameData;
        (uint32 gameId, uint40 startTime, string memory home, string memory away, uint8 homeTeamGoals, uint8 awayTeamGoals, string memory status) = abi.decode(gameData, (uint32, uint40, string, string, uint8, uint8, string));
        games[gameId] = Game(gameId, startTime, home, away, homeTeamGoals, awayTeamGoals, status);
        if (_callbackAddress != address(0)) {
            ICallback callBack = ICallback(_callbackAddress);
            callBack.fulfill(requestId, gameData);
        }
    }

    /**
     * @notice Stores, from Enetpulse, the scheduled games.
     */
    function fulfillSchedule(bytes32 requestId, bytes[] memory result) external recordChainlinkFulfillment(requestId) {
        emit RequestFulfilled(requestId, result);

        requestIdGames[requestId] = result;
        uint32 gameId = uint32(bytes4(BytesUtils._sliceDynamicArray(0, 4, result[0])));
        if (games[gameId].startTime == 0) {
            // create
            GameCreate memory g = _getGameCreateStruct(requestIdGames[requestId][0]);
            games[gameId] = Game(g.gameId, g.startTime, g.homeTeam, g.awayTeam, 0, 0, "");
        } else {
            // resolved
            GameResolve memory g = _getGameResolveStruct(requestIdGames[requestId][0]);
            games[gameId].homeScore = g.homeScore;
            games[gameId].awayScore = g.awayScore;
            games[gameId].status = g.status;

            if (_callbackAddress != address(0)) {
                ICallback callBack = ICallback(_callbackAddress);
                callBack.fulfill(requestId, abi.encode(games[gameId].gameId, games[gameId].startTime, games[gameId].homeTeam, games[gameId].awayTeam, games[gameId].homeScore, games[gameId].awayScore, games[gameId].status));
            }
        }
    }

    /**
    * @notice Requests, from any API,the tournament games to be resolved.
    */
    function requestData(string memory jobId, uint256 fee, string memory url, string memory path) public returns (bytes32 requestId) {
        require(msg.sender == _admin || msg.sender == _be, Errors.ONLY_ADMIN_ALLOWED);
        Chainlink.Request memory req = buildChainlinkRequest(StringUtils.stringToBytes32(jobId), address(this), this.fulfill.selector);
        req.add('get', url);
        req.add('path', path);
        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * @notice Requests, from Enetpulse, the tournament games either to be created or to be resolved on a specific date.
     */
    function requestSchedule(string memory jobId, uint256 fee, uint256 market, uint256 leagueId, uint256 date) external {
        require(msg.sender == _admin || msg.sender == _be, Errors.ONLY_ADMIN_ALLOWED);
        Chainlink.Request memory req = buildOperatorRequest(StringUtils.stringToBytes32(jobId), this.fulfillSchedule.selector);
        //0: create, 1: resolved
        req.addUint("market", market);
        // 77: FIFA World Cup
        req.addUint("leagueId", leagueId);
        req.addUint("date", date);
        sendOperatorRequest(req, fee);
    }

    function requestSchedule(
        bytes32 _specId,
        uint256 _payment,
        uint256 _market,
        uint256 _leagueId,
        uint256 _date,
        uint256[] calldata _gameIds
    ) external {
        require(msg.sender == _admin || msg.sender == _be, Errors.ONLY_ADMIN_ALLOWED);
        Chainlink.Request memory req = buildOperatorRequest(_specId, this.fulfillSchedule.selector);
        req.addUint("market", _market);
        req.addUint("leagueId", _leagueId);
        req.addUint("date", _date);
        _addUintArray(req, "gameIds", _gameIds);
        sendOperatorRequest(req, _payment);
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) external {
        require(msg.sender == _admin || msg.sender == _be, Errors.ONLY_ADMIN_ALLOWED);
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }

    function setRequestIdGames(bytes32 _requestId, bytes[] memory _games) external {
        require(msg.sender == _admin || msg.sender == _be, Errors.ONLY_ADMIN_ALLOWED);
        requestIdGames[_requestId] = _games;
    }

    function withdrawLink() public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success);
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */
    function getGameCreate(bytes32 _requestId, uint256 _idx) external view returns (GameCreate memory) {
        return _getGameCreateStruct(requestIdGames[_requestId][_idx]);
    }

    function getGameResolve(bytes32 _requestId, uint256 _idx) external view returns (GameResolve memory) {
        return _getGameResolveStruct(requestIdGames[_requestId][_idx]);
    }

    function _getOracleAddress() external view returns (address) {
        return chainlinkOracleAddress();
    }

    /* ========== PRIVATE PURE FUNCTIONS ========== */
    function _addUintArray(
        Chainlink.Request memory _req,
        string memory _key,
        uint256[] memory _values
    ) private pure {
        Chainlink.Request memory r2 = _req;
        r2.buf.encodeString(_key);
        r2.buf.startArray();
        uint256 valuesLength = _values.length;
        for (uint256 i = 0; i < valuesLength;) {
            r2.buf.encodeUInt(_values[i]);
        unchecked {
            ++i;
        }
        }
        r2.buf.endSequence();
        _req = r2;
    }

    function _getGameCreateStruct(bytes memory _data) private pure returns (GameCreate memory) {
        uint32 gameId = uint32(bytes4(BytesUtils._sliceDynamicArray(0, 4, _data)));
        uint40 startTime = uint40(bytes5(BytesUtils._sliceDynamicArray(4, 9, _data)));
        uint8 homeTeamLength = uint8(bytes1(_data[9]));
        uint256 endHomeTeam = 10 + homeTeamLength;
        string memory homeTeam = string(BytesUtils._sliceDynamicArray(10, endHomeTeam, _data));
        string memory awayTeam = string(BytesUtils._sliceDynamicArray(endHomeTeam, _data.length, _data));
        GameCreate memory gameCreate = GameCreate(gameId, startTime, homeTeam, awayTeam);
        return gameCreate;
    }

    function _getGameResolveStruct(bytes memory _data) private pure returns (GameResolve memory) {
        uint32 gameId = uint32(bytes4(BytesUtils._sliceDynamicArray(0, 4, _data)));
        uint8 homeScore = uint8(bytes1(_data[4]));
        uint8 awayScore = uint8(bytes1(_data[5]));
        string memory status = string(BytesUtils._sliceDynamicArray(6, _data.length, _data));
        GameResolve memory gameResolve = GameResolve(gameId, homeScore, awayScore, status);
        return gameResolve;
    }
}