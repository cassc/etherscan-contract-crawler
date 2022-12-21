// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FredVestingContract is Ownable, ReentrancyGuard {
    IERC20 public BUSD;
    IERC20 public FRED;
    bool public presaleActive;
    address[] public marketingWallets;
    address public teamWallet;
    uint256 public whiteListStartTime;
    uint256 public publicStartTime = whiteListStartTime + 1 hours;
    uint256 public launchTime = 1671822000; // 23rd of December @ 19 hours UTC
    uint256 public vestingEndDate = launchTime + 45 days;
    uint256 public presaleSpots = 150;
    uint256 public whitelListSpots = 50;
    uint256 public teamTokenLockTime;
    uint256 public lastMarketingClaim;
    TeamVest public teamVest;

    struct Vest {
        address _benificiary;
        uint256 _total;
        uint256 _amount;
        uint256 _claimed;
    }

    struct TeamVest {
        uint256 _amount;
        uint256 _lastClaimDate;
        uint256 _remaining;
        uint256 _vestingStartDate;
        uint256 _vestingEndDate;
        uint256 _claimed;
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
        require(!hasPurchased[msg.sender], "This wallet already has purchased");

        if (block.timestamp < publicStartTime) {
            require(whiteListed[msg.sender], "You are not whitelisted");
            require(whitelListSpots > 0);
        } else {
            require(presaleSpots + whitelListSpots > 0);
        }

        require(
            FRED.balanceOf(address(this)) >= 4000000 ether,
            "No more presale tokens availalbe"
        );

        require(
            BUSD.transferFrom(msg.sender, address(this), 60 ether), // $60 BUSD
            "Payment Failed"
        );

        createVest(msg.sender, 4000000 * 10 ** 18, false);
    }

    function createVest(
        address _benificiary,
        uint256 _amount,
        bool _marketing
    ) internal {
        Vest storage vest = vestingRegistry[_benificiary];

        uint256 available = (_amount * 40) / 100;
        require(
            FRED.transfer(_benificiary, available),
            "Token transfer failed"
        );

        vest._benificiary = _benificiary;
        vest._amount = _amount - available;
        vest._total = _amount - available;

        hasPurchased[_benificiary] = true;

        if (!_marketing) {
            if (block.timestamp < publicStartTime) {
                whitelListSpots -= 1;
            } else {
                if (whitelListSpots == 0) {
                    presaleSpots -= 1;
                } else {
                    whitelListSpots -= 1;
                }
            }
        }

        emit SpotBought(_benificiary);
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
        if (block.timestamp < launchTime) {
            timeElapsed = 0;
        } else {
            Vest storage vest = vestingRegistry[_address];
            block.timestamp > vestingEndDate
                ? timeElapsed = vestingEndDate - launchTime
                : timeElapsed = block.timestamp - launchTime;
            uint256 releasedPerSecond = vest._total /
                (vestingEndDate - launchTime);
            amountToClaim = ((timeElapsed * releasedPerSecond) - vest._claimed);
        }

        return amountToClaim;
    }

    function claimTokens() external nonReentrant {
        require(hasPurchased[msg.sender], "You dont have any vest");
        Vest storage vest = vestingRegistry[msg.sender];
        require(
            block.timestamp > launchTime + 1 days,
            "Your tokens will start releasing after 24hrs post launch"
        );

        uint256 available = checkAvailableTokens(msg.sender);
        if (vest._amount > 0) {
            vest._amount -= available;
            vest._claimed += available;
            FRED.transfer(msg.sender, available);
        }
    }

    // Marketing

    function createMarketingVest(
        address _address,
        uint256 _amount
    ) external onlyOwner {
        FRED.transferFrom(msg.sender, address(this), _amount);
        createVest(_address, _amount, true);
        marketingWallets.push(_address);
    }

    function claimMarketingTokens() external nonReentrant {
        require(
            block.timestamp > launchTime + 1 days,
            "Your tokens will start releasing after 24hrs"
        );
        require(
            block.timestamp >= lastMarketingClaim + 1 days,
            "Marketers can only claim once a day"
        );
        address[] memory wallets = marketingWallets;
        lastMarketingClaim = block.timestamp;
        for (uint256 i; i < wallets.length; i++) {
            uint256 available = checkAvailableTokens(wallets[i]);
            FRED.transfer(wallets[i], available);
        }
    }

    // Vest Team Tokens 100 weeks

    function vestTeamTokens(uint256 _amount) external onlyOwner {
        require(
            FRED.transferFrom(msg.sender, address(this), _amount),
            "Token transfer Failed"
        );
        TeamVest storage vest = teamVest;
        vest._amount = _amount;
        vest._lastClaimDate = block.timestamp;
        vest._remaining = _amount;
        vest._vestingStartDate = block.timestamp;
        vest._vestingEndDate = block.timestamp + 100 weeks;
    }

    function checkTeamTokensAvailable() public view returns (uint256) {
        uint256 timePast;
        uint256 unlockedPerSecond = teamVest._amount / 100 weeks;
        block.timestamp > teamVest._vestingEndDate
            ? timePast = teamVest._vestingEndDate - teamVest._vestingStartDate
            : timePast = block.timestamp - teamVest._vestingStartDate;

        return (timePast * unlockedPerSecond) - teamVest._claimed;
    }

    function withdrawTeamTokens() external {
        require(msg.sender == teamWallet, "Caller is not the team wallet");
        require(
            block.timestamp > teamVest._lastClaimDate + 1 weeks,
            "Can only claim once a week"
        );
        require(teamVest._remaining > 0, "Nothing left to claim");
        uint256 toClaim = checkTeamTokensAvailable();
        teamVest._claimed += toClaim;
        teamVest._lastClaimDate = block.timestamp;

        FRED.transfer(teamWallet, toClaim);
    }

    // SETTERS AND GETTERS

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

    function setStartTime(uint256 _newLaunchTime) external onlyOwner {
        require(
            _newLaunchTime < launchTime,
            "Cannot extend time, only shorten it"
        );
        launchTime = _newLaunchTime;
    }

    function startPresale() external onlyOwner {
        require(!presaleActive, "Presale is already active");
        presaleActive = true;
        whiteListStartTime = block.timestamp;
        emit PresaleStarted();
    }

    function getUnusedTokens() external onlyOwner {
        require(
            block.timestamp > launchTime + 100 days,
            "Cannot remove unused tokens until after 100 days"
        );
        uint256 amount = (whitelListSpots + presaleSpots) * 4000000 ether;
        require(FRED.balanceOf(address(this)) >= amount);
        FRED.transfer(owner(), amount);
    }

    function updateWhiteListSpots(uint256 _amt) external onlyOwner {
        whitelListSpots = _amt;
    }

    function updatePresaleSpots(uint256 _amt) external onlyOwner {
        presaleSpots = _amt;
    }

    function replaceMarketingWallet(address _address) external onlyOwner {
        address[] storage wallets = marketingWallets;
        for (uint256 i; i < wallets.length; i++) {
            if (wallets[i] == _address) {
                wallets[i] = owner();
            }
        }
    }

    function setTeamWallet(address _newTeamWallet) external onlyOwner {
        teamWallet = _newTeamWallet;
    }

    function getMarketingWallets() public view returns (address[] memory) {
        return marketingWallets;
    }

    function updateBUSD(address _newAddress) external onlyOwner {
        BUSD = IERC20(_newAddress);
    }
}