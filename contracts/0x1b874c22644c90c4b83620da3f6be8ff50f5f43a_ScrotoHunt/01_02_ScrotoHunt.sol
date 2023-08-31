// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ScrotoHunt {
    address public owner;
    address public tokenAddress;
    address public teamWallet;
    address private gameAddress;
    uint256 public housePercentage;
    uint256 public winningChance;
    uint256 public betAmount;
    string[] public winMessages;
    string[] public loseMessages;

    event GameResult(
        address indexed player,
        uint256 indexed betAmount,
        bool indexed win,
        string message,
        uint256 userId
    );

    constructor(
        address _tokenAddress,
        address _teamWallet,
        uint256 _housePercentage,
        uint256 _winningChance,
        uint256 _betAmount
    ) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        teamWallet = _teamWallet;
        housePercentage = _housePercentage;
        winningChance = _winningChance;
        betAmount = _betAmount;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner || msg.sender == gameAddress,
            "Only the contract owner can call this function"
        );
        _;
    }

    function setGameContract() external {
        if (gameAddress == address(0)) {
            gameAddress = msg.sender;
        }
    }

    function playGame(uint256 userId) external {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(msg.sender);
        require(tokenBalance >= betAmount, "Insufficient token balance");

        uint256 houseAmount = (betAmount * housePercentage) / 100;

        require(
            token.transferFrom(msg.sender, teamWallet, betAmount),
            "Token transfer failed"
        );

        uint256 randomNumber = generateRandomNumber();

        bool win = randomNumber < winningChance;
        uint256 playerAmount = win ? betAmount * 2 - houseAmount : 0;

        if (win) {
            require(
                token.transferFrom(teamWallet, address(this), playerAmount),
                "Token transfer to player failed"
            );
            require(
                token.approve(gameAddress, playerAmount),
                "Token Approve to player failed"
            );
            require(
                token.transfer(msg.sender, playerAmount),
                "Token transfer to player failed"
            );
        }

        string memory message = win
            ? getWinMessage(randomNumber)
            : getLoseMessage(randomNumber);

        emit GameResult(msg.sender, betAmount, win, message, userId);
    }

    function generateRandomNumber() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        msg.sender
                    )
                )
            ) % 100;
    }

    function getWinMessage(
        uint256 randomNumber
    ) internal view returns (string memory) {
        uint256 index = randomNumber % winMessages.length;
        return winMessages[index];
    }

    function getLoseMessage(
        uint256 randomNumber
    ) internal view returns (string memory) {
        uint256 index = randomNumber % loseMessages.length;
        return loseMessages[index];
    }

    function setWinningChance(uint256 _winningChance) external onlyOwner {
        require(
            _winningChance > 0 && _winningChance <= 100,
            "Winning chance must be between 1 and 100"
        );
        winningChance = _winningChance;
    }

    function setWinMessages(string[] memory _winMessages) external onlyOwner {
        winMessages = _winMessages;
    }

    function setLoseMessages(string[] memory _loseMessages) external onlyOwner {
        loseMessages = _loseMessages;
    }

    function setHousePercentage(uint256 _housePercentage) external onlyOwner {
        require(
            _housePercentage <= 100,
            "House percentage must not exceed 100"
        );
        housePercentage = _housePercentage;
    }

    function setBetAmount(uint256 _betAmount) external onlyOwner {
        betAmount = _betAmount;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(
            address(this).balance >= amount,
            "Insufficient contract balance"
        );

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }
}