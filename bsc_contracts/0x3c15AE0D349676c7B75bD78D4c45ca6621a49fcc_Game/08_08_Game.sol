pragma solidity ^0.8.7;
//SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Game {
    address beicompany;
    address[] diceGameWinners;
    address[] coinGameWinners;

    // OPEYEMI
    using SafeERC20 for IERC20;
    // mapping that maps an address to their expected payout
    mapping(address => uint) expectedPayoutCoinGame;
    mapping(address => uint) expectedPayoutDiceGame;

    enum GameType {
        CoinGame,
        DiceGame
    }
    /*
    CoinGame = 0
    DiceGame = 1
    SoccerGame = 2
    */

    enum ResultStatus {
        Lost,
        Won
    }
    /*
    Lost = 0
    Won = 1
    */

    struct GameResults {
        address user;
        ResultStatus status;
        uint256 reward;
    }

    constructor() payable {
        beicompany = payable(msg.sender);
    }

    receive() external payable {}

    event transaction(address to, uint256 amount, uint256 balance);
    event stake(address user, GameType gameType, uint256 amount);
    modifier onlybei() {
        require(msg.sender == beicompany);
        _;
    }

    // FOR BNB
    function main_account_balace() public view returns (uint256) {
        return address(this).balance;
    }

    // FOR BUSD
    function Company_balance_BUSD(IERC20 tokens) public view returns (uint256) {
        uint256 tokenbalance = tokens.balanceOf(address(this));
        return tokenbalance;
    }

    // ################################################################################

    function payoutWinners(
        IERC20 _rewardToken,
        GameType _gameType,
        GameResults[] memory _gameResults
    ) public payable onlybei {
        if (_gameType == GameType.CoinGame) {
            for (uint256 i; i < _gameResults.length; i++) {
                if (_gameResults[i].status == ResultStatus.Won) {
                    expectedPayoutCoinGame[_gameResults[i].user] = _gameResults[
                        i
                    ].reward;
                    coinGameWinners.push(_gameResults[i].user);
                }
            }
            if (coinGameWinners.length > 0) {
                payoutFunction(_rewardToken, _gameType, coinGameWinners);
            }
            coinGameWinners = new address[](0);
        } else if (_gameType == GameType.DiceGame) {
            for (uint256 i; i < _gameResults.length; i++) {
                if (_gameResults[i].status == ResultStatus.Won) {
                    expectedPayoutDiceGame[_gameResults[i].user] = _gameResults[
                        i
                    ].reward;
                    diceGameWinners.push(_gameResults[i].user);
                }
            }
            if (diceGameWinners.length > 0) {
                payoutFunction(_rewardToken, _gameType, coinGameWinners);
            }
            diceGameWinners = new address[](0);
        }
    }

    function payoutFunction(
        IERC20 _rewardToken,
        GameType _gameType,
        address[] memory _winnersAddresses
    ) internal {
        // Loop through and send rewards to token in one transaction

        if (_gameType == GameType.CoinGame) {
            // If the game that is being paid out is coin game
            for (uint256 i; i < _winnersAddresses.length; i++) {
                _rewardToken.transfer(
                    _winnersAddresses[i],
                    expectedPayoutCoinGame[_winnersAddresses[i]]
                );
            }
        } else if (_gameType == GameType.DiceGame) {
            // If the game that is being paid out is dice game
            for (uint256 i; i < _winnersAddresses.length; i++) {
                _rewardToken.transfer(
                    _winnersAddresses[i],
                    expectedPayoutDiceGame[_winnersAddresses[i]]
                );
            }
        }
    }

    function sendProfit(IERC20 _token, uint256 _amount) public onlybei {
        _token.transfer(beicompany, _amount);
    }
}