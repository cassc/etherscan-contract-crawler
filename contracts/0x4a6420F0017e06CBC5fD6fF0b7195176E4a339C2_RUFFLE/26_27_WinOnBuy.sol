//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WinOnBuy is Ownable {
    using SafeMath for uint256;
    //Lottery
    bool public buyWinnersActive = false;
    uint256 public lastBuyAmount;
    uint256 public lastSellTax;
    //The secret number that is being used for buyorder winner and sell tax winner
    uint256 internal _secretNumber;
    //The winning chances for the different prizes
    uint256 public chanceToWinSellTax;
    uint256 public chanceToWinLastBuy;
    uint256 public chanceToWin0SellTax;
    uint256 public minimumBuyToWin = 500_000 ether;
    uint256 public totalWinners;
    uint256 public lastAmountWon;
    uint256 public totalTokensWon;
    address public lastBuyWinner;
    mapping(address => uint256) public amountWonOnBuy;
    mapping(address => bool) public won0SellTax;
    mapping(address => bool) public wonLastBuy; //to avoid that same wallet wins multiple times

    event SetBuyWinnersActive(bool buyWinnersActive);
    event SetMinBuyToWin(uint256 oldMinBuyToWin, uint256 newMinimumBuyToWin);
    event SetChanceToWinLastBuy(uint256 oldChanceToWin, uint256 newChanceToWin);
    event SetChanceToWinSellTax(uint256 oldChanceToWin, uint256 newChanceToWin);
    event SetChanceToWin0SellTax(
        uint256 oldChanceToWin,
        uint256 newChanceToWin
    );
    event LastBuyWinner(address indexed winner, uint256 indexed amountWon);
    event LastSellTaxWinner(address indexed winner, uint256 indexed amountWon);

    /// @notice Enables the possibility to win on buy
    function setBuyWinnersActive(bool _buyWinnersActive) external onlyOwner {
        require(
            buyWinnersActive != _buyWinnersActive,
            "New value is the same as current value"
        );
        buyWinnersActive = _buyWinnersActive;
        emit SetBuyWinnersActive(_buyWinnersActive);
    }

    /// @notice Change the minimum buy size to be elgible to win
    /// @param _minimumBuyToWin The new cooldown in seconds
    function setMinimumBuyToWin(uint256 _minimumBuyToWin) external onlyOwner {
        uint256 _oldMinBuy = minimumBuyToWin;
        minimumBuyToWin = _minimumBuyToWin;
        emit SetMinBuyToWin(_oldMinBuy, _minimumBuyToWin);
    }

    /// @notice Change the chance to win the amount of the last buy order (1/Chance)
    /// @param _chanceToWinLastBuy The new chance to win
    function setChanceToWinLastBuy(uint256 _chanceToWinLastBuy)
        public
        onlyOwner
    {
        require(
            _chanceToWinLastBuy >= 100,
            "_chanceToWinLastBuy must be greater than or equal to 100"
        );
        require(
            _chanceToWinLastBuy <= 500,
            "_chanceToWinLastBuy must be less than or equal to 500"
        );
        uint256 _oldChanceToWin = chanceToWinLastBuy;
        chanceToWinLastBuy = _chanceToWinLastBuy;
        emit SetChanceToWinLastBuy(_oldChanceToWin, _chanceToWinLastBuy);
    }

    /// @notice Change the chance to win the last sell tax (1/Chance)
    /// @param _chanceToWinSellTax The new chance to win the last paid sell tax
    function setChanceToWinSellTax(uint256 _chanceToWinSellTax)
        public
        onlyOwner
    {
        require(
            _chanceToWinSellTax >= 50,
            "_chanceToWinSellTax must be greater than or equal to 50"
        );
        require(
            _chanceToWinSellTax <= 200,
            "_chanceToWinSellTax must be less than or equal to 200"
        );
        uint256 _oldChanceToWin = chanceToWinSellTax;
        chanceToWinSellTax = _chanceToWinSellTax;
        emit SetChanceToWinSellTax(_oldChanceToWin, _chanceToWinSellTax);
    }

    /// @notice Change the chance to win the 0 sell tax (1/Chance)
    /// @param _chanceToWin0SellTax The new chance to win the last paid sell tax
    function setChanceToWin0SellTax(uint256 _chanceToWin0SellTax)
        public
        onlyOwner
    {
        require(
            _chanceToWin0SellTax >= 50,
            "_chanceToWin0SellTax must be greater than or equal to 50"
        );
        require(
            _chanceToWin0SellTax <= 200,
            "_chanceToWin0SellTax must be less than or equal to 200"
        );
        uint256 _oldChanceToWin = chanceToWin0SellTax;
        chanceToWin0SellTax = _chanceToWin0SellTax;
        emit SetChanceToWin0SellTax(_oldChanceToWin, _chanceToWin0SellTax);
    }

    /// @notice Returns a bool if the user wins 0 sell tax
    /// @param amount the amount that is being send. Will be used to generate a more difficult pseudo random number
    /// @param user the address for which to generate a random number
    /// @return boolean if the user has won
    function _get0SellTaxWinner(uint256 amount, address user)
        internal
        view
        returns (bool)
    {
        uint256 randomTxNumber = _getPseudoRandomNumber(
            chanceToWin0SellTax,
            amount,
            user
        );
        uint256 winningNumber = _secretNumber % chanceToWin0SellTax;
        return (winningNumber == randomTxNumber);
    }

    /// @notice Get a pseudo random number to define the tax on the transaction.
    /// @dev We can use a pseudo random number because the likelihood of gaming the random number is low because of the buy and sell tax and limited amount to be won
    /// @param chanceVariable The chance (1/Chance) to win a specific prize
    /// @return pseudoRandomNumber a pseudeo random number created from the keccak256 of the block timestamp, difficulty and msg.sender
    function _getPseudoRandomNumber(
        uint256 chanceVariable,
        uint256 amount,
        address user
    ) internal view returns (uint256 pseudoRandomNumber) {
        return
            uint256(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp + amount,
                            block.difficulty,
                            user
                        )
                    )
                )
            ).mod(chanceVariable);
    }
}