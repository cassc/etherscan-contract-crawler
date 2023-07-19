import "./interfaces/IUniswapV3Factory.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/INonfungiblePositionManagerStrategy.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IFees.sol";
import "./interfaces/IERC20.sol";

import "./proxies/S4Proxy.sol";

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

contract S4Strategy {
    address immutable swapRouter;
    address immutable feeContract;
    address constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant uniV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant uniV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant nfpm = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    constructor(address swapRouter_, address feeContract_) {
        swapRouter = swapRouter_;
        feeContract = feeContract_;
    }

    uint256 public constant strategyId = 13;

    bytes32 constant onERC721ReceivedResponse =
        keccak256("onERC721Received(address,address,uint256,bytes)");

    //TICK MATH constants
    //https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    //mappings

    //mapping of user address to proxy contract
    //user address => proxy contract
    mapping(address => address) public depositors;

    //mapping of user's v3PositionNft
    //assumption is made that nftId 0 will never exist
    //user => token0 => token1 => poolFee => nftId
    mapping(address => mapping(address => mapping(address => mapping(uint24 => uint256))))
        public v3PositionNft;

    //events
    event Deposit(
        address depositor,
        address poolAddress,
        address tokenIn,
        uint256 amount
    );
    event Withdraw(
        address depositor,
        address poolAddress,
        address tokenOut,
        uint256 amount,
        uint256 fee
    );

    event v3Deposit(
        address depositor,
        address poolAddress,
        uint256 nftId,
        uint256 token0Amt,
        uint256 token1Amt
    );
    event v3Withdraw(
        address depositor,
        address poolAddress,
        uint256 nftId,
        uint256 token0Amt,
        uint256 token1Amt
    );

    event v2Deposit(
        address depositor,
        address poolAddress,
        uint256 token0Amt,
        uint256 token1Amt
    );
    event v2Withdraw(
        address depositor,
        address poolAddress,
        uint256 token0Amt,
        uint256 token1Amt
    );

    event Claim(
        address depositor,
        uint256 nftId,
        address tokenOut,
        uint256 amount
    );

    event v3Update(
        address token0,
        uint256 nftId,
        int24 tickLower,
        int24 tickUpper
    );
    event v3NftWithdraw(address depositor, uint256 nftId);

    event ProxyCreation(address user, address proxy);

    //modifiers
    modifier whitelistedToken(address token) {
        require(
            IFees(feeContract).whitelistedDepositCurrencies(strategyId, token),
            "whitelistedToken: invalid token"
        );
        _;
    }

    //V3 functions
    //getter for v3 position
    function getV3Position(uint256 nftId)
        public
        view
        returns (
            //0: nonce
            uint96,
            //1: operator
            address,
            //2: token0
            address,
            //3: token1
            address,
            //4: fee
            uint24,
            //5:tickLower
            int24,
            //6:tickUpper
            int24,
            //7:liquidity (@dev current deposit)
            uint128,
            //8:feeGrowthInside0LastX128
            uint256,
            //9:feeGrowthInside1LastX128
            uint256,
            //10:tokensOwed0 (@dev avaliable to claim)
            uint128,
            //11:tokensOwed1 (@dev avaliable to claim)
            uint128
        )
    {
        return INonfungiblePositionManagerStrategy(nfpm).positions(nftId);
    }

    //getter for v3 pool data given poolAddress
    function getV3PoolData(address poolAddress)
        public
        view
        returns (
            address,
            address,
            uint24
        )
    {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        return (pool.token0(), pool.token1(), pool.fee());
    }

    //getter for v3 PoolAddress give tokens and fees
    function getV3PoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) public view returns (address) {
        return IUniswapV3Factory(uniV3Factory).getPool(token0, token1, fee);
    }

    //getter for v3 position NFTs
    function getV3PositionNft(
        address user,
        address token0,
        address token1,
        uint24 poolFee
    )
        public
        view
        returns (
            address,
            address,
            uint256
        )
    {
        address _token0 = token0;
        address _token1 = token1;
        uint256 nftId = v3PositionNft[user][token0][token1][poolFee];
        if (nftId == 0) {
            _token0 = token1;
            _token1 = token0;
            nftId = v3PositionNft[user][token1][token0][poolFee];
        }
        return (_token0, _token1, nftId);
    }

    //updates the liquidity band
    //@dev this call is extremely expensive
    //the position is withdrawn, nft burnt and reminted with redefined liquidity band
    function updateV3Position(
        address token0,
        address token1,
        uint24 poolFee,
        int24 tickLower,
        int24 tickUpper
    ) external {
        uint256 nftId;
        (token0, token1, nftId) = getV3PositionNft(
            msg.sender,
            token0,
            token1,
            poolFee
        );
        nftId = S4Proxy(depositors[msg.sender]).updateV3(
            nftId,
            tickLower,
            tickUpper
        );
        //update mapping with new nft
        v3PositionNft[msg.sender][token0][token1][poolFee] = nftId;
        emit v3Update(msg.sender, nftId, tickLower, tickUpper);
    }

    //allows user to claim fees
    //pass in address(0) to receive ETH
    //claim only avaliable on uniV3
    //we force claim the maximum possible amount for both tokens
    function claimV3(
        address token0,
        address token1,
        uint256 nftId,
        address tokenOut,
        uint256 amountOutMin
    ) external whitelistedToken(tokenOut) {
        uint256 result;
        address _tokenOut = tokenOut == address(0) ? wethAddress : tokenOut;
        (uint256 amountA, uint256 amountB) = S4Proxy(depositors[msg.sender])
            .claimV3(nftId, address(this));
        result = _swapTwoToOne(token0, token1, amountA, amountB, _tokenOut);
        require(result >= amountOutMin, "claim: amountOutMin not met");
        _sendToken(tokenOut, msg.sender, result);
        emit Claim(msg.sender, nftId, tokenOut, result);
    }

    //V2 Functions
    //getter for v2 pools
    function getV2PoolData(address poolAddress)
        public
        view
        returns (address, address)
    {
        IUniswapV2Pair pool = IUniswapV2Pair(poolAddress);
        return (pool.token0(), pool.token1());
    }

    function getV2PoolAddress(address token0, address token1)
        public
        view
        returns (address)
    {
        return IUniswapV2Factory(uniV2Factory).getPair(token0, token1);
    }

    //@dev pass address(0) for eth
    function depositToken(
        address tokenIn,
        address poolAddress,
        uint256 amount,
        uint256 token0MinOut,
        uint256 token1MinOut,
        bytes calldata params
    ) public payable whitelistedToken(tokenIn) {
        require(_depositStatus(), "depositToken: depositsStopped");
        address proxy;
        address _tokenIn = tokenIn;
        if (msg.value > 0) {
            (bool success, ) = payable(wethAddress).call{value: msg.value}("");
            require(success);
            amount = msg.value;
            _tokenIn = wethAddress;
        } else {
            IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
        }
        //Check if proxy exists, else mint
        if (depositors[msg.sender] == address(0)) {
            proxy = _mintProxy(msg.sender);
        } else {
            proxy = depositors[msg.sender];
        }
        IUniswapV2Pair pool = IUniswapV2Pair(poolAddress);
        address token0 = pool.token0();
        address token1 = pool.token1();
        address factory = pool.factory();
        uint256 token0Amt = amount / 2;
        uint256 token1Amt = amount - token0Amt;
        //tickLower & tickUpper ignored for v2
        //tickLower & tickUpper will be the full range if 0 is passed
        if (_tokenIn != token0) {
            //swap half for token0 to proxy
            _approve(_tokenIn, swapRouter);
            token0Amt = ISwapRouter(swapRouter).swapTokenForToken(
                _tokenIn,
                token0,
                token0Amt,
                token0MinOut,
                address(this)
            );
        }
        if (_tokenIn != token1) {
            //swap half for token1 to proxy
            _approve(_tokenIn, swapRouter);
            token1Amt = ISwapRouter(swapRouter).swapTokenForToken(
                _tokenIn,
                token1,
                token1Amt,
                token1MinOut,
                address(this)
            );
        }
        IERC20(token0).transfer(proxy, token0Amt);
        IERC20(token1).transfer(proxy, token1Amt);
        if (factory == uniV3Factory) {
            //v3 deposit
            (int24 tickLower, int24 tickUpper) = abi.decode(
                params,
                (int24, int24)
            );
            //check if user has existing nft
            //returns 0 if no existing nft
            uint24 poolFee = IUniswapV3Pool(poolAddress).fee();

            //verify pool
            require(
                IUniswapV3Factory(uniV3Factory).getPool(
                    token0,
                    token1,
                    poolFee
                ) == poolAddress,
                "depositToken: Invalid V3 pool"
            );

            //get tick spacing
            int24 tickSpacing = IUniswapV3Pool(poolAddress).tickSpacing();

            //check and assign default value to tick if required
            tickLower = tickLower == 0 ? MIN_TICK : tickLower;
            tickUpper = tickUpper == 0 ? MAX_TICK : tickUpper;

            //ensure ticks are divisible by tick spacing
            tickLower = tickLower < 0
                ? -((-tickLower / tickSpacing) * tickSpacing)
                : (tickLower / tickSpacing) * tickSpacing;
            tickUpper = tickUpper < 0
                ? -((-tickUpper / tickSpacing) * tickSpacing)
                : (tickUpper / tickSpacing) * tickSpacing;

            uint256 nftId = v3PositionNft[msg.sender][token0][token1][poolFee];
            emit v3Deposit(
                msg.sender,
                poolAddress,
                nftId,
                token0Amt,
                token1Amt
            );
            //minting returns nftId > 0
            //increaseLiquidityPosition returns nftId 0
            nftId = S4Proxy(depositors[msg.sender]).depositV3(
                token0,
                token1,
                token0Amt,
                token1Amt,
                tickLower,
                tickUpper,
                poolFee,
                nftId
            );
            if (nftId > 0) {
                v3PositionNft[msg.sender][token0][token1][poolFee] = nftId;
            }
        } else {
            //verify pool
            require(
                IUniswapV2Factory(uniV2Factory).getPair(token0, token1) ==
                    poolAddress,
                "depositToken: Invalid V2 pair"
            );
            //v2 deposit
            S4Proxy(depositors[msg.sender]).depositV2(
                token0,
                token1,
                token0Amt,
                token1Amt
            );
            emit v2Deposit(msg.sender, poolAddress, token0Amt, token1Amt);
        }
        emit Deposit(msg.sender, poolAddress, tokenIn, amount);
    }

    //@dev pass address(0) for ETH
    function withdrawToken(
        address tokenOut,
        address poolAddress,
        uint128 amount,
        uint256 minAmountOut,
        address feeToken
    ) public whitelistedToken(tokenOut) {
        IUniswapV2Pair pool = IUniswapV2Pair(poolAddress);
        address token0 = pool.token0();
        address token1 = pool.token1();
        address factory = pool.factory();
        address proxy = depositors[msg.sender];
        //amount of token0 received
        uint256 amountA;
        //amount of token1 received
        uint256 amountB;

        uint256 result;

        address _tokenOut = tokenOut == address(0) ? wethAddress : tokenOut;

        if (factory == uniV3Factory) {
            //We ignore the nft transfer to save gas
            //The proxy contract will hold the position NFT by default unless withdraw requested by user
            uint24 poolFee = IUniswapV3Pool(poolAddress).fee();
            (, , uint256 nftId) = getV3PositionNft(
                msg.sender,
                token0,
                token1,
                poolFee
            );
            (amountA, amountB) = S4Proxy(proxy).withdrawV3(
                nftId,
                amount,
                address(this)
            );
            emit v3Withdraw(msg.sender, poolAddress, nftId, amountA, amountB);
        } else {
            (amountA, amountB) = S4Proxy(proxy).withdrawV2(
                token0,
                token1,
                poolAddress,
                amount
            );
            emit v2Withdraw(msg.sender, poolAddress, amountA, amountB);
        }
        result = _swapTwoToOne(token0, token1, amountA, amountB, _tokenOut);
        require(result >= minAmountOut, "withdrawToken: minAmountOut not met");
        //transfer fee to feeCollector
        uint256 fee = ((
            IFees(feeContract).calcFee(
                strategyId,
                msg.sender,
                feeToken == address(0) ? tokenOut : feeToken
            )
        ) * result) / 1000;
        IERC20(_tokenOut).transfer(
            IFees(feeContract).feeCollector(strategyId),
            fee
        );
        //Return token to sender
        _sendToken(tokenOut, msg.sender, result - fee);
        emit Withdraw(msg.sender, poolAddress, tokenOut, result-fee, fee);
    }

    //swap multiple tokens to one
    function _swapTwoToOne(
        address token0,
        address token1,
        uint256 amountA,
        uint256 amountB,
        address _tokenOut
    ) internal returns (uint256) {
        ISwapRouter router = ISwapRouter(swapRouter);
        //optimistically assume result
        uint256 result = amountA + amountB;
        if (_tokenOut != token0 && amountA > 0) {
            //deduct incorrect amount
            result -= amountA;
            _approve(token0, swapRouter);
            //swap and add correct amount to result
            result += router.swapTokenForToken(
                token0,
                _tokenOut,
                amountA,
                1,
                address(this)
            );
        }
        if (_tokenOut != token1 && amountB > 0) {
            //deduct incorrect amount
            result -= amountB;
            _approve(token1, swapRouter);
            //swap and add correct amount to result
            result += router.swapTokenForToken(
                token1,
                _tokenOut,
                amountB,
                1,
                address(this)
            );
        }
        return result;
    }

    //withdraw position NFT to user
    function withdrawV3PositionNft(
        address token0,
        address token1,
        uint24 poolFee,
        uint256 nftId
    ) external {
        require(!_depositStatus());
        require(
            v3PositionNft[msg.sender][token0][token1][poolFee] > 0,
            "No NFT"
        );
        //delete nft form mapping
        v3PositionNft[msg.sender][token0][token1][poolFee] = 0;
        //we use the proxy map to gatekeep the rightful nft owner
        S4Proxy(depositors[msg.sender]).withdrawV3Nft(nftId);
        emit v3NftWithdraw(msg.sender, nftId);
    }

    //withdraw any token to user
    function emergencyWithdraw(address token, uint256 amount) external {
        require(!_depositStatus());
        S4Proxy(depositors[msg.sender]).withdrawToUser(token, amount);
    }

    function _depositStatus() internal view returns (bool) {
        return IFees(feeContract).depositStatus(strategyId);
    }

    // internal functions
    function _approve(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).approve(spender, 2**256 - 1);
        }
    }

    function _sendToken(
        address tokenOut,
        address to,
        uint256 amount
    ) internal {
        if (tokenOut != address(0)) {
            IERC20(tokenOut).transfer(to, amount);
        } else {
            //unwrap eth
            IWETH(wethAddress).withdraw(amount);
            (bool sent, ) = payable(to).call{value: amount}("");
            require(sent, "_sendToken: send ETH fail");
        }
    }

    function _mintProxy(address user) internal returns (address) {
        require(
            depositors[user] == address(0),
            "_mintProxy: proxy already exists"
        );
        S4Proxy newProxy = new S4Proxy(user);
        address proxy = address(newProxy);
        depositors[user] = proxy;
        emit ProxyCreation(user, proxy);
        return proxy;
    }

    //hook called when nft is transferred to contract
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        require(_depositStatus());
        require(msg.sender == nfpm, "Unauthorized");
        require(
            INonfungiblePositionManagerStrategy(nfpm).ownerOf(tokenId) ==
                address(this),
            "S4Strategy: Invalid NFT"
        );
        if (depositors[from] == address(0)) {
            _mintProxy(depositors[from]);
        }
        //add position nft to mapping
        (
            ,
            ,
            address token0,
            address token1,
            uint24 poolFee,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,

        ) = getV3Position(tokenId);
        require(
            v3PositionNft[from][token0][token1][poolFee] == 0,
            "S4Strategy: Position already exists"
        );
        v3PositionNft[from][token0][token1][poolFee] = tokenId;
        bytes memory tokenData = abi.encode(poolFee, liquidity, token0, token1);
        INonfungiblePositionManagerStrategy(nfpm).safeTransferFrom(
            address(this),
            depositors[from],
            tokenId,
            tokenData
        );
        return bytes4(onERC721ReceivedResponse);
    }

    receive() external payable {}
}