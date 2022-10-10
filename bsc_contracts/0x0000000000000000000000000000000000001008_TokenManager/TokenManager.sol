/**
 *Submitted for verification at BscScan.com on 2021-03-01
*/

// File: contracts/interface/IBEP20.sol

pragma solidity 0.6.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interface/ITokenHub.sol

pragma solidity 0.6.4;

interface ITokenHub {

  function getMiniRelayFee() external view returns(uint256);

  function getContractAddrByBEP2Symbol(bytes32 bep2Symbol) external view returns(address);

  function getBep2SymbolByContractAddr(address contractAddr) external view returns(bytes32);

  function bindToken(bytes32 bep2Symbol, address contractAddr, uint256 decimals) external;

  function unbindToken(bytes32 bep2Symbol, address contractAddr) external;

  function transferOut(address contractAddr, address recipient, uint256 amount, uint64 expireTime)
    external payable returns (bool);

  /* solium-disable-next-line */
  function batchTransferOutBNB(address[] calldata recipientAddrs, uint256[] calldata amounts, address[] calldata refundAddrs,
    uint64 expireTime) external payable returns (bool);

}

// File: contracts/interface/IApplication.sol

pragma solidity 0.6.4;

interface IApplication {
    /**
     * @dev Handle syn package
     */
    function handleSynPackage(uint8 channelId, bytes calldata msgBytes) external returns(bytes memory responsePayload);

    /**
     * @dev Handle ack package
     */
    function handleAckPackage(uint8 channelId, bytes calldata msgBytes) external;

    /**
     * @dev Handle fail ack package
     */
    function handleFailAckPackage(uint8 channelId, bytes calldata msgBytes) external;
}

// File: contracts/interface/ICrossChain.sol

pragma solidity 0.6.4;

interface ICrossChain {
    /**
     * @dev Send package to Binance Chain
     */
    function sendSynPackage(uint8 channelId, bytes calldata msgBytes, uint256 relayFee) external;
}

// File: contracts/interface/IParamSubscriber.sol

pragma solidity 0.6.4;

interface IParamSubscriber {
    function updateParam(string calldata key, bytes calldata value) external;
}

// File: contracts/lib/SafeMath.sol

pragma solidity 0.6.4;

/**
 * Copyright (c) 2016-2019 zOS Global Limited
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/lib/RLPEncode.sol

pragma solidity 0.6.4;

library RLPEncode {

    uint8 constant STRING_OFFSET = 0x80;
    uint8 constant LIST_OFFSET = 0xc0;

    /**
     * @notice Encode string item
     * @param self The string (ie. byte array) item to encode
     * @return The RLP encoded string in bytes
     */
    function encodeBytes(bytes memory self) internal pure returns (bytes memory) {
        if (self.length == 1 && self[0] <= 0x7f) {
            return self;
        }
        return mergeBytes(encodeLength(self.length, STRING_OFFSET), self);
    }

    /**
     * @notice Encode address
     * @param self The address to encode
     * @return The RLP encoded address in bytes
     */
    function encodeAddress(address self) internal pure returns (bytes memory) {
        bytes memory b;
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, self))
            mstore(0x40, add(m, 52))
            b := m
        }
        return encodeBytes(b);
    }

    /**
     * @notice Encode uint
     * @param self The uint to encode
     * @return The RLP encoded uint in bytes
     */
    function encodeUint(uint self) internal pure returns (bytes memory) {
        return encodeBytes(toBinary(self));
    }

    /**
     * @notice Encode int
     * @param self The int to encode
     * @return The RLP encoded int in bytes
     */
    function encodeInt(int self) internal pure returns (bytes memory) {
        return encodeUint(uint(self));
    }

    /**
     * @notice Encode bool
     * @param self The bool to encode
     * @return The RLP encoded bool in bytes
     */
    function encodeBool(bool self) internal pure returns (bytes memory) {
        bytes memory rs = new bytes(1);
        if (self) {
            rs[0] = bytes1(uint8(1));
        }
        return rs;
    }

    /**
     * @notice Encode list of items
     * @param self The list of items to encode, each item in list must be already encoded
     * @return The RLP encoded list of items in bytes
     */
    function encodeList(bytes[] memory self) internal pure returns (bytes memory) {
        if (self.length == 0) {
            return new bytes(0);
        }
        bytes memory payload = self[0];
        for (uint i = 1; i < self.length; i++) {
            payload = mergeBytes(payload, self[i]);
        }
        return mergeBytes(encodeLength(payload.length, LIST_OFFSET), payload);
    }

    /**
     * @notice Concat two bytes arrays
     * @param _preBytes The first bytes array
     * @param _postBytes The second bytes array
     * @return The merged bytes array
     */
    function mergeBytes(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
    internal
    pure
    returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
            tempBytes := mload(0x40)

        // Store the length of the first bytes array at the beginning of
        // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

        // Maintain a memory counter for the current write location in the
        // temp bytes array by adding the 32 bytes for the array length to
        // the starting location.
            let mc := add(tempBytes, 0x20)
        // Stop copying when the memory counter reaches the length of the
        // first bytes array.
            let end := add(mc, length)

            for {
            // Initialize a copy counter to the start of the _preBytes data,
            // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
            // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
            // Write the _preBytes data into the tempBytes memory 32 bytes
            // at a time.
                mstore(mc, mload(cc))
            }

        // Add the length of _postBytes to the current length of tempBytes
        // and store it as the new length in the first 32 bytes of the
        // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

        // Move the memory counter back from a multiple of 0x20 to the
        // actual end of the _preBytes data.
            mc := end
        // Stop copying when the memory counter reaches the new combined
        // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

        // Update the free-memory pointer by padding our last write location
        // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
        // next 32 byte block, then round down to the nearest multiple of
        // 32. If the sum of the length of the two arrays is zero then add
        // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
            add(add(end, iszero(add(length, mload(_preBytes)))), 31),
            not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    /**
     * @notice Encode the first byte, followed by the `length` in binary form if `length` is more than 55.
     * @param length The length of the string or the payload
     * @param offset `STRING_OFFSET` if item is string, `LIST_OFFSET` if item is list
     * @return RLP encoded bytes
     */
    function encodeLength(uint length, uint offset) internal pure returns (bytes memory) {
        require(length < 256**8, "input too long");
        bytes memory rs = new bytes(1);
        if (length <= 55) {
            rs[0] = byte(uint8(length + offset));
            return rs;
        }
        bytes memory bl = toBinary(length);
        rs[0] = byte(uint8(bl.length + offset + 55));
        return mergeBytes(rs, bl);
    }

    /**
     * @notice Encode integer in big endian binary form with no leading zeroes
     * @param x The integer to encode
     * @return RLP encoded bytes
     */
    function toBinary(uint x) internal pure returns (bytes memory) {
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
        uint i;
        if (x & 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000 == 0) {
            i = 24;
        } else if (x & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000 == 0) {
            i = 16;
        } else {
            i = 0;
        }
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }
        uint length = 32 - i;
        bytes memory rs = new bytes(length);
        assembly {
            mstore(add(rs, length), x)
            mstore(rs, length)
        }
        return rs;
    }
}

// File: contracts/lib/RLPDecode.sol

pragma solidity 0.6.4;

library RLPDecode {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;

    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    struct Iterator {
        RLPItem item;   // Item that's being iterated over.
        uint nextPtr;   // Position of the next item in the list.
    }

    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint ptr = self.nextPtr;
        uint itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    function toRLPItem(bytes memory self) internal pure returns (RLPItem memory) {
        uint memPtr;
        assembly {
            memPtr := add(self, 0x20)
        }

        return RLPItem(self.length, memPtr);
    }

    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }

    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        return item.len - _payloadOffset(item.memPtr);
    }

    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33);

        uint offset = _payloadOffset(item.memPtr);
        require(item.len >= offset, "length is less than offset");
        uint len = item.len - offset;

        uint result;
        uint memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

        // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint) {
        // one byte prefix
        require(item.len == 33);

        uint result;
        uint memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    function numItems(RLPItem memory item) private pure returns (uint) {
        if (item.len == 0) return 0;

        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    function _itemLength(uint memPtr) private pure returns (uint) {
        uint itemLen;
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            itemLen = 1;

        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            uint dataLen;
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
            require(itemLen >= dataLen, "addition overflow");
        }

        else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        }

        else {
            uint dataLen;
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
            require(itemLen >= dataLen, "addition overflow");
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// File: contracts/interface/ISystemReward.sol

pragma solidity 0.6.4;

interface ISystemReward {
  function claimRewards(address payable to, uint256 amount) external returns(uint256 actualAmount);
}

// File: contracts/interface/IRelayerHub.sol

pragma solidity 0.6.4;

interface IRelayerHub {
  function isRelayer(address sender) external view returns (bool);
}

// File: contracts/interface/ILightClient.sol

pragma solidity 0.6.4;

interface ILightClient {

  function isHeaderSynced(uint64 height) external view returns (bool);

  function getAppHash(uint64 height) external view returns (bytes32);

  function getSubmitter(uint64 height) external view returns (address payable);

}

// File: contracts/System.sol

pragma solidity 0.6.4;




contract System {

  bool public alreadyInit;

  uint32 public constant CODE_OK = 0;
  uint32 public constant ERROR_FAIL_DECODE = 100;

  uint8 constant public BIND_CHANNELID = 0x01;
  uint8 constant public TRANSFER_IN_CHANNELID = 0x02;
  uint8 constant public TRANSFER_OUT_CHANNELID = 0x03;
  uint8 constant public STAKING_CHANNELID = 0x08;
  uint8 constant public GOV_CHANNELID = 0x09;
  uint8 constant public SLASH_CHANNELID = 0x0b;
  uint16 constant public bscChainID = 0x0038;

  address public constant VALIDATOR_CONTRACT_ADDR = 0x0000000000000000000000000000000000001000;
  address public constant SLASH_CONTRACT_ADDR = 0x0000000000000000000000000000000000001001;
  address public constant SYSTEM_REWARD_ADDR = 0x0000000000000000000000000000000000001002;
  address public constant LIGHT_CLIENT_ADDR = 0x0000000000000000000000000000000000001003;
  address public constant TOKEN_HUB_ADDR = 0x0000000000000000000000000000000000001004;
  address public constant INCENTIVIZE_ADDR=0x0000000000000000000000000000000000001005;
  address public constant RELAYERHUB_CONTRACT_ADDR = 0x0000000000000000000000000000000000001006;
  address public constant GOV_HUB_ADDR = 0x0000000000000000000000000000000000001007;
  address public constant TOKEN_MANAGER_ADDR = 0x0000000000000000000000000000000000001008;
  address public constant CROSS_CHAIN_CONTRACT_ADDR = 0x0000000000000000000000000000000000002000;


  modifier onlyCoinbase() {
    require(msg.sender == block.coinbase, "the message sender must be the block producer");
    _;
  }

  modifier onlyNotInit() {
    require(!alreadyInit, "the contract already init");
    _;
  }

  modifier onlyInit() {
    require(alreadyInit, "the contract not init yet");
    _;
  }

  modifier onlySlash() {
    require(msg.sender == SLASH_CONTRACT_ADDR, "the message sender must be slash contract");
    _;
  }

  modifier onlyTokenHub() {
    require(msg.sender == TOKEN_HUB_ADDR, "the message sender must be token hub contract");
    _;
  }

  modifier onlyGov() {
    require(msg.sender == GOV_HUB_ADDR, "the message sender must be governance contract");
    _;
  }

  modifier onlyValidatorContract() {
    require(msg.sender == VALIDATOR_CONTRACT_ADDR, "the message sender must be validatorSet contract");
    _;
  }

  modifier onlyCrossChainContract() {
    require(msg.sender == CROSS_CHAIN_CONTRACT_ADDR, "the message sender must be cross chain contract");
    _;
  }

  modifier onlyRelayerIncentivize() {
    require(msg.sender == INCENTIVIZE_ADDR, "the message sender must be incentivize contract");
    _;
  }

  modifier onlyRelayer() {
    require(IRelayerHub(RELAYERHUB_CONTRACT_ADDR).isRelayer(msg.sender), "the msg sender is not a relayer");
    _;
  }

  modifier onlyTokenManager() {
    require(msg.sender == TOKEN_MANAGER_ADDR, "the msg sender must be tokenManager");
    _;
  }

  // Not reliable, do not use when need strong verify
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}

// File: contracts/TokenManager.sol

pragma solidity 0.6.4;










contract TokenManager is System, IApplication, IParamSubscriber {

  using SafeMath for uint256;

  using RLPEncode for *;
  using RLPDecode for *;

  using RLPDecode for RLPDecode.RLPItem;
  using RLPDecode for RLPDecode.Iterator;

  // BC to BSC
  struct BindSynPackage {
    uint8   packageType;
    bytes32 bep2TokenSymbol;
    address contractAddr;
    uint256 totalSupply;
    uint256 peggyAmount;
    uint8   bep20Decimals;
    uint64  expireTime;
  }

  // BSC to BC
  struct ReactBindSynPackage {
    uint32 status;
    bytes32 bep2TokenSymbol;
  }

  // BSC to BC
  struct MirrorSynPackage {
    address mirrorSender;
    address bep20Addr;
    bytes32 bep20Name;
    bytes32 bep20Symbol;
    uint256 bep20Supply;
    uint8   bep20Decimals;
    uint256 mirrorFee;
    uint64  expireTime;
  }

  // BC to BSC
  struct MirrorAckPackage {
    address mirrorSender;
    address bep20Addr;
    uint8  bep20Decimals;
    bytes32 bep2Symbol;
    uint256 mirrorFee;
    uint8   errorCode;
  }

  // BSC to BC
  struct SyncSynPackage {
    address syncSender;
    address bep20Addr;
    bytes32 bep2Symbol;
    uint256 bep20Supply;
    uint256 syncFee;
    uint64  expireTime;
  }

  // BC to BSC
  struct SyncAckPackage {
    address syncSender;
    address bep20Addr;
    uint256 syncFee;
    uint8   errorCode;
  }

  uint8 constant public   BIND_PACKAGE = 0;
  uint8 constant public   UNBIND_PACKAGE = 1;

  // bind status
  uint8 constant public   BIND_STATUS_TIMEOUT = 1;
  uint8 constant public   BIND_STATUS_SYMBOL_MISMATCH = 2;
  uint8 constant public   BIND_STATUS_TOO_MUCH_TOKENHUB_BALANCE = 3;
  uint8 constant public   BIND_STATUS_TOTAL_SUPPLY_MISMATCH = 4;
  uint8 constant public   BIND_STATUS_DECIMALS_MISMATCH = 5;
  uint8 constant public   BIND_STATUS_ALREADY_BOUND_TOKEN = 6;
  uint8 constant public   BIND_STATUS_REJECTED = 7;

  uint8 constant public MIRROR_CHANNELID = 0x04;
  uint8 constant public SYNC_CHANNELID = 0x05;
  uint8 constant public BEP2_TOKEN_DECIMALS = 8;
  uint256 constant public MAX_GAS_FOR_TRANSFER_BNB=10000;
  uint256 constant public MAX_BEP2_TOTAL_SUPPLY = 9000000000000000000;
  uint256 constant public LOG_MAX_UINT256 = 77;
  // mirror status
  uint8 constant public   MIRROR_STATUS_TIMEOUT = 1;
  uint8 constant public   MIRROR_STATUS_DUPLICATED_BEP2_SYMBOL = 2;
  uint8 constant public   MIRROR_STATUS_ALREADY_BOUND = 3;
  // sync status
  uint8 constant public   SYNC_STATUS_TIMEOUT = 1;
  uint8 constant public   SYNC_STATUS_NOT_BOUND_MIRROR = 2;

  uint8 constant public   MINIMUM_BEP20_SYMBOL_LEN = 2;
  uint8 constant public   MAXIMUM_BEP20_SYMBOL_LEN = 8;

  uint256 constant public  TEN_DECIMALS = 1e10;

  mapping(bytes32 => BindSynPackage) public bindPackageRecord;

  mapping(address => bool) public mirrorPendingRecord;
  mapping(address => bool) public boundByMirror;
  uint256 public mirrorFee;
  uint256 public syncFee;

  event bindSuccess(address indexed contractAddr, string bep2Symbol, uint256 totalSupply, uint256 peggyAmount);
  event bindFailure(address indexed contractAddr, string bep2Symbol, uint32 failedReason);
  event unexpectedPackage(uint8 channelId, bytes msgBytes);
  event paramChange(string key, bytes value);
  event mirrorSuccess(address indexed bep20Addr, bytes32 bep2Symbol);
  event mirrorFailure(address indexed bep20Addr, uint8 errCode);
  event syncSuccess(address indexed bep20Addr);
  event syncFailure(address indexed bep20Addr, uint8 errCode);

  constructor() public {}

  function handleSynPackage(uint8 channelId, bytes calldata msgBytes) onlyCrossChainContract external override returns(bytes memory) {
    if (channelId == BIND_CHANNELID) {
      return handleBindSynPackage(msgBytes);
    } else {
      emit unexpectedPackage(channelId, msgBytes);
      return new bytes(0);
    }
  }

  function handleAckPackage(uint8 channelId, bytes calldata msgBytes) onlyCrossChainContract external override {
    if (channelId == MIRROR_CHANNELID) {
      handleMirrorAckPackage(msgBytes);
    } else if (channelId == SYNC_CHANNELID) {
      handleSyncAckPackage(msgBytes);
    } else {
      emit unexpectedPackage(channelId, msgBytes);
    }
  }

  function handleFailAckPackage(uint8 channelId, bytes calldata msgBytes) onlyCrossChainContract external override {
    if (channelId == MIRROR_CHANNELID) {
      handleMirrorFailAckPackage(msgBytes);
    } else if (channelId == SYNC_CHANNELID) {
      handleSyncFailAckPackage(msgBytes);
    } else {
      emit unexpectedPackage(channelId, msgBytes);
    }
  }

  function decodeBindSynPackage(bytes memory msgBytes) internal pure returns(BindSynPackage memory, bool) {
    BindSynPackage memory bindSynPkg;
    RLPDecode.Iterator memory iter = msgBytes.toRLPItem().iterator();
    bool success = false;
    uint256 idx=0;
    while (iter.hasNext()) {
        if (idx == 0)      bindSynPkg.packageType      = uint8(iter.next().toUint());
        else if (idx == 1) bindSynPkg.bep2TokenSymbol  = bytes32(iter.next().toUint());
        else if (idx == 2) bindSynPkg.contractAddr     = iter.next().toAddress();
        else if (idx == 3) bindSynPkg.totalSupply      = iter.next().toUint();
        else if (idx == 4) bindSynPkg.peggyAmount      = iter.next().toUint();
        else if (idx == 5) bindSynPkg.bep20Decimals    = uint8(iter.next().toUint());
        else if (idx == 6) {
          bindSynPkg.expireTime       = uint64(iter.next().toUint());
          success = true;
        }
        else break;
        idx++;
    }
    return (bindSynPkg, success);
  }

  function handleBindSynPackage(bytes memory msgBytes) internal returns(bytes memory) {
    (BindSynPackage memory bindSynPkg, bool success) = decodeBindSynPackage(msgBytes);
    require(success, "unrecognized transferIn package");
    if (bindSynPkg.packageType == BIND_PACKAGE) {
      bindPackageRecord[bindSynPkg.bep2TokenSymbol]=bindSynPkg;
    } else if (bindSynPkg.packageType == UNBIND_PACKAGE) {
      address contractAddr = ITokenHub(TOKEN_HUB_ADDR).getContractAddrByBEP2Symbol(bindSynPkg.bep2TokenSymbol);
      if (contractAddr!=address(0x00)) {
        ITokenHub(TOKEN_HUB_ADDR).unbindToken(bindSynPkg.bep2TokenSymbol, contractAddr);
      }
    } else {
      require(false, "unrecognized bind package");
    }
    return new bytes(0);
  }

  function encodeReactBindSynPackage(ReactBindSynPackage memory reactBindSynPackage) internal pure returns (bytes memory) {
    bytes[] memory elements = new bytes[](2);
    elements[0] = reactBindSynPackage.status.encodeUint();
    elements[1] = uint256(reactBindSynPackage.bep2TokenSymbol).encodeUint();
    return elements.encodeList();
  }

  function approveBind(address contractAddr, string memory bep2Symbol) payable public returns (bool) {
    require(!mirrorPendingRecord[contractAddr], "the bep20 token is in mirror pending status");
    bytes32 bep2TokenSymbol = bep2TokenSymbolConvert(bep2Symbol);
    BindSynPackage memory bindSynPkg = bindPackageRecord[bep2TokenSymbol];
    require(bindSynPkg.bep2TokenSymbol!=bytes32(0x00), "bind request doesn't exist");
    uint256 lockedAmount = bindSynPkg.totalSupply.sub(bindSynPkg.peggyAmount);
    require(contractAddr==bindSynPkg.contractAddr, "contact address doesn't equal to the contract address in bind request");
    require(IBEP20(contractAddr).getOwner()==msg.sender, "only bep20 owner can approve this bind request");
    uint256 tokenHubBalance = IBEP20(contractAddr).balanceOf(TOKEN_HUB_ADDR);
    require(IBEP20(contractAddr).allowance(msg.sender, address(this)).add(tokenHubBalance)>=lockedAmount, "allowance is not enough");
    uint256 relayFee = msg.value;
    uint256 miniRelayFee = ITokenHub(TOKEN_HUB_ADDR).getMiniRelayFee();
    require(relayFee >= miniRelayFee && relayFee%TEN_DECIMALS == 0, "relayFee must be N * 1e10 and greater than miniRelayFee");

    uint32 verifyCode = verifyBindParameters(bindSynPkg, contractAddr);
    if (verifyCode == CODE_OK) {
      IBEP20(contractAddr).transferFrom(msg.sender, TOKEN_HUB_ADDR, lockedAmount.sub(tokenHubBalance));
      ITokenHub(TOKEN_HUB_ADDR).bindToken(bindSynPkg.bep2TokenSymbol, bindSynPkg.contractAddr, bindSynPkg.bep20Decimals);
      emit bindSuccess(contractAddr, bep2Symbol, bindSynPkg.totalSupply, lockedAmount);
    } else {
      emit bindFailure(contractAddr, bep2Symbol, verifyCode);
    }
    delete bindPackageRecord[bep2TokenSymbol];
    ReactBindSynPackage memory reactBindSynPackage = ReactBindSynPackage({
      status: verifyCode,
      bep2TokenSymbol: bep2TokenSymbol
    });
    address(uint160(TOKEN_HUB_ADDR)).transfer(relayFee);
    ICrossChain(CROSS_CHAIN_CONTRACT_ADDR).sendSynPackage(BIND_CHANNELID, encodeReactBindSynPackage(reactBindSynPackage), relayFee.div(TEN_DECIMALS));
    return true;
  }

  function rejectBind(address contractAddr, string memory bep2Symbol) payable public returns (bool) {
    bytes32 bep2TokenSymbol = bep2TokenSymbolConvert(bep2Symbol);
    BindSynPackage memory bindSynPkg = bindPackageRecord[bep2TokenSymbol];
    require(bindSynPkg.bep2TokenSymbol!=bytes32(0x00), "bind request doesn't exist");
    require(contractAddr==bindSynPkg.contractAddr, "contact address doesn't equal to the contract address in bind request");
    require(IBEP20(contractAddr).getOwner()==msg.sender, "only bep20 owner can reject");
    uint256 relayFee = msg.value;
    uint256 miniRelayFee = ITokenHub(TOKEN_HUB_ADDR).getMiniRelayFee();
    require(relayFee >= miniRelayFee && relayFee%TEN_DECIMALS == 0, "relayFee must be N * 1e10 and greater than miniRelayFee");
    delete bindPackageRecord[bep2TokenSymbol];
    ReactBindSynPackage memory reactBindSynPackage = ReactBindSynPackage({
      status: BIND_STATUS_REJECTED,
      bep2TokenSymbol: bep2TokenSymbol
    });
    address(uint160(TOKEN_HUB_ADDR)).transfer(relayFee);
    ICrossChain(CROSS_CHAIN_CONTRACT_ADDR).sendSynPackage(BIND_CHANNELID, encodeReactBindSynPackage(reactBindSynPackage), relayFee.div(TEN_DECIMALS));
    emit bindFailure(contractAddr, bep2Symbol, BIND_STATUS_REJECTED);
    return true;
  }

  function expireBind(string memory bep2Symbol) payable public returns (bool) {
    bytes32 bep2TokenSymbol = bep2TokenSymbolConvert(bep2Symbol);
    BindSynPackage memory bindSynPkg = bindPackageRecord[bep2TokenSymbol];
    require(bindSynPkg.bep2TokenSymbol!=bytes32(0x00), "bind request doesn't exist");
    require(bindSynPkg.expireTime<block.timestamp, "bind request is not expired");
    uint256 relayFee = msg.value;
    uint256 miniRelayFee = ITokenHub(TOKEN_HUB_ADDR).getMiniRelayFee();
    require(relayFee >= miniRelayFee &&relayFee%TEN_DECIMALS == 0, "relayFee must be N * 1e10 and greater than miniRelayFee");
    delete bindPackageRecord[bep2TokenSymbol];
    ReactBindSynPackage memory reactBindSynPackage = ReactBindSynPackage({
      status: BIND_STATUS_TIMEOUT,
      bep2TokenSymbol: bep2TokenSymbol
    });
    address(uint160(TOKEN_HUB_ADDR)).transfer(relayFee);
    ICrossChain(CROSS_CHAIN_CONTRACT_ADDR).sendSynPackage(BIND_CHANNELID, encodeReactBindSynPackage(reactBindSynPackage), relayFee.div(TEN_DECIMALS));
    emit bindFailure(bindSynPkg.contractAddr, bep2Symbol, BIND_STATUS_TIMEOUT);
    return true;
  }

  function encodeMirrorSynPackage(MirrorSynPackage memory mirrorSynPackage) internal pure returns (bytes memory) {
    bytes[] memory elements = new bytes[](8);
    elements[0] = mirrorSynPackage.mirrorSender.encodeAddress();
    elements[1] = mirrorSynPackage.bep20Addr.encodeAddress();
    elements[2] = uint256(mirrorSynPackage.bep20Name).encodeUint();
    elements[3] = uint256(mirrorSynPackage.bep20Symbol).encodeUint();
    elements[4] = mirrorSynPackage.bep20Supply.encodeUint();
    elements[5] = uint256(mirrorSynPackage.bep20Decimals).encodeUint();
    elements[6] = mirrorSynPackage.mirrorFee.encodeUint();
    elements[7] = uint256(mirrorSynPackage.expireTime).encodeUint();
    return elements.encodeList();
  }

  function decodeMirrorSynPackage(bytes memory msgBytes) internal pure returns(MirrorSynPackage memory, bool) {
    MirrorSynPackage memory mirrorSynPackage;
    RLPDecode.Iterator memory iter = msgBytes.toRLPItem().iterator();
    bool success = false;
    uint256 idx=0;
    while (iter.hasNext()) {
      if (idx == 0)      mirrorSynPackage.mirrorSender  = iter.next().toAddress();
      else if (idx == 1) mirrorSynPackage.bep20Addr     = iter.next().toAddress();
      else if (idx == 2) mirrorSynPackage.bep20Name     = bytes32(iter.next().toUint());
      else if (idx == 3) mirrorSynPackage.bep20Symbol   = bytes32(iter.next().toUint());
      else if (idx == 4) mirrorSynPackage.bep20Supply   = iter.next().toUint();
      else if (idx == 5) mirrorSynPackage.bep20Decimals = uint8(iter.next().toUint());
      else if (idx == 6) mirrorSynPackage.mirrorFee     = iter.next().toUint();
      else if (idx == 7) {
        mirrorSynPackage.expireTime = uint64(iter.next().toUint());
        success = true;
      }
      else break;
      idx++;
    }
    return (mirrorSynPackage, success);
  }

  function decodeMirrorAckPackage(bytes memory msgBytes) internal pure returns(MirrorAckPackage memory, bool) {
    MirrorAckPackage memory mirrorAckPackage;
    RLPDecode.Iterator memory iter = msgBytes.toRLPItem().iterator();
    bool success = false;
    uint256 idx=0;
    while (iter.hasNext()) {
      if (idx == 0)      mirrorAckPackage.mirrorSender   = iter.next().toAddress();
      else if (idx == 1) mirrorAckPackage.bep20Addr      = iter.next().toAddress();
      else if (idx == 2) mirrorAckPackage.bep20Decimals  = uint8(iter.next().toUint());
      else if (idx == 3) mirrorAckPackage.bep2Symbol     = bytes32(iter.next().toUint());
      else if (idx == 4) mirrorAckPackage.mirrorFee      = iter.next().toUint();
      else if (idx == 5) {
        mirrorAckPackage.errorCode  = uint8(iter.next().toUint());
        success = true;
      }
      else break;
      idx++;
    }
    return (mirrorAckPackage, success);
  }

  function mirror(address bep20Addr, uint64 expireTime) payable public returns (bool) {
    require(ITokenHub(TOKEN_HUB_ADDR).getBep2SymbolByContractAddr(bep20Addr) == bytes32(0x00), "already bound");
    require(!mirrorPendingRecord[bep20Addr], "mirror pending");
    uint256 miniRelayFee = ITokenHub(TOKEN_HUB_ADDR).getMiniRelayFee();
    require(msg.value%TEN_DECIMALS == 0 && msg.value>=mirrorFee.add(miniRelayFee), "msg.value must be N * 1e10 and greater than sum of miniRelayFee and mirrorFee");
    require(expireTime>=block.timestamp + 120 && expireTime <= block.timestamp + 86400, "expireTime must be two minutes later and one day earlier");
    uint8 decimals = IBEP20(bep20Addr).decimals();
    uint256 totalSupply = IBEP20(bep20Addr).totalSupply();
    require(convertToBep2Amount(totalSupply, decimals) <= MAX_BEP2_TOTAL_SUPPLY, "too large total supply");
    string memory name = IBEP20(bep20Addr).name();
    bytes memory nameBytes = bytes(name);
    require(nameBytes.length>=1 && nameBytes.length<=32, "name length must be in [1,32]");
    string memory symbol = IBEP20(bep20Addr).symbol();
    bytes memory symbolBytes = bytes(symbol);
    require(symbolBytes.length>=MINIMUM_BEP20_SYMBOL_LEN && symbolBytes.length<=MAXIMUM_BEP20_SYMBOL_LEN, "symbol length must be in [2,8]");
    for (uint8 i = 0; i < symbolBytes.length; i++) {
      require((symbolBytes[i]>='A' && symbolBytes[i]<='Z') || (symbolBytes[i]>='a' && symbolBytes[i]<='z') || (symbolBytes[i]>='0' && symbolBytes[i]<='9'), "symbol should only contain alphabet and number");
    }
    address(uint160(TOKEN_HUB_ADDR)).transfer(msg.value.sub(mirrorFee));
    mirrorPendingRecord[bep20Addr] = true;
    bytes32 bytes32Name;
    assembly {
      bytes32Name := mload(add(name, 32))
    }
    bytes32 bytes32Symbol;
    assembly {
      bytes32Symbol := mload(add(symbol, 32))
    }
    MirrorSynPackage memory mirrorSynPackage = MirrorSynPackage({
      mirrorSender:  msg.sender,
      bep20Addr:     bep20Addr,
      bep20Name:     bytes32Name,
      bep20Symbol:   bytes32Symbol,
      bep20Supply:   totalSupply,
      bep20Decimals: decimals,
      mirrorFee:     mirrorFee.div(TEN_DECIMALS),
      expireTime:    expireTime
      });
    ICrossChain(CROSS_CHAIN_CONTRACT_ADDR).sendSynPackage(MIRROR_CHANNELID, encodeMirrorSynPackage(mirrorSynPackage), msg.value.sub(mirrorFee).div(TEN_DECIMALS));
    return true;
  }

  function handleMirrorAckPackage(bytes memory msgBytes) internal {
    (MirrorAckPackage memory mirrorAckPackage, bool decodeSuccess) = decodeMirrorAckPackage(msgBytes);
    require(decodeSuccess, "unrecognized package");
    mirrorPendingRecord[mirrorAckPackage.bep20Addr] = false;
    if (mirrorAckPackage.errorCode == CODE_OK ) {
      address(uint160(TOKEN_HUB_ADDR)).transfer(mirrorAckPackage.mirrorFee);
      ITokenHub(TOKEN_HUB_ADDR).bindToken(mirrorAckPackage.bep2Symbol, mirrorAckPackage.bep20Addr, mirrorAckPackage.bep20Decimals);
      boundByMirror[mirrorAckPackage.bep20Addr] = true;
      emit mirrorSuccess(mirrorAckPackage.bep20Addr, mirrorAckPackage.bep2Symbol);
      return;
    } else {
      (bool success, ) = mirrorAckPackage.mirrorSender.call{gas: MAX_GAS_FOR_TRANSFER_BNB, value: mirrorAckPackage.mirrorFee}("");
      if (!success) {
        address(uint160(SYSTEM_REWARD_ADDR)).transfer(mirrorAckPackage.mirrorFee);
      }
      emit mirrorFailure(mirrorAckPackage.bep20Addr, mirrorAckPackage.errorCode);
    }
  }

  function handleMirrorFailAckPackage(bytes memory msgBytes) internal {
    (MirrorSynPackage memory mirrorSynPackage, bool decodeSuccess) = decodeMirrorSynPackage(msgBytes);
    require(decodeSuccess, "unrecognized package");
    mirrorPendingRecord[mirrorSynPackage.bep20Addr] = false;
    (bool success, ) = mirrorSynPackage.mirrorSender.call{gas: MAX_GAS_FOR_TRANSFER_BNB, value: mirrorSynPackage.mirrorFee.mul(TEN_DECIMALS)}("");
    if (!success) {
      address(uint160(SYSTEM_REWARD_ADDR)).transfer(mirrorSynPackage.mirrorFee.mul(TEN_DECIMALS));
    }
  }

  function encodeSyncSynPackage(SyncSynPackage memory syncSynPackage) internal pure returns (bytes memory) {
    bytes[] memory elements = new bytes[](6);
    elements[0] = syncSynPackage.syncSender.encodeAddress();
    elements[1] = syncSynPackage.bep20Addr.encodeAddress();
    elements[2] = uint256(syncSynPackage.bep2Symbol).encodeUint();
    elements[3] = syncSynPackage.bep20Supply.encodeUint();
    elements[4] = syncSynPackage.syncFee.encodeUint();
    elements[5] = uint256(syncSynPackage.expireTime).encodeUint();
    return elements.encodeList();
  }

  function decodeSyncSynPackage(bytes memory msgBytes) internal pure returns(SyncSynPackage memory, bool) {
    SyncSynPackage memory syncSynPackage;
    RLPDecode.Iterator memory iter = msgBytes.toRLPItem().iterator();
    bool success = false;
    uint256 idx=0;
    while (iter.hasNext()) {
      if (idx == 0)      syncSynPackage.syncSender  = iter.next().toAddress();
      else if (idx == 1) syncSynPackage.bep20Addr   = iter.next().toAddress();
      else if (idx == 2) syncSynPackage.bep2Symbol  = bytes32(iter.next().toUint());
      else if (idx == 3) syncSynPackage.bep20Supply = iter.next().toUint();
      else if (idx == 4) syncSynPackage.syncFee     = iter.next().toUint();
      else if (idx == 5) {
        syncSynPackage.expireTime = uint64(iter.next().toUint());
        success = true;
      }
      else break;
      idx++;
    }
    return (syncSynPackage, success);
  }

  function decodeSyncAckPackage(bytes memory msgBytes) internal pure returns(SyncAckPackage memory, bool) {
    SyncAckPackage memory syncAckPackage;
    RLPDecode.Iterator memory iter = msgBytes.toRLPItem().iterator();
    bool success = false;
    uint256 idx=0;
    while (iter.hasNext()) {
      if (idx == 0)      syncAckPackage.syncSender   = iter.next().toAddress();
      else if (idx == 1) syncAckPackage.bep20Addr    = iter.next().toAddress();
      else if (idx == 2) syncAckPackage.syncFee      = iter.next().toUint();
      else if (idx == 3) {
        syncAckPackage.errorCode  = uint8(iter.next().toUint());
        success = true;
      }
      else break;
      idx++;
    }
    return (syncAckPackage, success);
  }

  function sync(address bep20Addr, uint64 expireTime) payable public returns (bool) {
    bytes32 bep2Symbol = ITokenHub(TOKEN_HUB_ADDR).getBep2SymbolByContractAddr(bep20Addr);
    require(bep2Symbol != bytes32(0x00), "not bound");
    require(boundByMirror[bep20Addr], "not bound by mirror");
    uint256 miniRelayFee = ITokenHub(TOKEN_HUB_ADDR).getMiniRelayFee();
    require(msg.value%TEN_DECIMALS == 0 && msg.value>=syncFee.add(miniRelayFee), "msg.value must be N * 1e10 and no less sum of miniRelayFee and syncFee");
    require(expireTime>=block.timestamp + 120 && expireTime <= block.timestamp + 86400, "expireTime must be two minutes later and one day earlier");
    uint256 totalSupply = IBEP20(bep20Addr).totalSupply();
    uint8 decimals = IBEP20(bep20Addr).decimals();
    require(convertToBep2Amount(totalSupply, decimals) <= MAX_BEP2_TOTAL_SUPPLY, "too large total supply");

    address(uint160(TOKEN_HUB_ADDR)).transfer(msg.value.sub(syncFee));
    SyncSynPackage memory syncSynPackage = SyncSynPackage({
      syncSender:    msg.sender,
      bep20Addr:     bep20Addr,
      bep2Symbol:    bep2Symbol,
      bep20Supply:   totalSupply,
      syncFee:       syncFee.div(TEN_DECIMALS),
      expireTime:    expireTime
      });
    ICrossChain(CROSS_CHAIN_CONTRACT_ADDR).sendSynPackage(SYNC_CHANNELID, encodeSyncSynPackage(syncSynPackage), msg.value.sub(syncFee).div(TEN_DECIMALS));
    return true;
  }

  function handleSyncAckPackage(bytes memory msgBytes) internal {
    (SyncAckPackage memory syncAckPackage, bool decodeSuccess) = decodeSyncAckPackage(msgBytes);
    require(decodeSuccess, "unrecognized package");
    if (syncAckPackage.errorCode == CODE_OK ) {
      address(uint160(TOKEN_HUB_ADDR)).transfer(syncAckPackage.syncFee);
      emit syncSuccess(syncAckPackage.bep20Addr);
      return;
    } else  {
      emit syncFailure(syncAckPackage.bep20Addr, syncAckPackage.errorCode);
    }
    (bool success, ) = syncAckPackage.syncSender.call{gas: MAX_GAS_FOR_TRANSFER_BNB, value: syncAckPackage.syncFee}("");
    if (!success) {
      address(uint160(SYSTEM_REWARD_ADDR)).transfer(syncAckPackage.syncFee);
    }
  }

  function handleSyncFailAckPackage(bytes memory msgBytes) internal {
    (SyncSynPackage memory syncSynPackage, bool decodeSuccess) = decodeSyncSynPackage(msgBytes);
    require(decodeSuccess, "unrecognized package");
    (bool success, ) = syncSynPackage.syncSender.call{gas: MAX_GAS_FOR_TRANSFER_BNB, value: syncSynPackage.syncFee.mul(TEN_DECIMALS)}("");
    if (!success) {
      address(uint160(SYSTEM_REWARD_ADDR)).transfer(syncSynPackage.syncFee.mul(TEN_DECIMALS));
    }
  }

  function updateParam(string calldata key, bytes calldata value) override external onlyGov {
    require(value.length == 32, "expected value length 32");
    string memory localKey = key;
    bytes memory localValue = value;
    bytes32 bytes32Key;
    assembly {
      bytes32Key := mload(add(localKey, 32))
    }
    if (bytes32Key == bytes32(0x6d6972726f724665650000000000000000000000000000000000000000000000)) { // mirrorFee
      uint256 newMirrorFee;
      assembly {
        newMirrorFee := mload(add(localValue, 32))
      }
      require(newMirrorFee%(TEN_DECIMALS)==0, "mirrorFee must be N * 1e10");
      mirrorFee = newMirrorFee;
    } else if (bytes32Key == bytes32(0x73796e6346656500000000000000000000000000000000000000000000000000)) { // syncFee
      uint256 newSyncFee;
      assembly {
        newSyncFee := mload(add(localValue, 32))
      }
      require(newSyncFee%(TEN_DECIMALS)==0, "syncFee must be N * 1e10");
      syncFee = newSyncFee;
    } else {
      require(false, "unknown param");
    }
    emit paramChange(key, value);
  }

  function bep2TokenSymbolConvert(string memory symbol) internal pure returns(bytes32) {
    bytes32 result;
    assembly {
      result := mload(add(symbol, 32))
    }
    return result;
  }

  function queryRequiredLockAmountForBind(string memory symbol) public view returns(uint256) {
    bytes32 bep2Symbol;
    assembly {
      bep2Symbol := mload(add(symbol, 32))
    }
    BindSynPackage memory bindRequest = bindPackageRecord[bep2Symbol];
    if (bindRequest.contractAddr==address(0x00)) {
      return 0;
    }
    uint256 tokenHubBalance = IBEP20(bindRequest.contractAddr).balanceOf(TOKEN_HUB_ADDR);
    uint256 requiredBalance = bindRequest.totalSupply.sub(bindRequest.peggyAmount);
    return requiredBalance.sub(tokenHubBalance);
  }

  function verifyBindParameters(BindSynPackage memory bindSynPkg, address contractAddr) internal view returns(uint32) {
    uint256 decimals = IBEP20(contractAddr).decimals();
    string memory bep20Symbol = IBEP20(contractAddr).symbol();
    uint256 tokenHubBalance = IBEP20(contractAddr).balanceOf(TOKEN_HUB_ADDR);
    uint256 lockedAmount = bindSynPkg.totalSupply.sub(bindSynPkg.peggyAmount);
    if (bindSynPkg.expireTime<block.timestamp) {
      return BIND_STATUS_TIMEOUT;
    }
    if (!checkSymbol(bep20Symbol, bindSynPkg.bep2TokenSymbol)) {
      return BIND_STATUS_SYMBOL_MISMATCH;
    }
    if (tokenHubBalance > lockedAmount) {
      return BIND_STATUS_TOO_MUCH_TOKENHUB_BALANCE;
    }
    if (IBEP20(bindSynPkg.contractAddr).totalSupply() != bindSynPkg.totalSupply) {
      return BIND_STATUS_TOTAL_SUPPLY_MISMATCH;
    }
    if (decimals!=bindSynPkg.bep20Decimals) {
      return BIND_STATUS_DECIMALS_MISMATCH;
    }
    if (ITokenHub(TOKEN_HUB_ADDR).getContractAddrByBEP2Symbol(bindSynPkg.bep2TokenSymbol)!=address(0x00)||
    ITokenHub(TOKEN_HUB_ADDR).getBep2SymbolByContractAddr(bindSynPkg.contractAddr)!=bytes32(0x00)) {
      return BIND_STATUS_ALREADY_BOUND_TOKEN;
    }
    return CODE_OK;
  }

  function checkSymbol(string memory bep20Symbol, bytes32 bep2TokenSymbol) internal pure returns(bool) {
    bytes memory bep20SymbolBytes = bytes(bep20Symbol);
    if (bep20SymbolBytes.length > MAXIMUM_BEP20_SYMBOL_LEN || bep20SymbolBytes.length < MINIMUM_BEP20_SYMBOL_LEN) {
      return false;
    }

    bytes memory bep2TokenSymbolBytes = new bytes(32);
    assembly {
      mstore(add(bep2TokenSymbolBytes, 32), bep2TokenSymbol)
    }
    if (bep2TokenSymbolBytes[bep20SymbolBytes.length] != 0x2d) { // '-'
      return false;
    }
    bool symbolMatch = true;
    for (uint256 index=0; index < bep20SymbolBytes.length; index++) {
      if (bep20SymbolBytes[index] != bep2TokenSymbolBytes[index]) {
        symbolMatch = false;
        break;
      }
    }
    return symbolMatch;
  }

  function convertToBep2Amount(uint256 amount, uint256 bep20TokenDecimals) internal pure returns (uint256) {
    if (bep20TokenDecimals > BEP2_TOKEN_DECIMALS) {
      require(bep20TokenDecimals-BEP2_TOKEN_DECIMALS <= LOG_MAX_UINT256, "too large decimals");
      return amount.div(10**(bep20TokenDecimals-BEP2_TOKEN_DECIMALS));
    }
    return amount.mul(10**(BEP2_TOKEN_DECIMALS-bep20TokenDecimals));
  }
}