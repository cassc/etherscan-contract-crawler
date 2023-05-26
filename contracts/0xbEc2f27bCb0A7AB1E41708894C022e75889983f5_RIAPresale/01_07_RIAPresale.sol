//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./lib/IERC20.sol";
import "./lib/Address.sol";
import "./lib/Context.sol";
import "./lib/Pausable.sol";
import "./lib/Ownable.sol";
import "./lib/ReentrancyGuard.sol";

interface Aggregator {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    );
}

contract RIAPresale is ReentrancyGuard, Ownable, Pausable {
    uint public salePrice;
    uint public totalTokensForPresale;
    uint public minimumBuyAmount;
    uint public inSale;
    uint public priceStep;
    uint public periodSize;
    uint public startTime;
    uint public endTime;
    uint public claimStart;
    uint public baseDecimals;

    address public saleToken;
    address dataOracle;
    address USDTtoken;
    address USDCtoken;
    address BUSDtoken;
    address DAItoken;

    mapping(address => uint) public userDeposits;
    mapping(address => bool) public hasClaimed;

    event TokensBought(
        address indexed user,
        uint indexed tokensBought,
        address indexed purchaseToken,
        uint amountPaid,
        uint timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint amount,
        uint timestamp
    );

    constructor(uint _startTime, uint _endTime, address _oracle, address _usdt, address _usdc, address _busd, address _dai) {
        require(_startTime > block.timestamp && _endTime > _startTime, "Invalid time");
        baseDecimals = (10 ** 18);
        salePrice = 0.01 * (10 ** 18); //USD
        priceStep = 0.0025 * (10 ** 18); //USD
        periodSize = 30_000_000;
        totalTokensForPresale = 300_000_000;
        minimumBuyAmount = 1000;
        inSale = totalTokensForPresale;
        startTime = _startTime;
        endTime = _endTime;
        dataOracle = _oracle;
        USDTtoken = _usdt;
        USDCtoken = _usdc;
        BUSDtoken = _busd;
        DAItoken = _dai;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function calculatePrice(uint256 _amount) internal view returns (uint256 totalValue) {
        uint256 totalSold = totalTokensForPresale - inSale;

        if(totalSold + _amount <= periodSize) return (_amount * salePrice);
        else {
            uint256 extra = (totalSold + _amount) - periodSize;
            uint256 _salePrice = salePrice;

            if(totalSold >= periodSize) {
                _salePrice = (_salePrice + priceStep) + (((totalSold - periodSize) / periodSize) * priceStep);

                uint256 period = _amount / periodSize;

                if(period == 0) return (_amount * _salePrice);
                else {
                    while(period > 0) {
                        totalValue = totalValue + (periodSize * _salePrice);
                        _amount -= periodSize;
                        _salePrice += priceStep;
                        period--;
                    }

                    if(_amount > 0) totalValue += (_amount * _salePrice);
                }
            } else {
                totalValue = (_amount - extra) * _salePrice;
                if(extra <= periodSize) return totalValue + (extra * ((_salePrice * 125) / 100));
                else {
                    while(extra >= periodSize) {
                        _salePrice += priceStep;
                        totalValue = totalValue + (periodSize * _salePrice);
                        extra -= periodSize;
                    }

                    if(extra > 0) {
                        _salePrice += priceStep;
                        totalValue += (extra * _salePrice);
                    }
                    return totalValue;
                }
            }
        }
    }

    function getETHLatestPrice() public view returns (uint) {
        (, int256 price, , , ) = Aggregator(dataOracle).latestRoundData();
        price = (price * (10 ** 10));
        return uint(price);
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    modifier checkSaleState(uint amount) {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Invalid time for buying");
        require(amount >= minimumBuyAmount, "Too small amount");
        require(amount > 0 && amount <= inSale, "Invalid sale amount");
        _;
    }

    function buyWithEth(uint amount) external payable checkSaleState(amount) whenNotPaused nonReentrant {
        uint usdPrice = calculatePrice(amount);
        uint ethAmount = (usdPrice * baseDecimals) / getETHLatestPrice();
        require(msg.value >= ethAmount, "Less payment");
        uint excess = msg.value - ethAmount;
        inSale -= amount;
        userDeposits[_msgSender()] += (amount * baseDecimals);
        sendValue(payable(owner()), ethAmount);
        if(excess > 0) sendValue(payable(_msgSender()), excess);

        emit TokensBought(
            _msgSender(),
            amount,
            address(0),
            ethAmount,
            block.timestamp
        );
    }

    function buyWithUSD(uint amount, uint purchaseToken) external checkSaleState(amount) whenNotPaused {
        uint usdPrice = calculatePrice(amount);
        if(purchaseToken == 0 || purchaseToken == 1) usdPrice = usdPrice / (10 ** 12); //USDT and USDC have 6 decimals
        inSale -= amount;
        userDeposits[_msgSender()] += (amount * baseDecimals);

        IERC20 tokenInterface;
        if(purchaseToken == 0) tokenInterface = IERC20(USDTtoken);
        else if(purchaseToken == 1) tokenInterface = IERC20(USDCtoken);
        else if(purchaseToken == 2) tokenInterface = IERC20(BUSDtoken);
        else if(purchaseToken == 3) tokenInterface = IERC20(DAItoken);

        uint ourAllowance = tokenInterface.allowance(_msgSender(), address(this));
        require(usdPrice <= ourAllowance, "Make sure to add enough allowance");

        (bool success, ) = address(tokenInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                owner(),
                usdPrice
            )
        );

        require(success, "Token payment failed");

        emit TokensBought(
            _msgSender(),
            amount,
            address(tokenInterface),
            usdPrice,
            block.timestamp
        );
    }

    function getEthAmount(uint amount) external view returns (uint ethAmount) {
        uint usdPrice = calculatePrice(amount);
        ethAmount = (usdPrice * baseDecimals) / getETHLatestPrice();
    }

    function getTokenAmount(uint amount, uint purchaseToken) external view returns (uint usdPrice) {
        usdPrice = calculatePrice(amount);
        if(purchaseToken == 0 || purchaseToken == 1) usdPrice = usdPrice / (10 ** 12); //USDT and USDC have 6 decimals
    }

    function startClaim(uint _claimStart, uint tokensAmount, address _saleToken) external onlyOwner {
        require(_claimStart > endTime && _claimStart > block.timestamp, "Invalid claim start time");
        require(tokensAmount >= ((totalTokensForPresale - inSale) * baseDecimals), "Tokens less than sold");
        require(_saleToken != address(0), "Zero token address");
        require(claimStart == 0, "Claim already set");
        claimStart = _claimStart;
        saleToken = _saleToken;
        IERC20(_saleToken).transferFrom(_msgSender(), address(this), tokensAmount);
    }

    function claim() external whenNotPaused {
        require(saleToken != address(0), "Sale token not added");
        require(block.timestamp >= claimStart, "Claim has not started yet");
        require(!hasClaimed[_msgSender()], "Already claimed");
        hasClaimed[_msgSender()] = true;
        uint amount = userDeposits[_msgSender()];
        require(amount > 0, "Nothing to claim");
        delete userDeposits[_msgSender()];
        IERC20(saleToken).transfer(_msgSender(), amount);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
    }

    function changeClaimStart(uint _claimStart) external onlyOwner {
        require(claimStart > 0, "Initial claim data not set");
        require(_claimStart > endTime, "Sale in progress");
        require(_claimStart > block.timestamp, "Claim start in past");
        claimStart = _claimStart;
    }

    function changeSaleTimes(uint _startTime, uint _endTime) external onlyOwner {
        require(_startTime > 0 || _endTime > 0, "Invalid parameters");

        if(_startTime > 0) {
            require(block.timestamp < _startTime, "Sale time in past");
            startTime = _startTime;
        }

        if(_endTime > 0) {
            require(_endTime > startTime, "Invalid endTime");
            endTime = _endTime;
        }
    }

    function changePriceStep(uint _priceStep) external onlyOwner {
        require(_priceStep > 0 && _priceStep != priceStep, "Invalid price step");
        priceStep = _priceStep;
    }

    function changePeriodSize(uint _periodSize) external onlyOwner {
        require(_periodSize > 0 && _periodSize != periodSize, "Invalid period size");
        periodSize = _periodSize;
    }

    function changeMinimumBuyAmount(uint _amount) external onlyOwner {
        require(_amount > 0 && _amount != minimumBuyAmount, "Invalid amount");
        minimumBuyAmount = _amount;
    }

    function withdrawTokens(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }

    function withdrawEthers() external onlyOwner {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }
}