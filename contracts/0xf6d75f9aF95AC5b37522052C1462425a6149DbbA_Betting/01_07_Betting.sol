// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./Token.sol";
import "./feeds/ChainlinkPriceConsumer.sol";
import "./feeds/PairOracleConsumer.sol";
import "./Initializable.sol";
//import "hardhat/console.sol";

contract Betting is Ownable, Initializable {

    using SafeMath for uint;

    struct Game {
        address gamer1;
        address gamer2;

        address token1;
        address token2;

        uint amount1;
        uint amount2;

        uint latestBet;

        bool closed;
    }

    uint public referrerFee; //50%
    uint public adminFee; //50%
    uint public globalFee; //in %
    uint public transactionFee; //in USD (10^18 meanth $1))
    bool public acceptBets;

    address public eth_usd_consumer_address;
    ChainlinkPriceConsumer private eth_usd_pricer;
    uint8 private eth_usd_pricer_decimals;

    uint256 private constant PRICE_PRECISION = 1e6;

    address public manager;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    mapping(address => bool) public bots;
    mapping(address => bool) public supportBots;
    mapping(uint => Game[]) public typeGames;

    mapping(uint => uint) public typePrice;
    mapping(address => uint) public tokenPrice;
    mapping(address => address) public userReferrer;
    mapping(address => bool) public userRegistered;
    mapping(address => bool) public inGame;
    mapping(address => ChainlinkPriceConsumer) public chainlinkMapper;
    mapping(address => uint8) public chainlinkMapperDecimals;
    mapping(address => bool) isSupportedToken;
    mapping(address => bool) isStablecoin;

    uint public closeDelay = 300;
    mapping(address => uint) public turnover;

    struct PriceOracle {
        address pairOracle;
        address chainlinkOracle;
    }

    mapping(address => PriceOracle) public priceOracleMapper;
    address public feeReceiver;

    event Registration(address indexed user, address indexed referrer, bytes32 password);
    event PriceUpdated(address indexed tokenAddress, uint price);
    event NewGamer(address indexed user, uint indexed betType, uint indexed gameIndex, address tokenAddress, uint value, bool supportsBot);
    event ForcedCloseGame(address indexed user, uint indexed betType, uint indexed gameIndex, address tokenAddress, uint value);
    event ManuallyCloseGame(address indexed user, uint indexed betType, uint indexed gameIndex, address tokenAddress, uint value);
    event NewGame(uint indexed betType, uint gameIndex);
    event GameStarted(address indexed user1, address indexed user2, uint indexed betType, uint gameIndex);
    event NewGlobalFee(uint newGlobalFee);
    event NewAdminFee(uint newAdminFee);
    event NewReferrerFee(uint newReferrerFee);
    event NewTransactionFee(uint newTransactionFee);
    event GameClosed(address indexed winner, uint indexed betType, uint indexed gameIndex, uint prize1, uint prize2, uint fee);
    event NewTypePrice(uint indexed betType, uint price);

    modifier onlyManager() {
        require(msg.sender == manager, 'only manager');
        _;
    }

    modifier onlyUnlocked() {
        require(acceptBets, 'Bets locked');
        _;
    }

    modifier onlyRegistrated() {
        require(userRegistered[msg.sender] || bots[msg.sender], 'register first');  // or bot
        require(!inGame[msg.sender] || bots[msg.sender], 'already in game'); // ? or bot
        _;
    }

    function changeCloseDelay(uint256 _newDelay) public onlyOwner {
        closeDelay = _newDelay;
    }

    function lockBets() public onlyOwner {
        acceptBets = false;
    }

    function unlockBets() public onlyOwner {
        acceptBets = true;
    }

    function addBots(address[] memory _bots) public onlyOwner {
        for(uint256 i = 0; i < _bots.length; i++) {
            bots[_bots[i]] = true;
        }
    }

    function init(address _managerAddress, address _eth_usd_consumer_address, address[] memory supportedTokens, address[] memory chainlink_price_consumer_addresses, bool[] memory _isStablecoin) public initializer {
        require(supportedTokens.length == chainlink_price_consumer_addresses.length);
        require(supportedTokens.length == _isStablecoin.length);

        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

        manager = _managerAddress;
        setETHUSDOracle(_eth_usd_consumer_address);

        for(uint i = 0; i < supportedTokens.length; i++) {
            addSupportedToken(supportedTokens[i], chainlink_price_consumer_addresses[i], _isStablecoin[i], address(0));
        }

        referrerFee = 50;
        adminFee = 50;
        globalFee = 10;

        acceptBets = true;
    }

    function addSupportedToken(address _newToken, address _chainlink_price_consumer_address, bool _isStablecoin, address _pair_oracle_address) public onlyOwner {
         if (!_isStablecoin && _pair_oracle_address == address(0)) {
            chainlinkMapper[_newToken] = ChainlinkPriceConsumer(_chainlink_price_consumer_address);
            chainlinkMapperDecimals[_newToken] = chainlinkMapper[_newToken].getDecimals();
        } else if (!_isStablecoin) {
             PriceOracle memory _priceOracle = PriceOracle(_pair_oracle_address, _chainlink_price_consumer_address);
             priceOracleMapper[_newToken] = _priceOracle;
        }

        isStablecoin[_newToken] = _isStablecoin;
        isSupportedToken[_newToken] = true;
    }

    function registration(address _referrer, bytes32 _password) public {
        require(!userRegistered[msg.sender], "user already exists");
        require(_referrer != msg.sender, "refferer must not be equal to user wallet");

        userRegistered[msg.sender] = true;
        userReferrer[msg.sender] = _referrer;

        emit Registration(msg.sender, _referrer, _password);
    }

    function newManager(address _newManagerAddress) public onlyOwner {
        manager = _newManagerAddress;
    }

    function setFeeReceiver(address _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function setGlobalFee(uint _newFee) public onlyManager {
        globalFee = _newFee;
        emit NewGlobalFee(_newFee);
    }

    function setAdminFee(uint _newAdminFee) public onlyManager {
        adminFee = _newAdminFee;
        emit NewAdminFee(_newAdminFee);
    }

    function setWinnerFee(uint _newReferrerFee) public onlyManager {
        referrerFee = _newReferrerFee;
        emit NewReferrerFee(_newReferrerFee);
    }

    function setTransactionFee(uint _newTransactionFee) public onlyManager {
        transactionFee = _newTransactionFee;
        emit NewTransactionFee(_newTransactionFee);
    }

    function bet(address tokenAddress, uint t, bool supportsBot) public payable onlyRegistrated onlyUnlocked {
        require(typePrice[t] != 0, "invalid bet type");
        require(isSupportedToken[tokenAddress], "Token is not supported");
        supportBots[msg.sender] = supportsBot;
        //@todo add referrer program
        inGame[msg.sender] = true;
        if(msg.value > 0) {
            ethBet(msg.sender, t, msg.value, supportsBot);
            return;
        }

        tokenBet(msg.sender, t, tokenAddress, supportsBot);
    }

    function forcedCloseGame(uint t, uint gameIndex) public onlyManager {
        Game memory _game = typeGames[t][gameIndex];

        require(!_game.closed, "Game already closed");
        require(_game.gamer2 == address(0), "Game started already");

        typeGames[t][gameIndex].closed = true;
        inGame[_game.gamer1] = false;

        IERC20(_game.token1).transfer(_game.gamer1, _game.amount1);

        emit ForcedCloseGame(_game.gamer1, t, gameIndex, _game.token1, _game.amount1);
    }

    function manuallyCloseGame(uint t, uint gameIndex) public {
        Game memory _game = typeGames[t][gameIndex];

        require(block.timestamp >= _game.latestBet + closeDelay, "Please wait");
        require(_game.gamer1 == msg.sender, "Sender is not in the game");
        require(_game.gamer2 == address(0), "Game started already");
        require(!_game.closed, "Game already closed");

        typeGames[t][gameIndex].closed = true;
        inGame[_game.gamer1] = false;

        IERC20(_game.token1).transfer(owner(), _game.amount1 * 5 / 100); // 5% fee
        IERC20(_game.token1).transfer(_game.gamer1, _game.amount1 - _game.amount1 * 5 / 100);

        emit ManuallyCloseGame(_game.gamer1, t, gameIndex, _game.token1, _game.amount1);
    }

    function closeGame(uint t, uint gameIndex, address payable winnerAddress) public onlyManager {
        require(!typeGames[t][gameIndex].closed, "game already closed");
        require(feeReceiver != address(0), "set feeReceiver");

        Game memory _game = typeGames[t][gameIndex];
        require(winnerAddress == _game.gamer1 || winnerAddress == _game.gamer2, "invalid winner");

        typeGames[t][gameIndex].closed = true;

        inGame[_game.gamer1] = false;
        inGame[_game.gamer2] = false;

        //added turnover
        turnover[_game.gamer1] += typePrice[t];
        turnover[_game.gamer2] += typePrice[t];

        uint gameFee1 = _game.amount1.mul(globalFee).div(100);
        uint gameFee2 = _game.amount2.mul(globalFee).div(100);

        if(_game.token1 == _game.token2) {
            uint completedFee = gameFee1.add(gameFee2);
            address looserAddress = winnerAddress == _game.gamer1 ? _game.gamer2 : _game.gamer1;

            if(_game.token1 == ETH_ADDRESS) {
                if(userReferrer[winnerAddress] == address(0) && userReferrer[looserAddress] == address(0)) {
                    safeEthTransfer(feeReceiver, completedFee);
                } else if(userReferrer[winnerAddress] == address(0)) {
                    safeEthTransfer(feeReceiver, completedFee.mul(adminFee.add(referrerFee.div(2))).div(100));
                    safeEthTransfer(userReferrer[looserAddress], completedFee.mul(referrerFee.div(2)).div(100));
                } else if(userReferrer[looserAddress] == address(0)) {
                    safeEthTransfer(feeReceiver, completedFee.mul(adminFee.add(referrerFee.div(2))).div(100));
                    safeEthTransfer(userReferrer[winnerAddress], completedFee.mul(referrerFee.div(2)).div(100));
                } else {
                    safeEthTransfer(feeReceiver, completedFee.mul(adminFee).div(100));
                    safeEthTransfer(userReferrer[winnerAddress], completedFee.mul(referrerFee.div(2)).div(100));
                    safeEthTransfer(userReferrer[looserAddress], completedFee.mul(referrerFee.div(2)).div(100));
                }

                safeEthTransfer(winnerAddress, _game.amount1.add(_game.amount2).sub(completedFee));
                // address(uint160(feeReceiver)).transfer(completedFee);
                // winnerAddress.transfer(_game.amount1.add(_game.amount2).sub(completedFee));
                emit GameClosed(winnerAddress, t, gameIndex, _game.amount1.add(_game.amount2).sub(completedFee), 0, completedFee);
                return;
            }

            if(userReferrer[winnerAddress] == address(0) && userReferrer[looserAddress] == address(0)) {
                IERC20(_game.token1).transfer(address(uint160(feeReceiver)), completedFee);
            } else if(userReferrer[winnerAddress] == address(0)) {
                IERC20(_game.token1).transfer(feeReceiver, completedFee.mul(adminFee.add(referrerFee.div(2))).div(100));
                IERC20(_game.token1).transfer(userReferrer[looserAddress], completedFee.mul(referrerFee.div(2)).div(100));
            } else if(userReferrer[looserAddress] == address(0)) {
                IERC20(_game.token1).transfer(feeReceiver, completedFee.mul(adminFee.add(referrerFee.div(2))).div(100));
                IERC20(_game.token1).transfer(userReferrer[winnerAddress], completedFee.mul(referrerFee.div(2)).div(100));
            } else {
                IERC20(_game.token1).transfer(feeReceiver, completedFee.mul(adminFee).div(100));
                IERC20(_game.token1).transfer(userReferrer[winnerAddress], completedFee.mul(referrerFee.div(2)).div(100));
                IERC20(_game.token1).transfer(userReferrer[looserAddress], completedFee.mul(referrerFee.div(2)).div(100));
            }

            IERC20(_game.token1).transfer(winnerAddress, _game.amount1.add(_game.amount2).sub(completedFee));
            emit GameClosed(winnerAddress, t, gameIndex, _game.amount1.add(_game.amount2).sub(completedFee), 0, completedFee);
            return;
        }

        uint totalFee1 = gameFee1;

        internalTransfer(winnerAddress, winnerAddress == _game.gamer1 ? _game.gamer2 : _game.gamer1, _game.token1, _game.amount1, totalFee1.mul(2));
        internalTransfer(winnerAddress, winnerAddress == _game.gamer1 ? _game.gamer2 : _game.gamer1, _game.token2, _game.amount2, 0);

        emit GameClosed(winnerAddress, t, gameIndex, _game.amount1.sub(totalFee1), _game.amount2, totalFee1);
    }

    function internalTransfer(address payable winnerAddress, address looserAddress, address tokenAddress, uint value, uint fee) internal {
        if(tokenAddress == ETH_ADDRESS) {
            if(fee != 0) {
                if(userReferrer[winnerAddress] == address(0) && userReferrer[looserAddress] == address(0)) {
                    safeEthTransfer(owner(), fee.mul(adminFee.add(referrerFee)).div(100));
                } else if(userReferrer[winnerAddress] == address(0)) {
                    safeEthTransfer(owner(), fee.mul(adminFee.add(referrerFee.div(2))).div(100));
                    safeEthTransfer(userReferrer[looserAddress], fee.mul(referrerFee.div(2)).div(100));
                } else if(userReferrer[looserAddress] == address(0)) {
                    safeEthTransfer(owner(), fee.mul(adminFee.add(referrerFee.div(2))).div(100));
                    safeEthTransfer(userReferrer[winnerAddress], fee.mul(referrerFee.div(2)).div(100));
                } else {
                    safeEthTransfer(owner(), fee.mul(adminFee).div(100));
                    safeEthTransfer(userReferrer[winnerAddress], fee.mul(referrerFee.div(2)).div(100));
                    safeEthTransfer(userReferrer[looserAddress], fee.mul(referrerFee.div(2)).div(100));
                }
            }
            safeEthTransfer(winnerAddress, value.sub(fee));
            return;
        }

        if(fee != 0) {
            if(userReferrer[winnerAddress] == address(0) && userReferrer[looserAddress] == address(0)) {
                IERC20(tokenAddress).transfer(owner(), fee.mul(adminFee.add(referrerFee)).div(100));
            } else if(userReferrer[winnerAddress] == address(0)) {
                IERC20(tokenAddress).transfer(owner(), fee.mul(adminFee.add(referrerFee.div(2))).div(100));
                IERC20(tokenAddress).transfer(userReferrer[looserAddress], fee.mul(referrerFee.div(2)).div(100));
            } else if(userReferrer[looserAddress] == address(0)) {
                IERC20(tokenAddress).transfer(owner(), fee.mul(adminFee.add(referrerFee.div(2))).div(100));
                IERC20(tokenAddress).transfer(userReferrer[winnerAddress], fee.mul(referrerFee.div(2)).div(100));
            } else {
                IERC20(tokenAddress).transfer(owner(), fee.mul(adminFee).div(100));
                IERC20(tokenAddress).transfer(userReferrer[winnerAddress], fee.mul(referrerFee.div(2)).div(100));
                IERC20(tokenAddress).transfer(userReferrer[looserAddress], fee.mul(referrerFee.div(2)).div(100));
            }
        }
        IERC20(tokenAddress).transfer(winnerAddress, value.sub(fee));
    }

    function ethBet(address user, uint t, uint ethValue, bool _supportsBot) internal {
        uint256 eth_usd_price = uint256(eth_usd_pricer.getLatestPrice()) * (PRICE_PRECISION) / (uint256(10) ** eth_usd_pricer_decimals);
        require(uint(1e18).mul(typePrice[t]).div(eth_usd_price) >= ethValue, "invalid type or msg.value");

        if (typeGames[t].length == 0) {
            newGame(user, t, ETH_ADDRESS, ethValue, _supportsBot);
            return;
        }

        // added closed check
        if (typeGames[t][typeGames[t].length-1].gamer2 == address(0) && !typeGames[t][typeGames[t].length-1].closed) {
            if(!_supportsBot) {
                require(!bots[typeGames[t][typeGames[t].length-1].gamer1], "User doesn't support bots");
            }

            if(!supportBots[typeGames[t][typeGames[t].length-1].gamer1]) {
                require(!bots[user], "User doesn't support bots");
            }

            typeGames[t][typeGames[t].length-1].gamer2 = user;
            typeGames[t][typeGames[t].length-1].token2 = ETH_ADDRESS;
            typeGames[t][typeGames[t].length-1].amount2 = ethValue;
            typeGames[t][typeGames[t].length-1].latestBet = block.timestamp;

            emit NewGamer(user, t, typeGames[t].length-1, ETH_ADDRESS, ethValue, _supportsBot);
            emit GameStarted(typeGames[t][typeGames[t].length-1].gamer1, typeGames[t][typeGames[t].length-1].gamer2, t, typeGames[t].length-1);
            return;
        }

        newGame(user, t, ETH_ADDRESS, ethValue, _supportsBot);
    }

    function tokenBet(address user, uint t, address tokenAddress, bool _supportsBot) internal {
        uint256 token_usd_price;
        uint decimals = IERC20(tokenAddress).decimals();
        uint tokenValue;

        if(isStablecoin[tokenAddress]) {
            token_usd_price = PRICE_PRECISION;
            tokenValue = (10 ** decimals).mul(typePrice[t]).div(token_usd_price);
        } else if (priceOracleMapper[tokenAddress].pairOracle != address(0) && priceOracleMapper[tokenAddress].chainlinkOracle != address(0)) {
            uint chain_link_price = uint256(ChainlinkPriceConsumer(priceOracleMapper[tokenAddress].chainlinkOracle).getLatestPrice());
            uint chain_link_decimals = uint256(ChainlinkPriceConsumer(priceOracleMapper[tokenAddress].chainlinkOracle).getDecimals());
            uint chain_link_price_reverte = (10 ** chain_link_decimals) * PRICE_PRECISION / chain_link_price;
            PairOracleConsumer pair_oracle = PairOracleConsumer(priceOracleMapper[tokenAddress].pairOracle);
            address pairToken = pair_oracle.token0() == tokenAddress ? pair_oracle.token1() : pair_oracle.token0();
            uint token_usd_price = PairOracleConsumer(priceOracleMapper[tokenAddress].pairOracle).consult(pairToken, chain_link_price_reverte);
            // decimals of tokenAddress or pairToken
            uint token_decimals = ERC20(pairToken).decimals();
            uint token_with_decimals = (10 ** token_decimals / PRICE_PRECISION) * token_usd_price;
            tokenValue = token_with_decimals * t;
        } else if (priceOracleMapper[tokenAddress].pairOracle != address(0) && priceOracleMapper[tokenAddress].chainlinkOracle == address(0)) {
            //pair with stable token
            PairOracleConsumer pair_oracle = PairOracleConsumer(priceOracleMapper[tokenAddress].pairOracle);
            address stableToken = pair_oracle.token0() == tokenAddress ? pair_oracle.token1(): pair_oracle.token0();
            uint stableDecimals = IERC20(stableToken).decimals();
            token_usd_price = pair_oracle.consult(stableToken, 10 ** stableDecimals);
            tokenValue = token_usd_price * t;
        } else {
            token_usd_price = uint256(chainlinkMapper[tokenAddress].getLatestPrice()) * (PRICE_PRECISION) / (uint256(10) ** chainlinkMapperDecimals[tokenAddress]);
            tokenValue = (10 ** decimals).mul(typePrice[t]).div(token_usd_price);
        }
        IERC20(tokenAddress).transferFrom(user, address(this), tokenValue);

        if (typeGames[t].length == 0) {
            newGame(user, t, tokenAddress, tokenValue, _supportsBot);
            return;
        }

        if (typeGames[t][typeGames[t].length-1].gamer2 == address(0) && !typeGames[t][typeGames[t].length-1].closed) {
            if(!_supportsBot && bots[typeGames[t][typeGames[t].length-1].gamer1]) {
                if(typeGames[t][typeGames[t].length-2].gamer2 == address(0) && !typeGames[t][typeGames[t].length-2].closed) {
                    _joinGame(t, user, tokenAddress, tokenValue, 2, _supportsBot);
                    return;
                }
                newGame(user, t, tokenAddress, tokenValue, _supportsBot);
                return;
            }

            if(!supportBots[typeGames[t][typeGames[t].length-1].gamer1] && bots[user]) {
                newGame(user, t, tokenAddress, tokenValue, _supportsBot);
                return;
            }

            if(bots[typeGames[t][typeGames[t].length-1].gamer1] && typeGames[t][typeGames[t].length-2].gamer2 == address(0) && !typeGames[t][typeGames[t].length-2].closed) {
                _joinGame(t, user, tokenAddress, tokenValue, 2, _supportsBot);
                return;
            }

            _joinGame(t, user, tokenAddress, tokenValue, 1, _supportsBot);
            return;
        }

        newGame(user, t, tokenAddress, tokenValue, _supportsBot);
    }

    function _joinGame(uint t, address user, address tokenAddress, uint tokenValue, uint _sub, bool _supportsBot) internal {
        require(typeGames[t][typeGames[t].length-_sub].gamer1 != user, 'double registration');
        typeGames[t][typeGames[t].length-_sub].gamer2 = user;
        typeGames[t][typeGames[t].length-_sub].token2 = tokenAddress;
        typeGames[t][typeGames[t].length-_sub].amount2 = tokenValue;
        typeGames[t][typeGames[t].length-_sub].latestBet = block.timestamp;

        emit NewGamer(user, t, typeGames[t].length-_sub, tokenAddress, tokenValue, _supportsBot);
        emit GameStarted(typeGames[t][typeGames[t].length-_sub].gamer1, typeGames[t][typeGames[t].length-_sub].gamer2, t, typeGames[t].length-_sub);
        return;
    }

    function newGame(address user, uint t, address tokenAddress, uint value, bool _supportsBot) internal {
        typeGames[t].push(Game(user, address(0), tokenAddress, address(0), value, 0, block.timestamp, false));

        emit NewGame(t, typeGames[t].length-1);
        emit NewGamer(user, t, typeGames[t].length-1, tokenAddress, value, _supportsBot);
    }

    function updateTokenPrice(address tokenAddress, uint price) public onlyManager {
        // example for 1 USD as basic price
        // 1 USD mean 10*18 usdt/usdc or any stablecoin with 18 decimals
        // 1 USD mean 8705 renBTC (8 decimals $11,283 price)
        // 1 USD mean 274710000000000000 UNI(18 decimals, $3.39 price)
        // etc

        tokenPrice[tokenAddress] = price;
        emit PriceUpdated(tokenAddress, price);
    }

    function setTypePrice(uint betType, uint price) public onlyManager {
        typePrice[betType] = price;
        emit NewTypePrice(betType, price);
    }

    function safeEthTransfer(address to, uint value) private {
        if(!address(uint160(to)).send(value)) {
            address(uint160(owner())).transfer(value);
        }
    }

    function setETHUSDOracle(address _eth_usd_consumer_address) public onlyOwner {
        eth_usd_consumer_address = _eth_usd_consumer_address;
        eth_usd_pricer = ChainlinkPriceConsumer(_eth_usd_consumer_address);
        eth_usd_pricer_decimals = eth_usd_pricer.getDecimals();
    }
}