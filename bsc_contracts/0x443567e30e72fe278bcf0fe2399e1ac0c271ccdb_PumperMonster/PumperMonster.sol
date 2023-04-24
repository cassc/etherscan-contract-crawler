/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approves(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    function mint(address recipient, uint256 amount) external;
}

interface IExtraBonus {
    function getBonus(address user) external view returns (uint256);
}

library SafeMath {
    function mul(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract PumperMonsterBase {
    using SafeMath for uint;
    
    address public ownerAddress;
    address public feeAddress;
    address public tokenAddress;
    address public extraBonusAddress;
    mapping (address => bool) public accessAlloweds;
    bool public paused;

    event AccessAllowed(address indexed allowedAddress, bool allowed);

    constructor() public {
        ownerAddress = msg.sender;
        feeAddress = ownerAddress;
        tokenAddress = address(0x3926B1a235CC293153e87476046cc0036B830D21);

        paused = false;
    }

    modifier onlyOwner() { 
        require(msg.sender == ownerAddress, "only owner"); 
        _; 
    }

    modifier onlyUnpaused() { 
        require(!paused || msg.sender == ownerAddress, "paused"); 
        _; 
    }

    modifier onlyAllowed() { 
        require(accessAlloweds[msg.sender] == true || msg.sender == ownerAddress, "only allowed"); 
        _; 
    }

    function authAddress(address value) public {
        _authAddress(value);
    }

    function _authAddress(address value) private onlyOwner() {
        require(value != address(0), "address require");

        accessAlloweds[value] = !accessAlloweds[value];
        emit AccessAllowed(value, accessAlloweds[value]);
    }

    function updateAddress(uint8 id, address value) public onlyOwner() {
        if (id == 1) {
            feeAddress = value;
        } else if (id == 2) {
            tokenAddress = value;
        } else if (id == 3) {
            extraBonusAddress = value;
        }
    }

    function balanceTokens(address token) public view returns (uint balance){
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    function withdrawTokens(address token, uint value) public {
        _withdrawTokens(token, value);
    }

    function _withdrawTokens(address token, uint value) private onlyOwner() {
        if (token != address(0)) {
            if (value > 0) {
                IERC20(token).transfer(ownerAddress, value);
            } else {
                IERC20(token).transfer(ownerAddress, IERC20(token).balanceOf(address(this)));
            }
        }
    }
}

contract PumperMonster is PumperMonsterBase {
    struct User {
        uint id;
        address referral;
        bool banned;
        uint createdAt;
        uint bonus;
    }

    struct Pump {
        uint id;
        address user;
        uint amountDeposited; //BNB
        uint amountWithdrawn; //PUMPUP
        uint dailyPercent;
        uint whiteListBonus;
        uint userBonus;
        uint extraBonus;
        uint withdrawnDaysCount;
        uint createdAt;
    }

    struct Exchange {
        uint id;
        address user;
        uint price;
        uint amountReceived; //PUMPUP
        uint amountSent; //BNB
        uint exchangedAt;
    }

    struct Game {
        uint id;
        address user;
        uint multiplier;
        uint chance;
        bool winning;
        uint8 gameCount;
        uint amountBet;
        uint amountTotalBet;
        uint amountWon;
        uint amountTotalWon;
        uint amountLoss;
        uint createdAt;
    }

    mapping (address => User) public users;
    mapping (uint => address) public userIdsAddress;
    mapping (uint => Pump) public pumps;
    mapping (address => uint) public usersActivePumps;
    mapping (uint => Exchange) public exchanges;
    mapping (address => uint) public lastExchangedAt;
    mapping (address => uint) public usersActiveGames;
    mapping (uint => Game) public games;

    uint public nextUserId;
    uint public nextPumpId;
    uint public nextExchangeId;
    uint public nextGameId;
    uint public usersCount;
    uint public tokenPrice;
    uint public additionalTokenPrice;
    uint public minPumpAmount;
    uint public pumpPeriod;
    uint public pumpsCount;
    uint public depositsCount;
    uint public gamesCount;
    uint public gamePeriod;
    uint public minGameAmount;
    uint public pumpIdsWiteList;
    uint public pumpWiteListBonus;
    uint public startDate;
    uint public minExchangePercent;
    uint public maxExchangePercent;

    bool public activeDepositReferralReward;
    bool public activeWithdrawReferralReward;
    bool public activeExchange;
    bool public activeGame;
    bool public activeWiteList;
    bool public activeUserBonus;
    bool public activeExtraBonus;

    event UserAdded(address indexed user, uint indexed userId, address indexed referral, uint createdAt);
    event UserUpdated(address indexed user, address indexed referral, bool banned, uint bonus);
    event PumpCreated(address indexed user, uint indexed pumpId, uint amount, uint dailyPercent, uint whiteListBonus, uint userBonus, uint extraBonus, uint createdAt);
    event ReferralRewardTransferred(address indexed user, address indexed referral, uint indexed pumpId, uint8 line, uint amount, uint amountReward, bool deposited);
    event PumpRewardTransferred(address indexed user, uint indexed pumpId, uint dailyPercent, uint daysReward, uint amountReward, uint withdrawnAt);
    event PumpDeposited(address indexed user, uint indexed pumpId, uint dailyPercent, uint whiteListBonus, uint userBonus, uint extraBonus, uint amount, uint amountDeposited);
    event ExchangeTransferred(address indexed user, uint indexed exchangeId, uint price, uint amountReceived, uint amountSent, uint exchangedAt);
    event GameResults(address indexed user, uint indexed gameId, uint multiplier, uint chance, bool winning, uint8 gameCount, uint amountBet, uint amountWon, uint createdAt);

    constructor() public {
        nextUserId = 1;
        nextPumpId = 1;
        nextExchangeId = 1;
        nextGameId = 1;
        usersCount = 0;
        tokenPrice = 1e15; // 0.001 BNB
        additionalTokenPrice = 1e13; // 0.00001 BNB
        minPumpAmount = 1e17; // 0.1 BNB
        pumpPeriod = 1 days;
        pumpsCount = 0;
        depositsCount = 0;
        gamesCount = 0;
        gamePeriod = 1 days;
        minGameAmount = 1e18; // 1 PUMPUP
        pumpIdsWiteList = 100;
        pumpWiteListBonus = 100; // 1%
        startDate = 0;
        minExchangePercent = 10; // 10%
        maxExchangePercent = 50; // 50%

        activeDepositReferralReward = true;
        activeWithdrawReferralReward = true;
        activeExchange = true;
        activeGame = true;
        activeWiteList = true;
        activeUserBonus = true;
        activeExtraBonus = true;

        User memory user = User(nextUserId, address(0), false, block.timestamp, 100);
        users[ownerAddress] = user;
        userIdsAddress[nextUserId] = ownerAddress;
        emit UserAdded(ownerAddress, user.id, user.referral, user.createdAt);

        usersCount++;
        nextUserId++;
    }

    function updateUint(uint8 id, uint value) public onlyOwner() {
        if (id == 1) {
            tokenPrice = value;
        } else if (id == 2) {
            minPumpAmount = value;
        } else if (id == 3) {
            pumpPeriod = value;
        }  else if (id == 4) {
            gamePeriod = value;
        } else if (id == 5) {
            minGameAmount = value;
        } else if (id == 6) {
            pumpIdsWiteList = value;
        } else if (id == 7) {
            startDate = value;
        } else if (id == 8) {
            minExchangePercent = value;
        } else if (id == 9) {
            maxExchangePercent = value;
        } else if (id == 10) {
            additionalTokenPrice = value;
        } else if (id == 11) {
            pumpWiteListBonus = value;
        }
    }

    function updateBool(uint8 id) public onlyOwner() {
        if (id == 1) {
            paused = !paused;
        } else if (id == 2) {
            activeDepositReferralReward = !activeDepositReferralReward;
        } else if (id == 3) {
            activeWithdrawReferralReward = !activeWithdrawReferralReward;
        } else if (id == 4) {
            activeExchange = !activeExchange;
        } else if (id == 5) {
            activeGame = !activeGame;
        } else if (id == 6) {
            activeWiteList = !activeWiteList;
        } else if (id == 7) {
            activeUserBonus = !activeUserBonus;
        } else if (id == 8) {
            activeExtraBonus = !activeExtraBonus;
        }
    }

    fallback() external payable {
        deposit();
    }

    receive() external payable {
       deposit();
    }

    function registration() public {
        _registration(msg.sender, address(0));
    }

    function registration(address user) public {
        _registration(user, address(0));
    }

    function registration(address user, address referral) public {
        _registration(user, referral);
    }

    function _registration(address userAddress, address referralAddress) private onlyUnpaused() {
        require(userAddress != address(0), "user address require");
        require(users[userAddress].id == 0, "user exists");

        if (referralAddress == address(0) || users[referralAddress].id == 0) {
            referralAddress = userIdsAddress[1]; //admin user
        }

        User memory user = User(nextUserId, referralAddress, false, block.timestamp, 0);
        users[userAddress] = user;
        userIdsAddress[nextUserId] = userAddress;
        emit UserAdded(userAddress, user.id, user.referral, user.createdAt);

        usersCount++;
        nextUserId++;
    }

    function isUserExists(address user) public view returns (bool exists) {
        return (users[user].id != 0);
    }

    function isUserBanned(address user) public view returns (bool exists, bool banned) {
        return ((users[user].id != 0), users[user].banned);
    }

    function getUser(address user) public view returns (uint id, address referral, bool banned, uint createdAt, uint bonus) {
        return (users[user].id, users[user].referral, users[user].banned, users[user].createdAt, users[user].bonus);
    }

    function updateUser(address user, address referral, bool banned, uint bonus) public returns(bool updated) {
        return _updateUser(user, referral, banned, bonus);
    }

    function _updateUser(address user, address referral, bool banned, uint bonus) private onlyAllowed() returns(bool updated) {
        require(user != address(0), "user address require");
        require(users[user].id != 0, "user not found");

        updated = false;
        if (referral != address(0) && users[referral].id != 0 && users[user].referral != referral) {
            users[user].referral = referral;
            updated = true;
        }

        if (users[user].banned != banned) {
            users[user].banned = banned;
            updated = true;
        }

        if (users[user].bonus != bonus) {
            users[user].bonus = bonus;
            updated = true;
        }

        if (updated) {
            emit UserUpdated(user, referral, banned, bonus);
        }

        return updated;
    }

    function getPump(uint pumpId) public view returns(address user, uint dailyPercent, uint amountDeposited, uint amountWithdrawn, uint withdrawnDaysCount, uint createdAt) {
        require(pumps[pumpId].id != 0, "pump not found");

        return (pumps[pumpId].user, pumps[pumpId].dailyPercent, pumps[pumpId].amountDeposited, pumps[pumpId].amountWithdrawn, pumps[pumpId].withdrawnDaysCount, pumps[pumpId].createdAt);
    }

    function deposit() public payable {
        require(msg.value >= minPumpAmount, "invalid value");
        require(!users[msg.sender].banned, "user banned");
        if (users[msg.sender].id == 0) {
            _registration(msg.sender, address(0));
        }

        if (usersActivePumps[msg.sender] == 0) {
            _createPump(msg.sender, msg.value);
        } else {
            require(pumps[usersActivePumps[msg.sender]].user == msg.sender, "pump user different");

            _withdrawRewardsPump(usersActivePumps[msg.sender], false);

            _depositPump(usersActivePumps[msg.sender], msg.value);
        }
    }

    function deposit(address referral) public payable {
        require(msg.value >= minPumpAmount, "invalid value");
        require(!users[msg.sender].banned, "user banned");
        require(usersActivePumps[msg.sender] == 0, "pump already exists");
        if (users[msg.sender].id == 0) {
            _registration(msg.sender, referral);
        }

        _createPump(msg.sender, msg.value);
    }

    function deposit(uint pumpId) public payable {
        require(msg.value >= minPumpAmount, "invalid value");
        require(!users[msg.sender].banned, "user banned");
        require(pumps[pumpId].user == msg.sender, "pump invalid");
        require(usersActivePumps[msg.sender] == pumpId, "active pump invalid");

        _withdrawRewardsPump(pumpId, false);

        _depositPump(pumpId, msg.value);
    }

    function withdraw() public {
        require(usersActivePumps[msg.sender] > 0, "active pump invalid");
        require(pumps[usersActivePumps[msg.sender]].user == msg.sender, "pump user different");
        require(pumps[usersActivePumps[msg.sender]].id != 0, "pump not found");
        require(users[pumps[usersActivePumps[msg.sender]].user].id != 0, "user not found");
        require(!users[pumps[usersActivePumps[msg.sender]].user].banned, "user banned");

        _withdrawRewardsPump(usersActivePumps[msg.sender], true);
    }

    function withdraw(uint pumpId) public {
        require(pumps[pumpId].id != 0, "pump not found");
        if (msg.sender != ownerAddress && accessAlloweds[msg.sender] != true) {
            require(pumps[pumpId].user == msg.sender, "pump user different");
            require(usersActivePumps[msg.sender] == pumpId, "active pump invalid");
        }
        require(users[pumps[pumpId].user].id != 0, "user not found");
        require(!users[pumps[pumpId].user].banned, "user banned");


        _withdrawRewardsPump(pumpId, true);
    }

    function exchangeTokens(address user, uint amount, address token)
    public 
    onlyUnpaused()
    {
        require(amount >= 1e18, "value invalid");
        require(user != address(0), "user invalid");

        if (token == tokenAddress) {
            require(IERC20(tokenAddress).balanceOf(user) >= amount, "tokens not enough");
            require(IERC20(tokenAddress).transferFrom(user, address(this), amount), "transfer error");
            IERC20(tokenAddress).burn(amount);

            _exchange(user, amount);
        } else {
            require(IERC20(tokenAddress).transferFrom(user, address(this), amount));
        }
    }

    function gameTokens(address user, uint amount, address token, uint game)
    public 
    onlyUnpaused()
    {
        require(amount >= minGameAmount, "value invalid");
        require(user != address(0), "user invalid");

        if (token == tokenAddress) {
            require(IERC20(tokenAddress).balanceOf(user) >= amount, "tokens not enough");
            require(IERC20(tokenAddress).transferFrom(user, address(this), amount), "transfer error");
            IERC20(tokenAddress).burn(amount);

            _game(user, game, amount);
        } else {
            require(IERC20(tokenAddress).transferFrom(user, address(this), amount));
        }
    }

    function _game(address user, uint gameId, uint amount) private onlyUnpaused() {
        require(activeGame, "game inactive");
        require(users[user].id > 0, "user not found");
        require(!users[user].banned, "user banned");
        require(usersActivePumps[user] > 0, "user pump not found");

        if (gameId == 0) {
            if (usersActiveGames[user] > 0) {
                require(!games[usersActiveGames[user]].winning || games[usersActiveGames[user]].createdAt.add(gamePeriod) < block.timestamp, "active game not finished");
            } 

            (uint multiplier, uint chance) = getGameMultiplier(nextGameId);
            require(multiplier > 0 && chance > 0, "game multiplier or chance invalid");

            Game memory game = Game(nextGameId, user, multiplier, chance, false, 1, amount, amount, 0, 0, 0, block.timestamp);
            games[nextGameId] = game;
            
            uint rand = _randomMinMax(user, 0, 100);
            if (rand < chance) {
                games[nextGameId].winning = true;
                games[nextGameId].amountWon = amount.mul(multiplier).div(10);
                games[nextGameId].amountTotalWon = games[nextGameId].amountWon;
                usersActiveGames[game.user] = nextGameId;

                IERC20(tokenAddress).mint(games[nextGameId].user, games[nextGameId].amountWon);
            } else {
                games[nextGameId].winning = false;
                games[nextGameId].amountWon = 0;
                games[nextGameId].amountLoss = amount;
                usersActiveGames[game.user] = 0;
            }

            emit GameResults(games[nextGameId].user, games[nextGameId].id, games[nextGameId].multiplier, games[nextGameId].chance, games[nextGameId].winning, games[nextGameId].gameCount, games[nextGameId].amountBet, games[nextGameId].amountWon, games[nextGameId].createdAt);
        
            nextGameId++;
        } else {
            require(games[gameId].winning, "game invalid");
            require(games[gameId].user != address(0), "game not found");
            require(games[gameId].user == user, "game user different");
            require(games[gameId].createdAt.add(gamePeriod) >= block.timestamp, "game timeout");
            require(games[gameId].amountWon == amount, "game amount invalid");

            (uint multiplier, uint chance) = getGameMultiplier(gameId);
            require(multiplier > 0 && chance > 0, "game multiplier or chance invalid");
            games[gameId].multiplier = multiplier;
            games[gameId].chance = chance;
            games[gameId].amountTotalBet = games[gameId].amountTotalBet.add(amount);
            games[gameId].gameCount++;

            uint rand = _randomMinMax(user, 0, 100);
            if (rand < chance) {
                games[gameId].winning = true;
                games[gameId].amountWon = games[gameId].amountWon.mul(multiplier).div(10);
                games[gameId].amountTotalWon = games[gameId].amountTotalWon.add(games[gameId].amountWon);

                IERC20(tokenAddress).mint(games[gameId].user, games[gameId].amountWon);
            } else {
                games[gameId].winning = false;
                games[gameId].amountWon = 0;
                games[gameId].amountLoss = games[gameId].amountLoss.add(amount);
                usersActiveGames[games[gameId].user] = 0;
            }

            emit GameResults(games[gameId].user, games[gameId].id, games[gameId].multiplier, games[gameId].chance, games[gameId].winning, games[nextGameId].gameCount, games[gameId].amountBet, games[gameId].amountWon, games[gameId].createdAt);
        }

        gamesCount++;
    }

    function _exchange(address user, uint amount) private onlyUnpaused() {
        require(activeExchange, "exchange inactive");
        require(tokenPrice > 0, "token price invalid");
        require(users[user].id > 0, "user not found");
        require(!users[user].banned, "user banned");
        require(usersActivePumps[user] > 0, "active pump invalid");
        require(pumps[usersActivePumps[user]].user == user, "pump user different");

        uint amountBnb = tokenPrice.mul(amount).div(1e18);
        require(amountBnb <= address(this).balance, "exchange balance not enough");

        require(lastExchangedAt[user].add(1 days) < block.timestamp, "exchange period invalid");

        uint minExchangeAmount = pumps[usersActivePumps[user]].amountDeposited.div(100).mul(minExchangePercent); //10%
        uint availableExchangeAmount = pumps[usersActivePumps[user]].amountDeposited.div(100).mul(maxExchangePercent); //50%
        require(minExchangeAmount > 0, "min available exchange amount invalid");
        require(minExchangeAmount <= amountBnb, "min exchange amount invalid");
        require(availableExchangeAmount > 0, "available exchange amount invalid");
        require(availableExchangeAmount >= amountBnb, "exchange amount invalid");

        Exchange memory exchange = Exchange (nextExchangeId, user, tokenPrice, amount, amountBnb, block.timestamp);
        exchanges[nextExchangeId] = exchange;
        lastExchangedAt[user] = exchange.exchangedAt;

        payable(feeAddress).transfer(exchange.amountSent.div(100).mul(5));
        payable(exchange.user).transfer(exchange.amountSent);

        emit ExchangeTransferred(exchange.user, exchange.id, exchange.price, exchange.amountReceived, exchange.amountSent, exchange.exchangedAt);

        nextExchangeId++;
    }

    function _withdrawRewardsPump(uint pumpId, bool reverted) private onlyUnpaused() {
        (uint rewardDays, uint rewardAmount) = getRewardsAmount(pumpId);
        if (reverted) {
            require(rewardAmount > 0, "reward amount invalid");
            require(rewardDays > 0, "reward days invalid");
        }
        
        if (rewardAmount > 0 && rewardDays > 0) {
            pumps[pumpId].amountWithdrawn = pumps[pumpId].amountWithdrawn.add(rewardAmount);
            pumps[pumpId].withdrawnDaysCount = pumps[pumpId].withdrawnDaysCount.add(rewardDays);

            IERC20(tokenAddress).mint(feeAddress, rewardAmount.div(100).mul(5));
            IERC20(tokenAddress).mint(pumps[pumpId].user, rewardAmount);

            emit PumpRewardTransferred(pumps[pumpId].user, pumps[pumpId].id, pumps[pumpId].dailyPercent, rewardDays, rewardAmount, block.timestamp);

            if (activeWithdrawReferralReward) {
                _transferReferralRewards(pumps[pumpId].user, pumpId, rewardAmount, false);
            }
        }
    }

    function _depositPump(uint pumpId, uint amount) private onlyUnpaused() {
        pumps[pumpId].amountDeposited = pumps[pumpId].amountDeposited.add(amount);
        (uint percentage, uint whiteListBonus, uint userBonus, uint extraBonus) = getPumpPercentage(pumps[pumpId].amountDeposited, pumpId, pumps[pumpId].user);
        pumps[pumpId].dailyPercent = percentage;
        pumps[pumpId].whiteListBonus = whiteListBonus;
        pumps[pumpId].userBonus = userBonus;
        pumps[pumpId].extraBonus = extraBonus;

        emit PumpDeposited(pumps[pumpId].user, pumps[pumpId].id, pumps[pumpId].dailyPercent, pumps[pumpId].whiteListBonus, pumps[pumpId].userBonus, pumps[pumpId].extraBonus, amount, pumps[pumpId].amountDeposited);

        payable(feeAddress).transfer(amount.div(100).mul(5));

        if (activeDepositReferralReward) {
            _transferReferralRewards(pumps[pumpId].user, pumps[pumpId].id, amount, true);
        }

        depositsCount++;
        _pumpTokenPrice();
    }

    function _createPump(address user, uint amount) private onlyUnpaused() {
        (uint percentage, uint whiteListBonus, uint userBonus, uint extraBonus) = getPumpPercentage(amount, nextPumpId, user);

        uint date = block.timestamp;
        if (date < startDate) {
            date = startDate;
        }

        Pump memory pump = Pump(nextPumpId, user, amount, 0, percentage, whiteListBonus, userBonus, extraBonus, 0, date);
        pumps[nextPumpId] = pump;
        usersActivePumps[user] = nextPumpId;

        emit PumpCreated(pump.user, pump.id, pump.amountDeposited, pump.dailyPercent, pump.whiteListBonus, pump.userBonus, pump.extraBonus, pump.createdAt);

        payable(feeAddress).transfer(amount.div(100).mul(5));

        if (activeDepositReferralReward) {
            _transferReferralRewards(pump.user, nextPumpId, pump.amountDeposited, true);
        }

        nextPumpId++;
        pumpsCount++;
        depositsCount++;
        _pumpTokenPrice();
    }

    function _transferReferralRewards(address user, uint pumpId, uint amount, bool deposited) private {
        address referral = users[user].referral;

        for (uint8 line = 1; line <= 5; line++) {
            if (referral == address(0)) {
                break;
            }

            uint rewardAmount = 0;
            if (line == 1) {
                if (deposited) {
                    rewardAmount = amount.div(100).mul(15);
                } else {
                    rewardAmount = amount.div(100).mul(5);
                }
            } else if (line == 2) {
                if (deposited) {
                    rewardAmount = amount.div(100).mul(5);
                } else {
                    rewardAmount = amount.div(100).mul(2);
                }
            } else if (line == 3) {
                if (deposited) {
                    rewardAmount = amount.div(100).mul(3);
                } else {
                    rewardAmount = amount.div(100).mul(1);
                }
            }  else if (line >= 4) {
                rewardAmount = amount.div(100).mul(1);
            }

            if (rewardAmount > 0) {
                if (deposited) {
                    payable(referral).transfer(rewardAmount);
                } 
                else
                {
                    IERC20(tokenAddress).mint(referral, rewardAmount);
                }
                
                emit ReferralRewardTransferred(user, referral, pumpId, line, amount, rewardAmount, deposited);
            }

            referral = users[referral].referral;
        }
    }

    function _pumpTokenPrice() private {
        if (depositsCount < 250) {
            tokenPrice = tokenPrice.add(1e14);
        } else if (depositsCount < 500) {
            tokenPrice = tokenPrice.add(5 * 1e13);
        } else if (depositsCount < 1000) {
            tokenPrice = tokenPrice.add(25 * 1e12);
        } else {
            tokenPrice = tokenPrice.add(additionalTokenPrice); // 1e13 - 0.00001 BNB
        }
    }

    function _randomMinMax(address user, uint min, uint max) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(user, block.timestamp, tokenPrice, usersCount, gamesCount, pumpsCount, depositsCount))) % (max - min + 1) + min;
    }

    function getGameMultiplier(uint gameId) public view returns(uint multiplier, uint chance) {
        if (games[gameId].user == address(0)) {
            return (20, 45); //x2, 45%
        } else if (games[gameId].user != address(0) && !games[gameId].winning) {
            return (0, 0); //x0, 0%
        } else if (games[gameId].user != address(0) && games[gameId].winning && games[gameId].createdAt.add(gamePeriod) >= block.timestamp) {
            return (games[gameId].multiplier.add(5), games[gameId].chance.sub(5)); //+x0.5, -5%
        } else {
            return (0, 0); //x0, 0%
        }
    }

    function getRewardsAmount(uint pumpId) public view returns(uint rewardDays, uint rewardAmount) {
        require(pumps[pumpId].id != 0, "pump not found");

        if (tokenPrice == 0) {
            return (0, 0);
        }

        uint pumpDays = 0;
        if (pumps[pumpId].createdAt > 0 && block.timestamp >= startDate) {
            pumpDays = block.timestamp.sub(pumps[pumpId].createdAt).div(pumpPeriod);
        }

        if (pumpDays == 0) {
            return (0, 0);
        } else {
            pumpDays = pumpDays.sub(pumps[pumpId].withdrawnDaysCount);
            if (pumpDays == 0) {
                return (0, 0);
            }

            uint amountBnb = pumps[pumpId].amountDeposited.div(10000).mul(pumps[pumpId].dailyPercent).mul(pumpDays);
            if (amountBnb == 0) {
                return (0, 0);
            }

            rewardDays = pumpDays;
            rewardAmount = amountBnb.mul(1e18).div(tokenPrice);
        } 
    }

    function getPumpPercentage(uint amount, uint pumpId, address user) public view returns(uint percentage, uint whiteListBonus, uint userBonus, uint extraBonus) {
        if (amount >= minPumpAmount && amount < 1 * 1e18) {
            percentage = 200; //2%
        } else if (amount < 25 * 1e17) {
            percentage = 225; //2.25%
        } else if (amount < 5 * 1e18) {
            percentage = 250; //2.5%
        } else if (amount < 10 * 1e18) {
            percentage = 275; //2.75%
        } else if (amount >= 10 * 1e18) {
            percentage = 300; //3%
        } else {
            percentage = 200; //2%
        }

        if (activeWiteList && pumpId > 0 && pumpId <= pumpIdsWiteList)
        {
            percentage = percentage.add(pumpWiteListBonus); //1%
            whiteListBonus = pumpWiteListBonus;
        }

        if (activeUserBonus && user != address(0) && users[user].bonus > 0) {
            percentage = percentage.add(users[user].bonus);
            userBonus = users[user].bonus;
        }

        if (activeExtraBonus && user != address(0) && extraBonusAddress != address(0)) {
            uint extraBonuses = IExtraBonus(extraBonusAddress).getBonus(user);
            if (extraBonuses > 0) {
                percentage = percentage.add(extraBonuses); //+0.5% from Forsage/HiveBnb/Amazy
                extraBonus = extraBonuses;
            }
        }
    }
}