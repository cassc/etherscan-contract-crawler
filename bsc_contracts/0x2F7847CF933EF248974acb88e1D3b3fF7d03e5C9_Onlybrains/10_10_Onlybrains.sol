// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/interfaces/IERC165.sol";
// import "hardhat/console.sol";

contract Onlybrains is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SESSION_CLOSER_ROLE = keccak256("SESSION_CLOSER_ROLE");
    bytes32 public constant SESSION_OPENER_ROLE = keccak256("SESSION_OPENER_ROLE");
    bytes32 public constant BLACKLISTED_USER_ROLE = keccak256("BLACKLISTED_USER_ROLE");
    bytes32 public constant COMMISSION_WITHDRAWER_ROLE = keccak256("COMMISSION_WITHDRAWER_ROLE");
    bytes32 public constant SESSION_MODIFIER_ROLE = keccak256("SESSION_MODIFIER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }


    struct Player {
        address account;
        uint reportTS;
        uint score;
        bytes32 sha256hash;
        bool resultUploaded;
        uint256 reward;
        bool checked;
    }

    struct GameSession { 
        uint gameID;
        uint startTimestamp; //think about explicit allowance to start session funding/gaming via dedicated actions. To avoid using timestamps
        uint endTimestamp;
        bytes32 secret;
        bool finished;
        bool commissionWithdrawn;

        uint256 requiredStake;
        address tokenContract;
        uint8 taxPercent;
        uint256 stake;

        Player[] players;
    }
    struct SessionPermissions {
        uint32 playersCountLimit;
        mapping(address=>bool) allowlist;
        bool hasAllowlist;
        mapping(address=>bool) blocklist;
    }
    mapping(uint16 => SessionPermissions) public sessionPermissionsStorage;
    mapping(uint => uint16) public sessionPermissionsMapping;
    mapping(uint => mapping(address => uint)) private sessionsPlayersMap;
    mapping(address => uint[]) private playerSessionsMap;
    mapping(uint => uint[]) private gameSessionsMap; 

    GameSession[] private sessions;


    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    error NotParticipating(address player, uint sessionID);
    error AlreadyParticipating(address player, uint sessionID);
    error SessionNotFound(uint sessionID);
    error SessionAlreadyExists(uint sessionID);
    error ResultAlreadyReported(address player, uint sessionID);
    error SessionNotActive(uint sessionID);
    error BadSessionTimeInterval(uint current, uint start, uint end);
    error SessionNotFinished(uint sessionID);
    error AlreadyWithdrawn(uint sessionID);
    error StakeFailed(address player, uint sessionID, uint stake, address token);
    error Blacklisted(address player);
    error PlayersCountLimitReached(uint sessionID);
    error NotAllowedForSession(uint sessionID, address player);
    error WithdrawalFailed(uint sessionID);

    function findSession(uint sessionID) private view returns (GameSession storage) {
        if(sessionID >= sessions.length) revert SessionNotFound(sessionID);
        return sessions[sessionID];
    }

    function checkParticipationAllowed(uint sessionID, address user) private view returns (bool) {
        if(sessionPermissionsMapping[sessionID] == 0) return true;
        GameSession storage session = findSession(sessionID);
        SessionPermissions storage perm = sessionPermissionsStorage[sessionPermissionsMapping[sessionID]];

        if(perm.playersCountLimit > 0 && session.players.length >= perm.playersCountLimit) revert PlayersCountLimitReached(sessionID);
        else if(perm.hasAllowlist && perm.allowlist[user] != true || perm.blocklist[user] == true) revert NotAllowedForSession(sessionID, user);
        return true;
    }

    function updateSessionPermissionsEntry(uint16 id, address[] calldata allowlist, address[] calldata blocklist, uint32 playersCountLimit) public whenNotPaused() onlyRole(SESSION_MODIFIER_ROLE) {
        SessionPermissions storage session = sessionPermissionsStorage[id];
        if(allowlist.length > 0) {
            session.hasAllowlist = true;
            for(uint i = 0; i < allowlist.length; i ++) {
                session.allowlist[allowlist[i]] = true;
            }
        } else {
            session.hasAllowlist = false;
        }
        for(uint i = 0; i < blocklist.length; i ++) {
            session.blocklist[blocklist[i]] = true;
        }
        session.playersCountLimit = playersCountLimit;
    }

    function setSessionPermissions(uint sessionID, uint16 permissionsID) public whenNotPaused() onlyRole(SESSION_MODIFIER_ROLE) {
        sessionPermissionsMapping[sessionID] = permissionsID;
    }
    
    event ScoreSent(
        uint id,
        address player,
        uint score,
        bytes32 hash
    );

    function putScore(uint sessionID, uint score,  bytes32 hash) public whenNotPaused() {
        if(hasRole(BLACKLISTED_USER_ROLE, msg.sender)) {
            revert Blacklisted(msg.sender);
        }

        GameSession storage session = findSession(sessionID);
        if(session.startTimestamp > block.timestamp || block.timestamp > session.endTimestamp || session.finished) revert SessionNotActive(sessionID);

        uint existingParticipantIndex = sessionsPlayersMap[sessionID][msg.sender];
        if(existingParticipantIndex == 0) revert NotParticipating(msg.sender, sessionID);

        Player storage player = session.players[existingParticipantIndex - 1];
        // if(player.resultUploaded) revert ResultAlreadyReported(msg.sender, sessionID);
        player.resultUploaded = true;
        player.score = score;
        player.sha256hash = hash;
        player.reportTS = block.timestamp;

        emit ScoreSent(sessionID, msg.sender, score, hash);
    }

    event NewSession(
        uint id
    );

    function createSession(uint gameID, uint startTS, uint endTS, uint256 requiredStake, address tokenContract, uint8 taxPercent) public whenNotPaused() onlyRole(SESSION_OPENER_ROLE) {
        if(startTS >= endTS || endTS <= block.timestamp || startTS == 0 || endTS == 0) revert BadSessionTimeInterval(block.timestamp, startTS, endTS);
        uint newId = sessions.length;

        GameSession storage session = sessions.push();

        session.endTimestamp = endTS;
        session.finished = false;
        session.commissionWithdrawn = false;
        session.gameID = gameID;
        session.requiredStake = requiredStake;
        session.startTimestamp = startTS;
        session.taxPercent = taxPercent > 100 ? 100: taxPercent;
        session.tokenContract = tokenContract;
        session.stake = 0;
        gameSessionsMap[gameID].push(newId);

        emit NewSession(newId);
    }

    event NewParticipation(
        uint id,
        address player
    );
    event SessionStakeChanged(uint sessionID, address from, uint delta, uint total);

    function participate(uint sessionID) public whenNotPaused() {
        if(hasRole(BLACKLISTED_USER_ROLE, msg.sender)) {
            revert Blacklisted(msg.sender);
        }
        GameSession storage session = findSession(sessionID);
        if(block.timestamp >= session.endTimestamp || session.finished) revert SessionNotActive(sessionID);
        checkParticipationAllowed(sessionID, msg.sender);

        uint existingParticipantIndex = sessionsPlayersMap[sessionID][msg.sender];
        if(existingParticipantIndex > 0) revert AlreadyParticipating(msg.sender, sessionID);

        Player storage newPlayer = session.players.push();

        newPlayer.account = msg.sender;
        newPlayer.checked = false;
        newPlayer.reportTS = 0;
        newPlayer.resultUploaded = false;
        newPlayer.reward = 0;
        newPlayer.score = 0;
        newPlayer.sha256hash = "";

        sessionsPlayersMap[sessionID][msg.sender] = session.players.length;

        playerSessionsMap[msg.sender].push(sessionID);

        bool transferOk = false;
        try IERC20(session.tokenContract).transferFrom(msg.sender, address(this), session.requiredStake) returns (bool success) {
            transferOk = success;
        } catch {
            transferOk = false;
        }
        if(!transferOk) {
            revert StakeFailed(msg.sender, sessionID, session.requiredStake, session.tokenContract);
        } 
        session.stake += session.requiredStake;
        emit NewParticipation(sessionID, msg.sender);
        emit SessionStakeChanged(sessionID, msg.sender, session.requiredStake, session.stake);
    }

    function toStr(address account) private pure returns(bytes memory) {
        return toStr(abi.encodePacked(account));
    }

    function toStr(bytes32 d) private pure returns(bytes memory) {
        return toStr(abi.encodePacked(d));
    }
    function toStr(uint256 value) private pure returns(bytes memory) {
        bytes memory alphabet = "0123456789";
        
        uint v = value;
        uint length = 0;
        while(true) {
            v /= 10;
            length ++;
            if(v == 0)
                break;
        }
        bytes memory s = new bytes(length);
        while(true) {
            uint remainder = value % 10;
            value /= 10;
            s[length-1] = alphabet[remainder];
            length --;
            if(value == 0)
                break;
        }
        return s;
    }
  
    function toStr(bytes memory data) private pure returns(bytes memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return str;
    }

    function comparePlayers(Player[] memory players,  uint l, uint r) private pure returns (bool) {
        if(players[l].score != players[r].score) {
            return players[l].score > players[r].score;
        } else {
            return players[l].reportTS < players[r].reportTS;
        }
    }

    function quickSort(Player[] memory players, uint[] memory arr, int left, int right) private pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (comparePlayers(players, arr[uint(i)], pivot)) i++;
            while (comparePlayers(players, pivot, arr[uint(j)])) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(players, arr, left, j);
        if (i < right)
            quickSort(players, arr, i, right);
    }

    event RevealedSession(
        uint id
    );

    event PaymentFailed(uint sessionID, address player, uint256 reward);
    event PlayerResult(uint sessionID, address player, uint stake, bool score_uploaded, bool checked, uint rank, uint reward);
    //TODO: https://fravoll.github.io/solidity-patterns/pull_over_push.html
    // dangerous to do it this way, if participant fails to receive for any reason, session will not be ever able to be revealed!
    function revealSession(uint sessionID, bytes32 secret) public whenNotPaused() onlyRole(SESSION_CLOSER_ROLE) {
        GameSession storage session = findSession(sessionID);

        if(session.finished) revert SessionNotActive(sessionID);
        if(session.endTimestamp >= block.timestamp)  {
            revert SessionNotFinished(sessionID);
            
        }
        
        session.finished = true;
        session.secret = secret;
        uint256 totalStake = session.stake;

        uint checkedCount = 0;
        for(uint i = 0; i < session.players.length; i ++) {
            Player storage player = session.players[i];
            if(player.resultUploaded) {
                bytes memory toHash = bytes.concat(toStr(player.account), toStr(sessionID), toStr(player.score), toStr(secret));
                // console.log("toHash %s", string(toHash));

                if(player.sha256hash == sha256(toHash)) {
                    player.checked = true;
                    checkedCount ++;
                } else {
                    emit PlayerResult(sessionID, player.account, session.requiredStake, true, false, 0, 0);
                }
            } else {
                emit PlayerResult(sessionID, player.account, session.requiredStake, false, false, 0, 0);
            }
        }
        if(checkedCount > 0) {           
            uint[] memory checkedPlayersIndexes = new uint[](checkedCount);
            uint j = 0;
            for(uint i = 0; i < session.players.length; i ++) {
                if(session.players[i].checked) {
                    checkedPlayersIndexes[j] = i;
                    j++;
                }
            }
            quickSort(session.players, checkedPlayersIndexes, 0, int256(checkedCount - 1));

            totalStake = (totalStake * (100 - session.taxPercent) ) / 100;
            uint256 totalStakeRemains = totalStake;

            totalStake = totalStake * (300*(1 + checkedCount)*(2 + checkedCount)*(3 + checkedCount)*(4 + checkedCount)*(5 + checkedCount)) / 
                (checkedCount*(10538 + 15525*checkedCount + 8045*checkedCount*checkedCount + 1755*checkedCount*checkedCount*checkedCount + 137*checkedCount*checkedCount*checkedCount*checkedCount));

           
            for(uint i = 0; i < checkedPlayersIndexes.length; i ++) {
                uint rank = i + 1;
                uint256 reward = totalStake / rank / (rank + 5);

                if(reward > totalStakeRemains) {
                    reward = totalStakeRemains;
                }
                
                if(reward > 0) {
                    session.players[checkedPlayersIndexes[i]].reward = reward;
                    totalStakeRemains -= reward;
                    address acc  = session.players[checkedPlayersIndexes[i]].account;
                    

                    try IERC20(session.tokenContract).transfer(acc, reward) returns (bool success) {
                        if(!success) {
                            emit PaymentFailed(sessionID, acc, reward);
                        } else {
                            
                            emit PlayerResult(sessionID, acc, session.requiredStake, true, true, rank, reward);
                        }
                    } catch {
                        emit PaymentFailed(sessionID, acc, reward);
                    }
                }           
            }
        }
        emit RevealedSession(sessionID);
    }
    function sessionsCount() public view returns (uint) {
        return sessions.length;
    }

    struct GameSessionInfo { 
        GameSession session;
        uint playersCount;
        uint id;
    }
    function extendedSessionInfo(GameSession storage session, uint id) private view returns (GameSessionInfo memory) {
        GameSessionInfo memory ret;
        ret.session = session;
        ret.playersCount = session.players.length;
        ret.id = id;
        return ret;
    }
    function sessionInfo(uint sessionID) public view returns (GameSessionInfo memory) {
        return extendedSessionInfo(findSession(sessionID), sessionID);
    }

    function sessionsInfo(uint from, uint to) public view returns (GameSessionInfo[] memory) {
        uint l = sessions.length;
        if(l == 0) return new GameSessionInfo[](0);
        if(from >= l) from = l - 1;
        if(to > l) to = l;
        if(to < from) to = from;
        GameSessionInfo[] memory ret = new GameSessionInfo[](to-from);
        for(uint i = 0; i < to-from ; i ++) {
            ret[i] = sessionInfo(i+from);
        }
        return ret;
    }

    function sessionPlayersCount(uint sessionID) public view returns (uint) {
        GameSession storage session = findSession(sessionID);
        return session.players.length;
    }

    function sessionPlayers(uint sessionID, uint from, uint to) public view returns (Player[] memory) {
        GameSession storage session = findSession(sessionID);
        uint l = session.players.length;
        if(l == 0) return new Player[](0);
        if(from >= l) from = l - 1;
        if(to > l) to = l;
        if(to < from) to = from;
        Player[] memory ret = new Player[](to-from);
        
        for(uint i = 0; i < to-from ; i ++) {
            ret[i] = session.players[i+from];
        }
        return ret;
    }

    function sessionPlayer(uint sessionID, address player) public view returns (Player memory) {
        GameSession storage session = findSession(sessionID);
        uint existingParticipantIndex = sessionsPlayersMap[sessionID][player];
        if(existingParticipantIndex == 0) revert NotParticipating(player, sessionID);
        return session.players[existingParticipantIndex - 1];
    }

    function playerSessionsCount(address player) public view returns (uint) {
        return playerSessionsMap[player].length;
    }

    function playerSessions(address player, uint from, uint to) public view returns (GameSessionInfo[] memory) {
        uint l = playerSessionsMap[player].length;
        if(l == 0) return new GameSessionInfo[](0);
        if(from >= l) from = l - 1;
        if(to > l) to = l;
        if(to < from) to = from;
        GameSessionInfo[] memory ret = new GameSessionInfo[](to-from);
     
        for(uint i = 0; i < to-from ; i ++) {
            ret[i] = extendedSessionInfo(findSession(playerSessionsMap[player][i+from]), playerSessionsMap[player][i+from]);
        }
        return ret;
    }

    function gameSessionsCount(uint gameID) public view returns (uint) {
        return gameSessionsMap[gameID].length; //NEED TO RETURN exception here
    }

    function gameSessions(uint gameID, uint from, uint to) public view returns (GameSessionInfo[] memory) {
        uint l = gameSessionsMap[gameID].length; //todo
        if(l == 0) return new GameSessionInfo[](0);
        if(from >= l) from = l - 1;
        if(to > l) to = l;
        if(to < from) to = from;
        GameSessionInfo[] memory ret = new GameSessionInfo[](to-from);
        for(uint i = 0; i < to-from ; i ++) {
            ret[i] = extendedSessionInfo(findSession(gameSessionsMap[gameID][i+from]), gameSessionsMap[gameID][i+from]);              
        }
        return ret;
    }

    function withdrawCommission(uint sessionID, address target) public whenNotPaused() onlyRole(COMMISSION_WITHDRAWER_ROLE) {
        GameSession storage session = findSession(sessionID);
        if(!session.finished) revert SessionNotFinished(sessionID);
        if(session.commissionWithdrawn) revert AlreadyWithdrawn(sessionID);
        session.commissionWithdrawn = true;
        uint256 totalStake = session.stake;
        uint256 totalReward = 0;
        for(uint i = 0; i < session.players.length; i ++) {
            Player storage player = session.players[i];
            if(player.resultUploaded && player.checked) {
                totalReward += player.reward;
            }
        }
        if(totalStake < totalReward) {
            revert("CRITICAL ERROR");
        }
        try IERC20(session.tokenContract).transfer(target, totalStake - totalReward) returns (bool success) {
            if(!success) {
                revert WithdrawalFailed(sessionID);
            } 
        } catch {
            revert WithdrawalFailed(sessionID);
        }
    }

    function addToSessionStake(uint sessionID, uint256 amount) public whenNotPaused() onlyRole(SESSION_MODIFIER_ROLE) {
        GameSession storage session = findSession(sessionID);
        if(block.timestamp >= session.endTimestamp || session.finished) revert SessionNotActive(sessionID);

        bool transferOk = false;
        try IERC20(session.tokenContract).transferFrom(msg.sender, address(this), amount) returns (bool success) {
            transferOk = success;
        } catch {
            transferOk = false;
        }
        if(!transferOk) {
            revert StakeFailed(msg.sender, sessionID, amount, session.tokenContract);
        } 
        session.stake += amount;
        emit SessionStakeChanged(sessionID, msg.sender, amount, session.stake);

    }
}