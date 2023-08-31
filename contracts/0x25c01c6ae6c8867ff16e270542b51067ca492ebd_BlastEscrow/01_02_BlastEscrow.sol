// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BlastBet.sol";

/**
 * @title BlastEscrow
 * @dev A smart contract for playing a blast game on Telegram with ERC20 token bets.
 */
contract BlastEscrow is Ownable {
    BlastBet public token;

    struct Game {
        bool inProgress;
        uint256 totalBet;
    }

    using SafeMath for uint256;

    mapping(uint256 => Game) public games;
    address public taxAddress;
    uint256 public taxFee;
    uint256 public burnFee;

    event BetSubmitted(
        uint256 indexed gameId,
        address[] indexed playersAddress,
        uint256 totalBet
    );
    event WinnerPaid(
        uint256 indexed gameId,
        address indexed winner,
        uint256 winningAmount
    );

    constructor(
        BlastBet _tokenAddress,
        address _taxAddress,
        uint256 _taxFee,
        uint256 _burnFee
    ) {
        token = BlastBet(_tokenAddress);
        taxAddress = _taxAddress;
        taxFee = _taxFee;
        burnFee = _burnFee;
    }

    address[] public players;

    /**
     * @dev Check if there is a game in progress for a Telegram group.
     * @param _tgChatId Telegram group to check
     * @return true if there is a game in progress, otherwise false
     */
    function isGameInProgress(uint256 _tgChatId) public view returns (bool) {
        return games[_tgChatId].inProgress;
    }

    /**
     * @dev Submit bets for a new game.
     * @param gameId Identifier for the game
     * @param _players Array of player addresses
     * @param bets Array of bet amounts corresponding to players
     * @return true if bets are successfully submitted
     */
    function submitBets(
        uint256 gameId,
        address[] memory _players,
        uint256[] memory bets
    ) external onlyOwner returns (bool) {
        require(_players.length > 1, "There must be more than 1 player");
        require(_players.length == bets.length, "Array Length Doesnot Matched");

        require(areAllBetsEqual(bets), "All bet amounts must be the same");
        require(!isGameInProgress(gameId), "Game is in Progress");

        uint256 totalSum = 0;
        for (uint256 i = 0; i < _players.length; i++) {
            require(
                token.allowance(_players[i], address(this)) >= bets[i],
                "Not enough allowance"
            );
            players.push(_players[i]);
            token.transferFrom(_players[i], address(this), bets[i]);
            totalSum += bets[i];
        }
        games[gameId] = Game(true, totalSum);

        emit BetSubmitted(gameId, players, totalSum);
        return true;
    }

    /**
     * @dev Pay the winner of a game and distribute tax.
     * @param _gameId Identifier for the game
     * @param _winner Address of the winner
     */
    function payWinner(uint256 _gameId, address _winner) external onlyOwner {
        require(isGameInProgress(_gameId), "invalid GameId");
        require(isPlayerInArray(_winner), "Invalid Winner Address");

        Game storage g = games[_gameId];
        uint256 taxAmount = g.totalBet.mul(taxFee).div(100);
        uint256 burnShare = g.totalBet.mul(burnFee).div(100);
        uint256 winningAmount = g.totalBet.sub(taxAmount).sub(burnShare);
        require(
            taxAmount + winningAmount + burnShare <= g.totalBet,
            "Transfer Amount Exceed Total Share"
        );

        token.transfer(_winner, winningAmount);
        token.transfer(taxAddress, taxAmount);
        token.burn(burnShare);
        delete games[_gameId];
        delete players;

        emit WinnerPaid(_gameId, _winner, winningAmount);
    }

    /**
     * @dev Pay the winners of a game and distribute tax.
     * @param _gameId Identifier for the game
     * @param _winners Array of winner addresses
     */
    function payWinners(uint256 _gameId, address[] memory _winners) external onlyOwner {
        require(isGameInProgress(_gameId), "invalid GameId");
        require(_winners.length > 0, "There must be at least 1 winner");

        Game storage g = games[_gameId];
        uint256 taxAmount = g.totalBet.mul(taxFee).div(100);
        uint256 burnShare = g.totalBet.mul(burnFee).div(100);
        uint256 winningAmount = g.totalBet.sub(taxAmount).sub(burnShare);
        require(
            taxAmount + winningAmount + burnShare <= g.totalBet,
            "Transfer Amount Exceed Total Share"
        );

        uint256 winningAmountPerPlayer = winningAmount.div(_winners.length);
        for (uint256 i = 0; i < _winners.length; i++) {
            require(isPlayerInArray(_winners[i]), "Invalid Winner Address");
            token.transfer(_winners[i], winningAmountPerPlayer);
        }
        token.transfer(taxAddress, taxAmount);
        token.burn(burnShare);
        delete games[_gameId];
        delete players;

        emit WinnerPaid(_gameId, _winners[0], winningAmount);
    }

    /**
     * @dev Set the address for tax collection.
     * @param _taxAddress Address to receive tax
     */
    function setTaxAddress(address _taxAddress) public onlyOwner {
        taxAddress = _taxAddress;
    }

    /**
     * @dev Set the tax fee percentage.
     * @param _taxFee New tax fee percentage
     */
    function setTaxFee(uint256 _taxFee) public onlyOwner {
        taxFee = _taxFee;
    }

    /** 
     * @dev Set the burn fee percentage.
     * @param _burnFee New burn fee percentage
     */
    function setBurnFee(uint256 _burnFee) public onlyOwner {
        burnFee = _burnFee;
    }

    /**
     * @dev Check if a player address is in the players array.
     * @param _player Address to check
     * @return true if the player is in the array, otherwise false
     */
    function isPlayerInArray(address _player) private view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == _player) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Check if all bet amounts in an array are equal.
     * @param bets Array of bet amounts
     * @return true if all bets are equal, otherwise false
     */
    function areAllBetsEqual(uint256[] memory bets)
        private
        pure
        returns (bool)
    {
        if (bets.length <= 1) {
            return true;
        }

        for (uint256 i = 1; i < bets.length; i++) {
            if (bets[i] != bets[0]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Withdraw ETH balance from the contract.
     */
    function withDrawEth() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Withdraw ERC20 token balance from the contract.
     * @param _tokenAddress Address of the ERC20 token
     */
    function withDrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(msg.sender, balance);
    }

    function changeTokenAddress(address payable _tokenAddress)
        public
        onlyOwner
    {
        token = BlastBet(_tokenAddress);
    }
}