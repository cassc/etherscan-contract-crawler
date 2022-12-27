// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// Imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "./VRFv2Consumer.sol";

uint constant MAX_BPS = 10_000;

/// @title CoffeeShop project contract
contract CoffeeShop is Ownable {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // Events
    event Coffeed(
        address user,
        address refadr,
        uint refCoffeeNum,
        uint amount,
        uint refund,
        uint links,
        uint coffeeman,
        uint lottery,
        uint fund,
        uint128 btcRate
    );
    event Widthdraw(address user, uint number, uint amount, uint price);
    event Lottery(uint num, address user, uint bank);

    /// Variables
    Counters.Counter _coffeeBeansCounter; // Coffees number counter
    Counters.Counter _refundsCounter; // Refunded coffees number counter
    bool private locker; // To prevent reentrancy attacks
    bool _final = false; // End game indicator
    uint public timer; // Timer, set after the completing of the game (so that users can collect their compensation)
    uint private _waitingTime; // The number of days set for the timer
    uint private _depositAmount; // Coffee amount
    address private _usd; // Currency token address
    address private _bitcoin; // Reserved token address
    address private _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // DEX router address
    address private _vrf = 0x8933e5FE1160966d17bdd0dA993FF282C9500F9a; // Randomizer generator contract address
    uint private _percentageOwner; // Owner's share (в BP, 1% = 100bp)
    uint private _percentageShop; // Shop share (в BP, 1% = 100bp)
    uint private _percentageLottery;  // Lottery share (в BP, 1% = 100bp)
    uint private _percentageCoffeeman;  // Referal share (в BP, 1% = 100bp)
    uint private _percentageFund; // Fund share (в BP, 1% = 100bp)
    uint private _bankLottery; // Lottery bank
    uint private _bankOwner; // Owner's bank
    uint private _bankShop;  // Shop bank
    uint private _bankFund; // Fund's bank
    uint private _randomNum; // The random number received from another contract
    uint private _startLotteryNum; // The coffee number from which a round of the lottery starts
    uint private _discountsNum; // Number of discounts
    mapping(uint => address) private _payments; // Mapping coffee number with contributor address
    mapping(uint => uint) private _multi;  // Mapping coffee number with multiplier
    mapping(address => CoffeeBean) private _coffeeBeans; // Mapping contributor address with the coffeeBean structure


    /// Structurs
    struct Coffee {
        uint128 _price; // Coffee price
        uint128 _to_fund; // USD amount sent to fund
        uint128 _btc_rate; // BTC rate when the coffee was buyCoffeed
        uint128 _coffeemans_left; // Coffeemans left
        uint128 _coffeemans_closed; // Coffeemans closed
        bool _gifted; // Is coffee gifted
    }

    struct CoffeeBean {
        mapping(uint => Coffee) _coffees; // Mapping user's coffeeBean number with the coffee structure
        Counters.Counter _coffeesCounter; // User's coffees counter
    }

    /// Constructor
    constructor(address usd, address bitcoin, uint waitingTime, uint depositAmount,
        uint percentageOwner, uint percentageShop, uint percentageLottery, uint percentageCoffeeman, uint percentageFund, uint numDiscounts) {
        _usd = usd;
        _bitcoin = bitcoin;
        _waitingTime = waitingTime;
        _depositAmount = depositAmount;
        _percentageOwner = percentageOwner;
        _percentageShop = percentageShop;
        _percentageLottery = percentageLottery;
        _percentageCoffeeman = percentageCoffeeman;
        _percentageFund = percentageFund;
        _discountsNum = numDiscounts;
    }

    /// @notice Getting sum Bank of Fund
    /// @return (uint)
    function getActiveCoffeemans(address account, uint coffee) external view onlyOwner returns (uint){
        return _coffeeBeans[account]._coffees[coffee]._coffeemans_left;
    }

    /// @notice Getting count of account coffees
    /// @return (uint)
    function getCountCoffee(address account) external view returns (uint){
        return _coffeeBeans[account]._coffeesCounter.current();
    }
    /// @notice Getting account coffee by number
    /// @return (uint)
    function getCoffee(address account, uint num) external view returns (Coffee memory){
        return _coffeeBeans[account]._coffees[num];
    }
    /// @notice Get lottery random number
    function getRandomNum() public view returns (uint){
        return _randomNum;
    }
    /// @notice Get amount of discounts
    function getNumSales() external view returns (uint){
        return _discountsNum;
    }
    /// @notice Get share buyCoffee
    /// @param multi - Coffeemans amount - 1
    function getShare(uint multi) internal view returns (uint, uint, uint, uint, uint, uint, uint){
        if (multi == 1) {
            uint _shareFond = _depositAmount * _percentageFund / MAX_BPS;
            uint _shareCoffeeman = _depositAmount * _percentageCoffeeman / MAX_BPS;
            uint _shareLottery = _depositAmount * _percentageLottery / MAX_BPS;
            uint _shareShop = _depositAmount * _percentageShop / MAX_BPS;
            uint _shareOwner = _depositAmount * _percentageOwner / MAX_BPS;
            uint _refund;
            return (_depositAmount, _shareFond, _shareCoffeeman, _shareLottery, _shareShop, _shareOwner, _refund);
        } else {
            uint _amountGen = multi * _depositAmount;
            uint _shareFond = _amountGen * _percentageFund / MAX_BPS;
            uint _shareCoffeeman = _depositAmount * _percentageCoffeeman / MAX_BPS;
            uint _shareLottery = _amountGen * _percentageLottery / MAX_BPS;
            uint _shareShop = _amountGen * _percentageShop / MAX_BPS;
            uint _shareOwner = _amountGen * _percentageOwner / MAX_BPS;
            uint _refund = (_amountGen * _percentageCoffeeman / MAX_BPS) - _shareCoffeeman;
            return (_amountGen, _shareFond, _shareCoffeeman, _shareLottery, _shareShop, _shareOwner, _refund);
        }
    }

    /// @notice Buy Coffee
    /// @param multi - Coffeemans amount - 1
    /// @param base - Root coffee or coffeeman
    /// @param coffeeman - Coffeeman address
    /// @param coffee - Coffeeman coffee number
    function buyCoffee(uint multi, bool base, address coffeeman, uint coffee) external {
        require(_final == false, "Game finalized");
        Coffee storage b_coffeeman = _coffeeBeans[coffeeman]._coffees[coffee];
        if (base == false) {
            require(b_coffeeman._coffeemans_left > 0);
        }
        require(!locker);
        locker = true;

        (uint _deposit, uint _fond, uint _coffeeman, uint _lottery, uint _shop, uint _toOwner, uint _refund) = getShare(multi);
        if (_discountsNum > 0 && base == true) {
            _deposit -= _depositAmount / 2;
            _coffeeman -= _depositAmount / 2;
        }
        address[] memory path = new address[](2);
        path[0] = _usd;
        path[1] = _bitcoin;
        _bankLottery += _lottery;
        _bankShop += _shop;
        _bankOwner += _toOwner;
        _payments[_coffeeBeansCounter.current()] = msg.sender;
        _multi[_coffeeBeansCounter.current()] = multi + 1;
        _coffeeBeansCounter.increment();

        CoffeeBean storage c_sender = _coffeeBeans[msg.sender];
        Coffee storage b_sender = _coffeeBeans[msg.sender]._coffees[c_sender._coffeesCounter.current()];

        b_sender._coffeemans_left = uint128(multi + 1);
        b_sender._coffeemans_closed = uint128(0);
        b_sender._gifted = false;

        if (base == true) {
            _fond += _coffeeman;
            _coffeeman = 0;
            IERC20(_usd).safeTransferFrom(msg.sender, address(this), _deposit - _refund);
            b_sender._price = uint128(_deposit - _refund);
        } else {
            IERC20(_usd).safeTransferFrom(msg.sender, coffeeman, _coffeeman);
            IERC20(_usd).safeTransferFrom(msg.sender, address(this), (_deposit - _coffeeman - _refund));
            b_coffeeman._coffeemans_left --;
            b_coffeeman._coffeemans_closed ++;
            b_sender._price = uint128(_deposit - _coffeeman - _refund);
        }

        b_sender._to_fund = uint128(_fond);

        IERC20(_usd).approve(_router, _fond);
        uint _fromSwap = IUniswapV2Router02(_router).swapExactTokensForTokens(_fond, 0, path, address(this), block.timestamp)[1];
        _bankFund += _fromSwap;
        require(_fromSwap > 0, "from DEX comes 0 token");
        require(_fond / _fromSwap > 0, "the price is 0");

        b_sender._btc_rate = uint128(_fond / _fromSwap);
        c_sender._coffeesCounter.increment();
        if (_discountsNum > 0 && base == true) {
            _discountsNum --;
        }
        locker = false;
        emit Coffeed(
            msg.sender,
            coffeeman,
            coffee,
            _deposit,
            _refund,
            b_sender._coffeemans_left,
            _coffeeman,
            _lottery,
            b_sender._to_fund,
            b_sender._btc_rate
        );
    }

    /// @notice Coffeeman buyCoffee
    /// @param number - user's refundable coffee number
    function offsetCoffeeBean(uint number) external {
        CoffeeBean storage c_sender = _coffeeBeans[msg.sender];
        require(c_sender._coffees[number]._gifted == false, 'This coffee was gifted');

        uint _unclose = c_sender._coffees[number]._coffeemans_left;
        uint _closed = c_sender._coffees[number]._coffeemans_closed;
        require(_unclose > 0, 'The coffee has already been refunded');
        require(!locker);
        locker = true;


        uint _amount = c_sender._coffees[number]._price - _closed * (_depositAmount * _percentageCoffeeman / MAX_BPS);
        require(_amount > 0, 'Coffee was already covered by coffeemans');
        address[] memory path = new address[](2);
        path[0] = _bitcoin;
        path[1] = _usd;
        uint _toSwap;
        uint _price = IUniswapV2Router02(_router).getAmountsOut(_amount, path)[1] / _amount;

        uint _new_share = (c_sender._coffees[number]._to_fund / c_sender._coffees[number]._btc_rate) * _price;

        if (_final == false) {
            require(_new_share >= _amount, 'The deposit of the rate in the reserve has not yet increased enough');
        }
        if (_new_share < _amount) {
            uint _count = _new_share / _price;
            IERC20(_bitcoin).approve(_router, _count);
            _toSwap = IUniswapV2Router02(_router).swapTokensForExactTokens(_new_share, _count, path, msg.sender, block.timestamp)[0];
            _bankFund -= _toSwap;
            _refundsCounter.increment();
            c_sender._coffees[number]._coffeemans_left = 0;
            emit Widthdraw(msg.sender, number, _new_share, _price);
        } else {
            uint _count = _amount / _price;
            IERC20(_bitcoin).approve(_router, _count);
            _toSwap = IUniswapV2Router02(_router).swapTokensForExactTokens(_amount, _count, path, msg.sender, block.timestamp)[0];
            _bankFund -= _toSwap;
            _refundsCounter.increment();
            c_sender._coffees[number]._coffeemans_left = 0;
            emit Widthdraw(msg.sender, number, _amount, _price);
        }
        locker = false;
    }

    /// @notice Run lottery
    function startLottery() external onlyOwner {
        require(_final == false, "Game finalized");
        uint number = VRFv2Consumer(_vrf).randomNums(0);
        require(_randomNum != number, 'Random number not yet received from oracle');
        _randomNum = number;
        uint count;
        for (uint i = _startLotteryNum + 1; i <= _coffeeBeansCounter.current(); i++) {
            count += _multi[i];
        }
        uint _num = getRandomNum() % count;
        address _winner;
        for (uint i = _startLotteryNum + 1; i <= _coffeeBeansCounter.current(); i++) {
            if (_num <= _multi[i]) {
                _winner = _payments[i];
                break;
            }
        }

        IERC20(_usd).safeTransfer(_winner, _bankLottery);

        emit Lottery(_num, _winner, _bankLottery);
        _bankLottery = 0;
        _startLotteryNum = _coffeeBeansCounter.current();
    }

    /// @notice Contribute
    /// @param multi - Coffeemans amount - 1
    /// @param recipient - Address of gift recipient
    function giftCoffee(uint multi, address recipient) external onlyOwner {
        require(_final == false, "Game finalized");
        require(!locker);
        locker = true;

        _payments[_coffeeBeansCounter.current()] = recipient;
        _multi[_coffeeBeansCounter.current()] = multi + 1;
        _coffeeBeansCounter.increment();

        CoffeeBean storage c_sender = _coffeeBeans[recipient];
        Coffee storage b_sender = _coffeeBeans[recipient]._coffees[c_sender._coffeesCounter.current()];

        b_sender._coffeemans_left = uint128(multi + 1);
        b_sender._coffeemans_closed = uint128(0);
        b_sender._price = uint128(0);
        b_sender._to_fund = uint128(0);
        b_sender._btc_rate = uint128(0);
        b_sender._gifted = true;

        c_sender._coffeesCounter.increment();
        locker = false;

        emit Coffeed(
            recipient,
            address(0x0000000000000000000000000000000000000000),
            uint128(0),
            uint128(0),
            uint128(0),
            b_sender._coffeemans_left,
            uint128(0),
            uint128(0),
            uint128(0),
            uint128(0)
        );
    }

    /// @notice Finalize project
    function finalize() external onlyOwner {
        require(_final == false, "Already finalized");
        timer = block.timestamp + (_waitingTime * 1 minutes);
        _final = true;
    }
    /// @notice Withdraw balance
    function withdrawAll() external onlyOwner {
        require(_final == true, "Game not yet finalized");
        require(timer < block.timestamp, "Time to withdraw users' funds has not yet expired");
        uint _balanceUsd = IERC20(_usd).balanceOf(address(this));
        IERC20(_usd).safeTransfer(msg.sender, _balanceUsd);
        uint _balanceBtc = IERC20(_bitcoin).balanceOf(address(this));
        IERC20(_bitcoin).safeTransfer(msg.sender, _balanceBtc);
    }
    /// @notice Withdraw Shop
    function withdrawShop() external onlyOwner {
        require(_bankShop > 0, "bank empty");
        IERC20(_usd).safeTransfer(msg.sender, _bankShop);
        _bankShop = 0;
    }
    /// @notice Withdraw Owner
    function withdrawOwner() external onlyOwner {
        require(_bankOwner > 0, "bank empty");
        IERC20(_usd).safeTransfer(msg.sender, _bankOwner);
        _bankOwner = 0;
    }
    /// @notice Withdraw Lottery
    function withdrawLottery() external onlyOwner {
        require(_final == true, "Game finalized");
        require(_bankLottery > 0, "bank empty");
        IERC20(_usd).safeTransfer(msg.sender, _bankLottery);
        _bankLottery = 0;
    }
}