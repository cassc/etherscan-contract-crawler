//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract PreSale is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IERC20 public controbuteToken;

    mapping(address => uint256) public myContribution;
    mapping(address => bool) public isWhitelisted;

    address[] public contributors;
    uint256[] public contributeValues;

    uint256 public currentRate;

    bool public isStarted;

    bool public isSet;

    uint256 public maxContribution;
    uint256 public hardCap;

    uint256 public filledBusd;
    uint256 public remainingBusd;

    uint256 public startDate;
    uint256 public filledDate;

    bool public isFilled;

    uint256 public investorsCount;

    event Contribute(address investor, uint256 amount);

    constructor() {}

    receive() external payable {}

    function initialize(address _token) public initializer {
        __Ownable_init();

        controbuteToken = IERC20(_token);

        transferOwnership(0x139370F6343A059B44Bc42625ddBdE98D7F7272F);
    }

    function setPreSale(
        uint256 _currentRate,
        uint256 _startDate,
        uint256 _maxContribution,
        uint256 _hardCap
    ) external onlyOwner {
        require(!isSet, "You already set the values");
        currentRate = _currentRate;
        startDate = _startDate;
        maxContribution = _maxContribution;
        hardCap = _hardCap;
        remainingBusd = _hardCap;

        isSet = true;
    }

    function updatePool() public {
        if (!isSet) return;
        if (isFilled) return;

        if (startDate > block.timestamp) return;

        if (!isStarted && startDate <= block.timestamp) {
            isStarted = true;
            return;
        }

        if (isStarted && hardCap == filledBusd) {
            isFilled = true;
            filledDate = block.timestamp;
        }
    }

    function contribute(uint256 _amount) public nonReentrant {
        updatePool();
        require(isWhitelisted[msg.sender], "You are not a whitelisted user");
        require(isStarted && !isFilled, "It's not the time to contribute");
        require(
            (_amount + myContribution[msg.sender]) <= maxContribution,
            "You have exceeded max contribution"
        );

        require(
            _amount <= remainingBusd,
            "Currently we can not accept this amount"
        );

        controbuteToken.transferFrom(msg.sender, address(this), _amount);

        contributors.push(msg.sender);
        contributeValues.push(_amount);

        if (myContribution[msg.sender] == 0) investorsCount++;

        myContribution[msg.sender] += _amount;

        filledBusd += _amount;
        remainingBusd -= _amount;

        updatePool();

        emit Contribute(msg.sender, _amount);
    }

    function getContributorsList() public view returns (address[] memory) {
        return contributors;
    }

    function getContributorsValues() public view returns (uint256[] memory) {
        return contributeValues;
    }

    function withdrawTokens() external onlyOwner {
        uint256 currentBalance = controbuteToken.balanceOf(address(this));

        controbuteToken.transfer(msg.sender, currentBalance);
    }

    function whitelistUsers(address[] memory _wallets) external onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            isWhitelisted[_wallets[i]] = true;
        }
    }

    function whitelistUsersRemove(address[] memory _wallets)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            isWhitelisted[_wallets[i]] = false;
        }
    }

    function changeMaxContribution(uint256 _amount) external onlyOwner {
        maxContribution = _amount;
    }

    function changeHardCap(uint256 _amount) external onlyOwner {
        remainingBusd = _amount - (hardCap - remainingBusd);
        hardCap = _amount;
    }
}