/**
 *Submitted for verification at BscScan.com on 2020-09-02
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/interface/ISystemReward.sol

pragma solidity 0.6.4;

interface ISystemReward {
  function claimRewards(address payable to, uint256 amount) external returns(uint256 actualAmount);
}


// File contracts/interface/IRelayerHub.sol

pragma solidity 0.6.4;

interface IRelayerHub {
  function isRelayer(address sender) external view returns (bool);
}


// File contracts/interface/ILightClient.sol

pragma solidity 0.6.4;

interface ILightClient {

  function isHeaderSynced(uint64 height) external view returns (bool);

  function getAppHash(uint64 height) external view returns (bytes32);

  function getSubmitter(uint64 height) external view returns (address payable);

}


// File contracts/System.sol

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


// File contracts/lib/BytesToTypes.sol

pragma solidity 0.6.4;

/**
 * @title BytesToTypes
 * Copyright (c) 2016-2020 zpouladzade/Seriality
 * @dev The BytesToTypes contract converts the memory byte arrays to the standard solidity types
 * @author [email protected]
 */

library BytesToTypes {
    

    function bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 
    
    function bytesToBool(uint _offst, bytes memory _input) internal pure returns (bool _output) {
        
        uint8 x;
        assembly {
            x := mload(add(_input, _offst))
        }
        x==0 ? _output = false : _output = true;
    }   
        
    function getStringSize(uint _offst, bytes memory _input) internal pure returns(uint size) {
        
        assembly{
            
            size := mload(add(_input,_offst))
            let chunk_count := add(div(size,32),1) // chunk_count = size/32 + 1
            
            if gt(mod(size,32),0) {// if size%32 > 0
                chunk_count := add(chunk_count,1)
            } 
            
             size := mul(chunk_count,32)// first 32 bytes reseves for size in strings
        }
    }

    function bytesToString(uint _offst, bytes memory _input, bytes memory _output) internal pure {

        uint size = 32;
        assembly {
            
            let chunk_count
            
            size := mload(add(_input,_offst))
            chunk_count := add(div(size,32),1) // chunk_count = size/32 + 1
            
            if gt(mod(size,32),0) {
                chunk_count := add(chunk_count,1)  // chunk_count++
            }
               
            for { let index:= 0 }  lt(index , chunk_count) { index := add(index,1) } {
                mstore(add(_output,mul(index,32)),mload(add(_input,_offst)))
                _offst := sub(_offst,32)           // _offst -= 32
            }
        }
    }

    function bytesToBytes32(uint _offst, bytes memory  _input, bytes32 _output) internal pure {
        
        assembly {
            mstore(_output , add(_input, _offst))
            mstore(add(_output,32) , add(add(_input, _offst),32))
        }
    }
    
    function bytesToInt8(uint _offst, bytes memory  _input) internal pure returns (int8 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }
    
    function bytesToInt16(uint _offst, bytes memory _input) internal pure returns (int16 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt24(uint _offst, bytes memory _input) internal pure returns (int24 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt32(uint _offst, bytes memory _input) internal pure returns (int32 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt40(uint _offst, bytes memory _input) internal pure returns (int40 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt48(uint _offst, bytes memory _input) internal pure returns (int48 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt56(uint _offst, bytes memory _input) internal pure returns (int56 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt64(uint _offst, bytes memory _input) internal pure returns (int64 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt72(uint _offst, bytes memory _input) internal pure returns (int72 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt80(uint _offst, bytes memory _input) internal pure returns (int80 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt88(uint _offst, bytes memory _input) internal pure returns (int88 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt96(uint _offst, bytes memory _input) internal pure returns (int96 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }
	
	function bytesToInt104(uint _offst, bytes memory _input) internal pure returns (int104 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }
    
    function bytesToInt112(uint _offst, bytes memory _input) internal pure returns (int112 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt120(uint _offst, bytes memory _input) internal pure returns (int120 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt128(uint _offst, bytes memory _input) internal pure returns (int128 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt136(uint _offst, bytes memory _input) internal pure returns (int136 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt144(uint _offst, bytes memory _input) internal pure returns (int144 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt152(uint _offst, bytes memory _input) internal pure returns (int152 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt160(uint _offst, bytes memory _input) internal pure returns (int160 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt168(uint _offst, bytes memory _input) internal pure returns (int168 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt176(uint _offst, bytes memory _input) internal pure returns (int176 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt184(uint _offst, bytes memory _input) internal pure returns (int184 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt192(uint _offst, bytes memory _input) internal pure returns (int192 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt200(uint _offst, bytes memory _input) internal pure returns (int200 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt208(uint _offst, bytes memory _input) internal pure returns (int208 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt216(uint _offst, bytes memory _input) internal pure returns (int216 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt224(uint _offst, bytes memory _input) internal pure returns (int224 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt232(uint _offst, bytes memory _input) internal pure returns (int232 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt240(uint _offst, bytes memory _input) internal pure returns (int240 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt248(uint _offst, bytes memory _input) internal pure returns (int248 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt256(uint _offst, bytes memory _input) internal pure returns (int256 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint8(uint _offst, bytes memory _input) internal pure returns (uint8 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint16(uint _offst, bytes memory _input) internal pure returns (uint16 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint24(uint _offst, bytes memory _input) internal pure returns (uint24 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint32(uint _offst, bytes memory _input) internal pure returns (uint32 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint40(uint _offst, bytes memory _input) internal pure returns (uint40 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint48(uint _offst, bytes memory _input) internal pure returns (uint48 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint56(uint _offst, bytes memory _input) internal pure returns (uint56 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint64(uint _offst, bytes memory _input) internal pure returns (uint64 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint72(uint _offst, bytes memory _input) internal pure returns (uint72 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint80(uint _offst, bytes memory _input) internal pure returns (uint80 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint88(uint _offst, bytes memory _input) internal pure returns (uint88 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint96(uint _offst, bytes memory _input) internal pure returns (uint96 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 
	
	function bytesToUint104(uint _offst, bytes memory _input) internal pure returns (uint104 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint112(uint _offst, bytes memory _input) internal pure returns (uint112 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint120(uint _offst, bytes memory _input) internal pure returns (uint120 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint128(uint _offst, bytes memory _input) internal pure returns (uint128 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint136(uint _offst, bytes memory _input) internal pure returns (uint136 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint144(uint _offst, bytes memory _input) internal pure returns (uint144 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint152(uint _offst, bytes memory _input) internal pure returns (uint152 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint160(uint _offst, bytes memory _input) internal pure returns (uint160 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint168(uint _offst, bytes memory _input) internal pure returns (uint168 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint176(uint _offst, bytes memory _input) internal pure returns (uint176 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint184(uint _offst, bytes memory _input) internal pure returns (uint184 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint192(uint _offst, bytes memory _input) internal pure returns (uint192 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint200(uint _offst, bytes memory _input) internal pure returns (uint200 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint208(uint _offst, bytes memory _input) internal pure returns (uint208 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint216(uint _offst, bytes memory _input) internal pure returns (uint216 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint224(uint _offst, bytes memory _input) internal pure returns (uint224 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint232(uint _offst, bytes memory _input) internal pure returns (uint232 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint240(uint _offst, bytes memory _input) internal pure returns (uint240 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint248(uint _offst, bytes memory _input) internal pure returns (uint248 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 
    
}


// File contracts/lib/Memory.sol

pragma solidity 0.6.4;

library Memory {

    // Size of a word, in bytes.
    uint internal constant WORD_SIZE = 32;
    // Size of the header of a 'bytes' array.
    uint internal constant BYTES_HEADER_SIZE = 32;
    // Address of the free memory pointer.
    uint internal constant FREE_MEM_PTR = 0x40;

    // Compares the 'len' bytes starting at address 'addr' in memory with the 'len'
    // bytes starting at 'addr2'.
    // Returns 'true' if the bytes are the same, otherwise 'false'.
    function equals(uint addr, uint addr2, uint len) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    // Compares the 'len' bytes starting at address 'addr' in memory with the bytes stored in
    // 'bts'. It is allowed to set 'len' to a lower value then 'bts.length', in which case only
    // the first 'len' bytes will be compared.
    // Requires that 'bts.length >= len'
    function equals(uint addr, uint len, bytes memory bts) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint addr2;
        assembly {
            addr2 := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        return equals(addr, addr2, len);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // Copy 'len' bytes from memory address 'src', to address 'dest'.
    // This function does not check the or destination, it only copies
    // the bytes.
    function copy(uint src, uint dest, uint len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

        // Copy remaining bytes
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    // Returns a memory pointer to the provided bytes array.
    function ptr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := bts
        }
    }

    // Returns a memory pointer to the data portion of the provided bytes array.
    function dataPtr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }

    // This function does the same as 'dataPtr(bytes memory)', but will also return the
    // length of the provided bytes array.
    function fromBytes(bytes memory bts) internal pure returns (uint addr, uint len) {
        len = bts.length;
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }

    // Creates a 'bytes memory' variable from the memory address 'addr', with the
    // length 'len'. The function will allocate new memory for the bytes array, and
    // the 'len bytes starting at 'addr' will be copied into that new memory.
    function toBytes(uint addr, uint len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint btsptr;
        assembly {
            btsptr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        copy(addr, btsptr, len);
    }

    // Get the word stored at memory address 'addr' as a 'uint'.
    function toUint(uint addr) internal pure returns (uint n) {
        assembly {
            n := mload(addr)
        }
    }

    // Get the word stored at memory address 'addr' as a 'bytes32'.
    function toBytes32(uint addr) internal pure returns (bytes32 bts) {
        assembly {
            bts := mload(addr)
        }
    }
}


// File contracts/interface/ISlashIndicator.sol

pragma solidity 0.6.4;

interface ISlashIndicator {
  function clean() external;
  function sendFelonyPackage(address validator) external;
  function getSlashThresholds() external view returns (uint256, uint256);
}


// File contracts/interface/ITokenHub.sol

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


// File contracts/interface/IParamSubscriber.sol

pragma solidity 0.6.4;

interface IParamSubscriber {
    function updateParam(string calldata key, bytes calldata value) external;
}


// File contracts/interface/IBSCValidatorSet.sol

pragma solidity 0.6.4;

interface IBSCValidatorSet {
  function misdemeanor(address validator) external;
  function felony(address validator)external;
  function isCurrentValidator(address validator) external view returns (bool);
}


// File contracts/interface/IApplication.sol

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


// File contracts/lib/SafeMath.sol

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


// File contracts/lib/RLPDecode.sol

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


// File contracts/lib/RLPEncode.sol

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


// File contracts/lib/CmnPkg.sol

pragma solidity 0.6.4;


library CmnPkg {

    using RLPEncode for *;
    using RLPDecode for *;


    struct CommonAckPackage {
        uint32 code;
    }

    function encodeCommonAckPackage(uint32 code) internal pure returns (bytes memory) {
        bytes[] memory elements = new bytes[](1);
        elements[0] = uint256(code).encodeUint();
        return elements.encodeList();
    }

    function decodeCommonAckPackage(bytes memory msgBytes) internal pure returns (CommonAckPackage memory, bool) {
        CommonAckPackage memory ackPkg;
        RLPDecode.Iterator memory iter = msgBytes.toRLPItem().iterator();

        bool success = false;
        uint256 idx=0;
        while (iter.hasNext()) {
            if (idx == 0) {
                ackPkg.code = uint32(iter.next().toUint());
                success = true;
            } else {
                break;
            }
            idx++;
        }
        return (ackPkg, success);
    }
}


// File contracts/BSCValidatorSet.sol

pragma solidity 0.6.4;













contract BSCValidatorSet is IBSCValidatorSet, System, IParamSubscriber, IApplication {

  using SafeMath for uint256;

  using RLPDecode for *;

  // will not transfer value less than 0.1 BNB for validators
  uint256 constant public DUSTY_INCOMING = 1e17;

  uint8 public constant JAIL_MESSAGE_TYPE = 1;
  uint8 public constant VALIDATORS_UPDATE_MESSAGE_TYPE = 0;

  // the precision of cross chain value transfer.
  uint256 public constant PRECISION = 1e10;
  uint256 public constant EXPIRE_TIME_SECOND_GAP = 1000;
  uint256 public constant MAX_NUM_OF_VALIDATORS = 41;

  bytes public constant INIT_VALIDATORSET_BYTES = hex"f905ec80f905e8f846942a7cdd959bfe8d9487b2a43b33565295a698f7e294b6a7edd747c0554875d3fc531d19ba1497992c5e941ff80f3f7f110ffd8920a3ac38fdef318fe94a3f86048c27395000f846946488aa4d1955ee33403f8ccb1d4de5fb97c7ade294220f003d8bdfaadf52aa1e55ae4cc485e6794875941a87e90e440a39c99aa9cb5cea0ad6a3f0b2407b86048c27395000f846949ef9f4360c606c7ab4db26b016007d3ad0ab86a0946103af86a874b705854033438383c82575f25bc29418e2db06cbff3e3c5f856410a1838649e760175786048c27395000f84694ee01c3b1283aa067c58eab4709f85e99d46de5fe94ee4b9bfb1871c64e2bcabb1dc382dc8b7c4218a29415904ab26ab0e99d70b51c220ccdcccabee6e29786048c27395000f84694685b1ded8013785d6623cc18d214320b6bb6475994a20ef4e5e4e7e36258dbf51f4d905114cb1b34bc9413e39085dc88704f4394d35209a02b1a9520320c86048c27395000f8469478f3adfc719c99674c072166708589033e2d9afe9448a30d5eaa7b64492a160f139e2da2800ec3834e94055838358c29edf4dcc1ba1985ad58aedbb6be2b86048c27395000f84694c2be4ec20253b8642161bc3f444f53679c1f3d479466f50c616d737e60d7ca6311ff0d9c434197898a94d1d678a2506eeaa365056fe565df8bc8659f28b086048c27395000f846942f7be8361c80a4c1e7e9aaf001d0877f1cfde218945f93992ac37f3e61db2ef8a587a436a161fd210b94ecbc4fb1a97861344dad0867ca3cba2b860411f086048c27395000f84694ce2fd7544e0b2cc94692d4a704debef7bcb613289444abc67b4b2fba283c582387f54c9cba7c34bafa948acc2ab395ded08bb75ce85bf0f95ad2abc51ad586048c27395000f84694b8f7166496996a7da21cf1f1b04d9b3e26a3d077946770572763289aac606e4f327c2f6cc1aa3b3e3b94882d745ed97d4422ca8da1c22ec49d880c4c097286048c27395000f846942d4c407bbe49438ed859fe965b140dcf1aab71a9943ad0939e120f33518fbba04631afe7a3ed6327b194b2bbb170ca4e499a2b0f3cc85ebfa6e8c4dfcbea86048c27395000f846946bbad7cf34b5fa511d8e963dbba288b1960e75d694853b0f6c324d1f4e76c8266942337ac1b0af1a229442498946a51ca5924552ead6fc2af08b94fcba648601d1a94a2000f846944430b3230294d12c6ab2aac5c2cd68e80b16b581947b107f4976a252a6939b771202c28e64e03f52d694795811a7f214084116949fc4f53cedbf189eeab28601d1a94a2000f84694ea0a6e3c511bbd10f4519ece37dc24887e11b55d946811ca77acfb221a49393c193f3a22db829fcc8e9464feb7c04830dd9ace164fc5c52b3f5a29e5018a8601d1a94a2000f846947ae2f5b9e386cd1b50a4550696d957cb4900f03a94e83bcc5077e6b873995c24bac871b5ad856047e19464e48d4057a90b233e026c1041e6012ada897fe88601d1a94a2000f8469482012708dafc9e1b880fd083b32182b869be8e09948e5adc73a2d233a1b496ed3115464dd6c7b887509428b383d324bc9a37f4e276190796ba5a8947f5ed8601d1a94a2000f8469422b81f8e175ffde54d797fe11eb03f9e3bf75f1d94a1c3ef7ca38d8ba80cce3bfc53ebd2903ed21658942767f7447f7b9b70313d4147b795414aecea54718601d1a94a2000f8469468bf0b8b6fb4e317a0f9d6f03eaf8ce6675bc60d94675cfe570b7902623f47e7f59c9664b5f5065dcf94d84f0d2e50bcf00f2fc476e1c57f5ca2d57f625b8601d1a94a2000f846948c4d90829ce8f72d0163c1d5cf348a862d5506309485c42a7b34309bee2ed6a235f86d16f059deec5894cc2cedc53f0fa6d376336efb67e43d167169f3b78601d1a94a2000f8469435e7a025f4da968de7e4d7e4004197917f4070f194b1182abaeeb3b4d8eba7e6a4162eac7ace23d57394c4fd0d870da52e73de2dd8ded19fe3d26f43a1138601d1a94a2000f84694d6caa02bbebaebb5d7e581e4b66559e635f805ff94c07335cf083c1c46a487f0325769d88e163b653694efaff03b42e41f953a925fc43720e45fb61a19938601d1a94a2000";

  uint32 public constant ERROR_UNKNOWN_PACKAGE_TYPE = 101;
  uint32 public constant ERROR_FAIL_CHECK_VALIDATORS = 102;
  uint32 public constant ERROR_LEN_OF_VAL_MISMATCH = 103;
  uint32 public constant ERROR_RELAYFEE_TOO_LARGE = 104;

  uint256 public constant INIT_NUM_OF_CABINETS = 21;
  uint256 public constant EPOCH = 200;

  /*********************** state of the contract **************************/
  Validator[] public currentValidatorSet;
  uint256 public expireTimeSecondGap;
  uint256 public totalInComing;

  // key is the `consensusAddress` of `Validator`,
  // value is the index of the element in `currentValidatorSet`.
  mapping(address =>uint256) public currentValidatorSetMap;
  uint256 public numOfJailed;

  uint256 public constant BURN_RATIO_SCALE = 10000;
  address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
  uint256 public constant INIT_BURN_RATIO = 1000;
  uint256 public burnRatio;
  bool public burnRatioInitialized;

  // BEP-127 Temporary Maintenance
  uint256 public constant INIT_MAX_NUM_OF_MAINTAINING = 3;
  uint256 public constant INIT_MAINTAIN_SLASH_SCALE = 2;

  uint256 public maxNumOfMaintaining;
  uint256 public numOfMaintaining;
  uint256 public maintainSlashScale;

  // Corresponds strictly to currentValidatorSet
  // validatorExtraSet[index] = the `ValidatorExtra` info of currentValidatorSet[index]
  ValidatorExtra[] public validatorExtraSet;
  // BEP-131 candidate validator
  uint256 public numOfCabinets;
  uint256 public maxNumOfCandidates;
  uint256 public maxNumOfWorkingCandidates;

  struct Validator{
    address consensusAddress;
    address payable feeAddress;
    address BBCFeeAddress;
    uint64  votingPower;

    // only in state
    bool jailed;
    uint256 incoming;
  }

  struct ValidatorExtra {
    // BEP-127 Temporary Maintenance
    uint256 enterMaintenanceHeight;     // the height from where the validator enters Maintenance
    bool isMaintaining;

    // reserve for future use
    uint256[20] slots;
  }

  /*********************** cross chain package **************************/
  struct IbcValidatorSetPackage {
    uint8  packageType;
    Validator[] validatorSet;
  }

  /*********************** modifiers **************************/
  modifier noEmptyDeposit() {
    require(msg.value > 0, "deposit value is zero");
    _;
  }

  modifier initValidatorExtraSet() {
    if (validatorExtraSet.length == 0) {
      ValidatorExtra memory validatorExtra;
      // init validatorExtraSet
      uint256 validatorsNum = currentValidatorSet.length;
      for (uint i; i < validatorsNum; ++i) {
        validatorExtraSet.push(validatorExtra);
      }
    }

    _;
  }

  /*********************** events **************************/
  event validatorSetUpdated();
  event validatorJailed(address indexed validator);
  event validatorEmptyJailed(address indexed validator);
  event batchTransfer(uint256 amount);
  event batchTransferFailed(uint256 indexed amount, string reason);
  event batchTransferLowerFailed(uint256 indexed amount, bytes reason);
  event systemTransfer(uint256 amount);
  event directTransfer(address payable indexed validator, uint256 amount);
  event directTransferFail(address payable indexed validator, uint256 amount);
  event deprecatedDeposit(address indexed validator, uint256 amount);
  event validatorDeposit(address indexed validator, uint256 amount);
  event validatorMisdemeanor(address indexed validator, uint256 amount);
  event validatorFelony(address indexed validator, uint256 amount);
  event failReasonWithStr(string message);
  event unexpectedPackage(uint8 channelId, bytes msgBytes);
  event paramChange(string key, bytes value);
  event feeBurned(uint256 amount);
  event validatorEnterMaintenance(address indexed validator);
  event validatorExitMaintenance(address indexed validator);

  /*********************** init **************************/
  function init() external onlyNotInit{
    (IbcValidatorSetPackage memory validatorSetPkg, bool valid)= decodeValidatorSetSynPackage(INIT_VALIDATORSET_BYTES);
    require(valid, "failed to parse init validatorSet");
    for (uint i;i<validatorSetPkg.validatorSet.length;++i) {
      currentValidatorSet.push(validatorSetPkg.validatorSet[i]);
      currentValidatorSetMap[validatorSetPkg.validatorSet[i].consensusAddress] = i+1;
    }
    expireTimeSecondGap = EXPIRE_TIME_SECOND_GAP;
    alreadyInit = true;
  }

  /*********************** Cross Chain App Implement **************************/
  function handleSynPackage(uint8, bytes calldata msgBytes) onlyInit onlyCrossChainContract initValidatorExtraSet external override returns(bytes memory responsePayload) {
    (IbcValidatorSetPackage memory validatorSetPackage, bool ok) = decodeValidatorSetSynPackage(msgBytes);
    if (!ok) {
      return CmnPkg.encodeCommonAckPackage(ERROR_FAIL_DECODE);
    }
    uint32 resCode;
    if (validatorSetPackage.packageType == VALIDATORS_UPDATE_MESSAGE_TYPE) {
      resCode = updateValidatorSet(validatorSetPackage.validatorSet);
    } else if (validatorSetPackage.packageType == JAIL_MESSAGE_TYPE) {
      if (validatorSetPackage.validatorSet.length != 1) {
        emit failReasonWithStr("length of jail validators must be one");
        resCode = ERROR_LEN_OF_VAL_MISMATCH;
      } else {
        resCode = jailValidator(validatorSetPackage.validatorSet[0]);
      }
    } else {
      resCode = ERROR_UNKNOWN_PACKAGE_TYPE;
    }
    if (resCode == CODE_OK) {
      return new bytes(0);
    } else {
      return CmnPkg.encodeCommonAckPackage(resCode);
    }
  }

  function handleAckPackage(uint8 channelId, bytes calldata msgBytes) external onlyCrossChainContract override {
    // should not happen
    emit unexpectedPackage(channelId, msgBytes);
  }

  function handleFailAckPackage(uint8 channelId, bytes calldata msgBytes) external onlyCrossChainContract override {
    // should not happen
    emit unexpectedPackage(channelId, msgBytes);
  }

  /*********************** External Functions **************************/
  function deposit(address valAddr) external payable onlyCoinbase onlyInit noEmptyDeposit{
    uint256 value = msg.value;
    uint256 index = currentValidatorSetMap[valAddr];

    uint256 curBurnRatio = INIT_BURN_RATIO;
    if (burnRatioInitialized) {
      curBurnRatio = burnRatio;
    }

    if (value > 0 && curBurnRatio > 0) {
      uint256 toBurn = value.mul(curBurnRatio).div(BURN_RATIO_SCALE);
      if (toBurn > 0) {
        address(uint160(BURN_ADDRESS)).transfer(toBurn);
        emit feeBurned(toBurn);

        value = value.sub(toBurn);
      }
    }

    if (index>0) {
      Validator storage validator = currentValidatorSet[index-1];
      if (validator.jailed) {
        emit deprecatedDeposit(valAddr,value);
      } else {
        totalInComing = totalInComing.add(value);
        validator.incoming = validator.incoming.add(value);
        emit validatorDeposit(valAddr,value);
      }
    } else {
      // get incoming from deprecated validator;
      emit deprecatedDeposit(valAddr,value);
    }
  }

  function jailValidator(Validator memory v) internal returns (uint32) {
    uint256 index = currentValidatorSetMap[v.consensusAddress];
    if (index==0 || currentValidatorSet[index-1].jailed) {
      emit validatorEmptyJailed(v.consensusAddress);
      return CODE_OK;
    }
    uint n = currentValidatorSet.length;
    bool shouldKeep = (numOfJailed >= n-1);
    // will not jail if it is the last valid validator
    if (shouldKeep) {
      emit validatorEmptyJailed(v.consensusAddress);
      return CODE_OK;
    }
    numOfJailed ++;
    currentValidatorSet[index-1].jailed = true;
    emit validatorJailed(v.consensusAddress);
    return CODE_OK;
  }

  function updateValidatorSet(Validator[] memory validatorSet) internal returns (uint32) {
    {
      // do verify.
      (bool valid, string memory errMsg) = checkValidatorSet(validatorSet);
      if (!valid) {
        emit failReasonWithStr(errMsg);
        return ERROR_FAIL_CHECK_VALIDATORS;
      }
    }

    // step 0: force all maintaining validators to exit `Temporary Maintenance`
    // - 1. validators exit maintenance
    // - 2. clear all maintainInfo
    // - 3. get unjailed validators from validatorSet
    Validator[] memory validatorSetTemp = _forceMaintainingValidatorsExit(validatorSet);

    //step 1: do calculate distribution, do not make it as an internal function for saving gas.
    uint crossSize;
    uint directSize;
    uint validatorsNum = currentValidatorSet.length;
    for (uint i; i < validatorsNum; ++i) {
      if (currentValidatorSet[i].incoming >= DUSTY_INCOMING) {
        crossSize ++;
      } else if (currentValidatorSet[i].incoming > 0) {
        directSize ++;
      }
    }

    //cross transfer
    address[] memory crossAddrs = new address[](crossSize);
    uint256[] memory crossAmounts = new uint256[](crossSize);
    uint256[] memory crossIndexes = new uint256[](crossSize);
    address[] memory crossRefundAddrs = new address[](crossSize);
    uint256 crossTotal;
    // direct transfer
    address payable[] memory directAddrs = new address payable[](directSize);
    uint256[] memory directAmounts = new uint256[](directSize);
    crossSize = 0;
    directSize = 0;
    uint256 relayFee = ITokenHub(TOKEN_HUB_ADDR).getMiniRelayFee();
    if (relayFee > DUSTY_INCOMING) {
      emit failReasonWithStr("fee is larger than DUSTY_INCOMING");
      return ERROR_RELAYFEE_TOO_LARGE;
    }
    for (uint i; i < validatorsNum; ++i) {
      if (currentValidatorSet[i].incoming >= DUSTY_INCOMING) {
        crossAddrs[crossSize] = currentValidatorSet[i].BBCFeeAddress;
        uint256 value = currentValidatorSet[i].incoming - currentValidatorSet[i].incoming % PRECISION;
        crossAmounts[crossSize] = value.sub(relayFee);
        crossRefundAddrs[crossSize] = currentValidatorSet[i].BBCFeeAddress;
        crossIndexes[crossSize] = i;
        crossTotal = crossTotal.add(value);
        crossSize ++;
      } else if (currentValidatorSet[i].incoming > 0) {
        directAddrs[directSize] = currentValidatorSet[i].feeAddress;
        directAmounts[directSize] = currentValidatorSet[i].incoming;
        directSize ++;
      }
    }

    //step 2: do cross chain transfer
    bool failCross = false;
    if (crossTotal > 0) {
      try ITokenHub(TOKEN_HUB_ADDR).batchTransferOutBNB{value:crossTotal}(crossAddrs, crossAmounts, crossRefundAddrs, uint64(block.timestamp + expireTimeSecondGap)) returns (bool success) {
        if (success) {
           emit batchTransfer(crossTotal);
        } else {
           emit batchTransferFailed(crossTotal, "batch transfer return false");
        }
      }catch Error(string memory reason) {
        failCross = true;
        emit batchTransferFailed(crossTotal, reason);
      }catch (bytes memory lowLevelData) {
        failCross = true;
        emit batchTransferLowerFailed(crossTotal, lowLevelData);
      }
    }

    if (failCross) {
      for (uint i; i< crossIndexes.length;++i) {
        uint idx = crossIndexes[i];
        bool success = currentValidatorSet[idx].feeAddress.send(currentValidatorSet[idx].incoming);
        if (success) {
          emit directTransfer(currentValidatorSet[idx].feeAddress, currentValidatorSet[idx].incoming);
        } else {
          emit directTransferFail(currentValidatorSet[idx].feeAddress, currentValidatorSet[idx].incoming);
        }
      }
    }

    // step 3: direct transfer
    if (directAddrs.length>0) {
      for (uint i;i<directAddrs.length;++i) {
        bool success = directAddrs[i].send(directAmounts[i]);
        if (success) {
          emit directTransfer(directAddrs[i], directAmounts[i]);
        } else {
          emit directTransferFail(directAddrs[i], directAmounts[i]);
        }
      }
    }

    // step 4: do dusk transfer
    if (address(this).balance>0) {
      emit systemTransfer(address(this).balance);
      address(uint160(SYSTEM_REWARD_ADDR)).transfer(address(this).balance);
    }
    // step 5: do update validator set state
    totalInComing = 0;
    numOfJailed = 0;
    if (validatorSetTemp.length>0) {
      doUpdateState(validatorSetTemp);
    }

    // step 6: clean slash contract
    ISlashIndicator(SLASH_CONTRACT_ADDR).clean();
    emit validatorSetUpdated();
    return CODE_OK;
  }

  function shuffle(address[] memory validators, uint256 epochNumber, uint startIdx, uint offset, uint limit, uint modNumber) internal pure {
    for (uint i; i<limit; ++i) {
      uint random = uint(keccak256(abi.encodePacked(epochNumber, startIdx+i))) % modNumber;
      if ( (startIdx+i) != (offset+random) ) {
        address tmp = validators[startIdx+i];
        validators[startIdx+i] = validators[offset+random];
        validators[offset+random] = tmp;
      }
    }
  }

  function getMiningValidators() public view returns(address[] memory) {
    uint256 _maxNumOfWorkingCandidates = maxNumOfWorkingCandidates;
    uint256 _numOfCabinets = numOfCabinets;
    if (_numOfCabinets == 0 ){
      _numOfCabinets = INIT_NUM_OF_CABINETS;
    }

    address[] memory validators = getValidators();
    if (validators.length <= _numOfCabinets) {
      return validators;
    }

    if ((validators.length - _numOfCabinets) < _maxNumOfWorkingCandidates){
      _maxNumOfWorkingCandidates = validators.length - _numOfCabinets;
    }
    if (_maxNumOfWorkingCandidates > 0) {
      uint256 epochNumber = block.number / EPOCH;
      shuffle(validators, epochNumber, _numOfCabinets-_maxNumOfWorkingCandidates, 0, _maxNumOfWorkingCandidates, _numOfCabinets);
      shuffle(validators, epochNumber, _numOfCabinets-_maxNumOfWorkingCandidates, _numOfCabinets-_maxNumOfWorkingCandidates,
      _maxNumOfWorkingCandidates, validators.length-_numOfCabinets+_maxNumOfWorkingCandidates);
    }
    address[] memory miningValidators = new address[](_numOfCabinets);
    for (uint i; i<_numOfCabinets; ++i) {
      miningValidators[i] = validators[i];
    }
    return miningValidators;
  }

  function getValidators() public view returns(address[] memory) {
    uint n = currentValidatorSet.length;
    uint valid = 0;
    for (uint i; i<n; ++i) {
      if (isWorkingValidator(i)) {
        valid ++;
      }
    }
    address[] memory consensusAddrs = new address[](valid);
    valid = 0;
    for (uint i; i<n; ++i) {
      if (isWorkingValidator(i)) {
        consensusAddrs[valid] = currentValidatorSet[i].consensusAddress;
        valid ++;
      }
    }
    return consensusAddrs;
  }

  function isWorkingValidator(uint index) public view returns (bool) {
    if (index >= currentValidatorSet.length) {
      return false;
    }

    // validatorExtraSet[index] should not be used before it has been init.
    if (index >= validatorExtraSet.length) {
      return !currentValidatorSet[index].jailed;
    }

    return !currentValidatorSet[index].jailed && !validatorExtraSet[index].isMaintaining;
  }

  function getIncoming(address validator)external view returns(uint256) {
    uint256 index = currentValidatorSetMap[validator];
    if (index<=0) {
      return 0;
    }
    return currentValidatorSet[index-1].incoming;
  }

  function isCurrentValidator(address validator) external view override returns (bool) {
    uint256 index = currentValidatorSetMap[validator];
    if (index <= 0) {
      return false;
    }

    // the actual index
    index = index - 1;
    return isWorkingValidator(index);
  }

  function getWorkingValidatorCount() public view returns(uint256 workingValidatorCount) {
    workingValidatorCount = getValidators().length;
    uint256 _numOfCabinets = numOfCabinets > 0 ? numOfCabinets : INIT_NUM_OF_CABINETS;
    if (workingValidatorCount > _numOfCabinets) {
      workingValidatorCount = _numOfCabinets;
    }
    if (workingValidatorCount == 0) {
      workingValidatorCount = 1;
    }
  }
  /*********************** For slash **************************/
  function misdemeanor(address validator) external onlySlash initValidatorExtraSet override {
    uint256 validatorIndex = _misdemeanor(validator);
    if (canEnterMaintenance(validatorIndex)) {
      _enterMaintenance(validator, validatorIndex);
    }
  }

  function felony(address validator)external onlySlash initValidatorExtraSet override{
    uint256 index = currentValidatorSetMap[validator];
    if (index <= 0) {
      return;
    }
    // the actual index
    index = index - 1;

    bool isMaintaining = validatorExtraSet[index].isMaintaining;
    if (_felony(validator, index) && isMaintaining) {
      numOfMaintaining--;
    }
  }

  /*********************** For Temporary Maintenance **************************/
  function getCurrentValidatorIndex(address _validator) public view returns (uint256) {
    uint256 index = currentValidatorSetMap[_validator];
    require(index > 0, "only current validators");

    // the actual index
    return index - 1;
  }

  function canEnterMaintenance(uint256 index) public view returns (bool) {
    if (index >= currentValidatorSet.length) {
      return false;
    }

    if (
      currentValidatorSet[index].consensusAddress == address(0)     // - 0. check if empty validator
      || (maxNumOfMaintaining == 0 || maintainSlashScale == 0)      // - 1. check if not start
      || numOfMaintaining >= maxNumOfMaintaining                    // - 2. check if reached upper limit
      || !isWorkingValidator(index)                                 // - 3. check if not working(not jailed and not maintaining)
      || validatorExtraSet[index].enterMaintenanceHeight > 0        // - 5. check if has Maintained during current 24-hour period
                                                                    // current validators are selected every 24 hours(from 00:00:00 UTC to 23:59:59 UTC)
                                                                    // for more details, refer to https://github.com/bnb-chain/docs-site/blob/master/docs/smart-chain/validator/Binance%20Smart%20Chain%20Validator%20FAQs%20-%20Updated.md
      || getValidators().length <= 1                                // - 6. check num of remaining working validators
    ) {
      return false;
    }

    return true;
  }

  function enterMaintenance() external initValidatorExtraSet {
    // check maintain config
    if (maxNumOfMaintaining == 0) {
      maxNumOfMaintaining = INIT_MAX_NUM_OF_MAINTAINING;
    }
    if (maintainSlashScale == 0) {
      maintainSlashScale = INIT_MAINTAIN_SLASH_SCALE;
    }

    uint256 index = getCurrentValidatorIndex(msg.sender);
    require(canEnterMaintenance(index), "can not enter Temporary Maintenance");
    _enterMaintenance(msg.sender, index);
  }

  function exitMaintenance() external {
    uint256 index = getCurrentValidatorIndex(msg.sender);

    // jailed validators are allowed to exit maintenance
    require(validatorExtraSet[index].isMaintaining, "not in maintenance");
    uint256 workingValidatorCount = getWorkingValidatorCount();
    _exitMaintenance(msg.sender, index, workingValidatorCount);
  }

  /*********************** Param update ********************************/
  function updateParam(string calldata key, bytes calldata value) override external onlyInit onlyGov{
    if (Memory.compareStrings(key, "expireTimeSecondGap")) {
      require(value.length == 32, "length of expireTimeSecondGap mismatch");
      uint256 newExpireTimeSecondGap = BytesToTypes.bytesToUint256(32, value);
      require(newExpireTimeSecondGap >=100 && newExpireTimeSecondGap <= 1e5, "the expireTimeSecondGap is out of range");
      expireTimeSecondGap = newExpireTimeSecondGap;
    } else if (Memory.compareStrings(key, "burnRatio")) {
      require(value.length == 32, "length of burnRatio mismatch");
      uint256 newBurnRatio = BytesToTypes.bytesToUint256(32, value);
      require(newBurnRatio <= BURN_RATIO_SCALE, "the burnRatio must be no greater than 10000");
      burnRatio = newBurnRatio;
      burnRatioInitialized = true;
    } else if (Memory.compareStrings(key, "maxNumOfMaintaining")) {
      require(value.length == 32, "length of maxNumOfMaintaining mismatch");
      uint256 newMaxNumOfMaintaining = BytesToTypes.bytesToUint256(32, value);
      uint256 _numOfCabinets = numOfCabinets;
      if (_numOfCabinets == 0) {
        _numOfCabinets = INIT_NUM_OF_CABINETS;
      }
      require(newMaxNumOfMaintaining < _numOfCabinets, "the maxNumOfMaintaining must be less than numOfCaninates");
      maxNumOfMaintaining = newMaxNumOfMaintaining;
    } else if (Memory.compareStrings(key, "maintainSlashScale")) {
      require(value.length == 32, "length of maintainSlashScale mismatch");
      uint256 newMaintainSlashScale = BytesToTypes.bytesToUint256(32, value);
      require(newMaintainSlashScale > 0, "the maintainSlashScale must be greater than 0");
      maintainSlashScale = newMaintainSlashScale;
    } else if (Memory.compareStrings(key, "maxNumOfWorkingCandidates")) {
      require(value.length == 32, "length of maxNumOfWorkingCandidates mismatch");
      uint256 newMaxNumOfWorkingCandidates = BytesToTypes.bytesToUint256(32, value);
      require(newMaxNumOfWorkingCandidates <= maxNumOfCandidates, "the maxNumOfWorkingCandidates must be not greater than maxNumOfCandidates");
      maxNumOfWorkingCandidates = newMaxNumOfWorkingCandidates;
    } else if (Memory.compareStrings(key, "maxNumOfCandidates")) {
      require(value.length == 32, "length of maxNumOfCandidates mismatch");
      uint256 newMaxNumOfCandidates = BytesToTypes.bytesToUint256(32, value);
      maxNumOfCandidates = newMaxNumOfCandidates;
      if (maxNumOfWorkingCandidates > maxNumOfCandidates) {
        maxNumOfWorkingCandidates = maxNumOfCandidates;
      }
    } else if (Memory.compareStrings(key, "numOfCabinets")) {
      require(value.length == 32, "length of numOfCabinets mismatch");
      uint256 newNumOfCabinets = BytesToTypes.bytesToUint256(32, value);
      require(newNumOfCabinets > 0, "the numOfCabinets must be greater than 0");
      require(newNumOfCabinets <= MAX_NUM_OF_VALIDATORS, "the numOfCabinets must be less than MAX_NUM_OF_VALIDATORS");
      numOfCabinets = newNumOfCabinets;
    } else {
      require(false, "unknown param");
    }
    emit paramChange(key, value);
  }

  /*********************** Internal Functions **************************/

  function checkValidatorSet(Validator[] memory validatorSet) private pure returns(bool, string memory) {
    if (validatorSet.length > MAX_NUM_OF_VALIDATORS){
      return (false, "the number of validators exceed the limit");
    }
    for (uint i; i < validatorSet.length; ++i) {
      for (uint j = 0; j<i; j++) {
        if (validatorSet[i].consensusAddress == validatorSet[j].consensusAddress) {
          return (false, "duplicate consensus address of validatorSet");
        }
      }
    }
    return (true,"");
  }

  function doUpdateState(Validator[] memory validatorSet) private{
    uint n = currentValidatorSet.length;
    uint m = validatorSet.length;

    for (uint i; i<n; ++i) {
      bool stale = true;
      Validator memory oldValidator = currentValidatorSet[i];
      for (uint j = 0;j<m;j++) {
        if (oldValidator.consensusAddress == validatorSet[j].consensusAddress) {
          stale = false;
          break;
        }
      }
      if (stale) {
        delete currentValidatorSetMap[oldValidator.consensusAddress];
      }
    }

    if (n>m) {
      for (uint i = m; i < n; ++i) {
        currentValidatorSet.pop();
        validatorExtraSet.pop();
      }
    }
    uint k = n < m ? n:m;
    for (uint i; i < k; ++i) {
      if (!isSameValidator(validatorSet[i], currentValidatorSet[i])) {
        currentValidatorSetMap[validatorSet[i].consensusAddress] = i+1;
        currentValidatorSet[i] = validatorSet[i];
      } else {
        currentValidatorSet[i].incoming = 0;
      }
    }
    if (m>n) {
      ValidatorExtra memory validatorExtra;
      for (uint i = n; i < m; ++i) {
        currentValidatorSet.push(validatorSet[i]);
        validatorExtraSet.push(validatorExtra);
        currentValidatorSetMap[validatorSet[i].consensusAddress] = i+1;
      }
    }

    // make sure all new validators are cleared maintainInfo
    // should not happen, still protect
    numOfMaintaining = 0;
    n = currentValidatorSet.length;
    for (uint i; i < n; ++i) {
      validatorExtraSet[i].isMaintaining = false;
      validatorExtraSet[i].enterMaintenanceHeight = 0;
    }
  }

  function isSameValidator(Validator memory v1, Validator memory v2) private pure returns(bool) {
    return v1.consensusAddress == v2.consensusAddress && v1.feeAddress == v2.feeAddress && v1.BBCFeeAddress == v2.BBCFeeAddress && v1.votingPower == v2.votingPower;
  }

  function _misdemeanor(address validator) private returns (uint256) {
    uint256 index = currentValidatorSetMap[validator];
    if (index <= 0) {
      return ~uint256(0);
    }
    // the actually index
    index = index - 1;

    uint256 income = currentValidatorSet[index].incoming;
    currentValidatorSet[index].incoming = 0;
    uint256 rest = currentValidatorSet.length - 1;
    emit validatorMisdemeanor(validator, income);
    if (rest == 0) {
      // should not happen, but still protect
      return index;
    }
    uint256 averageDistribute = income / rest;
    if (averageDistribute != 0) {
      for (uint i; i < index; ++i) {
        currentValidatorSet[i].incoming = currentValidatorSet[i].incoming + averageDistribute;
      }
      uint n = currentValidatorSet.length;
      for (uint i = index + 1; i < n; ++i) {
        currentValidatorSet[i].incoming = currentValidatorSet[i].incoming + averageDistribute;
      }
    }
    // averageDistribute*rest may less than income, but it is ok, the dust income will go to system reward eventually.

    return index;
  }

  function _felony(address validator, uint256 index) private returns (bool){
    uint256 income = currentValidatorSet[index].incoming;
    uint256 rest = currentValidatorSet.length - 1;
    if (getValidators().length <= 1) {
      // will not remove the validator if it is the only one validator.
      currentValidatorSet[index].incoming = 0;
      return false;
    }
    emit validatorFelony(validator, income);

    // remove the validator from currentValidatorSet
    delete currentValidatorSetMap[validator];
    // remove felony validator
    for (uint i = index;i < (currentValidatorSet.length-1);++i) {
      currentValidatorSet[i] = currentValidatorSet[i+1];
      validatorExtraSet[i] = validatorExtraSet[i+1];
      currentValidatorSetMap[currentValidatorSet[i].consensusAddress] = i+1;
    }
    currentValidatorSet.pop();
    validatorExtraSet.pop();

    uint256 averageDistribute = income / rest;
    if (averageDistribute != 0) {
      uint n = currentValidatorSet.length;
      for (uint i; i < n; ++i) {
        currentValidatorSet[i].incoming = currentValidatorSet[i].incoming + averageDistribute;
      }
    }
    // averageDistribute*rest may less than income, but it is ok, the dust income will go to system reward eventually.
    return true;
  }

  function _forceMaintainingValidatorsExit(Validator[] memory _validatorSet) private returns (Validator[] memory unjailedValidatorSet){
    uint256 numOfFelony = 0;
    address validator;
    bool isFelony;

    // 1. validators exit maintenance
    uint256 i;
    // caution: it must calculate workingValidatorCount before _exitMaintenance loop
    // because the workingValidatorCount will be changed in _exitMaintenance
    uint256 workingValidatorCount = getWorkingValidatorCount();
    // caution: it must loop from the endIndex to startIndex in currentValidatorSet
    // because the validators order in currentValidatorSet may be changed by _felony(validator)
    for (uint index = currentValidatorSet.length; index > 0; --index) {
      i = index - 1;  // the actual index
      if (!validatorExtraSet[i].isMaintaining) {
        continue;
      }

      // only maintaining validators
      validator = currentValidatorSet[i].consensusAddress;

      // exit maintenance
      isFelony = _exitMaintenance(validator, i, workingValidatorCount);
      if (!isFelony || numOfFelony >= _validatorSet.length - 1) {
        continue;
      }

      // record the jailed validator in validatorSet
      for (uint k; k < _validatorSet.length; ++k) {
        if (_validatorSet[k].consensusAddress == validator) {
          _validatorSet[k].jailed = true;
          numOfFelony++;
          break;
        }
      }
    }

    // 2. get unjailed validators from validatorSet
    unjailedValidatorSet = new Validator[](_validatorSet.length - numOfFelony);
    i = 0;
    for (uint index; index < _validatorSet.length; ++index) {
      if (!_validatorSet[index].jailed) {
        unjailedValidatorSet[i] = _validatorSet[index];
        i++;
      }
    }

    return unjailedValidatorSet;
  }

  function _enterMaintenance(address validator, uint256 index) private {
    numOfMaintaining++;
    validatorExtraSet[index].isMaintaining = true;
    validatorExtraSet[index].enterMaintenanceHeight = block.number;
    emit validatorEnterMaintenance(validator);
  }

  function _exitMaintenance(address validator, uint index, uint256 workingValidatorCount) private returns (bool isFelony){
    if (maintainSlashScale == 0 || workingValidatorCount == 0 || numOfMaintaining == 0) {
      // should not happen, still protect
      return false;
    }

    // step 0: modify numOfMaintaining
    numOfMaintaining--;

    // step 1: calculate slashCount
    uint256 slashCount =
      block.number
        .sub(validatorExtraSet[index].enterMaintenanceHeight)
        .div(workingValidatorCount)
        .div(maintainSlashScale);

    // step 2: clear maintaining info of the validator
    validatorExtraSet[index].isMaintaining = false;

    // step3: slash the validator
    (uint256 misdemeanorThreshold, uint256 felonyThreshold) = ISlashIndicator(SLASH_CONTRACT_ADDR).getSlashThresholds();
    isFelony = false;
    if (slashCount >= felonyThreshold) {
      _felony(validator, index);
      ISlashIndicator(SLASH_CONTRACT_ADDR).sendFelonyPackage(validator);
      isFelony = true;
    } else if (slashCount >= misdemeanorThreshold) {
      _misdemeanor(validator);
    }

    emit validatorExitMaintenance(validator);
  }

  //rlp encode & decode function
  function decodeValidatorSetSynPackage(bytes memory msgBytes) internal pure returns (IbcValidatorSetPackage memory, bool) {
    IbcValidatorSetPackage memory validatorSetPkg;

    RLPDecode.Iterator memory iter = msgBytes.toRLPItem().iterator();
    bool success = false;
    uint256 idx=0;
    while (iter.hasNext()) {
      if (idx == 0) {
        validatorSetPkg.packageType = uint8(iter.next().toUint());
      } else if (idx == 1) {
        RLPDecode.RLPItem[] memory items = iter.next().toList();
        validatorSetPkg.validatorSet =new Validator[](items.length);
        for (uint j;j<items.length;++j) {
          (Validator memory val, bool ok) = decodeValidator(items[j]);
          if (!ok) {
            return (validatorSetPkg, false);
          }
          validatorSetPkg.validatorSet[j] = val;
        }
        success = true;
      } else {
        break;
      }
      idx++;
    }
    return (validatorSetPkg, success);
  }

  function decodeValidator(RLPDecode.RLPItem memory itemValidator) internal pure returns(Validator memory, bool) {
    Validator memory validator;
    RLPDecode.Iterator memory iter = itemValidator.iterator();
    bool success = false;
    uint256 idx=0;
    while (iter.hasNext()) {
      if (idx == 0) {
        validator.consensusAddress = iter.next().toAddress();
      } else if (idx == 1) {
        validator.feeAddress = address(uint160(iter.next().toAddress()));
      } else if (idx == 2) {
        validator.BBCFeeAddress = iter.next().toAddress();
      } else if (idx == 3) {
        validator.votingPower = uint64(iter.next().toUint());
        success = true;
      } else {
        break;
      }
      idx++;
    }
    return (validator, success);
  }

    
}