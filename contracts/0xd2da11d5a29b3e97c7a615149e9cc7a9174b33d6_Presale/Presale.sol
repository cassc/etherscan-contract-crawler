/**
 *Submitted for verification at Etherscan.io on 2023-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    using SafeMath for uint256;

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Presale is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    IERC20 public usdtToken;
    AggregatorV3Interface internal price_feed;
    uint256 public usdRate = 1666; // 1 USD = 1666 Tokens
    uint256 public usdRaised;
    uint256 public minUsdtPurchase = 10e6; // 10 USDT minimum purchase
    uint256 public minEthPurchase = 0.005 ether; // 0.005 ETH minimum purchase
    uint256 public startTime;
    uint256 public endTime;

    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensRecovered(address indexed sender, address indexed tokenAddress, uint256 amount);

    constructor(address _tokenAddress, address _usdtTokenAddress, address _oracle, uint256 _startTime, uint256 _endTime) {
        token = IERC20(_tokenAddress);
        usdtToken = IERC20(_usdtTokenAddress);
        price_feed = AggregatorV3Interface(_oracle);
        startTime = _startTime;
        endTime = _endTime;
        _transferOwnership(msg.sender);
    }

    modifier onlyDuringSale() {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Presale is not active");
        _;
    }

    function getEthInUsdt() internal view returns (uint256) {
        (, int256 price, , , ) = price_feed.latestRoundData();
        price = price * 1e10;
        return uint256(price);
    }

    function buyTokensWithETH() external payable onlyDuringSale {
        require(msg.value >= minEthPurchase, "ETH amount below minimum purchase");

        uint256 amountInUsdt = (msg.value * getEthInUsdt()) / 1e30;

        uint256 amountInTokens = amountInUsdt.mul(usdRate).mul(1e18).div(1e6);
        require(amountInTokens <= token.balanceOf(address(this)), "Not enough tokens available");

        (bool ethTransferSuccess, ) = payable(owner()).call{value: msg.value}("");
        require(ethTransferSuccess, "ETH transfer failed");

        token.transfer(msg.sender, amountInTokens);
        usdRaised = usdRaised.add(amountInUsdt);
        emit TokensPurchased(msg.sender, amountInTokens);
    }

    function buyTokensWithUSDT(uint256 usdtAmount) external onlyDuringSale {
        require(usdtAmount >= minUsdtPurchase, "USDT amount below minimum purchase");

        uint256 amountInUsdt = usdtAmount;
        uint256 amountInTokens = amountInUsdt.mul(usdRate).mul(1e18).div(1e6);

        require(amountInTokens <= token.balanceOf(address(this)), "Not enough tokens available");
        require(usdtToken.transferFrom(msg.sender, owner(), amountInUsdt), "USDT transfer failed");

        token.transfer(msg.sender, amountInTokens);
        usdRaised = usdRaised.add(amountInUsdt);
        emit TokensPurchased(msg.sender, amountInTokens);
    }

    function setUsdRate(uint256 newUsdRate) external onlyOwner {
        require(newUsdRate > 0, "USD rate must be greater than zero");
        usdRate = newUsdRate;
    }

    function setMinUsdtPurchase(uint256 amount) external onlyOwner {
        minUsdtPurchase = amount;
    }

    function setMinEthPurchase(uint256 amount) external onlyOwner {
        minEthPurchase = amount;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
    }

    function setTokenContract(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "Token contract address cannot be zero");
        token = IERC20(newTokenAddress);
    }

    function setUsdtTokenContract(address newUsdtTokenAddress) external onlyOwner {
        require(newUsdtTokenAddress != address(0), "USDT Token contract address cannot be zero");
        usdtToken = IERC20(newUsdtTokenAddress);
    }

    function withdrawFunds() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: ethBalance}("");
        require(success, "ETH withdrawal failed");
    }

    function recoverWrongTokens(address _tokenAddress) external onlyOwner {
        IERC20 wrongToken = IERC20(_tokenAddress);
        uint256 balance = wrongToken.balanceOf(address(this));
        require(balance > 0, "No tokens to recover");

        require(wrongToken.transfer(owner(), balance), "Token recovery failed");

        emit TokensRecovered(msg.sender, _tokenAddress, balance);
    }
}