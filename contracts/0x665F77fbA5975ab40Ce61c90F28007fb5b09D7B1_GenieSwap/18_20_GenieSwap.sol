// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "./lib/TickMath.sol";
import "./lib/FullMath.sol";

interface IUSDT {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract GenieSwap is ERC20, Ownable, ReentrancyGuard {

    event Transformed(
        address token,
        uint256 amount, 
        uint256 value,
        uint256 minted,
        uint256 rate         
    );

    event Referred(
        address minter,
        address referrer,
        uint256 value,
        uint256 rate,
        address token,
        uint256 rewardRate,
        uint256 rewardAmount        
    );

    event MintingClosed(
        uint256 minted,
        uint256 team,
        uint256 liquidity
    );

    constructor(
        address _flush
    ) payable ERC20("GenieSwap", "GENIE") {
        // Pools to use
        pools[WETH] = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640; // ETH/USDC  0.05%
        pools[WBTC] = 0x99ac8cA7087fA4A2A1FB6357269965A2014ABc35; // WBTC/USDC 0.3%
        pools[USDC] = 0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168; // DAI/USDC  0.01%
        pools[USDT] = 0x3416cF6C708Da44DB2624D63ea0AAef7113527C6; // USDT/USDC 0.01%
        pools[DAI]  = 0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168; // DAI/USDC  0.01%

        // Flush address
        flushAddress = _flush;

        // Set launch day
        launchDay = _today();
    }

    // Pools to use for TWAP
    mapping(address => address) public pools;

    // TWAP for pricing
    int32 public constant twapInterval = 60 minutes;

    // @dev address to tokens to
    address public flushAddress;       
    bool public flushOnTransaction;  

    // Accepted tokens
    address immutable WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address immutable WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address immutable USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address immutable USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address immutable DAI  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // Referrer value
    mapping(address => uint256) public referrerValue;    

    // Launch settings
    uint64 public launchDay;
    uint64 public constant launchDays    = 365;
    uint64 public constant referrerRate  = 5;
    uint64 public constant customerBonus = 15;
    uint64 public constant endTeam       = 25;
    uint64 public constant endLiquidity  = 10;

    // Allow for closing
    bool public mintPhaseClosed = false;

    // @dev get current day
    function today() external view returns (uint64) {
        return _today();
    }

    // @dev returns days since launch
    function currentDay() external view returns (uint64) {
        return _currentDay();
    }

    // @dev returns current launch window
    function currentWindow() external view returns(uint64) {
        return _currentWindow();
    }

    // @dev returns next window timestamp 
    function nextWindow() external view returns(uint64) {
        return launchDay + ((_currentWindow() + 1) * _windowDays() * 1 days);
    }

    // @dev returns days per window 
    function windowDays() external view returns(uint64) {
        return _windowDays();
    }

    // @dev returns current launch mint rate
    function mintRate() external view returns (uint256) {
        return _mintRate(_currentWindow());
    }

    // @dev returns next launch mint rate
    function nextRate() external view returns (uint256) {
        return _mintRate(_currentWindow() + 1);
    }    

    // @dev returns reward rate for an address
    function rewardRate(address referrer) external view returns (uint256) {
        return _rewardRate(referrer);
    }

    // @dev quote token 
    function quoteToken(address token, uint256 amount, address caller) external view returns (
        uint256 value,
        uint256 rate,
        uint256 minted
    ) {
        return _quoteToken(token, amount, caller);
    }

    // @dev mint token for sender
    function mintToken(address token, uint256 amount, address referrer) external payable returns (
        uint256 value,
        uint256 rate,
        uint256 minted
    ) {
        return _mintToken(token, amount, msg.sender, referrer);
    }

    // @dev mint token for an address 
    function mintTokenFor(address token, uint256 amount, address to) external payable returns (
        uint256 value,
        uint256 rate,
        uint256 minted
    ) {
        return _mintToken(token, amount, to, address(0));
    }

    // @dev close the launch phase
    function closeLaunchPhase() external onlyOwner nonReentrant returns (
        uint256 minted,
        uint256 team,
        uint256 liquidity
    ) {
        // Restrict to after launch phase
        require(_currentDay() > launchDays, 'Minting phase still in progress');
        
        // Only closable once
        require(!mintPhaseClosed, 'Minting already closed');

        // Close mint phase
        mintPhaseClosed = true;

        // Total minted during launch phase
        minted = totalSupply();

        // Mint team token supply
        team = (minted * endTeam) / 100;
        _mint(msg.sender, team);

        // Mint liquidity tokens
        liquidity = (minted * endLiquidity) / 100;        
        _mint(msg.sender, liquidity);

        // Emit event
        emit MintingClosed(
                minted,
                team,
                liquidity
            );
    }

    // @dev allow owner to set the launch date
    function setLaunchDay() external onlyOwner{
        // Restrict to first 30 days
        require(_currentDay() < 30, 'Minting phase has started');

        launchDay = _today();
    }

    // @dev allow owner to set flush address
    function setFlushAddress(address to) external onlyOwner{
        require(to != address(0), 'flushAddress can not be zero address');
        flushAddress = to;
    }

    // @dev allow owner to enable / disable flush on transaction
    function setFlushOnTransaction(bool immediately) external onlyOwner{
        flushOnTransaction = immediately;
    }

    // @dev flush eth
    function flush() external onlyOwner {
        Address.sendValue(payable(flushAddress), address(this).balance);
    }

    // @dev flush token
    function flushToken(address token) external onlyOwner {
        SafeERC20.safeTransfer(IERC20(token), flushAddress, IERC20(token).balanceOf(address(this)));
    }

    // @dev get current day
    function _today() internal view returns (uint64) {
        return uint64((block.timestamp / 1 days) * 1 days);
    }

    // @dev returns days since launch
    function _currentDay() internal view returns (uint64 since) {
        since = _today() - launchDay;
        if(since > 0) { since = since / 1 days; }
    }

    // @dev returns current launch window
    function _currentWindow() internal view returns(uint64 window) {
        window = _currentDay();
        if(window > 0) { window = window / _windowDays(); }
    }

    // @dev returns days per window
    function _windowDays() internal view returns(uint64) {
        // 2 days for testnet
        if(block.chainid == 941) {
            return 2;
        }
        // 30 for mainnet
        return 30;
    }

    // @dev returns current rate
    function _mintRate(uint64 window) pure internal returns (uint256) {
        if(window < 2)   { return 10; } // Month 2:  0.010
        if(window < 3)   { return 15; } // Month 3:  0.015
        if(window < 4)   { return 15; } // Month 4:  0.015
        if(window < 5)   { return 20; } // Month 5:  0.020
        if(window < 6)   { return 21; } // Month 6:  0.021 
        if(window < 7)   { return 22; } // Month 7:  0.022
        if(window < 8)   { return 23; } // Month 8:  0.023
        if(window < 9)   { return 24; } // Month 9:  0.024
        if(window < 10)  { return 25; } // Month 10: 0.025
        if(window < 11)  { return 26; } // Month 11: 0.026
        return 28;                      // Month 12: 0.028
    }

    // @dev returns reward rate for an address
    function _rewardRate(address referrer) view internal returns (uint256) { 
        uint256 value = referrerValue[referrer];
        if(value >= 500000_000000 ) { return 22; } // Above $500,000 = 22%
        if(value >= 250000_000000 ) { return 15; } // $250,000 - $500,000 = 15%
        if(value >= 100000_000000 ) { return 12; } // $100,000 - $250,000 = 12%
        if(value >=  50000_000000 ) { return 9; }  // $50,000 - $100,000 = 9%
        if(value >=  25000_000000 ) { return 7; }  // $25,000 - $50,000 = 7%
        return 5;                                  // $0 - $25,000 = 5%
    }

    // @dev quote token using TWAP 
    function _quoteToken(address token, uint256 amount, address caller) internal view returns (
        uint256 value,
        uint256 rate,
        uint256 minted
    ) {
        // Get pool (use WETH for ETH)
        address pool = pools[token == address(0) ? WETH : token];

        // Check token accepted
        require(pool != address(0), 'Token not accepted');

        // Get current price
        uint256 price = _getPriceX96FromSqrtPriceX96(_getSqrtTwapX96(pool));

        // USDC is 1 to 1
        if(token == USDC) {
            value = amount;
        }
        // Use USDC side of pool
        else if(IUniswapV3Pool(pool).token0() == USDC) {
            value = (amount * (2**96)) / price;
        } 
        // Otherwise other side of pool
        else {
            value = amount * price / (2 ** 96);
        }

        // Current rate to use
        rate = _mintRate(_currentWindow());

        // Convert using rate and to 18 decimals and 3 for basis
        minted = (value * 10 ** 15) / rate;

        // Include 15% bonus when minting on behalf of customer
        if(caller == owner()) {
            minted += (minted * customerBonus) / 100;
        }
    }

    // @dev mint token using TWAP 
    function _mintToken(address token, uint256 amount, address to, address referrer) internal nonReentrant returns (
        uint256 value,
        uint256 rate,
        uint256 minted
    ) {

        // Require at least something
        require(amount > 0, 'Amount must be > 0');

        // Restrict to launch days
        require(_currentDay() < launchDays, 'Minting phase has ended');

        // Get pool (use WETH for ETH)
        address pool = pools[token == address(0) ? WETH : token];

        // Check token accepted
        require(pool != address(0), 'Token not accepted');

        // Get value rate and total to mint
        (value, rate, minted) = _quoteToken(token, amount, msg.sender);

        // Deal with ETH
        if(token == address(0)) {
            require(amount == msg.value, 'Amount does not match msg.value');
        }
        // Transfer token
        else {
            if(token == USDT) {
                // USDT does not conform to IERC20
                IUSDT(token).transferFrom(msg.sender, address(this), amount);
            }
            else {
                // IERC20 returns a value
                IERC20(token).transferFrom(msg.sender, address(this), amount);
            }
        }

        // Emit event
        emit Transformed(
            token,
            amount,
            value,
            minted,
            rate 
        );

        // Mint tokens for sender
        _mint(to, minted);

        // Reward referrer when not owner or self
        if(referrer != address(0) && referrer != owner() && msg.sender != owner() && referrer != msg.sender) {

            // Mint for referrer
            _mint(referrer, (minted * referrerRate) / 100);

            // Increase referrer value
            referrerValue[referrer] += value;

            // Reward referrer
            uint256 rewardedRate = _rewardRate(referrer);
            uint256 rewardAmount = (amount * rewardedRate) / 100;

            // Transfer reward
            if(rewardAmount > 0) {
                // ETH
                if(token == address(0)) {
                    payable(referrer).transfer(rewardAmount);
                }
                // ERC20
                else {
                    SafeERC20.safeTransfer(IERC20(token), referrer, rewardAmount);
                }
            }
            
            // Emit event
            emit Referred(
                msg.sender,
                referrer,
                value,
                rate,
                token,
                rewardedRate,
                rewardAmount
            );
        }

        // Flush on transaction
        if(flushOnTransaction && token != address(0)) {
            SafeERC20.safeTransfer(IERC20(token), flushAddress, IERC20(token).balanceOf(address(this)));
        }
    }

    // @dev get TWAP from pool
    function _getSqrtTwapX96(address uniswapV3Pool) internal view returns (uint160 sqrtPriceX96) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = uint32(twapInterval);
        secondsAgos[1] = 0;
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);
          sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
            int24((tickCumulatives[1] - tickCumulatives[0]) / twapInterval)
        );
    }

    // @dev get price from sqrt
    function _getPriceX96FromSqrtPriceX96(uint160 sqrtPriceX96) internal pure returns(uint256 priceX96) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }


}