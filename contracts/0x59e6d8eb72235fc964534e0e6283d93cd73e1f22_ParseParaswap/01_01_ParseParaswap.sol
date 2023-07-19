pragma solidity >=0.8.0;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

library Utils {
    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee;
        Route[] route;
    }

    struct Route {
        uint256 index; //Adapter at which index needs to be used
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee; //Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; //Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }
}

library ParseParaswap {
    uint256 constant CUT_ADDRESS =
        0x00000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 constant DIRECTION_FLAG =
        0x0000000000000000000000010000000000000000000000000000000000000000;

    function convertBytesToBytes4(bytes memory inBytes)
        public
        pure
        returns (bytes4 outBytes4)
    {
        if (inBytes.length == 0) {
            return 0x0;
        }
        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    // @param data, bytecode data returned from Paraswap API
    // Decode Paraswap API bytecode and return source and destination tokens
    function getResult(bytes calldata data)
        public
        view
        returns (
            address,
            address,
            uint256
        )
    {
        bytes calldata myData = bytes(data[4:]);
        bytes4 result = bytes4(
            bytes4(data[0]) |
                (bytes4(data[1]) >> 8) |
                (bytes4(data[2]) >> 16) |
                (bytes4(data[3]) >> 24)
        );
        address from;
        address to;
        address beneficiary;
        uint256 amount;

        // swapOnUniswap, buyOnUniswap, swapOnUniswapFork, buyOnUniswapFork, swapOnUniswapV2Fork, buyOnUniswapV2Fork, simpleBuy, simpleSwap, multiSwap, megaSwap, protectedMultiSwap, protectedMegaSwap, protectedSimpleSwap, protectedSimpleBuy, swapOnZeroXv2, swapOnZeroXv4, buy

        // MultiSwap
        if (result == 0xa94e78ef) {
            (from, to, beneficiary, amount) = sellDataDecode(myData);
            // MegaSwap
        } else if (result == 0x46c67b6d) {
            (from, to, beneficiary, amount) = megaSwapSellDataDecode(myData);
            // ProtectedMultiSwap
        } else if (result == 0x2478ba3e) {
            (from, to, beneficiary, amount) = sellDataDecode(myData);
            // ProtectedMegaSwap
        } else if (result == 0x37809db4) {
            (from, to, beneficiary, amount) = megaSwapSellDataDecode(myData);
            // ProtectedSimpleSwap
        } else if (result == 0xa8795e3d) {
            (from, to, amount) = simpleDataDecode(myData);
            // ProtectedSimpleBuy
        } else if (result == 0xfab13517) {
            (from, to, amount) = simpleDataDecode(myData);
            // SimpleSwap
        } else if (result == 0x54e3f31b) {
            (from, to, amount) = simpleDataDecode(myData);
            // SimpleBuy
        } else if (result == 0x2298207a) {
            (from, to, amount) = simpleDataDecode(myData);
            // SwapOnUniswap
        } else if (result == 0x54840d1a) {
            (from, to, amount) = uuaDecode(myData);
            // SwapOnUniswapFork
        } else if (result == 0xf5661034) {
            (from, to, amount) = abuuaDecode(myData);
            // BuyOnUniswap
        } else if (result == 0x935fb84b) {
            (from, to, amount) = uuaDecode(myData);
            // BuyOnUniswapFork
        } else if (result == 0xc03786b0) {
            (from, to, amount) = abuuaDecode(myData);
            // SwapOnUniswapV2Fork
        } else if (result == 0x0b86a4c1) {
            (from, to, amount) = auuauDecode(myData);
            // BuyOnUniswapV2Fork
        } else if (result == 0xb2f1e6db) {
            (from, to, amount) = auuauDecode(myData);
            // SwapOnZeroXV2
        } else if (result == 0x81033120) {
            (from, to, amount) = iiuuabDecode(myData);
            // SwapOnZeroXV4
        } else if (result == 0x64466805) {
            (from, to, amount) = iiuuabDecode(myData);
        } else {
            require(false, "No corresponding function");
        }
        return (from, to, amount);
    }

    function uuaDecode(bytes calldata data)
        public
        pure
        returns (
            address,
            address,
            uint256
        )
    {
        (uint256 amountInMax, , address[] memory path) = abi.decode(
            data,
            (uint256, uint256, address[])
        );
        address from = path[0];
        address to = path[path.length - 1];
        uint256 amount = amountInMax;
        return (from, to, amount);
    }

    function abuuaDecode(bytes calldata data)
        public
        pure
        returns (
            address,
            address,
            uint256
        )
    {
        (, , uint256 amountInMax, , address[] memory path) = abi.decode(
            data,
            (address, bytes32, uint256, uint256, address[])
        );
        address from = path[0];
        address to = path[path.length - 1];
        uint256 amount = amountInMax;
        return (from, to, amount);
    }

    function iiuuabDecode(bytes calldata data)
        public
        pure
        returns (
            address,
            address,
            uint256
        )
    {
        (address fromToken, address toToken, uint256 fromAmount, , , ) = abi
            .decode(data, (address, address, uint256, uint256, address, bytes));
        address from = address(fromToken);
        address to = address(toToken);
        uint256 amount = fromAmount; /// units in fromToken
        return (from, to, amount);
    }

    function auuauDecode(bytes calldata data)
        public
        view
        returns (
            address,
            address,
            uint256
        )
    {
        (address tokenIn, uint256 amountInMax, , , uint256[] memory pools) = abi
            .decode(data, (address, uint256, uint256, address, uint256[]));
        address from = address(tokenIn);
        require(pools.length >= 1, "pool too big");
        address to = getTokenFromUniswapUint(pools[pools.length - 1]);
        uint256 amount = amountInMax;
        return (from, to, amount);
    }

    function simpleDataDecode(bytes calldata bytedata)
        public
        pure
        returns (
            address,
            address,
            uint256
        )
    {
        Utils.SimpleData memory simpleData = abi.decode(
            bytedata,
            (Utils.SimpleData)
        );
        address from = simpleData.fromToken;
        address to = simpleData.toToken;
        // address beneficiary = simpleData.beneficiary;
        uint256 amountIn = simpleData.fromAmount;
        return (from, to, amountIn);
    }

    function sellDataDecode(bytes calldata bytedata)
        public
        pure
        returns (
            address,
            address,
            address,
            uint256
        )
    {
        Utils.SellData memory data = abi.decode(bytedata, (Utils.SellData));
        Utils.Path[] memory paths = data.path;
        return (
            data.fromToken,
            paths[paths.length - 1].to,
            data.beneficiary,
            data.fromAmount
        );
    }

    function megaSwapSellDataDecode(bytes calldata bytedata)
        public
        pure
        returns (
            address,
            address,
            address,
            uint256
        )
    {
        Utils.MegaSwapSellData memory megaSwapSellData = abi.decode(
            bytedata,
            (Utils.MegaSwapSellData)
        );
        Utils.MegaSwapPath[] memory megaSwapPaths = megaSwapSellData.path;
        address to;
        for (uint256 i; i < megaSwapPaths.length; i++) {
            Utils.Path[] memory paths = megaSwapPaths[i].path;
            if (i == 0) {
                to = paths[paths.length - 1].to;
            }
            if (i != 0) {
                require(
                    to == paths[paths.length - 1].to,
                    "Destination token not consistent"
                );
            }
        }

        return (
            megaSwapSellData.fromToken,
            to,
            megaSwapSellData.beneficiary,
            megaSwapSellData.fromAmount
        );
    }

    // Pool bits are 255-161: fee, 160: direction flag, 159-0: address
    // This functions truncate fee and direction flag from it to only return address of the pool
    function getPoolAddressFromUniswapUint(uint256 pool)
        public
        pure
        returns (address)
    {
        return address(uint160(pool & CUT_ADDRESS));
    }

    function getPoolDirectionFromUniswapUint(uint256 pool)
        public
        pure
        returns (bool)
    {
        return DIRECTION_FLAG & pool == 0;
    }

    function getTokenFromUniswapPool(address poolAddress, bool direction)
        public
        view
        returns (address)
    {
        if (direction == false) {
            return IUniswapV2Pair(poolAddress).token0();
        }
        return IUniswapV2Pair(poolAddress).token1();
    }

    function getTokenFromUniswapUint(uint256 pool)
        public
        view
        returns (address)
    {
        bool direction = getPoolDirectionFromUniswapUint(pool);
        address poolAddress = getPoolAddressFromUniswapUint(pool);

        return getTokenFromUniswapPool(poolAddress, direction);
    }
}