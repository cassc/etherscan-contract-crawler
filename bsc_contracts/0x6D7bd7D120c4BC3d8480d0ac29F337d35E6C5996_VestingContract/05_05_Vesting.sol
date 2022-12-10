// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VestingContract is Ownable, ReentrancyGuard {
    IERC20 public FRED;
    IERC20 public BUSD;
    bool public presaleActive;
    uint256 public startTime = 1670954400;
    uint256 public presaleSpots = 140;
    uint256 public whitelListSpots = 10;
    uint256 public teamTokens;
    uint256 public teamTokenLockTime;
    uint256 public lastMarketingClaim;
    address[] public marketingWallets;

    struct Vest {
        address _benificiary;
        uint256 _total;
        uint256 _amount;
        uint256 _claimed;
        uint256 _startTime;
        uint256 _endTime;
    }

    mapping(address => Vest) public vestingRegistry;
    mapping(address => bool) public hasPurchased;
    mapping(address => bool) public whiteListed;

    event PresaleStarted();
    event SpotBought(address _address);

    constructor(address _fred) {
        FRED = IERC20(_fred);
        BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    }

    function buyPresaleSlot() external {
        require(presaleActive, "Presale is not active yet");
        if (whiteListed[msg.sender]) {
            require(whitelListSpots > 0);
        } else {
            require(presaleSpots > 0);
        }

        require(
            FRED.balanceOf(address(this)) >= 4000000 ether,
            "No more presale tokens availalbe"
        );

        if (!whiteListed[msg.sender]) {
            require(
                BUSD.transferFrom(msg.sender, address(this), 110 ether), // $110 BUSD
                "Payment Failed"
            );
        }

        createVest(msg.sender, 4000000 * 10 ** 18);
    }

    function createVest(address _benificiary, uint256 _amount) internal {
        require(
            !hasPurchased[_benificiary],
            "This wallet already has purchased"
        );
        Vest storage vest = vestingRegistry[_benificiary];

        vest._benificiary = _benificiary;
        vest._amount = _amount;
        vest._startTime = startTime;
        vest._endTime = startTime + 45 days;
        vest._total = _amount;

        hasPurchased[_benificiary] = true;

        if (whiteListed[msg.sender]) {
            whitelListSpots -= 1;
        } else {
            presaleSpots -= 1;
        }

        emit SpotBought(_benificiary);
    }

    function createMarketingVest(
        address _address,
        uint256 _amount
    ) external onlyOwner {
        createVest(_address, _amount);
        marketingWallets.push(_address);
    }

    function checkAvailableTokens(
        address _address
    ) public view returns (uint256) {
        require(
            hasPurchased[_address],
            "You have not purchased any tokens yet.."
        );
        uint256 timeElapsed;
        uint256 amountToClaim;
        if (block.timestamp < startTime) {
            timeElapsed = 0;
        } else {
            Vest storage vest = vestingRegistry[_address];
            block.timestamp > vest._endTime
                ? timeElapsed = vest._endTime - startTime
                : timeElapsed = block.timestamp - startTime;
            uint256 releasedPerSecond = vest._total /
                (vest._endTime - startTime);
            amountToClaim = ((timeElapsed * releasedPerSecond) - vest._claimed);
        }

        return amountToClaim;
    }

    function claimTokens() external nonReentrant {
        Vest storage vest = vestingRegistry[msg.sender];
        require(
            block.timestamp > vest._startTime + 1 days,
            "Your tokens will start releasing after 24hrs"
        );

        uint256 available = checkAvailableTokens(msg.sender);
        if (vest._amount > 0) {
            vest._amount -= available;
            vest._claimed += available;
            FRED.transfer(msg.sender, available);
        }
    }

    function claimMarketingTokens() external {
        require(
            block.timestamp >= lastMarketingClaim + 1 days,
            "Marketers can only claim once a day"
        );
        require(
            block.timestamp > startTime + 1 days,
            "Your tokens will start releasing after 24hrs"
        );
        address[] memory wallets = marketingWallets;
        for (uint256 i; i < wallets.length; i++) {
            uint256 available = checkAvailableTokens(wallets[i]);
            FRED.transfer(wallets[i], available);
        }
        lastMarketingClaim = block.timestamp;
    }

    // Vest Team Tokens
    // 10% for 10 weeks

    function vestTeamTokens(uint256 _amount) external onlyOwner {
        FRED.transferFrom(msg.sender, address(this), _amount);
        teamTokens += _amount;
        teamTokenLockTime = block.timestamp;
    }

    function withdrawTeamTokens() external onlyOwner {
        require(
            block.timestamp > teamTokenLockTime + 10 weeks,
            "Tokens cannot be unlocked yet.."
        );
        FRED.transfer(msg.sender, teamTokens);
    }

    function updateFREDToken(address _address) external onlyOwner {
        FRED = IERC20(_address);
    }

    function withdrawBUSD() external onlyOwner {
        require(BUSD.balanceOf(address(this)) > 0, "Nothing to withdraw");
        require(
            BUSD.transfer(owner(), BUSD.balanceOf(address(this))),
            "Withdraw Failed"
        );
    }

    function addWhiteListed(address _address) external onlyOwner {
        whiteListed[_address] = true;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        // require(_startTime < startTime, "Cannot extend time, only shorten it");
        startTime = _startTime;
    }

    function startPresale() external onlyOwner {
        require(!presaleActive, "Presale is already active");
        presaleActive = true;
        emit PresaleStarted();
    }
}