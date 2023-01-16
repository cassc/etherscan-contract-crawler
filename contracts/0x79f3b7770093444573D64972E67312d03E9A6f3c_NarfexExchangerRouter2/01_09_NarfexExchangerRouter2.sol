//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import './PancakeLibrary.sol';
import './INarfexOracle.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface INarfexFiat is IERC20 {
    function burnFrom(address _address, uint _amount) external;
    function mintTo(address _address, uint _amount) external;
}

interface INarfexExchangerPool {
    function getBalance() external view returns (uint);
    function approveRouter() external;
}

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

/// @title DEX Router for Narfex Fiats
/// @author Danil Sakhinov
/// @dev Allows to exchange between fiats and crypto coins
/// @dev Exchanges using USDT liquidity pool
/// @dev Uses Narfex oracle to get commissions and prices
/// @dev Supports tokens with a transfer fee
contract NarfexExchangerRouter2 is Ownable {
    using Address for address;

    /// Structures for solving the problem of limiting the number of variables

    struct ExchangeData {
        uint rate;
        int commission;
        uint inAmountClear;
        uint outAmountClear;
        uint inAmount;
        uint outAmount;
        address commToken;
        int commAmount;
        uint referReward;
        int profitUSDT;
    }

    struct SwapData {
        address[] path;
        uint[] amounts;
        bool isExactOut;
        uint amount;
        uint inAmount;
        uint inAmountMax;
        uint outAmount;
        uint outAmountMin;
        uint deadline;
        address refer;
    }

    struct Token {
        address addr;
        bool isFiat;
        int commission;
        uint price;
        uint reward;
        uint transferFee;
    }

    IERC20 public USDT;
    IWBNB public WBNB;
    INarfexOracle public oracle;
    INarfexExchangerPool public pool;

    uint constant PRECISION = 10**18;
    uint private USDT_PRECISION = 10**6;
    uint constant PERCENT_PRECISION = 10**4;
    uint constant MAX_INT = 2**256 - 1;

    /// @param _oracleAddress NarfexOracle address
    /// @param _poolAddress NarfexExchangerPool address
    /// @param _usdtAddress USDT address
    /// @param _wbnbAddress WrapBNB address
    constructor (
        address _oracleAddress,
        address _poolAddress,
        address _usdtAddress,
        address _wbnbAddress
    ) {
        oracle = INarfexOracle(_oracleAddress);
        USDT = IERC20(_usdtAddress);
        WBNB = IWBNB(_wbnbAddress);
        pool = INarfexExchangerPool(_poolAddress);
        if (block.chainid == 56 || block.chainid == 97) {
            USDT_PRECISION = 10**18;
        }
    }

    /// @notice Checking for an outdated transaction
    /// @param deadline Limit block timestamp
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "Transaction expired");
        _;
    }

    event SwapFiat(address indexed _account, address _fromToken, address _toToken, ExchangeData _exchange);
    event SwapDEX(address indexed _account, address _fromToken, address _toToken, uint inAmount, uint outAmount);
    event ReferralReward(address _token, uint _amount, address indexed _receiver);

    /// @notice Default function for BNB receive. Accepts BNB only from WBNB contract
    receive() external payable {
        assert(msg.sender == address(WBNB));
    }

    /// @notice Assigns token data from oracle to structure with token address
    /// @param addr Token address
    /// @param t Token data from the oracle
    /// @return New structure with addr
    function _assignTokenData(address addr, INarfexOracle.TokenData memory t)
        internal pure returns (Token memory)
    {
        return Token(addr, t.isFiat, t.commission, t.price, t.reward, t.transferFee);
    }

    /// @notice Returns the price of the token quantity in USDT equivalent
    /// @param _token Token address
    /// @param _amount Token amount
    /// @return USDT amount
    function _getUSDTValue(address _token, int _amount) internal view returns (int) {
        if (_amount == 0) return 0;
        uint uintValue = oracle.getPrice(_token) * uint(_amount) / USDT_PRECISION;
        return _amount >= 0
            ? int(uintValue)
            : -int(uintValue);
    }

    /// @notice Calculates prices and commissions when exchanging with fiat
    /// @param A First token
    /// @param B Second token
    /// @param _amount The amount of one of the tokens. Depends on _isExactOut
    /// @param _isExactOut Is the specified amount an output value
    /// @dev The last parameter shows the direction of the exchange
    function _getExchangeValues(Token memory A, Token memory B, uint _amount, bool _isExactOut)
        internal view returns (ExchangeData memory exchange)
    {
        /// Calculate price
        {
            uint priceA = A.addr == address(USDT) ? USDT_PRECISION : A.price;
            uint priceB = B.addr == address(USDT) ? USDT_PRECISION : B.price;
            exchange.rate = priceA * USDT_PRECISION / priceB;
        }

        /// Calculate commission
        {
            int unit = int(PERCENT_PRECISION);
            exchange.commission = (A.commission + unit) * (B.commission + unit) / unit - unit;
        }

        /// Calculate clear amounts
        exchange.inAmountClear = _isExactOut
            ? _amount * USDT_PRECISION / exchange.rate
            : _amount;
        exchange.outAmountClear = _isExactOut
            ? _amount
            : _amount * exchange.rate / USDT_PRECISION;

        /// Calculate amounts with commission
        if (_isExactOut) {
            exchange.inAmount = exchange.inAmountClear
                * uint(int(PERCENT_PRECISION) + exchange.commission)
                / PERCENT_PRECISION;
            exchange.outAmount = _amount;
        } else {
            exchange.inAmount = _amount;
            exchange.outAmount = exchange.outAmountClear
                * uint(int(PERCENT_PRECISION) - exchange.commission)
                / PERCENT_PRECISION;
        }

        /// Calculate commission and profit amount
        exchange.commToken = A.isFiat
            ? A.addr
            : B.addr;
        exchange.commAmount = int(A.isFiat ? exchange.inAmount : exchange.outAmount)
            * exchange.commission
            / int(PERCENT_PRECISION);
        exchange.profitUSDT = _getUSDTValue(exchange.commToken, exchange.commAmount);
    }

    /// @notice Sends the referral agent his reward
    /// @param A Reward token
    /// @param _amount Quantity from which the amount of the reward should be calculated
    /// @param _receiver Referral agent address
    function _sendReferReward(Token memory A, uint _amount, address _receiver)
        internal returns (uint)
    {
        if (_receiver != address(0)) {
            uint refPercent = A.reward;
            if (refPercent > 0) {
                uint refAmount = refPercent * _amount / PERCENT_PRECISION;
                INarfexFiat(A.addr).mintTo(_receiver, refAmount);
                emit ReferralReward(A.addr, _amount, _receiver);
                return refAmount;
            }
        }  
        return 0;
    }

    /// @notice Only exchanges between fiats
    /// @param _accountAddress Recipient address
    /// @param A First token
    /// @param B Second token
    /// @param exchange Calculated values to exchange
    /// @param _refer Referral agent address
    function _swapFiats(
        address _accountAddress,
        Token memory A,
        Token memory B,
        ExchangeData memory exchange,
        address _refer
    ) private {
        require(INarfexFiat(A.addr).balanceOf(_accountAddress) >= exchange.inAmount, "Not enough balance");

        /// Exchange tokens
        INarfexFiat(A.addr).burnFrom(_accountAddress, exchange.inAmount);
        INarfexFiat(B.addr).mintTo(_accountAddress, exchange.outAmount);

        /// Send referral reward
        Token memory C = A.addr == exchange.commToken ? A : B;
        exchange.referReward = _sendReferReward(C, exchange.inAmountClear, _refer);
        exchange.profitUSDT -= _getUSDTValue(C.addr, int(exchange.referReward));

        emit SwapFiat(_accountAddress, A.addr, B.addr, exchange);
    }

    /// @notice Fiat and USDT Pair Exchange
    /// @param _accountAddress Recipient address
    /// @param A First token
    /// @param B Second token
    /// @param exchange Calculated values to exchange
    /// @param _refer Referral agent address
    /// @param _isItSwapWithDEX Cancels sending USDT to the user
    /// @dev The last parameter is needed for further or upcoming work with DEX
    function _swapFiatAndUSDT(
        address _accountAddress,
        Token memory A,
        Token memory B,
        ExchangeData memory exchange,
        address _refer,
        bool _isItSwapWithDEX
    ) private returns (uint usdtAmount) {
        Token memory C = A.addr == exchange.commToken ? A : B;

        if (A.addr == address(USDT)) {
            /// If conversion from USDT to fiat
            if (!_isItSwapWithDEX) { 
                /// Transfer from the account
                USDT.transferFrom(_accountAddress, address(pool), exchange.inAmount);
            } /// ELSE: USDT must be already transferred to the pool by DEX
            /// Mint fiat to the final account
            INarfexFiat(B.addr).mintTo(_accountAddress, exchange.outAmount);
            /// Send refer reward
            exchange.referReward = _sendReferReward(C, exchange.outAmountClear, _refer);
            exchange.profitUSDT -= _getUSDTValue(C.addr, int(exchange.referReward));
        } else {
            /// If conversion from fiat to usdt
            require(pool.getBalance() >= exchange.outAmount, "Not enough liquidity pool amount");
            /// Burn fiat from account
            INarfexFiat(A.addr).burnFrom(_accountAddress, exchange.inAmount);
            /// Send refer reward
            exchange.referReward = _sendReferReward(C, exchange.outAmountClear, _refer);
            exchange.profitUSDT -= _getUSDTValue(C.addr, int(exchange.referReward));
            /// Then transfer USDT
            if (!_isItSwapWithDEX) {
                /// Transfer USDT to the final account
                USDT.transferFrom(address(pool), _accountAddress, exchange.outAmount);
            }
            usdtAmount = exchange.outAmount;
        }

        emit SwapFiat(_accountAddress, A.addr, B.addr, exchange);
    }

    /// @notice Truncates the path, excluding the fiat from it
    /// @param _path An array of addresses representing the exchange path
    /// @param isFromFiat Indicates the direction of the route (Fiat>DEX of DEX>Fiat)
    function _getDEXSubPath(address[] memory _path, bool isFromFiat) internal pure returns (address[] memory) {
        address[] memory path = new address[](_path.length - 1);
        for (uint i = 0; i < path.length; i++) {
            path[i] = _path[isFromFiat ? i + 1 : i];
        }
        return path;
    }

    /// @notice Gets the reserves of tokens in the path and calculates the final value
    /// @param data Prepared swap data
    /// @dev Updates the data in the structure passed as a parameter
    function _processSwapData(SwapData memory data) internal view {
        if (data.isExactOut) {
            data.amounts = PancakeLibrary.getAmountsIn(data.outAmount, data.path);
            data.inAmount = data.amounts[0];
        } else {
            data.amounts = PancakeLibrary.getAmountsOut(data.inAmount, data.path);
            data.outAmount = data.amounts[data.amounts.length - 1];
        }
    }

    /// @notice Exchange only between crypto Сoins through liquidity pairs
    /// @param _account Recipient account address
    /// @param data Prepared swap data
    /// @param A Input token data
    /// @param B Output token data
    function _swapOnlyDEX(
        address payable _account,
        SwapData memory data,
        Token memory A,
        Token memory B
        ) private
    {
        uint transferInAmount;
        if (data.isExactOut) {
            /// Increase output amount by outgoing token fee for calculations
            data.outAmount = B.transferFee > 0
                ? data.amount * (PERCENT_PRECISION + B.transferFee) / PERCENT_PRECISION
                : data.amount;
        } else {
            transferInAmount = data.amount;
            /// Decrease input amount for calculations
            data.inAmount = A.transferFee > 0
                ? data.amount * (PERCENT_PRECISION - A.transferFee) / PERCENT_PRECISION
                : data.amount;
        }
        /// Calculate the opposite value
        _processSwapData(data);

        if (data.isExactOut) {
            /// Increase input amount by inbound token fee
            transferInAmount = A.transferFee > 0
                ? data.inAmount * (PERCENT_PRECISION + A.transferFee) / PERCENT_PRECISION
                : data.inAmount;
            require(data.inAmount <= data.inAmountMax, "Input amount is higher than maximum");
        } else {
            require(data.outAmount >= data.outAmountMin, "Output amount is lower than minimum");
        }
        address firstPair = PancakeLibrary.pairFor(data.path[0], data.path[1]);
        if (A.addr == address(WBNB)) {
            /// BNB insert
            require(msg.value >= transferInAmount, "BNB is not sended");
            WBNB.deposit{value: transferInAmount}();
            assert(WBNB.transfer(firstPair, transferInAmount));
            if (msg.value > transferInAmount) {
                /// Return unused BNB
                _account.transfer(msg.value - transferInAmount);
            }
        } else {
            /// Coin insert
            SafeERC20.safeTransferFrom(IERC20(data.path[0]), _account, firstPair, transferInAmount);
        }
        if (B.addr == address(WBNB)) {
            /// Send BNB after swap
            _swapDEX(data.amounts, data.path, address(this));
            WBNB.withdraw(data.outAmount);
            _account.transfer(data.outAmount);
        } else {
            /// Send Coin after swap
            _swapDEX(data.amounts, data.path, _account);
        }
        emit SwapDEX(_account, A.addr, B.addr, data.inAmount, data.outAmount);
    }

    /// @notice Exchange through liquidity pairs along the route
    /// @param amounts Pre-read reserves in liquidity pairs
    /// @param path An array of addresses representing the exchange path
    /// @param _to Address of the recipient
    function _swapDEX(uint[] memory amounts, address[] memory path, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PancakeLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? PancakeLibrary.pairFor(output, path[i + 2]) : _to;
            IPancakePair(PancakeLibrary.pairFor(input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    /// @notice Fiat to crypto Coin exchange and vice versa
    /// @param _account Recipient address
    /// @param data Prepared swap data
    /// @param F Fiat token data
    /// @param C Coin token data
    /// @param isFromFiat Exchange direction
    /// @dev Takes into account tokens with transfer fees
    function _swapFiatWithDEX(
        address payable _account,
        SwapData memory data,
        Token memory F, // Fiat
        Token memory C, // Coin
        bool isFromFiat
        ) private
    {
        /// USDT token data
        Token memory U = _assignTokenData(address(USDT), oracle.getTokenData(address(USDT), false));
        uint lastIndex = data.path.length - 1;

        require((isFromFiat && data.path[0] == U.addr)
            || (!isFromFiat && data.path[lastIndex] == U.addr),
            "The exchange between fiat and crypto must be done via USDT");

        ExchangeData memory exchange;

        if (data.isExactOut) {
            /// If exact OUT
            if (isFromFiat) { /// FIAT > USDT > DEX > COIN!!
                /// Calculate other amounts from the start amount data
                data.outAmount = data.amount;
                if (C.transferFee > 0) {
                    /// Increasing the output amount offsets the loss from the fee
                    data.outAmount = data.outAmount * (PERCENT_PRECISION + C.transferFee) / PERCENT_PRECISION;
                }
                _processSwapData(data);
                exchange = _getExchangeValues(F, U, data.inAmount, true);
                require(exchange.inAmount <= data.inAmountMax, "Input amount is higher than maximum");
                /// Swap Fiat with USDT
                _swapFiatAndUSDT(_account, F, U, exchange, data.refer, true);
                /// Transfer USDT from the Pool to the first pair
                {
                    address firstPair = PancakeLibrary.pairFor(U.addr, data.path[1]);
                    SafeERC20.safeTransferFrom(USDT, address(pool), firstPair, data.inAmount);
                }
                /// Swap and send to the account
                if (C.addr == address(WBNB)) {
                    /// Swap with BNB out
                    _swapDEX(data.amounts, data.path, address(this));
                    WBNB.withdraw(data.outAmount);
                    _account.transfer(data.outAmount);
                } else {
                    /// Swap with coin out
                    _swapDEX(data.amounts, data.path, _account);
                }
                emit SwapDEX(_account, data.path[0], data.path[lastIndex], data.inAmount, data.outAmount);
            } else { /// COIN > DEX > USDT > FIAT!!
                /// Calculate other amounts from the start amount data
                exchange = _getExchangeValues(U, F, data.amount, true);
                data.outAmount = exchange.inAmount;
                _processSwapData(data);
                require(data.inAmount <= data.inAmountMax, "Input amount is higher than maximum");
                /// Transfer Coin from the account to the first pair
                {
                    address firstPair = PancakeLibrary.pairFor(C.addr, data.path[1]);
                    if (C.addr == address(WBNB)) {
                        /// BNB transfer
                        require(msg.value >= data.inAmount, "BNB is not sended");
                        WBNB.deposit{value: data.inAmount}();
                        assert(WBNB.transfer(firstPair, data.inAmount));
                        if (msg.value > data.inAmount) {
                            /// Return unused BNB
                            _account.transfer(msg.value - data.inAmount);
                        }
                    } else {
                        /// Send increased coin amount from the account to DEX
                        uint inAmountWithFee = C.transferFee > 0
                        ? data.inAmount * (PERCENT_PRECISION + C.transferFee) / PERCENT_PRECISION
                        : data.inAmount;
                        SafeERC20.safeTransferFrom(IERC20(C.addr), _account, firstPair, inAmountWithFee);
                    }
                }
                /// Swap and send USDT to the pool
                _swapDEX(data.amounts, data.path, address(pool));
                emit SwapDEX(_account, data.path[0], data.path[lastIndex], data.inAmount, data.outAmount);
                /// Swap USDT and Fiat
                _swapFiatAndUSDT(_account, U, F, exchange, data.refer, true);
            }
        } else {
            /// If exact IN
            if (isFromFiat) { /// FIAT!! > USDT > DEX > COIN
                /// Calculate other amounts from the start amount data
                exchange = _getExchangeValues(F, U, data.amount, false);
                data.inAmount = exchange.outAmount;
                _processSwapData(data);
                require(data.outAmount >= data.outAmountMin, "Output amount is lower than minimum");
                /// Swap Fiat with USDT
                _swapFiatAndUSDT(_account, F, U, exchange, data.refer, true);
                /// Transfer USDT from the Pool to the first pair
                {
                    address firstPair = PancakeLibrary.pairFor(U.addr, data.path[1]);
                    SafeERC20.safeTransferFrom(USDT, address(pool), firstPair, data.inAmount);
                    /// TransferFee only affects delivered amount
                }
                /// Swap and send to the account
                if (C.addr == address(WBNB)) {
                    /// Swap with BNB transfer
                    _swapDEX(data.amounts, data.path, address(this));
                    WBNB.withdraw(data.outAmount);
                    _account.transfer(data.outAmount);
                } else {
                    /// Swap with coin transfer
                    _swapDEX(data.amounts, data.path, _account);
                }
                emit SwapDEX(_account, data.path[0], data.path[lastIndex], data.inAmount, data.outAmount);
            } else { /// COIN!! > DEX > USDT > FIAT
                /// Calculate other amounts from the start amount data
                data.inAmount = data.amount;
                if (C.transferFee > 0) {
                    /// DEX swap with get a reduced value
                    data.inAmount = data.inAmount * (PERCENT_PRECISION - C.transferFee) / PERCENT_PRECISION;
                }
                _processSwapData(data);
                exchange = _getExchangeValues(U, F, data.outAmount, false);
                require(exchange.outAmount >= data.outAmountMin, "Output amount is lower than minimum");
                /// Transfer Coin from the account to the first pair
                {
                    address firstPair = PancakeLibrary.pairFor(C.addr, data.path[1]);
                    if (C.addr == address(WBNB)) {
                        /// BNB transfer
                        require(msg.value >= data.amount, "BNB is not sended");
                        WBNB.deposit{value: data.amount}();
                        assert(WBNB.transfer(firstPair, data.amount));
                    } else {
                        /// Coin transfer
                        SafeERC20.safeTransferFrom(IERC20(C.addr), _account, firstPair, data.amount); /// Full amount
                    }
                }
                /// Swap and send USDT to the pool
                _swapDEX(data.amounts, data.path, address(pool));
                emit SwapDEX(_account, data.path[0], data.path[lastIndex], data.inAmount, data.outAmount);
                /// Swap USDT and Fiat
                _swapFiatAndUSDT(_account, U, F, exchange, data.refer, true);
            }
        }
    }

    /// @notice Main Routing Exchange Function
    /// @param _account Recipient address
    /// @param data Prepared data for exchange
    function _swap(
        address payable _account,
        SwapData memory data
        ) private
    {
        require(data.refer != _account, "Refer address can't be the sender's address");
        require(data.path.length > 1, "Path length must be at least 2 addresses");
        uint lastIndex = data.path.length - 1;

        Token memory A; /// First token
        Token memory B; /// Last token
        {
            /// Get the oracle data for the first and last tokens
            address[] memory sideTokens = new address[](2);
            sideTokens[0] = data.path[0];
            sideTokens[1] = data.path[lastIndex];
            INarfexOracle.TokenData[] memory tokensData = oracle.getTokensData(sideTokens, true);
            A = _assignTokenData(sideTokens[0], tokensData[0]);
            B = _assignTokenData(sideTokens[1], tokensData[1]);
        }
        require(A.addr != B.addr, "Can't swap the same tokens");

        if (A.isFiat && B.isFiat)
        { /// If swap between fiats
            ExchangeData memory exchange = _getExchangeValues(A, B, data.amount, data.isExactOut);
            _swapFiats(_account, A, B, exchange, data.refer);
            return;
        }
        if (!A.isFiat && !B.isFiat)
        { /// Swap on DEX only
            _swapOnlyDEX(_account, data, A, B);
            return;
        }
        if ((A.isFiat && B.addr == address(USDT))
            || (B.isFiat && A.addr == address(USDT)))
        { /// If swap between fiat and USDT in the pool
            ExchangeData memory exchange = _getExchangeValues(A, B, data.amount, data.isExactOut);
            _swapFiatAndUSDT(_account, A, B, exchange, data.refer, false);
            return;
        }

        /// Swap with DEX and Fiats
        data.path = _getDEXSubPath(data.path, A.isFiat);
        _swapFiatWithDEX(_account, data, A.isFiat ? A : B, A.isFiat ? B : A, A.isFiat);  
    }

    /// @notice Swap tokens public function
    /// @param path An array of addresses representing the exchange path
    /// @param isExactOut Is the amount an output value
    /// @param amountLimit Becomes the min output amount for isExactOut=true, and max input for false
    /// @param deadline The transaction must be completed no later than the specified time
    /// @param refer Referral agent address
    /// @dev If the user wants to get an exact amount in the output, isExactOut should be true
    /// @dev Fiat to crypto must be exchanged via USDT
    function swap(
        address[] memory path,
        bool isExactOut,
        uint amount,
        uint amountLimit,
        uint deadline,
        address refer) public payable ensure(deadline)
    {
        SwapData memory data;
        data.path = path;
        data.isExactOut = isExactOut;
        data.amount = amount;
        data.inAmount = isExactOut ? 0 : amount;
        data.inAmountMax = isExactOut ? amountLimit : MAX_INT;
        data.outAmount = isExactOut ? amount : 0;
        data.outAmountMin = isExactOut ? amountLimit : 0;
        data.refer = refer;

        _swap(payable(msg.sender), data);
    }

    /// @notice Allows the owner to perform a swap for the user
    /// @param _account User account
    /// @param path An array of addresses representing the exchange path
    /// @param isExactOut Is the amount an output value
    /// @param amountLimit Becomes the min output amount for isExactOut=true, and max input for false
    /// @param deadline The transaction must be completed no later than the specified time
    /// @param refer Referral agent address
    /// @dev Suitable for cases where the user does not have gas to exchange fiat for BNB
    function swapFor(
        address payable _account,
        address[] memory path,
        bool isExactOut,
        uint amount,
        uint amountLimit,
        uint deadline,
        address refer) public payable ensure(deadline) onlyOwner
    {
        SwapData memory data;
        data.path = path;
        data.isExactOut = isExactOut;
        data.amount = amount;
        data.inAmount = isExactOut ? 0 : amount;
        data.inAmountMax = isExactOut ? amountLimit : MAX_INT;
        data.outAmount = isExactOut ? amount : 0;
        data.outAmountMin = isExactOut ? amountLimit : 0;
        data.refer = refer;

        _swap(_account, data);
    }
}