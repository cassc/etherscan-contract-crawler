// SPDX-License-Identifier: MIT 
//    ▄██████▄   ▄█        ▄█  ████████▄   ███    █▄   ▄█  ████████▄  
//   ███    ███ ███       ███  ███    ███  ███    ███ ███  ███   ▀███ 
//   ███    █▀  ███       ███▌ ███    ███  ███    ███ ███▌ ███    ███ 
//  ▄███        ███       ███▌ ███    ███  ███    ███ ███▌ ███    ███ 
// ▀▀███ ████▄  ███       ███▌ ███    ███  ███    ███ ███▌ ███    ███ 
//   ███    ███ ███       ███  ███    ███  ███    ███ ███  ███    ███ 
//   ███    ███ ███▌    ▄ ███  ███  ▀ ███  ███    ███ ███  ███   ▄███ 
//   ████████▀  █████▄▄██ █▀    ▀██████▀▄█ ████████▀  █▀   ████████▀  
//              ▀                                                     
// https://t.me/glitchproto
// https://twitter.com/protocolglitch
// https://discord.gg/jyehnJHW9q
// GLIQUID Token for the GLITCH Protocol
//
pragma solidity ^0.8.0;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC20/ERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/ReentrancyGuard.sol";
import "https://raw.githubusercontent.com/smartcontractkit/chainlink/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Pausable.sol";
import "./GLIQUIDITY.sol";

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract GLIQUID is ERC20, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    struct TokenData {
        address tokenAddress;
        address chainlinkFeed;
    }

    mapping(address => TokenData) public tokens;
    address[] public tokenAddresses;
    address public owner;
    GLIQUIDITY public gliquidity;
    
    modifier onlyGLIQUIDITY() {
        require(msg.sender == address(gliquidity), "Not authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addToken(address _tokenAddress, address _chainlinkFeed) public onlyOwner {
        require(tokens[_tokenAddress].tokenAddress == address(0), "Token already added");
        tokens[_tokenAddress] = TokenData(_tokenAddress, _chainlinkFeed);
        tokenAddresses.push(_tokenAddress);
    }

    constructor() ERC20("GLIQUID Token", "GLIQUID") {
        owner = msg.sender;
        // Initialize with Chainlink price feed addresses for each token
        addToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // WETH with ETH/USD Price Feed
        addToken(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6); // USDC with USDC/USD Price Feed
        addToken(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c); // WBTC with BTC/USD Price Feed
        addToken(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9); // DAI with DAI/USD Price Feed 
        addToken(0xdAC17F958D2ee523a2206206994597C13D831ec7, 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D); // USDT with USDT/USD Price Feed
    }

    function getTokenAddresses() external view returns (address[] memory) {
        return tokenAddresses;
    }

    function isTokenSupported(address token) external view returns (bool) {
        for (uint i = 0; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == token) {
                return true;
            }
        }
        return false;
    }

    function updateTokenFeedAddress(address _tokenAddress, address _newFeedAddress) external onlyOwner {
        require(_tokenAddress != address(0) && _newFeedAddress != address(0), "Invalid address");
        
        require(tokens[_tokenAddress].tokenAddress != address(0), "Token not recognized");
        
        tokens[_tokenAddress].chainlinkFeed = _newFeedAddress;
    }

    function getTokenValueInPool(address _tokenAddress) public view returns (uint256) {
        uint256 tokenDecimals = IExtendedERC20(_tokenAddress).decimals();
        uint256 tokenBalance = IERC20(_tokenAddress).balanceOf(address(gliquidity));
        
        uint256 tokenPrice = getTokenPriceUSD(_tokenAddress);
        
        return tokenBalance.mul(tokenPrice).div(10 ** tokenDecimals);
    }

    function getWeight(address _tokenAddress) public view returns (uint256) {
        uint256 tokenValueInPool = getTokenValueInPool(_tokenAddress);

        uint256 totalValue = getTotalValueInPool();

        if (totalValue == 0) {
            return 0;
        }

        if (tokenValueInPool == 0) {
            return 0;
        }

        return tokenValueInPool.mul(1e18).div(totalValue);
    }

    function getTotalValueInPool() public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            
            uint256 tokenValue = getTokenValueInPool(tokenAddress);
            
            totalValue = totalValue.add(tokenValue);
        }
        return totalValue;
    }

    function getTokenPriceUSD(address _tokenAddress) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(tokens[_tokenAddress].chainlinkFeed);
        (, int price,,,) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return uint256(price).mul(10 ** 18).div(10 ** decimals);
    }

    function getPrice() public view returns (uint256) {
        uint256 gliquidSupply = totalSupply();

        if (gliquidSupply == 0) {
            return 0;
        }

        uint256 totalValue = 0;

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            uint256 tokenDecimals = IExtendedERC20(tokenAddress).decimals();
            uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(gliquidity));
        
            uint256 scaledTokenBalance;
            if (tokenDecimals < 18) {
                scaledTokenBalance = tokenBalance.mul(10 ** (18 - tokenDecimals));
            } else {
                scaledTokenBalance = tokenBalance;
            }

            uint256 tokenPrice = getTokenPriceUSD(tokenAddress);
            totalValue = totalValue.add(scaledTokenBalance.mul(tokenPrice));
        }

        return totalValue.div(gliquidSupply);
    }

    function setGLIQUIDITY(address _gliquidity) external onlyOwner {
        gliquidity = GLIQUIDITY(_gliquidity);
    }

    function mint(address to, uint256 amount) external onlyGLIQUIDITY {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyGLIQUIDITY {
        _burn(from, amount);
    }

    function transfer(address, uint256) public virtual override whenNotPaused returns (bool) {
        revert("Function disabled. Use transferAll instead.");
    }

    function transferFrom(address, address, uint256) public virtual override whenNotPaused returns (bool) {
        revert("Function disabled. Use transferAll instead.");
    }

    function transferAll(address recipient) public whenNotPaused returns (bool) {
        uint256 amount = balanceOf(msg.sender);
        require(amount > 0, "You have no GLIQUID tokens to transfer");
        gliquidity.gclaim(msg.sender);
        gliquidity.handleTransfer(msg.sender, recipient);
        super.transfer(recipient, amount);

        return true;
    }
}