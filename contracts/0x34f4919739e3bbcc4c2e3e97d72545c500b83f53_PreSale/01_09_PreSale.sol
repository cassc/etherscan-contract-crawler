// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Vesting.sol";
import "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "openzeppelin/security/Pausable.sol";

interface ERC20Interface is IERC20, IERC20Permit {}

contract PreSale is Ownable, Pausable, ReentrancyGuard {

    Vesting public vestingContract;
    ERC20Interface public erc20Token;
    AggregatorV3Interface public aggregator;
    bool public isSaleEnd;
    uint256 public tokenPrice;
    uint256 public maxTokensToSell;
    uint256 public remainingTokens;
    uint256 public duration;
    uint256 public vestingStartDate;
    uint256 public lockDuration;
    uint256 public usdPrice;
    address public treasuryAddress;
    uint256 public maxInt = 2**256 - 1;
    mapping(address => uint256) public usdcAmount;
    mapping(address => uint256) public ethAmount;

    mapping(address => uint256) public vestedAmount;
    mapping(address => bool) public whitelist;

    event TokensPurchased(address buyer, uint256 amount);
    event TokensClaimed(address beneficiary, uint256 amount);

    constructor(address _vestingContract, address _erc20TokenContract, address _aggregatorContract, uint256 _maxTokensToSell, uint256 _tokenPrice, uint256 _usdPrice, uint256 _vestingDuration, uint256 _vestingStartDate, uint256 _lockDuration, address _treasuryAddress) Ownable(msg.sender) {
        require(_treasuryAddress != address(0), "Treasury address cannot be Zero");
        vestingContract = Vesting(_vestingContract);
        tokenPrice = _tokenPrice; // This is the price of Adeno in ERC20 'token bits'
        duration = _vestingDuration;
        vestingStartDate = _vestingStartDate;
        lockDuration = _lockDuration;
        erc20Token = ERC20Interface(_erc20TokenContract);
        aggregator = AggregatorV3Interface(_aggregatorContract);
        maxTokensToSell = _maxTokensToSell;
        remainingTokens = _maxTokensToSell;
        usdPrice = _usdPrice; // This is the USD price for Eth purchases
        isSaleEnd = false;
        treasuryAddress = _treasuryAddress;
    }

    modifier onlySaleEnd() {
        require(isSaleEnd, "Sale has not ended");
        _;
    }

    modifier onlySaleNotEnd() {
        require(!isSaleEnd, "Sale is not running");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Sender is not whitelisted");
        _;
    }

    function purchaseTokensWithUSDC(uint256 _numberOfTokens)
        external
        onlySaleNotEnd
        onlyWhitelisted
        nonReentrant
    {
        uint256 _tokensToBuy = _numberOfTokens * 10**18;
        require(_numberOfTokens > 0, "Number of tokens must be greater than zero");
        require(remainingTokens >= _tokensToBuy, "Insufficient tokens available for sale");
        require(duration > 0, "Duration must be greater than zero");

        uint256 usdcValue = _numberOfTokens * tokenPrice;
        uint256 allowance = erc20Token.allowance(msg.sender, address(this));
        require(allowance >= usdcValue, "Check the token allowance");
        bool success = erc20Token.transferFrom(msg.sender, address(this), usdcValue);
        require(success, "Transaction was not successful");
        usdcAmount[msg.sender] = usdcAmount[msg.sender] + usdcValue;

        vestedAmount[msg.sender] = vestedAmount[msg.sender] + _tokensToBuy;

        vestingContract.createVestingSchedule(
            msg.sender,
            _tokensToBuy,
            duration, // Number of months for the release period
            vestingStartDate, // Start time of the vesting schedule
            lockDuration // Number of months before vesting period begins
        );

        remainingTokens = remainingTokens - _tokensToBuy;

        emit TokensPurchased(msg.sender, _tokensToBuy);
    }

    function permitAndPurchaseTokensWithUSDC(uint256 _numberOfTokens, uint8 v, bytes32 r, bytes32 s)
        external
        onlySaleNotEnd
        onlyWhitelisted
        nonReentrant
    {
        uint256 _tokensToBuy = _numberOfTokens * 10**18;
        require(_numberOfTokens > 0, "Number of tokens must be greater than zero");
        require(remainingTokens >= _tokensToBuy, "Insufficient tokens available for sale");
        require(duration > 0, "Duration must be greater than zero");

        uint256 usdcValue = _numberOfTokens * tokenPrice;
        erc20Token.permit(msg.sender, address(this), usdcValue, uint256(maxInt), v, r, s);
        bool success = erc20Token.transferFrom(msg.sender, address(this), usdcValue);
        require(success, "Transaction was not successful");
        usdcAmount[msg.sender] = usdcAmount[msg.sender] + usdcValue;

        vestedAmount[msg.sender] = vestedAmount[msg.sender] + _tokensToBuy;

        vestingContract.createVestingSchedule(
            msg.sender,
            _tokensToBuy,
            duration, // Number of months for the release period
            vestingStartDate, // Start time of the vesting schedule
            lockDuration // Number of months before vesting period begins
        );

        remainingTokens = remainingTokens - _tokensToBuy;

        emit TokensPurchased(msg.sender, _tokensToBuy);
    }

    function purchaseTokensWithEth(uint256 _numberOfTokens)
        external payable
        onlySaleNotEnd
        onlyWhitelisted
        nonReentrant
    {
        uint256 _tokensToBuy = _numberOfTokens * 10**18;
        (, int256 price, , , ) = aggregator.latestRoundData();
        require(price >= 0, "Price value must be positive");
        uint256 ethValue = (usdPrice * _tokensToBuy) / uint256(price);
        require(msg.value >= ethValue, "Insufficient Eth for purchase");
        require(_numberOfTokens > 0, "Number of tokens must be greater than zero");
        require(remainingTokens >= _tokensToBuy, "Insufficient tokens available for sale");
        require(duration > 0, "Duration must be greater than zero");
        uint256 excess = msg.value - ethValue;
        ethAmount[msg.sender] = ethAmount[msg.sender] + ethValue;

        vestedAmount[msg.sender] = vestedAmount[msg.sender] + _tokensToBuy;

        vestingContract.createVestingSchedule(
            msg.sender,
            _tokensToBuy,
            duration, // Number of months for the release period
            vestingStartDate, // Start time of the vesting schedule
            lockDuration // Number of months before vesting period begins
        );

        remainingTokens = remainingTokens - _tokensToBuy;
        if (excess > 0) {
            require(address(this).balance >= excess, "Not enough Eth to make the transfer");
            (bool success, ) = payable(msg.sender).call{value: excess}("");
            require(success, "ETH transfer failed");
        }
        emit TokensPurchased(msg.sender, _tokensToBuy);
    }

    function changeAggregatorInterface(address _address) external onlyOwner {
        aggregator = AggregatorV3Interface(_address);
    }

    function seeVestingSchedule() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return vestingContract.vestingSchedules(address(this), msg.sender);
    }

    function seeClaimableTokens() external view returns (uint256 releasableTokens) {
        releasableTokens = vestingContract.getReleasableTokens(address(this), msg.sender);
    }

    function claimVestedTokens() external onlySaleEnd {
        require(vestedAmount[msg.sender] > 0, "No tokens available to claim");
        uint256 releasableTokens = vestingContract.getReleasableTokens(address(this), msg.sender);
        require(releasableTokens > 0, "No tokens available for release");
        vestingContract.releaseTokens(address(this), msg.sender);
        emit TokensClaimed(msg.sender, releasableTokens);
    }

    function refundPurchase(address _buyer) external onlySaleNotEnd nonReentrant onlyOwner {
        (uint256 totalTokens,,, uint256 releasedTokens,) = vestingContract.vestingSchedules(address(this), _buyer);
        require(totalTokens != 0, "Nothing to refund");
        require(releasedTokens == 0, "Tokens have already been claimed");
        bool refundEth;
        bool refundUSDC;
        uint256 ethToRefund = 0;
        uint256 usdcToRefund = 0;
        if(ethAmount[_buyer] > 0) {
            require(address(this).balance >= ethAmount[_buyer], "Not enough Eth to make the transfer");
            ethToRefund = ethAmount[_buyer];
            ethAmount[_buyer] = 0;
            refundEth = true;
        }
        if(usdcAmount[_buyer] > 0) {
            require(erc20Token.balanceOf(address(this)) >= usdcAmount[_buyer], "Not enough USDC to make the transfer");
            usdcToRefund = usdcAmount[_buyer];
            usdcAmount[_buyer] = 0;
            refundUSDC = true;
        }
        remainingTokens = remainingTokens + vestedAmount[_buyer];
        vestedAmount[_buyer] = 0;
        vestingContract.removeVestingSchedule(address(this), _buyer);
        if(refundEth) {
            (bool success, ) = payable(_buyer).call{value: ethToRefund}("");
            require(success, "ETH transfer failed");
        }
        if(refundUSDC) {
            require(erc20Token.transfer(_buyer, usdcToRefund), "USDC transfer failed");
        }
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            whitelist[addr] = true;
        }
    }

    function removeFromWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            whitelist[addr] = false;
        }
    }

    function setSaleEnd() external onlyOwner {
        isSaleEnd = !isSaleEnd;
    }

    function transferRemaining() external onlySaleEnd onlyOwner {
        require(remainingTokens > 0, "No tokens remaining");
        uint256 vestingAmount = remainingTokens;
        remainingTokens = 0;
        vestingContract.createVestingSchedule(
            treasuryAddress,
            vestingAmount,
            1,
            vestingStartDate,
            0
        );
    }

    function updateTreasuryAddress(address treasuryAddr) external onlyOwner {
        require(treasuryAddr != address(0), "Treasury address cannot be Zero");
        treasuryAddress = treasuryAddr;
    }

    function updateVestingAddress(address vestingAddr) external onlyOwner {
        require(vestingAddr != address(0), "Vesting address cannot be Zero");
        vestingContract = Vesting(vestingAddr);
    }

    function updateUSDCAddress(address erc20Addr) external onlyOwner {
        require(erc20Addr != address(0), "ERC20 address cannot be Zero");
        erc20Token = ERC20Interface(erc20Addr);
    }

    function updateAggregatorAddress(address aggregatorAddr) external onlyOwner {
        require(aggregatorAddr != address(0), "Aggregator address cannot be Zero");
        aggregator = AggregatorV3Interface(aggregatorAddr);
    }

    function updateTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice; // This is the price of Adeno in ERC20 'token bits'
    }

    function updateEthPrice(uint256 _usdPrice) external onlyOwner {
        usdPrice = _usdPrice; // This is the USD price for Eth purchases
    }

    function withdrawUSDC() external onlySaleEnd nonReentrant onlyOwner {
        require(erc20Token.balanceOf(address(this)) > 0, "No USDC to withdraw");
        require(erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this))));
    }

    function withdrawEth() external onlySaleEnd nonReentrant onlyOwner {
        require(address(this).balance > 0, "No Eth to withdraw");
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent);
    }
}