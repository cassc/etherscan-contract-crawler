// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./structs/Structs.sol";

contract WorldCupQuiz is Ownable, ReentrancyGuard {
    mapping(uint256 => Game) public games;

    mapping(address => uint256[]) public createdGames;
    mapping(address => uint256) public tickets;
    mapping(address => bool) public banned;
    mapping(address => uint256) public earnings;
    mapping(address => address) public referrals;

    // Influencers cannot change after the first ticket is bought
    address[] public influencers;
    uint256[] public influencersPercents;

    bool public allowRefunds = false;

    uint256 public poolCount;

    uint256 public ticketPrice = 1 ether; // 1 USDT

    uint256 public minBuyIn = 1;
    uint256 public worldCupStartTime = 1668956400; // 2022-11-20 03:00:00 PM GMT

    address public server;
    address private adminSigner;

    uint256[10] percentages = [21, 17, 14, 12, 10, 8, 6, 5, 4, 3];
    uint256 public teamFunds = 0;

    // constructor
    constructor (
        address _server,
        address _adminSigner,
        uint256 _ticketPrice,
        uint256 _minBuyIn
    ) {
        server = _server;
        adminSigner = _adminSigner;
        ticketPrice = _ticketPrice;
        minBuyIn = _minBuyIn;
    }

    modifier onlyServer() {
        require(msg.sender == server, "Only server can call this function.");
        _;
    }



    function buyTicket(address _recipient, uint256 _amount, address _referrer) public payable {
        require(_recipient != address(0), "Recipient cannot be 0 address");
        require(_amount > 0, "Amount must be greater than 0");
        require(msg.value == _amount * ticketPrice, "Incorrect amount of ETH sent");
        if (referrals[_recipient] != address(0)) {
            require(referrals[_recipient] == _referrer, "Referrer cannot change");
        } else {
            referrals[_recipient] = _referrer;
        }

        uint256 totalPercent = 0;
        if (referrals[_recipient] != address(0)) {
            earnings[_referrer] += _amount * ticketPrice * 10 / 100;
            totalPercent += 10;
        }
        for (uint256 i = 0; i < influencers.length; i++) {
            uint256 percent = influencersPercents[i];
            earnings[influencers[i]] += _amount * ticketPrice * percent / 100;
            totalPercent += percent;
        }
        teamFunds += _amount * ticketPrice * (80 - totalPercent) / 100; // 40-80% of the ticket price goes to the team
        tickets[_recipient] += _amount;
    }

    function refundTicket(uint256 _amount) public {
        require(allowRefunds, "Refunds are not allowed at this time");
        require(_amount > 0, "Amount must be greater than 0");
        require(tickets[msg.sender] >= _amount, "Insufficient tickets");
        _sendFunds(msg.sender, _amount * ticketPrice);

        uint256 totalPercent = 0;
        if(referrals[msg.sender] != address(0)) {
            earnings[referrals[msg.sender]] -= _amount * ticketPrice * 10 / 100;
            totalPercent += 10;
        }
        for (uint256 i = 0; i < influencers.length; i++) {
            uint256 percent = influencersPercents[i];
            earnings[influencers[i]] -= _amount * ticketPrice * percent / 100;
            totalPercent += percent;
        }
        teamFunds -= _amount * ticketPrice * (80 - totalPercent) / 100;
        tickets[msg.sender] -= _amount;
    }



    function createGame(uint256 _serverGameId, uint256 _ticketsRequired, Authorization memory _authorization) public {
        require(_ticketsRequired >= minBuyIn, "Tickets required must be greater than min buy in");
        if (msg.sender != server) {
            require(_ticketsRequired > 0, "Tickets required must be greater than 0");
            require(tickets[msg.sender] >= _ticketsRequired, "Insufficient tickets");
            require(createdGames[msg.sender].length == 0, "You already have an ongoing/upcoming game scheduled");
            bytes32 digest = keccak256(abi.encode(_serverGameId, msg.sender));
            require(_isVerifiedCoupon(digest, _authorization), 'Invalid authorization');
        }

        _createGame(_serverGameId, _ticketsRequired, msg.sender != server);
        createdGames[msg.sender].push(_serverGameId);
    }

    function startGame(uint256 gameId) public onlyServer {
        require(games[gameId]._exists, "Game does not exist");
        require(!games[gameId].started, "Game already started");
        require(games[gameId].entryCount > 0, "Game has no entries");

        games[gameId].started = true;
        games[gameId].prize = games[gameId].entryCount * games[gameId].buyIn * ticketPrice * 10 / 100;
        games[gameId].timestamp = block.timestamp;
    }

    function endGame(uint256 gameId, address winner, address[] memory top10) public onlyServer {
        require(games[gameId]._exists, "Game does not exist");
        require(games[gameId].started, "Game not started");
        require(!games[gameId].ended, "Game already ended");
        require(games[gameId].entries[winner], "Winner not in game");

        earnings[winner] += games[gameId].prize;
        uint256 top10Prize = games[gameId].prize * 10 / 100;
        for (uint256 i = 0; i < top10.length; i++) {
            // Top 10 prize is split 21% - 17% - 14% - 12% - 10% - 8% - 6% - 5% - 4% - 3%
            // top10 is sorted by points, so the first element is the 2nd place
            earnings[top10[i]] += top10Prize * percentages[i] / 100;
        }
        games[gameId].ended = true;
        games[gameId].winner = winner;
    }

    function joinGame(uint256 _gameId) public {
        require(games[_gameId]._exists, "Invalid game id");
        require(!games[_gameId].started, "Game started");
        require(!banned[msg.sender], "You are banned");
        require(!games[_gameId].kicked[msg.sender], "You have been kicked from this game");

        require(tickets[msg.sender] >= games[_gameId].buyIn, "Insufficient tickets");
        tickets[msg.sender] -= games[_gameId].buyIn;
        games[_gameId].entries[msg.sender] = true;
        games[_gameId].entryCount++;
    }

    function leaveGame(uint256 _gameId) public {
        _removeFromSession(msg.sender, _gameId);
    }


    function claimFunds() public {
        require(earnings[msg.sender] > 0, "No funds to claim");
        uint256 amount = earnings[msg.sender];
        earnings[msg.sender] = 0;
        _sendFunds(msg.sender, amount);
    }
    function claimRemainingFunds(address _to) public onlyOwner {
        uint256 amount = teamFunds;
        teamFunds = 0;
        _sendFunds(_to, amount);
    }
    function claimFundsFor(address _earner) public onlyOwner {
        require(earnings[_earner] > 0, "No funds to claim");
        uint256 amount = earnings[_earner];
        earnings[_earner] = 0;
        _sendFunds(_earner, amount);
    }



    function kickFromGame(address _player, uint256 _gameId) public onlyServer {
        _removeFromSession(_player, _gameId);
        games[_gameId].kicked[_player] = true;
    }

    function ban(address _player, bool _status) public onlyServer {
        banned[_player] = _status;
    }


    function _removeFromSession(address _player, uint256 _gameId) internal {
        require(games[_gameId]._exists, "Invalid game id");
        require(!games[_gameId].started, "Game started");
        require(games[_gameId].entries[_player], "Not in game");
        games[_gameId].entries[_player] = false;
        games[_gameId].entryCount--;
    }
    function _createGame(uint256 _serverGameId, uint256 _ticketsRequired, bool _includeCreator) internal {
        games[_serverGameId].id = _serverGameId;
        games[_serverGameId].buyIn = _ticketsRequired;
        games[_serverGameId].timestamp = block.timestamp;
        games[_serverGameId]._exists = true;

        if(_includeCreator){
            games[_serverGameId].entries[msg.sender] = true;
            games[_serverGameId].entryCount++;
        }
    }
    function _isVerifiedCoupon(bytes32 _digest, Authorization memory _auth) internal view returns (bool) {
        address signer = ecrecover(_digest, _auth.v, _auth.r, _auth.s);
        require(signer != address(0), 'ECDSA: invalid signature');
        return signer == adminSigner;
    }
    function _sendFunds(address _to, uint256 _amount) internal nonReentrant {
        (bool os, ) = payable(_to).call{value: _amount}("");
        require(os);
    }



    function emergencyOverrideTickets(address _user, uint256 _amount) public onlyOwner {
        tickets[_user] = _amount;
    }
    function emergencyRefund(address _player, uint256 _amount) public onlyOwner {
        _sendFunds(_player, _amount * ticketPrice);
        tickets[msg.sender] -= _amount;
    }
    function setServer(address _server) public onlyOwner {
        server = _server;
    }
    function setAdminSigner(address _adminSigner) public onlyOwner {
        adminSigner = _adminSigner;
    }
    function updateTicketPrice(uint256 _ticketPrice) public onlyOwner {
        ticketPrice = _ticketPrice;
    }
    function addInfluencers(address[] memory _influencers, uint256[] memory _percentages) public onlyOwner {
        require(_influencers.length == _percentages.length, "Invalid input");
        for (uint256 i = 0; i < _influencers.length; i++) {
            addInfluencer(_influencers[i], _percentages[i]);
        }
    }
    function addInfluencer(address _influencer, uint256 percentage) public onlyOwner {
        influencers.push(_influencer);
        influencersPercents.push(percentage);
    }
    function removeInfluencer(address _influencer) public onlyOwner {
        for (uint256 i = 0; i < influencers.length; i++) {
            if (influencers[i] == _influencer) {
                influencers[i] = influencers[influencers.length - 1];
                influencers.pop();
                influencersPercents[i] = influencersPercents[influencersPercents.length - 1];
                influencersPercents.pop();
                break;
            }
        }
    }
}