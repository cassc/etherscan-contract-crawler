// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IKannaStockOption} from "./interfaces/IKannaStockOption.sol";

/**
 *   __
 *  |  | ___\|/_     ____    ____  _\|/_
 *  |  |/ /\__  \   /    \  /    \ \__  \
 *  |    <  / __ \_|   |  \|   |  \ / __ \_
 *  |__|_ \(____  /|___|  /|___|  /(____  /
 *       \/     \/      \/      \/      \/
 *            __                    __                       __   .__
 *    _______/  |_   ____    ____  |  | __   ____  ______  _/  |_ |__|  ____    ____
 *   /  ___/\   __\ /  _ \ _/ ___\ |  |/ /  /  _ \ \____ \ \   __\|  | /  _ \  /    \
 *   \___ \  |  |  (  <_> )\  \___ |    <  (  <_> )|  |_> > |  |  |  |(  <_> )|   |  \
 *  /____  > |__|   \____/  \___  >|__|_ \  \____/ |   __/  |__|  |__| \____/ |___|  /
 *       \/                     \/      \/         |__|                            \/
 *
 *  @title KNN Stock Option (Vesting)
 *  @author KANNA Team
 *  @custom:github  https://github.com/kanna-coin
 *  @custom:site https://kannacoin.io
 *  @custom:discord https://discord.kannacoin.io
 */
contract KannaStockOption is IKannaStockOption, Ownable, ReentrancyGuard {
    IERC20 _token;
    uint256 _startDate;
    uint256 _daysOfVesting;
    uint256 _daysOfCliff;
    uint256 _daysOfLock;
    uint256 _percentOfGrant;
    uint256 _amount;
    address _beneficiary;
    uint256 _grantAmount;
    uint256 _withdrawn;
    uint256 _lockEndDate;
    uint256 _cliffEndDate;
    uint256 _vestingEndDate;
    bool _finalized;
    uint256 _finalizedAt;
    bool _initialized;
    uint256 _initializedAt;
    uint256 _lastWithdrawalTime;

    event Initialize(
        address tokenAddress,
        uint256 startDate,
        uint256 daysOfVesting,
        uint256 daysOfCliff,
        uint256 daysOfLock,
        uint256 percentOfGrant,
        uint256 amount,
        address beneficiary,
        uint256 initializedAt
    );

    event Withdraw(address indexed beneficiary, uint256 amount, uint256 elapsed);

    event Finalize(address indexed initiator, uint256 amount, uint256 elapsed);

    event Abort(address indexed beneficiary, uint256 amount);

    function initialize(
        address tokenAddress,
        uint256 startDate,
        uint256 daysOfVesting,
        uint256 daysOfCliff,
        uint256 daysOfLock,
        uint256 percentOfGrant,
        uint256 amount,
        address beneficiary
    ) external {
        if (owner() != address(0)) {
            _checkOwner();
        }
        require(_initialized == false, "KannaStockOption: contract already initialized");
        require(startDate > 0, "KannaStockOption: startDate is zero");
        require(daysOfVesting > 0, "KannaStockOption: daysOfVesting is zero");
        require(amount > 0, "KannaStockOption: amount is zero");
        require(beneficiary != address(0), "KannaStockOption: beneficiary is zero");
        require(
            daysOfCliff + daysOfLock <= daysOfVesting,
            "KannaStockOption: daysOfCliff plus daysOfLock overflows daysOfVesting"
        );
        require(percentOfGrant <= 100, "KannaStockOption: percentOfGrant is greater than 100");

        _token = IERC20(tokenAddress);

        require(_token.allowance(_msgSender(), address(this)) >= amount, "KannaStockOption: insufficient allowance");
        require(_token.transferFrom(_msgSender(), address(this), amount), "KannaStockOption: insufficient balance");

        _startDate = startDate;
        _daysOfVesting = daysOfVesting;
        _daysOfCliff = daysOfCliff;
        _daysOfLock = daysOfLock;
        _percentOfGrant = percentOfGrant;
        _amount = amount;
        _beneficiary = beneficiary;

        _grantAmount = (_amount * _percentOfGrant) / 100;

        _cliffEndDate = startDate + (daysOfCliff * 1 days);
        _lockEndDate = _cliffEndDate + (daysOfLock * 1 days);
        _vestingEndDate = startDate + (daysOfVesting * 1 days);

        _finalized = false;
        _withdrawn = 0;
        _initialized = true;
        _initializedAt = block.timestamp;

        emit Initialize(
            tokenAddress,
            startDate,
            daysOfVesting,
            daysOfCliff,
            daysOfLock,
            percentOfGrant,
            amount,
            beneficiary,
            block.timestamp
        );

        if (owner() == address(0)) {
            _transferOwnership(_msgSender());
        }
    }

    function timestamp() public view returns (uint256) {
        return _finalized ? _finalizedAt : block.timestamp;
    }

    function totalVested() public view initialized returns (uint256) {
        if (timestamp() < _cliffEndDate) return 0;
        if (timestamp() >= _vestingEndDate) return _amount;

        return (_amount * (timestamp() - _startDate)) / (_vestingEndDate - _startDate);
    }

    function vestingForecast(uint256 date) public view initialized returns (uint256) {
        require(date >= _startDate, "KannaStockOption: date is before startDate");

        if (date < _cliffEndDate) return 0;
        if (date >= _vestingEndDate) return _amount;

        return (_amount * (date - _startDate)) / (_vestingEndDate - _startDate);
    }

    function availableToWithdraw() public view initialized returns (uint256) {
        if (timestamp() < _cliffEndDate) return 0;
        if (timestamp() >= _vestingEndDate) return _amount - _withdrawn;

        if (block.timestamp < _lockEndDate && totalVested() > _grantAmount) return _grantAmount - _withdrawn;

        return totalVested() - _withdrawn;
    }

    function finalize() public nonReentrant initialized {
        require(
            _msgSender() == owner() || _msgSender() == _beneficiary,
            "KannaStockOption: caller is not the owner or beneficiary"
        );
        require(_finalized == false, "KannaStockOption: contract already finalized");

        uint256 availableAmount = availableToWithdraw();

        if (availableAmount > 0) {
            _withdrawn += availableAmount;
            _token.transfer(_beneficiary, availableAmount);
        }

        uint256 leftover = _amount - totalVested();

        if (leftover > 0) {
            _token.transfer(owner(), leftover);
        }

        _finalizedAt = block.timestamp;
        _finalized = true;

        emit Finalize(_msgSender(), availableAmount, _finalizedAt - _initializedAt);
    }

    function status() public view returns (Status) {
        if (timestamp() < _cliffEndDate) return Status.Cliff;
        if (timestamp() >= _vestingEndDate) return Status.Vesting;

        return Status.Lock;
    }

    function maxGrantAmount() public view returns (uint256) {
        return _grantAmount;
    }

    function withdraw(uint256 amountToWithdraw) public nonReentrant initialized {
        require(_msgSender() == _beneficiary, "KannaStockOption: caller is not the beneficiary");
        require(amountToWithdraw > 0, "KannaStockOption: invalid amountToWithdraw");
        require(
            amountToWithdraw <= availableToWithdraw(),
            "KannaStockOption: amountToWithdraw is greater than availableToWithdraw"
        );

        uint256 withdrawDate = block.timestamp;

        require(withdrawDate - _lastWithdrawalTime >= 1 days, "KannaStockOption: Only one withdrawal allowed per day");

        _withdrawn += amountToWithdraw;
        _token.transfer(_beneficiary, amountToWithdraw);

        emit Withdraw(_msgSender(), amountToWithdraw, withdrawDate - _initializedAt);

        if (_withdrawn == _amount) {
            _finalizedAt = withdrawDate;
            _finalized = true;

            emit Finalize(_msgSender(), amountToWithdraw, _finalizedAt - _initializedAt);
        }

        _lastWithdrawalTime = withdrawDate;
    }

    function abort() public nonReentrant {
        require(_token.balanceOf(address(this)) > 0, "KannaStockOption: contract has no balance");
        require(_msgSender() == _beneficiary, "KannaStockOption: caller is not the beneficiary");

        uint256 returnedAmount = _token.balanceOf(address(this));

        _token.transfer(owner(), returnedAmount);
        _finalized = true;
        emit Abort(_msgSender(), returnedAmount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IKannaStockOption).interfaceId;
    }

    modifier initialized() {
        require(_initialized, "KannaStockOption: contract is not initialized");
        _;
    }
}