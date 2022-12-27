// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/uniswapv2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "hardhat/console.sol";

struct VaultParams {
    address quoteToken;
    address baseToken;
    address aggregatorAddr;
    address uniswapRouter;
    address[] uniswapPath;
    address ubxnToken;
    address ubxnPairToken;
    address quotePriceFeed;
    address basePriceFeed;
    uint256 maxCap;
}

struct FeeParams {
    // percent values for the fees
    uint16 pctDeposit;
    uint16 pctWithdraw;
    uint16 pctPerfBurning;
    uint16 pctPerfStakers;
    uint16 pctPerfAlgoDev;
    uint16 pctPerfUpbots;
    uint16 pctPerfPartners;
    uint16 pctTradUpbots;
    // address for the fees
    address addrStakers;
    address addrAlgoDev;
    address addrUpbots;
    address addrPartner;
}

contract VaultV2 is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    string public vaultName;
    address public strategist;

    VaultParams public vaultParams;
    FeeParams public feeParams;
    bool public initialized = false;

    mapping(address => bool) public whiteList;

    address[] public uniswapBackPath;

    bool public position = false; // false: closed, true: opened
    uint256 public soldAmount = 0;
    uint256 public profit = PERCENT_MAX;

    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    uint256 private constant MAX_APPROVAL = type(uint256).max;
    uint16 public constant PERCENT_MAX = 10000;
    uint256 private constant PRICE_DECIMALS = (10**18);
    uint16 public constant SLIPPAGE = 9850; // 1.5%
    uint16 public constant SLIPPAGE_SELL = 9500; // 5%

    event Initialized(VaultParams, FeeParams);
    event WhiteListAdded(address);
    event WhiteListRemoved(address);
    event TradeDone(bool, uint256, uint256);
    event StrategistUpdated(address);

    constructor(string memory _name, address _strategist)
        ERC20(
            string(abi.encodePacked("xUBXN_", _name)),
            string(abi.encodePacked("xUBXN_", _name))
        )
    {
        require(_strategist != address(0));

        vaultName = _name;
        strategist = _strategist;
    }

    function initialize(
        VaultParams calldata _vaultParams,
        FeeParams calldata _feeParams
    ) external {
        require(msg.sender == strategist, "NS");
        require(!initialized, "already initialized");

        require(_vaultParams.quoteToken != address(0));
        require(_vaultParams.baseToken != address(0));
        require(_vaultParams.aggregatorAddr != address(0));
        require(_vaultParams.ubxnToken != address(0));
        require(_vaultParams.ubxnPairToken != address(0));
        require(_vaultParams.quotePriceFeed != address(0));
        require(_vaultParams.basePriceFeed != address(0));
        require(_vaultParams.maxCap > 0);
        require(_vaultParams.uniswapPath.length > 1);
        require(_vaultParams.uniswapPath[0] == _vaultParams.quoteToken);
        require(
            _vaultParams.uniswapPath[_vaultParams.uniswapPath.length - 1] ==
                _vaultParams.baseToken
        );
        for (uint256 i = 0; i < _vaultParams.uniswapPath.length; i++) {
            uniswapBackPath.push(
                _vaultParams.uniswapPath[
                    _vaultParams.uniswapPath.length - 1 - i
                ]
            );
        }

        require(_feeParams.pctDeposit < PERCENT_MAX);
        require(_feeParams.pctWithdraw < PERCENT_MAX);
        require(_feeParams.pctTradUpbots < PERCENT_MAX);
        require(_feeParams.pctPerfAlgoDev < PERCENT_MAX);
        require(_feeParams.pctPerfPartners < PERCENT_MAX);
        require(_feeParams.pctPerfStakers < PERCENT_MAX);
        require(_feeParams.pctPerfBurning < PERCENT_MAX);
        require(_feeParams.pctPerfUpbots < PERCENT_MAX);

        require(_feeParams.addrStakers != address(0));
        require(_feeParams.addrAlgoDev != address(0));
        require(_feeParams.addrUpbots != address(0));

        vaultParams = _vaultParams;
        feeParams = _feeParams;

        IERC20(vaultParams.quoteToken).safeApprove(
            vaultParams.aggregatorAddr,
            MAX_APPROVAL
        );

        IERC20(vaultParams.baseToken).safeApprove(
            vaultParams.aggregatorAddr,
            MAX_APPROVAL
        );

        IERC20(vaultParams.quoteToken).safeApprove(
            vaultParams.uniswapRouter,
            MAX_APPROVAL
        );

        IERC20(vaultParams.baseToken).safeApprove(
            vaultParams.uniswapRouter,
            MAX_APPROVAL
        );

        initialized = true;

        emit Initialized(vaultParams, feeParams);
    }

    function setStrategist(address _address) external {
        require(msg.sender == strategist, "NS");
        require(_address != address(0), "IA");
        strategist = _address;
        emit StrategistUpdated(_address);
    }

    function addToWhiteList(address _address) external {
        require(msg.sender == strategist, "NS");
        require(_address != address(0), "IA");
        whiteList[_address] = true;
        emit WhiteListAdded(_address);
    }

    function removeFromWhiteList(address _address) external {
        require(msg.sender == strategist, "NS");
        require(_address != address(0), "IA");
        whiteList[_address] = false;
        emit WhiteListRemoved(_address);
    }

    function depositQuote(uint256 amount) external nonReentrant {
        require(initialized, "NI");

        // Check max cap
        uint256 oraclePrice = getDerivedPrice(false);
        uint256 _poolSize = (IERC20(vaultParams.baseToken).balanceOf(
            address(this)
        ) * oraclePrice) /
            PRICE_DECIMALS +
            IERC20(vaultParams.quoteToken).balanceOf(address(this)); // get approximate pool size to compare with max cap
        require(
            vaultParams.maxCap == 0 || _poolSize + amount < vaultParams.maxCap,
            "MC"
        );

        // transfer quote from sender to this vault
        uint256 _before = IERC20(vaultParams.quoteToken).balanceOf(
            address(this)
        );
        IERC20(vaultParams.quoteToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        uint256 _after = IERC20(vaultParams.quoteToken).balanceOf(
            address(this)
        );
        amount = _after - _before; // Additional check for deflationary tokens
        _poolSize = _before;

        // pay deposit fees
        amount = takePartnerFees(vaultParams.quoteToken, amount, true);

        // swap Quote to Base if position is opened
        if (position == true) {
            soldAmount = soldAmount + amount;

            _before = IERC20(vaultParams.baseToken).balanceOf(address(this));
            _swapWithUni(true, amount, getDerivedPrice(true));
            _after = IERC20(vaultParams.baseToken).balanceOf(address(this));
            amount = _after - _before;

            _poolSize = _before;
        }

        // calculate share and send back xUBXN
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupply()) / _poolSize;
        }
        require(shares > 0, "SC");
        _mint(msg.sender, shares);
    }

    function depositBase(uint256 amount) external nonReentrant {
        require(initialized, "NI");

        // . Check max cap
        uint256 oraclePrice = getDerivedPrice(false);
        uint256 _poolSize = (IERC20(vaultParams.baseToken).balanceOf(
            address(this)
        ) * oraclePrice) /
            PRICE_DECIMALS +
            IERC20(vaultParams.quoteToken).balanceOf(address(this)); // get approximate pool size to compare with max cap
        require(
            vaultParams.maxCap == 0 ||
                _poolSize + (oraclePrice * amount) / PRICE_DECIMALS <
                vaultParams.maxCap,
            "MC"
        );

        // . transfer base from sender to this vault
        uint256 _before = IERC20(vaultParams.baseToken).balanceOf(
            address(this)
        );
        IERC20(vaultParams.baseToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        uint256 _after = IERC20(vaultParams.baseToken).balanceOf(address(this));
        amount = _after - _before; // Additional check for deflationary tokens
        _poolSize = _before;

        // 3. pay deposit fees
        amount = takePartnerFees(vaultParams.baseToken, amount, true);

        // 4. swap Base to Quote if position is closed
        if (position == false) {
            _before = IERC20(vaultParams.quoteToken).balanceOf(address(this));
            _swapWithUni(false, amount, oraclePrice);
            _after = IERC20(vaultParams.quoteToken).balanceOf(address(this));
            amount = _after - _before;

            _poolSize = _before;
        }

        // update soldAmount if position is opened
        if (position == true) {
            soldAmount = soldAmount + (oraclePrice * amount) / PRICE_DECIMALS;
        }

        // 5. calculate share and send back xUBXN
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupply()) / _poolSize;
        }
        require(shares > 0, "SC");
        _mint(msg.sender, shares);
    }

    function withdraw(uint256 shares) external nonReentrant {
        require(initialized, "NI");
        require(shares <= balanceOf(msg.sender), "IA2");

        uint256 withdrawAmount;

        if (position == false) {
            withdrawAmount =
                (IERC20(vaultParams.quoteToken).balanceOf(address(this)) *
                    shares) /
                totalSupply();
            if (withdrawAmount > 0) {
                // pay withdraw fees
                withdrawAmount = takePartnerFees(
                    vaultParams.quoteToken,
                    withdrawAmount,
                    false
                );
                IERC20(vaultParams.quoteToken).safeTransfer(
                    msg.sender,
                    withdrawAmount
                );
            }
        }

        if (position == true) {
            withdrawAmount =
                (IERC20(vaultParams.baseToken).balanceOf(address(this)) *
                    shares) /
                totalSupply();
            uint256 amountInQuote = (getDerivedPrice(false) * withdrawAmount) /
                PRICE_DECIMALS;

            uint256 thisSoldAmount = (soldAmount * shares) / totalSupply();
            uint256 _profit = (profit * amountInQuote) / thisSoldAmount;
            if (_profit > PERCENT_MAX) {
                uint256 profitAmount = (withdrawAmount *
                    (_profit - PERCENT_MAX)) / _profit;
                uint256 feeAmount = takePerfFees(
                    vaultParams.baseToken,
                    profitAmount
                );
                withdrawAmount = withdrawAmount - feeAmount;
            }
            soldAmount = soldAmount - thisSoldAmount;

            if (withdrawAmount > 0) {
                // pay withdraw fees
                withdrawAmount = takePartnerFees(
                    vaultParams.baseToken,
                    withdrawAmount,
                    false
                );
                IERC20(vaultParams.baseToken).safeTransfer(
                    msg.sender,
                    withdrawAmount
                );
            }
        }

        // burn these shares from the sender wallet
        _burn(msg.sender, shares);
    }

    function withdrawQuote(uint256 shares) external nonReentrant {
        require(initialized, "NI");
        require(shares <= balanceOf(msg.sender), "IA2");

        uint256 withdrawAmount;

        if (position == false) {
            withdrawAmount =
                (IERC20(vaultParams.quoteToken).balanceOf(address(this)) *
                    shares) /
                totalSupply();
        }

        if (position == true) {
            withdrawAmount =
                (IERC20(vaultParams.baseToken).balanceOf(address(this)) *
                    shares) /
                totalSupply();
            uint256 oraclePrice = getDerivedPrice(false);
            uint256 amountInQuote = (oraclePrice * withdrawAmount) /
                PRICE_DECIMALS;

            uint256 thisSoldAmount = (soldAmount * shares) / totalSupply();
            uint256 _profit = (profit * amountInQuote) / thisSoldAmount;
            if (_profit > PERCENT_MAX) {
                uint256 profitAmount = (withdrawAmount *
                    (_profit - PERCENT_MAX)) / _profit;
                uint256 feeAmount = takePerfFees(
                    vaultParams.baseToken,
                    profitAmount
                );
                withdrawAmount = withdrawAmount - feeAmount;
            }
            soldAmount = soldAmount - thisSoldAmount;

            if (withdrawAmount > 0) {
                uint256 _before = IERC20(vaultParams.quoteToken).balanceOf(
                    address(this)
                );
                _swapWithUni(false, withdrawAmount, oraclePrice);
                uint256 _after = IERC20(vaultParams.quoteToken).balanceOf(
                    address(this)
                );
                withdrawAmount = _after - _before;
            }
        }

        if (withdrawAmount > 0) {
            // pay withdraw fees
            withdrawAmount = takePartnerFees(
                vaultParams.quoteToken,
                withdrawAmount,
                false
            );
            IERC20(vaultParams.quoteToken).safeTransfer(
                msg.sender,
                withdrawAmount
            );
        }

        // burn these shares from the sender wallet
        _burn(msg.sender, shares);
    }

    function buy(bytes calldata swapCallData) external nonReentrant {
        require(initialized, "NI");
        require(whiteList[msg.sender], "NW");
        require(position == false, "PO");

        // 1. get the amount of quoteToken to trade
        uint256 amount = IERC20(vaultParams.quoteToken).balanceOf(
            address(this)
        );
        require(amount > 0, "IA3");

        // 2. takeTradingFees
        amount = takeTradingFees(vaultParams.quoteToken, amount);

        // 3. save the remaining to soldAmount
        soldAmount = amount;

        // 4. swap tokens to Base
        _swapWithAggregator(swapCallData, true, getDerivedPrice(true));

        // 5. update position
        position = true;

        // 6. emit event
        emit TradeDone(
            position,
            soldAmount,
            IERC20(vaultParams.baseToken).balanceOf(address(this))
        );
    }

    function sell(bytes calldata swapCallData) external nonReentrant {
        require(initialized, "NI");
        require(whiteList[msg.sender], "NW");
        require(position == true, "PO");

        // 1. get the amount of baseToken to trade
        uint256 baseAmount = IERC20(vaultParams.baseToken).balanceOf(
            address(this)
        );
        require(baseAmount > 0, "IA3");

        // 2. calc base fee amount
        baseAmount = takeTradingFees(vaultParams.baseToken, baseAmount);

        // 4. swap tokens to Quote and get the newly create quoteToken
        _swapWithAggregator(swapCallData, false, getDerivedPrice(false));
        uint256 quoteAmount = IERC20(vaultParams.quoteToken).balanceOf(
            address(this)
        );

        // 6. calculate the profit in percent
        profit = (profit * quoteAmount) / soldAmount;

        // 7. take performance fees in case of profit
        if (profit > PERCENT_MAX) {
            uint256 profitAmount = (quoteAmount * (profit - PERCENT_MAX)) /
                profit;
            takePerfFees(vaultParams.quoteToken, profitAmount);
            profit = PERCENT_MAX;
        }

        // 8. update soldAmount
        soldAmount = 0;

        // 9. update position
        position = false;

        // emit event
        emit TradeDone(position, baseAmount, quoteAmount);
    }

    function takePartnerFees(
        address token,
        uint256 amount,
        bool isDeposit
    ) private returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        if (feeParams.addrPartner == address(0)) {
            // take fees when partner is provided
            return amount;
        }

        uint256 fees = (amount *
            (isDeposit ? feeParams.pctDeposit : feeParams.pctWithdraw)) /
            PERCENT_MAX;
        IERC20(token).safeTransfer(feeParams.addrPartner, fees);
        return amount - fees;
    }

    function takeTradingFees(address token, uint256 amount)
        private
        returns (uint256)
    {
        if (amount == 0) {
            return 0;
        }

        // swap to UBXN
        uint256 fee = (amount * feeParams.pctTradUpbots) / PERCENT_MAX;
        uint256 _before = IERC20(vaultParams.ubxnToken).balanceOf(
            address(this)
        );
        _swapToUBXN(token, fee);
        uint256 _after = IERC20(vaultParams.ubxnToken).balanceOf(address(this));
        uint256 ubxnAmt = _after - _before;

        // transfer to company wallet
        IERC20(vaultParams.ubxnToken).safeTransfer(
            feeParams.addrUpbots,
            ubxnAmt
        );

        // return remaining token amount
        return amount - fee;
    }

    function takePerfFees(address token, uint256 amount)
        private
        returns (uint256)
    {
        if (amount == 0) {
            return 0;
        }

        // calculate fees
        uint256 burnAmount = (amount * feeParams.pctPerfBurning) / PERCENT_MAX;
        uint256 stakersAmount = (amount * feeParams.pctPerfStakers) /
            PERCENT_MAX;
        uint256 devAmount = (amount * feeParams.pctPerfAlgoDev) / PERCENT_MAX;
        uint256 pctCompany = feeParams.addrPartner != address(0)
            ? feeParams.pctPerfPartners
            : feeParams.pctPerfUpbots;
        address addrCompany = feeParams.addrPartner != address(0)
            ? feeParams.addrPartner
            : feeParams.addrUpbots;
        uint256 companyAmount = (amount * pctCompany) / PERCENT_MAX;

        // swap to UBXN
        uint256 _total = stakersAmount + devAmount + burnAmount + companyAmount;

        uint256 _tokenBefore = IERC20(token).balanceOf(address(this));
        uint256 _before = IERC20(vaultParams.ubxnToken).balanceOf(
            address(this)
        );
        _swapToUBXN(token, _total);
        uint256 _after = IERC20(vaultParams.ubxnToken).balanceOf(address(this));
        uint256 _tokenAfter = IERC20(vaultParams.baseToken).balanceOf(
            address(this)
        );

        uint256 ubxnAmt = _after - _before;
        uint256 feeAmount = _tokenBefore - _tokenAfter;

        // calculate UBXN amounts
        stakersAmount = (ubxnAmt * stakersAmount) / _total;
        devAmount = (ubxnAmt * devAmount) / _total;
        companyAmount = (ubxnAmt * companyAmount) / _total;
        burnAmount = ubxnAmt - stakersAmount - devAmount - companyAmount;

        // Transfer
        IERC20(vaultParams.ubxnToken).safeTransfer(
            BURN_ADDRESS, // burn
            burnAmount
        );

        IERC20(vaultParams.ubxnToken).safeTransfer(
            feeParams.addrStakers, // stakers
            stakersAmount
        );

        IERC20(vaultParams.ubxnToken).safeTransfer(
            feeParams.addrAlgoDev, // algodev
            devAmount
        );

        IERC20(vaultParams.ubxnToken).safeTransfer(
            addrCompany, // company (upbots or partner)
            companyAmount
        );

        return feeAmount;
    }

    function getDerivedPrice(bool isQuotePrice) public view returns (uint256) {
        (, int256 basePrice, , , ) = AggregatorV3Interface(
            vaultParams.basePriceFeed
        ).latestRoundData();

        (, int256 quotePrice, , , ) = AggregatorV3Interface(
            vaultParams.quotePriceFeed
        ).latestRoundData();

        return
            !isQuotePrice
                ? ((uint256(basePrice) *
                    (10**IERC20Metadata(vaultParams.quoteToken).decimals()) *
                    PRICE_DECIMALS) /
                    uint256(quotePrice) /
                    (10**IERC20Metadata(vaultParams.baseToken).decimals()))
                : ((uint256(quotePrice) *
                    (10**IERC20Metadata(vaultParams.baseToken).decimals()) *
                    PRICE_DECIMALS) /
                    uint256(basePrice) /
                    (10**IERC20Metadata(vaultParams.quoteToken).decimals()));
    }

    // *** internal functions ***
    function _swapWithAggregator(
        bytes calldata swapCallData,
        bool isBuy,
        uint256 oraclePrice
    ) internal {
        IERC20 tokenFrom = isBuy
            ? IERC20(vaultParams.quoteToken)
            : IERC20(vaultParams.baseToken);
        IERC20 tokenTo = isBuy
            ? IERC20(vaultParams.baseToken)
            : IERC20(vaultParams.quoteToken);

        uint256 expectedAmount = (((oraclePrice *
            tokenFrom.balanceOf(address(this))) / PRICE_DECIMALS) *
            (isBuy ? SLIPPAGE : SLIPPAGE_SELL)) /
            PERCENT_MAX +
            tokenTo.balanceOf(address(this));

        (bool success, ) = vaultParams.aggregatorAddr.call(swapCallData);
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(tokenTo.balanceOf(address(this)) >= expectedAmount, "IS");
    }

    function _swapWithUni(
        bool isBuy,
        uint256 amount,
        uint256 oraclePrice
    ) internal {
        IERC20 tokenFrom = isBuy
            ? IERC20(vaultParams.quoteToken)
            : IERC20(vaultParams.baseToken);
        IERC20 tokenTo = isBuy
            ? IERC20(vaultParams.baseToken)
            : IERC20(vaultParams.quoteToken);

        uint256 expectedAmount = (((oraclePrice * amount) / PRICE_DECIMALS) *
            SLIPPAGE) / PERCENT_MAX;

        uint256[] memory amounts = UniswapRouterV2(vaultParams.uniswapRouter)
            .swapExactTokensForTokens(
                amount,
                expectedAmount,
                isBuy ? vaultParams.uniswapPath : uniswapBackPath,
                address(this),
                block.timestamp + 60
            );

        require(amounts[0] > 0, "IA4");
    }

    function _swapToUBXN(address _from, uint256 _amount) internal {
        if (_amount == 0) return;
        address[] memory path;

        //from token could be one of quote, base, ubxnPair token.
        if (_from == vaultParams.ubxnPairToken) {
            path = new address[](2);
            path[0] = _from;
            path[1] = vaultParams.ubxnToken;
        } else if (
            _from == vaultParams.quoteToken ||
            vaultParams.ubxnPairToken == vaultParams.quoteToken
        ) {
            path = new address[](3);
            path[0] = _from;
            path[1] = vaultParams.ubxnPairToken;
            path[2] = vaultParams.ubxnToken;
        } else {
            path = new address[](4);
            path[0] = _from;
            path[1] = vaultParams.quoteToken;
            path[2] = vaultParams.ubxnPairToken;
            path[3] = vaultParams.ubxnToken;
        }

        uint256[] memory amounts = UniswapRouterV2(vaultParams.uniswapRouter)
            .swapExactTokensForTokens(
                _amount,
                0,
                path,
                address(this),
                block.timestamp + 60
            );

        require(amounts[0] > 0);
    }

    function estimatedPoolSize() public view returns (uint256) {
        return
            IERC20(vaultParams.quoteToken).balanceOf(address(this)) +
            ((IERC20(vaultParams.baseToken).balanceOf(address(this)) *
                getDerivedPrice(false)) / PRICE_DECIMALS);
    }

    function estimatedDeposit(address account) external view returns (uint256) {
        return
            totalSupply() == 0
                ? 0
                : (estimatedPoolSize() * balanceOf(account)) / totalSupply();
    }
}