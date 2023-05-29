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

contract SVCPresale is ReentrancyGuard, Ownable, Pausable {
    uint public salePriceStage1;
    uint public salePriceStage2;
    uint public salePriceStage3;
    uint public salePriceStage4;
    uint public totalTokensForPresale;
    uint public minimumBuyAmount;
    uint public inSale;
    uint public periodSize;
    uint public startTime;
    uint public endTime;
    uint public claimStart;
    uint public baseDecimals;

    address public saleToken;
    address public receiver;
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
        salePriceStage1 = 0.0143 * (10 ** 18); //USD
        salePriceStage2 = 0.0186 * (10 ** 18); //USD
        salePriceStage3 = 0.023 * (10 ** 18); //USD
        salePriceStage4 = 0.03 * (10 ** 18); //USD
        periodSize = 35_000_000;
        totalTokensForPresale = 140_000_000;
        minimumBuyAmount = 1000;
        receiver = owner();
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

    function calculatePrice(uint _amount) internal view returns (uint totalValue) {
        uint totalSold = totalTokensForPresale - inSale;

        if(totalSold + _amount <= periodSize) return (_amount * salePriceStage1);
        else {
            uint currentStage = (totalSold / periodSize) + 1;

            if(totalSold >= periodSize) {
                uint rest = (currentStage * periodSize) - totalSold;

                if(_amount <= rest) return (_amount * getCurrentStagePrice(currentStage));
                else {
                    totalValue = totalValue + (rest * getCurrentStagePrice(currentStage));
                    _amount -= rest;

                    uint i = 0;
                    while(_amount >= periodSize) {
                        i++;
                        totalValue = totalValue + (periodSize * getCurrentStagePrice(currentStage + i));
                        _amount -= periodSize;
                    }

                    if(_amount > 0) totalValue += (_amount * getCurrentStagePrice(currentStage + i + 1));

                    return totalValue;
                }
            } else {
                uint extra = (totalSold + _amount) - periodSize;
                totalValue = (_amount - extra) * getCurrentStagePrice(currentStage);
                if(extra <= periodSize) return totalValue + (extra * getCurrentStagePrice(currentStage + 1));
                else {
                    uint i = 0;
                    while(extra >= periodSize) {
                        i++;
                        totalValue = totalValue + (periodSize * getCurrentStagePrice(currentStage + i));
                        extra -= periodSize;
                    }

                    if(extra > 0) totalValue += (extra * getCurrentStagePrice(currentStage + i + 1));

                    return totalValue;
                }
            }
        }
    }

    function getCurrentStagePrice(uint _stage) internal view returns (uint stagePrice) {
        if(_stage <= 1) return salePriceStage1;
        else if(_stage == 2) return salePriceStage2;
        else if(_stage == 3) return salePriceStage3;
        else if(_stage >= 4) return salePriceStage4;
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
        sendValue(payable(receiver), ethAmount);
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
                receiver,
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

    function addClaimers(address[] calldata claimers, uint[] calldata amounts) external onlyOwner {
        require(claimers.length > 0, "Claimers are not specified");
        require(claimers.length == amounts.length, "Arrays lengths does not match");

        for(uint i = 0; i < claimers.length; i++) {
            inSale -= (amounts[i] / baseDecimals);
            userDeposits[claimers[i]] += amounts[i];
        }
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

    function changeMinimumBuyAmount(uint _amount) external onlyOwner {
        require(_amount > 0 && _amount != minimumBuyAmount, "Invalid amount");
        minimumBuyAmount = _amount;
    }

    function changeReceiver(address _receiver) external onlyOwner {
        require(receiver != _receiver, "The same receiver");
        receiver = _receiver;
    }

    function changeStagePrice(uint _stage, uint _price) external onlyOwner {
        if(_stage <= 1) salePriceStage1 = _price;
        else if(_stage == 2) salePriceStage2 = _price;
        else if(_stage == 3) salePriceStage3 = _price;
        else if(_stage >= 4) salePriceStage4 = _price;
    }

    function withdrawTokens(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(receiver, amount);
    }

    function withdrawEthers() external onlyOwner {
        (bool success,) = receiver.call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }
}