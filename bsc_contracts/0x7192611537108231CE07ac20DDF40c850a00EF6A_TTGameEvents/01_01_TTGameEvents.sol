//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract TTGameEvents {
    event ConnectToDapp(uint time, address user);
    event GameStart(uint time, address user, string gameId);
    event GameLike(uint time, address user, string gameId);
    event GameComplete(uint time, address user, string gameId);
    event CreatorGamePlayed(uint time, address creator, string gameId);
    event CreateNewGame(uint time, address user, string gameId);
    event GamePublish(uint time, address creator, string gameId);
    
    event RegisterAction(string action, address user, uint time);

    function connectToDapp(uint time, address user) external {
        emit ConnectToDapp(time, user);
    }

    function gameStart(uint time, address user, string calldata gameId) external {
        emit GameStart(time, user, gameId);
    }
    
    function gameLike(uint time, address user, string calldata gameId) external {
        emit GameLike(time, user, gameId);
    }

    function gameComplete(uint time, address user, string calldata gameId) external {
        emit GameComplete(time, user,gameId);
    }

    function creatorGamePlayed(uint time, address creator, string calldata gameId ) external {
        emit CreatorGamePlayed(time, creator,gameId);
    }

    function createNewGame(uint time, address creator, string calldata gameId ) external {
        emit CreateNewGame(time, creator,gameId);
    }

    function gamePublish(uint time, address creator, string calldata gameId) external {
        emit GamePublish(time, creator,gameId);
    }


    function registerAction(
        string memory action,
        address user,
        uint time
    ) external {
        emit RegisterAction(action, user, time);
    }

    function versionRecipient() external pure returns (string memory) {
        return "1";
    }
}