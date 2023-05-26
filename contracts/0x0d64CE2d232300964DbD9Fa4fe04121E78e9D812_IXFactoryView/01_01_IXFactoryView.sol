// LICENSE Notice
//
// This License is NOT an Open Source license. Copyright 2022. Ozy Co.,Ltd. All rights reserved.
// Licensor: Ozys. Co.,Ltd.
// Licensed Work / Source Code : This Source Code, Intella X DEX Project
// The Licensed Work is (c) 2022 Ozys Co.,Ltd.
// Detailed Terms and Conditions for Use Grant: Defined at https://ozys.io/LICENSE.txt
pragma solidity 0.5.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IFactory {
    function getPoolCount() external view returns (uint);
    function getPoolAddress(uint) external view returns (address);
}

interface IExchange {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint);
    function decimals() external view returns (uint);

    function totalSupply() external view returns (uint);
    function getCurrentPool() external view returns (uint, uint);

    function balanceOf(address) external view returns (uint);
    function userRewardSum(address) external view returns (uint);
    function userLastIndex(address) external view returns (uint);
}

contract IXFactoryView {

    using SafeMath for uint256;

    address public owner;

    string public constant version = "IXFactoryView20220819";
    IFactory public factory;

    constructor(address _factory) public {
        owner = msg.sender;
        factory = IFactory(_factory);
    }

    function getPoolCount() public view returns (uint) {
        return factory.getPoolCount();
    }

    function getFixedData(uint si, uint ei) public view returns (uint length, address[] memory fixedDatas, uint[] memory fees, uint[] memory amountDatas, uint[] memory decimalDatas) {
        length = ei.sub(si);

        fixedDatas = new address[](length.mul(3));
        amountDatas = new uint[](length.mul(3));

        fees = new uint[](length);
        decimalDatas = new uint[](length);

        for(uint i = 0; i < length; i++) {
            IExchange exc = IExchange(factory.getPoolAddress(i.add(si)));

            for(uint j = 0; j < 3; j++) {
                uint256 index = i.add(j.mul(length));

                if (j == 0) {
                    fixedDatas[index] = address(exc);
                    amountDatas[index] = exc.totalSupply();

                    fees[i] = exc.fee();
                    decimalDatas[i] = exc.decimals();
                }

                if (j == 1) {
                    fixedDatas[index] = exc.token0();

                    (amountDatas[index], ) = exc.getCurrentPool();
                }

                if (j == 2) {
                    fixedDatas[index] = exc.token1();

                    (, amountDatas[index]) = exc.getCurrentPool();
                }
            }
        }
    }

    function getPoolData(address pool) public view returns (
        uint poolTotalSupply,
        uint poolDecimal,
        uint fee,
        address token0,
        uint token0Supply,
        address token1,
        uint token1Supply
    ) {
        IExchange exc = IExchange(pool);
        poolTotalSupply = exc.totalSupply();
        poolDecimal = exc.decimals();
        fee = exc.fee();
        token0 = exc.token0();
        token1 = exc.token1();
        (token0Supply, token1Supply) = exc.getCurrentPool();
    }

    function getUserData(address user, uint si, uint ei) public view returns (uint[] memory) {
        require(si < ei);

        uint n = ei - si;

        uint[] memory liquis = new uint[](n);

        for(uint i = 0; i < n; i++) {
            IExchange exc = IExchange(factory.getPoolAddress(si + i));

            liquis[i] = exc.balanceOf(user);
        }

        return (liquis);
    }
}