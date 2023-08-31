// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC20 Interface
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

}

contract VersusBattle {
    address public owner;
    address private gameDrawer = 0x06E618E5fc0eF690EB75D93e44bf98a3D4109c27;

    // Address of the VERSUS token contract
    address constant VERSUS_TOKEN_ADDRESS = 0xf2F80327097d312334Fe4E665F60a83CB6ce71B3;
    IERC20 public versusToken = IERC20(VERSUS_TOKEN_ADDRESS);

    struct Game {
        bool isActive;
        uint256 totalPot;
    }

    mapping(uint256 => Game) public games;
    mapping(uint256 => mapping(address => uint256)) public stakes;
    mapping(uint256 => address[]) public gameParticipants;

    event GameStarted(uint256 gameId);
    event PlayerJoined(uint256 gameId, address player, uint256 amount);
    event GameConcluded(uint256 gameId, address winner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyGameDrawer() {
        require(msg.sender == gameDrawer, "Not authorized to draw games");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function startGame(uint256 gameId) external onlyGameDrawer {
        require(!games[gameId].isActive, "Game already active");
        
        games[gameId] = Game({
            isActive: true,
            totalPot: 0
        });

        emit GameStarted(gameId);
    }

    function joinGame(uint256 gameId, uint256 amount) external {
    require(games[gameId].isActive, "Game is not active");
    require(amount > 0, "Stake must be greater than 0");

    // Check if the user has approved the necessary tokens
    uint256 approvedAmount = versusToken.allowance(msg.sender, address(this));
    require(approvedAmount >= amount, "Approve the contract to spend your VERSUS tokens first");

    // Transfer VERSUS tokens from player to this contract
    require(versusToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");


        if(stakes[gameId][msg.sender] == 0) {
            gameParticipants[gameId].push(msg.sender);
        }

        stakes[gameId][msg.sender] += amount;
        games[gameId].totalPot += amount;

        emit PlayerJoined(gameId, msg.sender, amount);
    }

    function getParticipants(uint256 gameId) external view returns(address[] memory) {
        return gameParticipants[gameId];
    }

    function drawGame(uint256 gameId, address winner) external onlyGameDrawer {
        require(games[gameId].isActive, "Game is not active");

        uint256 pot = games[gameId].totalPot;

        require(versusToken.transfer(winner, pot), "Token transfer to winner failed");

        games[gameId].isActive = false;

        emit GameConcluded(gameId, winner);
    }

    receive() external payable {}

    function withdrawStuckETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function withdrawVersus() external onlyOwner {
        uint256 contractBalance = versusToken.balanceOf(address(this));
        require(contractBalance > 0, "No VERSUS tokens to withdraw");

        require(versusToken.transfer(owner, contractBalance), "Token withdrawal failed");
    }
}