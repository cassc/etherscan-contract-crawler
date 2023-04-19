// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../CToken.sol";
import "../PriceOracle.sol";
import "./BaseV1-libs.sol";


interface IBaseV1Factory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address);
}

interface IBaseV1Pair {
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function getAmountOut(uint, address) external view returns (uint);
    function current(address tokenIn, uint amountIn) external view returns(uint);
    function token0() external view returns(address);
    function token1() external view returns(address);
    function stable() external view returns(bool);
    function _k(uint x, uint y) external view returns(uint);
    //LP token pricing
    function sampleReserves(uint points, uint window) external view returns(uint[] memory, uint[] memory);
    function sampleSupply(uint points, uint window) external view returns(uint[] memory);
    function sample(address tokenIn, uint amountIn, uint points, uint window) external view returns(uint[] memory);
    function quote(address tokenIn, uint amountIn, uint granularity) external view returns(uint);
    function observationLength() external view returns(uint);
}

interface IWCANTO {
    function deposit() external payable ;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external ;
}

interface ICErc20 {
    function underlying() external view returns(address);
}

contract BaseV1Router01 is PriceOracle {
    //address of Unitroller to obtain prices with respect to USDC
    address public immutable note;  
    //address of Comptroller, so that price of note may be set to 1 in Account Liquidity calculations
    address public immutable Comptroller;

    address public admin;

    struct route {
        address from;
        address to;
        bool stable;
    }

    address public immutable factory;
    IWCANTO public immutable wcanto;
    uint internal constant MINIMUM_LIQUIDITY = 10**3;
    bytes32 immutable pairCodeHash;

    mapping(address => bool) public isStable;

    error SenderNotAdmin(address sender, address admin);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "BaseV1Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _wcanto, address note_, address Comptroller_) {
        factory = _factory;
        pairCodeHash = IBaseV1Factory(_factory).pairCodeHash();
        wcanto = IWCANTO(_wcanto);
        note = note_;
        Comptroller = Comptroller_;
        admin = msg.sender;
    }

    receive() external payable {
        assert(msg.sender == address(wcanto)); // only accept ETH via fallback from the WETH contract
    }

    // admin for setting the stable pairs
    function setAdmin(address admin_) external {
        require(msg.sender == admin);
        admin = admin_;
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, "BaseV1Router: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "BaseV1Router: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB, bool stable) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1, stable)),
            pairCodeHash // init code hash
        )))));
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quoteLiquidity(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "BaseV1Router: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "BaseV1Router: INSUFFICIENT_LIQUIDITY");
        amountB = amountA * reserveB / reserveA;
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB, bool stable) public view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IBaseV1Pair(pairFor(tokenA, tokenB, stable)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable) {
        address pair = pairFor(tokenIn, tokenOut, true);
        uint amountStable;
        uint amountVolatile;
        if (IBaseV1Factory(factory).isPair(pair)) {
            amountStable = IBaseV1Pair(pair).getAmountOut(amountIn, tokenIn);
        }
        pair = pairFor(tokenIn, tokenOut, false);
        if (IBaseV1Factory(factory).isPair(pair)) {
            amountVolatile = IBaseV1Pair(pair).getAmountOut(amountIn, tokenIn);
        }
        return amountStable > amountVolatile ? (amountStable, true) : (amountVolatile, false);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint amountIn, route[] memory routes) public view returns (uint[] memory amounts) {
        require(routes.length >= 1, "BaseV1Router: INVALID_PATH");
        amounts = new uint[](routes.length+1);
        amounts[0] = amountIn;
        for (uint i = 0; i < routes.length; i++) {
            address pair = pairFor(routes[i].from, routes[i].to, routes[i].stable);
            if (IBaseV1Factory(factory).isPair(pair)) {
                amounts[i+1] = IBaseV1Pair(pair).getAmountOut(amounts[i], routes[i].from);
            }
        }
    }

    function isPair(address pair) public view returns (bool) {
        return IBaseV1Factory(factory).isPair(pair);
    }

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    ) external view returns (uint amountA, uint amountB, uint liquidity) {
        // create the pair if it doesn"t exist yet
        address _pair = IBaseV1Factory(factory).getPair(tokenA, tokenB, stable);
        (uint reserveA, uint reserveB) = (0,0);
        uint _totalSupply = 0;
        if (_pair != address(0)) {
            _totalSupply = erc20(_pair).totalSupply();
            (reserveA, reserveB) = getReserves(tokenA, tokenB, stable);
        }
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
        } else {

            uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
                liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
            } else {
                uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
                liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
            }
        }
    }

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity
    ) public view returns (uint amountA, uint amountB) {
        // create the pair if it doesn"t exist yet
        address _pair = IBaseV1Factory(factory).getPair(tokenA, tokenB, stable);

        if (_pair == address(0)) {
            return (0,0);
        }

        (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable);
        uint _totalSupply = erc20(_pair).totalSupply();

        amountA = liquidity * reserveA / _totalSupply; // using balances ensures pro-rata distribution
        amountB = liquidity * reserveB / _totalSupply; // using balances ensures pro-rata distribution

    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        require(amountADesired >= amountAMin);
        require(amountBDesired >= amountBMin);
        // create the pair if it doesn"t exist yet
        address _pair = IBaseV1Factory(factory).getPair(tokenA, tokenB, stable);
        if (_pair == address(0)) {
            _pair = IBaseV1Factory(factory).createPair(tokenA, tokenB, stable);
        }
        (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "BaseV1Router: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "BaseV1Router: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, stable, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = pairFor(tokenA, tokenB, stable);
        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IBaseV1Pair(pair).mint(to);
    }

    function addLiquidityCANTO(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountCANTOMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountCANTO, uint liquidity) {
        (amountToken, amountCANTO) = _addLiquidity(
            token,
            address(wcanto),
            stable,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountCANTOMin
        );
        address pair = pairFor(token, address(wcanto), stable);
        _safeTransferFrom(token, msg.sender, pair, amountToken);
        wcanto.deposit{value: amountCANTO}();
        assert(wcanto.transfer(pair, amountCANTO));
        liquidity = IBaseV1Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountCANTO) _safeTransferCANTO(msg.sender, msg.value - amountCANTO);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = pairFor(tokenA, tokenB, stable);
        require(IBaseV1Pair(pair).transferFrom(msg.sender, pair, liquidity)); // send liquidity to pair
        (uint amount0, uint amount1) = IBaseV1Pair(pair).burn(to);
        (address token0,) = sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "BaseV1Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "BaseV1Router: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityCANTO(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountCANTOMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountCANTO) {
        (amountToken, amountCANTO) = removeLiquidity(
            token,
            address(wcanto),
            stable,
            liquidity,
            amountTokenMin,
            amountCANTOMin,
            address(this),
            deadline
        );
        _safeTransfer(token, to, amountToken);
        wcanto.withdraw(amountCANTO);
        _safeTransferCANTO(to, amountCANTO);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB) {
        address pair = pairFor(tokenA, tokenB, stable);
        {
            uint value = approveMax ? type(uint).max : liquidity;
            IBaseV1Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        }

        (amountA, amountB) = removeLiquidity(tokenA, tokenB, stable, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityCANTOWithPermit(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountCANTOMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountCANTO) {
        address pair = pairFor(token, address(wcanto), stable);
        uint value = approveMax ? type(uint).max : liquidity;
        IBaseV1Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountCANTO) = removeLiquidityCANTO(token, stable, liquidity, amountTokenMin, amountCANTOMin, to, deadline);
    }
    
    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, route[] memory routes, address _to) internal virtual {
        for (uint i = 0; i < routes.length; i++) {
            (address token0,) = sortTokens(routes[i].from, routes[i].to);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = routes[i].from == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < routes.length - 1 ? pairFor(routes[i+1].from, routes[i+1].to, routes[i+1].stable) : _to;
            IBaseV1Pair(pairFor(routes[i].from, routes[i].to, routes[i].stable)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function swapExactTokensForTokensSimple(
        uint amountIn,
        uint amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        route[] memory routes = new route[](1);
        routes[0].from = tokenFrom;
        routes[0].to = tokenTo;
        routes[0].stable = stable;
        amounts = getAmountsOut(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, "BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        _safeTransferFrom(
            routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]
        );
        _swap(amounts, routes, to);
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = getAmountsOut(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, "BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        _safeTransferFrom(
            routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]
        );
        _swap(amounts, routes, to);
    }

    function swapExactCANTOForTokens(uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(routes[0].from == address(wcanto), "BaseV1Router: INVALID_PATH");
        amounts = getAmountsOut(msg.value, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, "BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        wcanto.deposit{value: amounts[0]}();
        assert(wcanto.transfer(pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]));
        _swap(amounts, routes, to);
    }

    function swapExactTokensForCANTO(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(routes[routes.length - 1].to == address(wcanto), "BaseV1Router: INVALID_PATH");
        amounts = getAmountsOut(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, "BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        _safeTransferFrom(
            routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]
        );
        _swap(amounts, routes, address(this));
        wcanto.withdraw(amounts[amounts.length - 1]);
        _safeTransferCANTO(to, amounts[amounts.length - 1]);
    }

    function UNSAFE_swapExactTokensForTokens(
        uint[] memory amounts,
        route[] calldata routes,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory) {
        _safeTransferFrom(routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]);
        _swap(amounts, routes, to);
        return amounts;
    }

    function _safeTransferCANTO(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0, "token code length failure");

        erc20 tokenCon = erc20(token);
        tokenCon.transferFrom(from, to, value);
    }

    function setStable(address underlying) external returns (uint) {
        if (msg.sender != admin) {
            revert SenderNotAdmin(msg.sender, admin);
        }

        isStable[underlying] = true;
    }

    //returns the underlying price of the assets as a mantissa (scaled by 1e18)
    function getUnderlyingPrice(CToken ctoken) external override view returns(uint) {
         address underlying;
        { //manual scope to pop symbol off of stack
        string memory symbol = ctoken.symbol();
        if (compareStrings(symbol, "cCANTO")) {
            underlying = address(wcanto);
            return getPriceNote(address(wcanto), false);
        } else {
            underlying = address(ICErc20(address(ctoken)).underlying()); // We are getting the price for a CErc20 lending market
        }
        //set price statically to 1 when the Comptroller is retrieving Price
        if (compareStrings(symbol, "cNOTE")) { // note in terms of note will always be 1 
            return 1e18; // Stable coins supported by the lending market are instantiated by governance and their price will always be 1 note
        } 
        else if (compareStrings(symbol, "cUSDT") && (msg.sender == Comptroller )) {
            uint decimals = erc20(underlying).decimals();
            return 1e18 * 1e18 / (10 ** decimals); //Scale Price as a mantissa to maintain precision in comptroller
        } 
        else if (compareStrings(symbol, "cUSDC") && (msg.sender == Comptroller)) {
            uint decimals = erc20(underlying).decimals();
            return 1e18 * 1e18 / (10 ** decimals); //Scale Price as a mantissa to maintain precision in comptroller
        }
        }
        
        if (isPair(underlying)) { // this is an LP Token
            return getPriceLP(IBaseV1Pair(underlying));
        }
        // this is not an LP Token
        else {
            if (isStable[underlying]) {
                return getPriceNote(underlying, true); // value has already been scaled
            }

            return getPriceCanto(underlying) * getPriceNote(address(wcanto), false) / 1e18;
        }   
    }
    
    //return the price of this asset in terms of Canto
    function getPriceCanto(address token_) internal view returns(uint) {
        erc20 token = erc20(token_);
        address pair = pairFor(address(wcanto), address(token), false);
        if (!isPair(pair)) {
            return 0; // this pair does not exist with Canto
        }
        uint decimals = 10 ** token.decimals(); // get decimals of token
        uint price = IBaseV1Pair(pair).quote(address(token), decimals, 8); // how much Canto is this asset worth?
        return price * 1e18 / decimals; //return the scaled price
    } 
    
    // returns the price of token in terms of note, scaled by 18 decimals, Notice this will most likely be used with pairs that are stable with note
    function getPriceNote(address token_, bool stable) internal view returns(uint) { 
        erc20 token = erc20(token_);
        address pair = pairFor(note, address(token), stable); // pairs with Note may be volatile or stable
        if (!isPair(pair)) {
            return 0; // this pair has not yet been deployed
        }
        uint decimals = 10 ** token.decimals();
        uint price = IBaseV1Pair(pair).quote(address(token), decimals, 8);
        return price * 1e18 / decimals; // divide by decimals now to maintain precision
    }

    // this function returns the TWAP of the LP tokens from pair
    function getPriceLP(IBaseV1Pair pair) internal view returns(uint) {
        uint[] memory supply = pair.sampleSupply(12, 1);
        uint[] memory prices; 
        uint[] memory unitReserves; 
        uint[] memory assetReserves; 
        address token0 = pair.token0();
        address token1 = pair.token1();
        uint decimals;

        if (pair.stable()) { // stable pairs will be priced in terms of Note
            if (token0 == note) { //token0 is the unit, token1 will be priced with respect to this asset initially
                decimals = 10 ** (erc20(token1).decimals()); // we must normalize the price of token1 to 18 decimals
                prices = pair.sample(token1, decimals, 12, 1);
                (unitReserves, assetReserves) = pair.sampleReserves(12, 1);
            } else {
                decimals = 10 ** (erc20(token0).decimals());
                prices = pair.sample(token0, decimals, 12, 1);
                (assetReserves, unitReserves) = pair.sampleReserves(12, 1);
            }
        } else { // non-stable pairs will be priced in terms of Canto
            if (token0 == address(wcanto)) { // token0 is Canto, and the unit asset of this pair is Canto
                decimals = 10 ** (erc20(token1).decimals());
                prices = pair.sample(token1, decimals, 12, 1);
                (unitReserves, assetReserves) = pair.sampleReserves(12, 1);
            } else {
                decimals = 10 ** (erc20(token0)).decimals();
                prices = pair.sample(token0, decimals, 12, 1);
                (assetReserves, unitReserves) = pair.sampleReserves(12, 1);
            }
        }
        uint LpPricesCumulative;

        for(uint i; i < 12; ++i) {
            uint token0TVL = (assetReserves[i] * prices[i]) / decimals;
             uint token1TVL = unitReserves[i]; // price of the unit asset is always 1
            LpPricesCumulative += (token0TVL + token1TVL) * 1e18 / supply[i];
        }
        uint LpPrice = LpPricesCumulative / 12; // take the average of the cumulative prices 
        
        if (pair.stable()) { // this asset has been priced in terms of Note
            return LpPrice;
        }
        // this asset has been priced in terms of Canto
        return LpPrice * getPriceNote(address(wcanto), false) / 1e18; // return the price in terms of Note
    }


    function compareStrings(string memory str1, string memory str2) internal pure returns(bool) {
        return (keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2)));
    }

    function _returnStableBooleans(uint8 stable) internal pure returns (bool, bool){
        if (stable == 2) {
            return (true, false);
        } else if (stable == 3) {
            return (false, true);
        } else if (stable == 4) {
            return (false, false);
        } else {
            return (true, true);
        }
    }
}