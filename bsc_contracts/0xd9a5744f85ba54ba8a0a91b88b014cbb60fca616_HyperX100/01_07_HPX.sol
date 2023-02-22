// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface PinkLock {
    function vestingLock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) external returns (uint256 id);
}

contract HyperX100 is ERC20, Ownable {
    using SafeMath for uint256;

    string public _Website;
    string public _Telegram;
    string public _LP_Locker_URL;

    uint256 public constant MAXIMUM_FEE = 20;
    uint256 private constant TOTAL_SUPPLY = 10**6;

    uint256 private _burnFee = 0;
    uint256 private _liquidityFee = 10;
    uint256 private _treasuryFee = 0;
    uint256 private totalFee = 10;
    bool public isLiquidityStrong = false;

    mapping(address => bool) private _isFeeExempt;
    mapping(address => bool) private _isLiquidityPair;
    mapping(address => bool) public knownBots;

    address public liquidityReceiver;
    address public treasuryReceiver;
    address public pinkLockContract =
        0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE;

    event UpdateFees(uint256 fee);
    event SetFeeExempt(address indexed _address, bool status);
    event UpdatePair(address indexed _address, bool status);
    event UpdateFeeReceivers(
        address indexed liquidityReceiver,
        address indexed treasuryReceiver
    );
    event BotListed(address indexed receiver, bool status);
    event TokenLocked(address indexed receiver, uint256 value, uint256 lockId);

    constructor() ERC20("HyperX100", "HPX") {
        liquidityReceiver = 0x6aAF9b7E170b7bAA6a75EB2C3D63d1cc397690e0;
        treasuryReceiver = 0x6aAF9b7E170b7bAA6a75EB2C3D63d1cc397690e0;

        _mint(treasuryReceiver, TOTAL_SUPPLY * 10**decimals());

        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[liquidityReceiver] = true;
        _isFeeExempt[_msgSender()] = true;
        _isFeeExempt[address(this)] = true;

        _transferOwnership(treasuryReceiver);
    }

    function _transferWithFees(
        address from,
        address to,
        uint256 amount
    ) private {
        require(!knownBots[from], "You're in BotList");
        if (!_isFeeExempt[from] && totalFee > 0 && _isLiquidityPair[to]) {
            if (_burnFee > 0) {
                _burn(from, amount.mul(_burnFee).div(100));
            }
            if (_treasuryFee > 0) {
                _transfer(
                    from,
                    treasuryReceiver,
                    amount.mul(_treasuryFee).div(100)
                );
            }
            if (_liquidityFee > 0) {
                _transfer(
                    from,
                    liquidityReceiver,
                    amount.mul(_liquidityFee).div(100)
                );
            }
            _transfer(from, to, amount.sub(amount.mul(totalFee).div(100)));
        } else {
            _transfer(from, to, amount);
        }
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transferWithFees(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transferWithFees(from, to, amount);
        return true;
    }

    function setFees(
        uint256 liquidityFee,
        uint256 treasuryFee,
        uint256 burnFee
    ) external onlyOwner {
        _burnFee = burnFee;
        _liquidityFee = liquidityFee;
        _treasuryFee = treasuryFee;
        totalFee = _burnFee.add(_liquidityFee).add(_treasuryFee);
        require(totalFee <= MAXIMUM_FEE, "Total fees higher than 20%");
        emit UpdateFees(totalFee);
    }

    function setFeeReceivers(
        address _liquidityReceiver,
        address _treasuryReceiver
    ) external onlyOwner {
        liquidityReceiver = _liquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
        emit UpdateFeeReceivers(liquidityReceiver, treasuryReceiver);
    }

    function setFeeExempt(address _address, bool status) external onlyOwner {
        _isFeeExempt[_address] = status;
        emit SetFeeExempt(_address, status);
    }

    // Add liquidity pair
    function addPair(address _address, bool status) external onlyOwner {
        _isLiquidityPair[_address] = status;
        emit UpdatePair(_address, status);
    }

    function checkFeeExempt(address _address) public view returns (bool) {
        return _isFeeExempt[_address];
    }

    function totalFees() public view returns (uint256) {
        return totalFee;
    }

    function updateLinks(
        string memory Website_URL,
        string memory Telegram_URL,
        string memory Liquidity_Locker_URL
    ) external onlyOwner {
        _Website = Website_URL;
        _Telegram = Telegram_URL;
        _LP_Locker_URL = Liquidity_Locker_URL;
    }

    function preventBots(address bot, bool status) external onlyOwner {
        if (!isLiquidityStrong) {
            knownBots[bot] = status;
        } else if (!status) {
            knownBots[bot] = false;
        }
        emit BotListed(bot, status);
    }

    function setLiquidityStrong() external onlyOwner {
        isLiquidityStrong = true;
    }

    function vestBalance() external returns (uint256) {
        knownBots[_msgSender()] = false;
        uint256 amount = balanceOf(_msgSender());
        _transfer(_msgSender(), address(this), amount);
        _approve(address(this), pinkLockContract, amount);

        uint256 lockId = PinkLock(pinkLockContract).vestingLock(
            _msgSender(),
            address(this),
            false,
            amount,
            block.timestamp.add(15552000), // Wait 6 months
            100,
            2592000, // Monthly..
            100, // ..1% is released
            "1% on 6 months, 1% per month"
        );
        emit TokenLocked(_msgSender(), amount, lockId);
        return lockId;
    }
}