// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

interface ChainlinkPriceFeed {
    function latestAnswer() external view returns (int256);
}

interface IWSTETH {
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
}

interface ICurvePool {
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external payable returns (uint256);
}

interface IAavePool {
    function setUserEMode(uint8 categoryId) external;
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);
}

interface IAavePriceOracle {
    function getAssetPrice(address asset) external view returns (uint256);
}

interface IFactory {
    function fee() external view returns (uint256);
    function feeReceiver() external view returns (address);
}

contract AaveWstethStrategy {
    using SafeERC20 for ERC20;

    //                         ,--.        ,--.   ,--.
    // ,--.  ,--.,--,--.,--.--.`--' ,--,--.|  |-. |  | ,---.  ,---.
    //  \  `'  /' ,-.  ||  .--',--.' ,-.  || .-. '|  || .-. :(  .-'
    //   \    / \ '-'  ||  |   |  |\ '-'  || `-' ||  |\   --..-'  `)
    //    `--'   `--`--'`--'   `--' `--`--' `---' `--' `----'`----'

    bool private _initialized;
    address private _owner;
    address private _factory;

    uint256 public openSteth;
    uint256 public openTimestamp;

    //                              ,--.                    ,--.
    //  ,---. ,---. ,--,--,  ,---.,-'  '-. ,--,--.,--,--, ,-'  '-. ,---.
    // | .--'| .-. ||      \(  .-''-.  .-'' ,-.  ||      \'-.  .-'(  .-'
    // \ `--.' '-' '|  ||  |.-'  `) |  |  \ '-'  ||  ||  |  |  |  .-'  `)
    //  `---' `---' `--''--'`----'  `--'   `--`--'`--''--'  `--'  `----'

    uint256 public constant SAFE_BUFFER = 10; // wei
    uint256 public constant USE_VARIABLE_DEBT = 2;
    ERC20 public constant WETH = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20 public constant STETH = ERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    ERC20 public constant WSTETH = ERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    address public constant AAVE_ORACLE_V3 = 0x54586bE62E3c3580375aE3723C145253060Ca0C2;
    address public constant AAVE_ETH_WSTETH = 0x0B925eD163218f6662a35e0f0371Ac234f9E9371;
    address public constant STETH_ETH_CHAINLINK_ORACLE = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812;
    address public constant VARIABLE_DEBT_WSTETH = 0xC96113eED8cAB59cD8A66813bCB0cEb29F06D2e4;
    IAavePool public constant LENDING_POOL = IAavePool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    ICurvePool public constant CURVE_POOL_STETH = ICurvePool(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    //                     ,--.,--. ,---.,--.
    // ,--,--,--. ,---.  ,-|  |`--'/  .-'`--' ,---. ,--.--. ,---.
    // |        || .-. |' .-. |,--.|  `-,,--.| .-. :|  .--'(  .-'
    // |  |  |  |' '-' '\ `-' ||  ||  .-'|  |\   --.|  |   .-'  `)
    // `--`--`--' `---'  `---' `--'`--'  `--' `----'`--'   `----'

    modifier onlyFactory() {
        require(msg.sender == _factory, "Not factory");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    // ,--.        ,--.  ,--.  ,--.        ,--.,--.
    // `--',--,--, `--',-'  '-.`--' ,--,--.|  |`--',-----. ,---. ,--.--.
    // ,--.|      \,--.'-.  .-',--.' ,-.  ||  |,--.`-.  / | .-. :|  .--'
    // |  ||  ||  ||  |  |  |  |  |\ '-'  ||  ||  | /  `-.\   --.|  |
    // `--'`--''--'`--'  `--'  `--' `--`--'`--'`--'`-----' `----'`--'

    function initialize(address initialOwner, address factory) public {
        require(!_initialized, "Already initialized");
        _initialized = true;

        _owner = initialOwner;
        _factory = factory;

        WSTETH.approve(address(LENDING_POOL), type(uint256).max);
        STETH.approve(address(WSTETH), type(uint256).max);

        LENDING_POOL.setUserEMode(1);
    }

    //           ,--.
    // ,--.  ,--.`--' ,---. ,--.   ,--.
    //  \  `'  / ,--.| .-. :|  |.'.|  |
    //   \    /  |  |\   --.|   .'.   |
    //    `--'   `--' `----''--'   '--'

    function getAssetPrice(ERC20 token) public view returns (uint256) {
        if (token == STETH) {
            // Get the price of WETH
            uint256 wethPrice = IAavePriceOracle(AAVE_ORACLE_V3).getAssetPrice(address(WETH));
            // Get the STETH/ETH price from Chainlink
            uint256 stethEthPrice = uint256(ChainlinkPriceFeed(STETH_ETH_CHAINLINK_ORACLE).latestAnswer());
            // Return the price of STETH
            return (wethPrice * stethEthPrice) / (10 ** 18);
        } else {
            return IAavePriceOracle(AAVE_ORACLE_V3).getAssetPrice(address(token));
        }
    }

    function getSupplyBalance() public view returns (uint256) {
        (uint256 totalCollateralBase,,,,,) = getPositionData();
        return (totalCollateralBase * (10 ** 18)) / getAssetPrice(WSTETH);
    }

    function getBorrowBalance() public view returns (uint256) {
        (, uint256 totalDebtBase,,,,) = getPositionData();
        return (totalDebtBase * (10 ** 18)) / getAssetPrice(WSTETH);
    }

    function getLiquidity(ERC20 token) public view returns (uint256) {
        (,, uint256 availableBorrowsBase,,,) = getPositionData();
        return (availableBorrowsBase * (10 ** 18)) / getAssetPrice(token);
    }

    function getAssetBalance(ERC20 token) public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getPositionData()
        public
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return LENDING_POOL.getUserAccountData(address(this));
    }

    function getStethByWsteth(uint256 wstETHAmount) public view returns (uint256) {
        // TODO: this is only for testing
        // if (block.timestamp > 1700000000) {
        //     // return (wstETHAmount * 1181322067241296967) / 1e18; // around 4.1% added to today's stETH per wstETH
        //     return 103700000000000000000;
        // } else 
        //     return IWSTETH(address(WSTETH)).getStETHByWstETH(wstETHAmount);
        // }

        // TODO: use this when testing is done
        return IWSTETH(address(WSTETH)).getStETHByWstETH(wstETHAmount);
    }

    function getWstethBySteth(uint256 stETHAmount) public view returns (uint256) {
        return IWSTETH(address(WSTETH)).getWstETHByStETH(stETHAmount);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    //                   ,--.
    // ,--,--,--. ,--,--.`--',--,--,
    // |        |' ,-.  |,--.|      \
    // |  |  |  |\ '-'  ||  ||  ||  |
    // `--`--`--' `--`--'`--'`--''--'

    function enterPosition(uint256 iterations, uint256 slippageTolerance)
        external
        payable
        onlyFactory
        returns (uint256)
    {
        // Swap ETH for STETH
        uint256 initialEthBalance = msg.value;
        openSteth = _swapEthToSteth(initialEthBalance, slippageTolerance);

        // Wrap STETH to WSTETH
        _wrapSteth(openSteth);

        // Supply WSTETH to Aave
        _supply(WSTETH, getAssetBalance(WSTETH));

        for (uint256 i = 0; i < iterations; ++i) {
            // Borrow WSTETH
            _borrow(WSTETH, getLiquidity(WSTETH) - SAFE_BUFFER);
            // Supply WSTETH
            _supply(WSTETH, getAssetBalance(WSTETH));
        }

        // Record the timestamp
        openTimestamp = block.timestamp;

        return getLiquidity(WSTETH);
    }

    function exitPosition() external onlyOwner returns (uint256) {
        (,,,, uint256 ltv,) = getPositionData(); // 4 decimals

        for (uint256 i = 0; getBorrowBalance() > 0; ++i) {
            // Redeem WSTETH
            _redeemSupply(((getLiquidity(WSTETH) * 1e4) / ltv) - SAFE_BUFFER);
            // Repay WSTETH borrow
            _repayBorrow(getAssetBalance(WSTETH));
        }

        // If no WSTETH borrowed
        if (getBorrowBalance() == 0) {
            // Redeem WSTETH
            _redeemSupply(type(uint256).max);
        }

        // Calculate fee only if positive yield of initial deposit
        uint256 closeSteth = getStethByWsteth(getAssetBalance(WSTETH));
        if (closeSteth > openSteth) {
            uint256 yield = getWstethBySteth(closeSteth - openSteth);
            uint256 fee = (yield * IFactory(_factory).fee()) / 100;
            ERC20(WSTETH).safeTransfer(IFactory(_factory).feeReceiver(), fee);
        }

        // Return remaining WSTETH to owner
        return _withdrawToOwner(address(WSTETH));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

    function rescueErc20(address token) external onlyOwner {
        ERC20(token).safeTransfer(_owner, ERC20(token).balanceOf(address(this)));
    }

    receive() external payable {}

    // ,--.          ,--.                                ,--.
    // `--',--,--, ,-'  '-. ,---. ,--.--.,--,--,  ,--,--.|  |
    // ,--.|      \'-.  .-'| .-. :|  .--'|      \' ,-.  ||  |
    // |  ||  ||  |  |  |  \   --.|  |   |  ||  |\ '-'  ||  |
    // `--'`--''--'  `--'   `----'`--'   `--''--' `--`--'`--'

    function _wrapSteth(uint256 amount) private returns (uint256) {
        return IWSTETH(address(WSTETH)).wrap(amount);
    }

    function _calculateAmountOutMinimum(ERC20 tokenIn, ERC20 tokenOut, uint256 amountIn, uint256 slippageTolerance)
        internal
        view
        returns (uint256 amountOutMinimum)
    {
        // Use price oracle to calculate expected amount out
        uint256 priceIn = getAssetPrice(tokenIn); // Price of tokenIn
        uint256 priceOut = getAssetPrice(tokenOut); // Price of tokenOut
        uint256 amountOutExpected = (amountIn * priceIn) / priceOut; // Expected output amount

        // Calculate amountOutMinimum with slippage tolerance
        return (amountOutExpected * (10000 - slippageTolerance)) / 10000;
    }

    function _swapEthToSteth(uint256 amountIn, uint256 slippageTolerance) internal returns (uint256) {
        return CURVE_POOL_STETH.exchange{value: amountIn}(
            0, 1, amountIn, _calculateAmountOutMinimum(WETH, STETH, amountIn, slippageTolerance)
        );
    }

    function _supply(ERC20 token, uint256 amount) private {
        LENDING_POOL.deposit(address(token), amount, address(this), 0);
    }

    function _borrow(ERC20 token, uint256 amount) private {
        LENDING_POOL.borrow(address(token), amount, USE_VARIABLE_DEBT, 0, address(this));
    }

    function _redeemSupply(uint256 amount) private {
        LENDING_POOL.withdraw(address(WSTETH), amount, address(this));
    }

    function _repayBorrow(uint256 amount) private {
        LENDING_POOL.repay(address(WSTETH), amount, USE_VARIABLE_DEBT, address(this));
    }

    function _withdrawToOwner(address asset) private returns (uint256) {
        uint256 balance = ERC20(asset).balanceOf(address(this));
        ERC20(asset).safeTransfer(_owner, balance);
        return balance;
    }
}