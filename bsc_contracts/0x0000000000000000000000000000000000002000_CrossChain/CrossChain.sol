/**
 *Submitted for verification at BscScan.com on 2020-09-02
*/

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

// File: contracts/interface/ILightClient.sol

pragma solidity 0.6.4;

interface ILightClient {

  function isHeaderSynced(uint64 height) external view returns (bool);

  function getAppHash(uint64 height) external view returns (bytes32);

  function getSubmitter(uint64 height) external view returns (address payable);

}

// File: contracts/interface/IRelayerIncentivize.sol

pragma solidity 0.6.4;

interface IRelayerIncentivize {

    function addReward(address payable headerRelayerAddr, address payable packageRelayer, uint256 amount, bool fromSystemReward) external returns (bool);

}

// File: contracts/interface/IRelayerHub.sol

pragma solidity 0.6.4;

interface IRelayerHub {
  function isRelayer(address sender) external view returns (bool);
}

// File: contracts/lib/Memory.sol

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

// File: contracts/lib/BytesToTypes.sol

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

// File: contracts/interface/IParamSubscriber.sol

pragma solidity 0.6.4;

interface IParamSubscriber {
    function updateParam(string calldata key, bytes calldata value) external;
}

// File: contracts/interface/ISystemReward.sol

pragma solidity 0.6.4;

interface ISystemReward {
  function claimRewards(address payable to, uint256 amount) external returns(uint256 actualAmount);
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

// File: contracts/MerkleProof.sol

pragma solidity 0.6.4;


library MerkleProof {
  function validateMerkleProof(bytes32 appHash, string memory storeName, bytes memory key, bytes memory value, bytes memory proof)
  internal view returns (bool) {
    if (appHash == bytes32(0)) {
      return false;
    }

    // | storeName | key length | key | value length | value | appHash  | proof |
    // | 32 bytes  | 32 bytes   |   | 32 bytes   |     | 32 bytes |
    bytes memory input = new bytes(128+key.length+value.length+proof.length);

    uint256 ptr = Memory.dataPtr(input);

    bytes memory storeNameBytes = bytes(storeName);
    /* solium-disable-next-line */
    assembly {
      mstore(ptr, mload(add(storeNameBytes, 32)))
    }

    uint256 src;
    uint256 length;

    // write key length and key to input
    ptr += 32;
    (src, length) = Memory.fromBytes(key);
    /* solium-disable-next-line */
    assembly {
      mstore(ptr, length)
    }
    ptr += 32;
    Memory.copy(src, ptr, length);

    // write value length and value to input
    ptr += length;
    (src, length) = Memory.fromBytes(value);
    /* solium-disable-next-line */
    assembly {
      mstore(ptr, length)
    }
    ptr += 32;
    Memory.copy(src, ptr, length);

    // write appHash to input
    ptr += length;
    /* solium-disable-next-line */
    assembly {
      mstore(ptr, appHash)
    }

    // write proof to input
    ptr += 32;
    (src,length) = Memory.fromBytes(proof);
    Memory.copy(src, ptr, length);

    length = input.length+32;

    uint256[1] memory result;
    /* solium-disable-next-line */
    assembly {
    // call validateMerkleProof precompile contract
    // Contract address: 0x65
      if iszero(staticcall(not(0), 0x65, input, length, result, 0x20)) {}
    }

    return result[0] == 0x01;
  }
}

// File: contracts/CrossChain.sol

pragma solidity 0.6.4;












contract CrossChain is System, ICrossChain, IParamSubscriber{

  // constant variables
  string constant public STORE_NAME = "ibc";
  uint256 constant public CROSS_CHAIN_KEY_PREFIX = 0x01003800; // last 6 bytes
  uint8 constant public SYN_PACKAGE = 0x00;
  uint8 constant public ACK_PACKAGE = 0x01;
  uint8 constant public FAIL_ACK_PACKAGE = 0x02;
  uint256 constant public INIT_BATCH_SIZE = 50;

  // governable parameters
  uint256 public batchSizeForOracle;

  //state variables
  uint256 public previousTxHeight;
  uint256 public txCounter;
  int64 public oracleSequence;
  mapping(uint8 => address) public channelHandlerContractMap;
  mapping(address => mapping(uint8 => bool))public registeredContractChannelMap;
  mapping(uint8 => uint64) public channelSendSequenceMap;
  mapping(uint8 => uint64) public channelReceiveSequenceMap;
  mapping(uint8 => bool) public isRelayRewardFromSystemReward;

  // event
  event crossChainPackage(uint16 chainId, uint64 indexed oracleSequence, uint64 indexed packageSequence, uint8 indexed channelId, bytes payload);
  event receivedPackage(uint8 packageType, uint64 indexed packageSequence, uint8 indexed channelId);
  event unsupportedPackage(uint64 indexed packageSequence, uint8 indexed channelId, bytes payload);
  event unexpectedRevertInPackageHandler(address indexed contractAddr, string reason);
  event unexpectedFailureAssertionInPackageHandler(address indexed contractAddr, bytes lowLevelData);
  event paramChange(string key, bytes value);
  event enableOrDisableChannel(uint8 indexed channelId, bool isEnable);
  event addChannel(uint8 indexed channelId, address indexed contractAddr);

  modifier sequenceInOrder(uint64 _sequence, uint8 _channelID) {
    uint64 expectedSequence = channelReceiveSequenceMap[_channelID];
    require(_sequence == expectedSequence, "sequence not in order");

    channelReceiveSequenceMap[_channelID]=expectedSequence+1;
    _;
  }

  modifier blockSynced(uint64 _height) {
    require(ILightClient(LIGHT_CLIENT_ADDR).isHeaderSynced(_height), "light client not sync the block yet");
    _;
  }

  modifier channelSupported(uint8 _channelID) {
    require(channelHandlerContractMap[_channelID]!=address(0x0), "channel is not supported");
    _;
  }

  modifier onlyRegisteredContractChannel(uint8 channleId) {
    require(registeredContractChannelMap[msg.sender][channleId], "the contract and channel have not been registered");
    _;
  }

  // | length   | prefix | sourceChainID| destinationChainID | channelID | sequence |
  // | 32 bytes | 1 byte | 2 bytes      | 2 bytes            |  1 bytes  | 8 bytes  |
  function generateKey(uint64 _sequence, uint8 _channelID) internal pure returns(bytes memory) {
    uint256 fullCROSS_CHAIN_KEY_PREFIX = CROSS_CHAIN_KEY_PREFIX | _channelID;
    bytes memory key = new bytes(14);

    uint256 ptr;
    assembly {
      ptr := add(key, 14)
    }
    assembly {
      mstore(ptr, _sequence)
    }
    ptr -= 8;
    assembly {
      mstore(ptr, fullCROSS_CHAIN_KEY_PREFIX)
    }
    ptr -= 6;
    assembly {
      mstore(ptr, 14)
    }
    return key;
  }

  function init() external onlyNotInit {
    channelHandlerContractMap[BIND_CHANNELID] = TOKEN_MANAGER_ADDR;
    isRelayRewardFromSystemReward[BIND_CHANNELID] = false;
    registeredContractChannelMap[TOKEN_MANAGER_ADDR][BIND_CHANNELID] = true;

    channelHandlerContractMap[TRANSFER_IN_CHANNELID] = TOKEN_HUB_ADDR;
    isRelayRewardFromSystemReward[TRANSFER_IN_CHANNELID] = false;
    registeredContractChannelMap[TOKEN_HUB_ADDR][TRANSFER_IN_CHANNELID] = true;

    channelHandlerContractMap[TRANSFER_OUT_CHANNELID] = TOKEN_HUB_ADDR;
    isRelayRewardFromSystemReward[TRANSFER_OUT_CHANNELID] = false;
    registeredContractChannelMap[TOKEN_HUB_ADDR][TRANSFER_OUT_CHANNELID] = true;


    channelHandlerContractMap[STAKING_CHANNELID] = VALIDATOR_CONTRACT_ADDR;
    isRelayRewardFromSystemReward[STAKING_CHANNELID] = true;
    registeredContractChannelMap[VALIDATOR_CONTRACT_ADDR][STAKING_CHANNELID] = true;

    channelHandlerContractMap[GOV_CHANNELID] = GOV_HUB_ADDR;
    isRelayRewardFromSystemReward[GOV_CHANNELID] = true;
    registeredContractChannelMap[GOV_HUB_ADDR][GOV_CHANNELID] = true;

    channelHandlerContractMap[SLASH_CHANNELID] = SLASH_CONTRACT_ADDR;
    isRelayRewardFromSystemReward[SLASH_CHANNELID] = true;
    registeredContractChannelMap[SLASH_CONTRACT_ADDR][SLASH_CHANNELID] = true;

    batchSizeForOracle = INIT_BATCH_SIZE;

    oracleSequence = -1;
    previousTxHeight = 0;
    txCounter = 0;

    alreadyInit=true;
  }

function encodePayload(uint8 packageType, uint256 relayFee, bytes memory msgBytes) public pure returns(bytes memory) {
    uint256 payloadLength = msgBytes.length + 33;
    bytes memory payload = new bytes(payloadLength);
    uint256 ptr;
    assembly {
      ptr := payload
    }
    ptr+=33;

    assembly {
      mstore(ptr, relayFee)
    }

    ptr-=32;
    assembly {
      mstore(ptr, packageType)
    }

    ptr-=1;
    assembly {
      mstore(ptr, payloadLength)
    }

    ptr+=65;
    (uint256 src,) = Memory.fromBytes(msgBytes);
    Memory.copy(src, ptr, msgBytes.length);

    return payload;
  }

  // | type   | relayFee   |package  |
  // | 1 byte | 32 bytes   | bytes    |
  function decodePayloadHeader(bytes memory payload) internal pure returns(bool, uint8, uint256, bytes memory) {
    if (payload.length < 33) {
      return (false, 0, 0, new bytes(0));
    }

    uint256 ptr;
    assembly {
      ptr := payload
    }

    uint8 packageType;
    ptr+=1;
    assembly {
      packageType := mload(ptr)
    }

    uint256 relayFee;
    ptr+=32;
    assembly {
      relayFee := mload(ptr)
    }

    ptr+=32;
    bytes memory msgBytes = new bytes(payload.length-33);
    (uint256 dst, ) = Memory.fromBytes(msgBytes);
    Memory.copy(ptr, dst, payload.length-33);

    return (true, packageType, relayFee, msgBytes);
  }

  function handlePackage(bytes calldata payload, bytes calldata proof, uint64 height, uint64 packageSequence, uint8 channelId) onlyInit onlyRelayer
      sequenceInOrder(packageSequence, channelId) blockSynced(height) channelSupported(channelId) external {
    bytes memory payloadLocal = payload; // fix error: stack too deep, try removing local variables
    bytes memory proofLocal = proof; // fix error: stack too deep, try removing local variables
    require(MerkleProof.validateMerkleProof(ILightClient(LIGHT_CLIENT_ADDR).getAppHash(height), STORE_NAME, generateKey(packageSequence, channelId), payloadLocal, proofLocal), "invalid merkle proof");

    address payable headerRelayer = ILightClient(LIGHT_CLIENT_ADDR).getSubmitter(height);

    uint8 channelIdLocal = channelId; // fix error: stack too deep, try removing local variables
    (bool success, uint8 packageType, uint256 relayFee, bytes memory msgBytes) = decodePayloadHeader(payloadLocal);
    if (!success) {
      emit unsupportedPackage(packageSequence, channelIdLocal, payloadLocal);
      return;
    }
    emit receivedPackage(packageType, packageSequence, channelIdLocal);
    if (packageType == SYN_PACKAGE) {
      address handlerContract = channelHandlerContractMap[channelIdLocal];
      try IApplication(handlerContract).handleSynPackage(channelIdLocal, msgBytes) returns (bytes memory responsePayload) {
        if (responsePayload.length!=0) {
          sendPackage(channelSendSequenceMap[channelIdLocal], channelIdLocal, encodePayload(ACK_PACKAGE, 0, responsePayload));
          channelSendSequenceMap[channelIdLocal] = channelSendSequenceMap[channelIdLocal] + 1;
        }
      } catch Error(string memory reason) {
        sendPackage(channelSendSequenceMap[channelIdLocal], channelIdLocal, encodePayload(FAIL_ACK_PACKAGE, 0, msgBytes));
        channelSendSequenceMap[channelIdLocal] = channelSendSequenceMap[channelIdLocal] + 1;
        emit unexpectedRevertInPackageHandler(handlerContract, reason);
      } catch (bytes memory lowLevelData) {
        sendPackage(channelSendSequenceMap[channelIdLocal], channelIdLocal, encodePayload(FAIL_ACK_PACKAGE, 0, msgBytes));
        channelSendSequenceMap[channelIdLocal] = channelSendSequenceMap[channelIdLocal] + 1;
        emit unexpectedFailureAssertionInPackageHandler(handlerContract, lowLevelData);
      }
    } else if (packageType == ACK_PACKAGE) {
      address handlerContract = channelHandlerContractMap[channelIdLocal];
      try IApplication(handlerContract).handleAckPackage(channelIdLocal, msgBytes) {
      } catch Error(string memory reason) {
        emit unexpectedRevertInPackageHandler(handlerContract, reason);
      } catch (bytes memory lowLevelData) {
        emit unexpectedFailureAssertionInPackageHandler(handlerContract, lowLevelData);
      }
    } else if (packageType == FAIL_ACK_PACKAGE) {
      address handlerContract = channelHandlerContractMap[channelIdLocal];
      try IApplication(handlerContract).handleFailAckPackage(channelIdLocal, msgBytes) {
      } catch Error(string memory reason) {
        emit unexpectedRevertInPackageHandler(handlerContract, reason);
      } catch (bytes memory lowLevelData) {
        emit unexpectedFailureAssertionInPackageHandler(handlerContract, lowLevelData);
      }
    }
    IRelayerIncentivize(INCENTIVIZE_ADDR).addReward(headerRelayer, msg.sender, relayFee, isRelayRewardFromSystemReward[channelIdLocal] || packageType != SYN_PACKAGE);
  }

  function sendPackage(uint64 packageSequence, uint8 channelId, bytes memory payload) internal {
    if (block.number > previousTxHeight) {
      oracleSequence++;
      txCounter = 1;
      previousTxHeight=block.number;
    } else {
      txCounter++;
      if (txCounter>batchSizeForOracle) {
        oracleSequence++;
        txCounter = 1;
      }
    }
    emit crossChainPackage(bscChainID, uint64(oracleSequence), packageSequence, channelId, payload);
  }

  function sendSynPackage(uint8 channelId, bytes calldata msgBytes, uint256 relayFee) onlyInit onlyRegisteredContractChannel(channelId) external override {
    uint64 sendSequence = channelSendSequenceMap[channelId];
    sendPackage(sendSequence, channelId, encodePayload(SYN_PACKAGE, relayFee, msgBytes));
    sendSequence++;
    channelSendSequenceMap[channelId] = sendSequence;
  }

  function updateParam(string calldata key, bytes calldata value) onlyGov external override {
    if (Memory.compareStrings(key, "batchSizeForOracle")) {
      uint256 newBatchSizeForOracle = BytesToTypes.bytesToUint256(32, value);
      require(newBatchSizeForOracle <= 10000 && newBatchSizeForOracle >= 10, "the newBatchSizeForOracle should be in [10, 10000]");
      batchSizeForOracle = newBatchSizeForOracle;
    } else if (Memory.compareStrings(key, "addOrUpdateChannel")) {
      bytes memory valueLocal = value;
      require(valueLocal.length == 22, "length of value for addOrUpdateChannel should be 22, channelId:isFromSystem:handlerAddress");
      uint8 channelId;
      assembly {
        channelId := mload(add(valueLocal, 1))
      }

      uint8 rewardConfig;
      assembly {
        rewardConfig := mload(add(valueLocal, 2))
      }
      bool isRewardFromSystem = (rewardConfig == 0x0);

      address handlerContract;
      assembly {
        handlerContract := mload(add(valueLocal, 22))
      }

      require(isContract(handlerContract), "address is not a contract");
      channelHandlerContractMap[channelId]=handlerContract;
      registeredContractChannelMap[handlerContract][channelId] = true;
      isRelayRewardFromSystemReward[channelId] = isRewardFromSystem;
      emit addChannel(channelId, handlerContract);
    } else if (Memory.compareStrings(key, "enableOrDisableChannel")) {
      bytes memory valueLocal = value;
      require(valueLocal.length == 2, "length of value for enableOrDisableChannel should be 2, channelId:isEnable");

      uint8 channelId;
      assembly {
        channelId := mload(add(valueLocal, 1))
      }
      uint8 status;
      assembly {
        status := mload(add(valueLocal, 2))
      }
      bool isEnable = (status == 1);

      address handlerContract = channelHandlerContractMap[channelId];
      if (handlerContract != address(0x00)) { //channel existing
        registeredContractChannelMap[handlerContract][channelId] = isEnable;
        emit enableOrDisableChannel(channelId, isEnable);
      }
    } else {
      require(false, "unknown param");
    }
    emit paramChange(key, value);
  }
}