// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Private is Ownable {

    address public immutable usdt;
    address public immutable busd;
    address public receiver;
    uint256 public start;
    uint256 public end;
    uint256 public min;
    uint256 public max;
    uint256 public price;
    uint256 public hardcap;
    uint256 public totalPaid;
    uint256 public wlPeriod;
    uint256 public totalContributors;
    mapping(uint256 => address) public contributor;
    mapping(address => uint256) public paid;
    mapping(address => bool) public whitelist;

    event OnBuy (uint256 _amount, address _usd);

    constructor(address _usdt, address _busd){
        require(_usdt != address(0), "Zero address");
        require(_busd != address(0), "Zero address");
        usdt = _usdt;
        busd = _busd;
        start = 1675083600;
        end = 1677589200;
        receiver = 0x4438DbD66FF19d534AE74Ce93AB1dD74cc1F6A04;
        price = 0.014 * 10 ** 18;
        hardcap = 840000 * 10 ** 18;
        min = 1000 * 10 ** 18;
        max = 5000 * 10 ** 18;
        wlPeriod = 12 * 24 * 60 * 60;
    }

    function setStart(uint256 _start) external onlyOwner {
        require(_start > block.timestamp, "Start time must be in the future");
        start = _start;
    }

    function setEnd(uint256 _end) external onlyOwner {
        require(_end > start, "End time must be after start time");
        end = _end;
    }

    function setReceiver(address _receiver) external onlyOwner {
        require(_receiver != address(0), "Zero address");
        receiver = _receiver;
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Price must be greater than zero");
        price = _price;
    }

    function setHardcap(uint256 _hardcap) external onlyOwner {
        require(_hardcap > 0, "Hardcap must be greater than zero");
        hardcap = _hardcap;
    }

    function setMin(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Zero amount");
        min = _amount;
    }

    function setMax(uint256 _amount) external onlyOwner {
        require(_amount > min, "Max must be greater than min");
        max = _amount;
    }

    function setWhitelist(address _addr, bool _status) external onlyOwner {
        whitelist[_addr] = _status;
    }

    function setWhitelistBatch(address[] memory _addr, bool _status) external onlyOwner {
        for (uint256 i = 0 ; i < _addr.length; i++) {
            whitelist[_addr[i]] = _status;
        }
    }

    function setWLperiod(uint256 _period) external onlyOwner {
        wlPeriod = _period;
    }

    function buy(uint256 _amount, address _usd) external {
        require(block.timestamp >= start, "Sale has not started");
        require(block.timestamp <= end, "Sale has ended");
        require(_amount >= min, "Amount is less than minimum");
        require(_amount + paid[_msgSender()] <= max, "Amount is more than maximum");
        require(_amount + totalPaid <= hardcap, "Hardcap reached");
        if (block.timestamp < start + wlPeriod) {
            require(whitelist[_msgSender()], "Not in whitelist");
        }
        if (paid[_msgSender()] == 0) {
            contributor[totalContributors] = _msgSender();
            totalContributors++;
        }
        paid[_msgSender()] += _amount;
        totalPaid += _amount;
        if (_usd == usdt) {
            IERC20(usdt).transferFrom(_msgSender(), receiver, _amount);
        } else {
            IERC20(busd).transferFrom(_msgSender(), receiver, _amount);
        }
        emit OnBuy (_amount, _usd);
    }

    function quoteAmount(uint256 _amount) external view returns (uint256) {
        return _amount * 10 ** 18 / price;
    }

    function getBalance(address _wallet) public view returns (uint256) {
        return paid[_wallet] * 10 ** 18/price;
    }

    function withdraw (
        address _token
    ) public onlyOwner {
        require(IERC20(_token).transfer(_msgSender(), IERC20(_token).balanceOf(address(this))), "Fail transfer");
    }
}