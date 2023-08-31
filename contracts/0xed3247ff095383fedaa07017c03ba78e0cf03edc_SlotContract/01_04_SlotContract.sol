// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SlotContract is Ownable {
    address public revenueWallet;
    IERC20 public bettingToken;
    IERC20 public WETH;
    uint256 public immutable minimumBet;
    uint256 public immutable revenueBps;

    constructor(
        address _bettingToken,
        address _WETH,
        uint256 _minimumBet,
        uint256 _revenueBps,
        address _revenueWallet
    ) {
        revenueWallet = _revenueWallet;
        revenueBps = _revenueBps;
        bettingToken = IERC20(_bettingToken);
        WETH = IERC20(_WETH);
        minimumBet = _minimumBet;
    }

    struct Game {
        uint256 minBet;
        uint256[] betAmounts;
        address[] players;
        bool inProgress;
        uint16 loser;
    }

    mapping(int64 => Game) public games;
    int64[] public activeTgGroups;

    event Bet(int64 tgChatId, address player, uint256 amount);
    event Win(int64 tgChatId, address player, uint256 amount);
    event Loss(int64 tgChatId, address player, uint256 amount);
    event Revenue(int64 tgChatId, uint256 amount);

    function isGameInProgress(int64 _tgChatId) public view returns (bool) {
        return games[_tgChatId].inProgress;
    }

    function removeTgId(int64 _tgChatId) internal {
        for (uint256 i = 0; i < activeTgGroups.length; i++) {
            if (activeTgGroups[i] == _tgChatId) {
                activeTgGroups[i] = activeTgGroups[activeTgGroups.length - 1];
                activeTgGroups.pop();
            }
        }
    }

    function newGame(
        int64 _tgChatId,
        uint256 _minBet,
        address[] memory _players,
        uint256[] memory _bets,
        bool useWETH
    ) public returns (uint256[] memory) {
        require(
            _players.length == _bets.length,
            "Players/bets length mismatch"
        );
        require(
            !isGameInProgress(_tgChatId),
            "There is already a game in progress"
        );

        uint256 betTotal = 0;
        for (uint16 i = 0; i < _bets.length; i++) {
            require(_bets[i] >= _minBet, "Bet is smaller than the minimum");
            betTotal += _bets[i];
        }

        IERC20 chosenToken = useWETH ? WETH : bettingToken;

        for (uint16 i = 0; i < _bets.length; i++) {
            require(
                chosenToken.allowance(_players[i], address(this)) >= _bets[i],
                "Not enough allowance"
            );
            bool isSent = chosenToken.transferFrom(
                _players[i],
                address(this),
                _bets[i]
            );
            require(isSent, "Funds transfer failed");

            emit Bet(_tgChatId, _players[i], _bets[i]);
        }

        Game memory g;
        g.minBet = _minBet;
        g.betAmounts = _bets;
        g.players = _players;
        g.inProgress = true;

        games[_tgChatId] = g;
        activeTgGroups.push(_tgChatId);

        return _bets;
    }

    function endGame(
        int64 _tgChatId,
        address _winner,
        bool usedWETH
    ) public onlyOwner {
        require(
            isGameInProgress(_tgChatId),
            "No game in progress for this Telegram chat ID"
        );

        Game storage g = games[_tgChatId];
        require(g.inProgress, "Game is not in progress");

        g.inProgress = false;
        removeTgId(_tgChatId);

        uint256 totalBets = 0;
        for (uint16 i = 0; i < g.betAmounts.length; i++) {
            totalBets += g.betAmounts[i];
        }

        uint256 revenueShare = (totalBets * revenueBps) / 10000; // Calculate revenue share
        uint256 winnings = totalBets - revenueShare;

        IERC20 chosenToken = usedWETH ? WETH : bettingToken;

        // Transfer winnings to the winner
        chosenToken.transfer(_winner, winnings);
        emit Win(_tgChatId, _winner, winnings);

        // Transfer revenue share to the revenue wallet (funding wallet)
        chosenToken.transfer(revenueWallet, revenueShare);
        emit Revenue(_tgChatId, revenueShare);
    }

    function abortGame(int64 _tgChatId, bool usedWETH) public onlyOwner {
        require(
            isGameInProgress(_tgChatId),
            "No game in progress for this Telegram chat ID"
        );
        Game storage g = games[_tgChatId];

        IERC20 chosenToken = usedWETH ? WETH : bettingToken;

        for (uint16 i = 0; i < g.players.length; i++) {
            bool isSent = chosenToken.transfer(g.players[i], g.betAmounts[i]);
            require(isSent, "Funds transfer failed");
        }

        g.inProgress = false;
        removeTgId(_tgChatId);
    }

    function abortAllGames(bool usedWETH) public onlyOwner {
        int64[] memory _activeTgGroups = activeTgGroups;
        for (uint256 i = 0; i < _activeTgGroups.length; i++) {
            abortGame(_activeTgGroups[i], usedWETH);
        }
    }

    function setBettingToken(address _newBettingToken) public onlyOwner {
        require(_newBettingToken != address(0), "Invalid token address");
        bettingToken = IERC20(_newBettingToken);
    }

    function setrevenueWallet(address _revenueWallet) public onlyOwner {
        revenueWallet = address(_revenueWallet);
    }

    function setWETH(address _newWETH) public onlyOwner {
        require(_newWETH != address(0), "Invalid token address");
        WETH = IERC20(_newWETH);
    }

    function emergencyWithdrawERC20(address tokenAddress, address to)
        external
        onlyOwner
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "No tokens to withdraw");

        token.transfer(to, tokenBalance);
    }

    function emergencyWithdrawEther(address payable to) external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No Ether to withdraw");

        (bool success, ) = to.call{value: contractBalance}("");
        require(success, "Withdraw failed");
    }
}