// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ICO is Ownable {

    uint256 public startTime;
    uint256 public endTime;
    uint256 public amountPerStable;
    Token   public token;
    IERC20  public usdtToken;

    AggregatorV3Interface public priceFeed;

    using SafeMath for uint256;
    event BuyICO(uint256 currency, uint256 amount, uint256 balance, address referrer);

    struct Referrer {
        address f1;
    }

    mapping(address => Referrer) public referrers;

    constructor(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _amountPerStable,
        address _token,
        address _usdtAddress,
        address _priceFeedAddress){

        startTime       = _startTime;
        endTime         = _endTime;
        amountPerStable = _amountPerStable;

        token     = Token(_token);
        usdtToken = IERC20(_usdtAddress);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function setRoundInfo(uint256 _startTime, uint256 _endTime, uint256 _amountPerStable) external onlyOwner {
        require(_startTime > block.timestamp && _startTime < _endTime, "ICO Time Invalid");
        require(_amountPerStable > 0, "Rate Invalid");

        startTime = _startTime;
        endTime   = _endTime;
        amountPerStable = _amountPerStable;
    }

    function setAmountPerStable(uint256 _amountPerStable) external onlyOwner {
        require(_amountPerStable > 0, "Rate Invalid");
        amountPerStable = _amountPerStable;
    }

    function setPriceFeed(address _priceFeedAddress) external onlyOwner {
        require(_priceFeedAddress != address(0), "Price Feed Address Invalid");
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function buyByEth() external payable {
        validate(msg.value);

        uint256 stablePerBnb = uint256(getLatestPrice()); // USDT/ETH
        uint256 amount       = msg.value.mul(10 ** 18).div(stablePerBnb);
        uint256 buyAmount    = amount.mul(amountPerStable);
        require(buyAmount   <= token.balanceOf(address(this)), "Not Enough Token To Buy");

        token.transferLockToken(msg.sender, buyAmount);
    }

    function buyByUsdt(uint256 _amount) external {
        validate(_amount);

        uint256 buyAmount  = _amount.mul(amountPerStable);
        require(buyAmount <= token.balanceOf(address(this)), "Not Enough Token To Buy");

        usdtToken.transferFrom(msg.sender, address(this), _amount);
        token.transferLockToken(msg.sender, buyAmount);
    }

    function validate(uint256 _amount) private view {
        require(_amount > 0, "Amount Invalid");
        require(block.timestamp >= startTime, "Not Start Time");
        require(block.timestamp <= endTime, "Time End");
    }

    function getLatestPrice() internal view returns (int256) {
        ( ,int256 answer, , , ) = priceFeed.latestRoundData();
        return answer;
    }

    function withdrawToken() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        usdtToken.transfer(msg.sender, usdtToken.balanceOf(address(this)));
    }
}