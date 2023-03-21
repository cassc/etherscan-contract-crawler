/**
 *Submitted for verification at BscScan.com on 2023-03-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function terminate() public onlyOwner {
        selfdestruct(payable(owner));
    }
}

contract Terminatable is Owned {
    uint256 public terminationBlock;
    uint256 public creationBlock;

    constructor() {
        terminationBlock = 0;
        creationBlock = block.number;
    }

    modifier notTerminated() {
        if (terminationBlock != 0 && block.number >= terminationBlock) {
            revert();
        }
        _;
    }

    // intendedly left non-blocked to allow reassignment of termination block
    function gracefullyTerminateAt(uint256 blockNumber) public onlyOwner {
        terminationBlock = blockNumber;
    }
}

contract BlockNumberRingBufferIndex {
    
    uint256 constant empty0 = 0x00ff000000ffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant empty1 = 0x00ffffffff000000ffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant empty2 = 0x00ffffffffffffff000000ffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant empty3 = 0x00ffffffffffffffffffff000000ffffffffffffffffffffffffffffffffffff;
    uint256 constant empty4 = 0x00ffffffffffffffffffffffffff000000ffffffffffffffffffffffffffffff;
    uint256 constant empty5 = 0x00ffffffffffffffffffffffffffffffff000000ffffffffffffffffffffffff;
    uint256 constant empty6 = 0x00ffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff;
    uint256 constant empty7 = 0x00ffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffff;
    uint256 constant empty8 = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffff000000ffffff;
    uint256 constant empty9 = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000;

    uint256 constant indexF = 0xff00000000000000000000000000000000000000000000000000000000000000;

    uint256 constant index1 = 0x0100000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index2 = 0x0200000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index3 = 0x0300000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index4 = 0x0400000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index5 = 0x0500000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index6 = 0x0600000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index7 = 0x0700000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index8 = 0x0800000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index9 = 0x0900000000000000000000000000000000000000000000000000000000000000;

    uint256 constant shift024 = 0x0000000000000000000000000000000000000000000000000000000001000000;
    uint256 constant shift048 = 0x0000000000000000000000000000000000000000000000000001000000000000;
    uint256 constant shift072 = 0x0000000000000000000000000000000000000000000001000000000000000000;
    uint256 constant shift096 = 0x0000000000000000000000000000000000000001000000000000000000000000;
    uint256 constant shift120 = 0x0000000000000000000000000000000001000000000000000000000000000000;
    uint256 constant shift144 = 0x0000000000000000000000000001000000000000000000000000000000000000;
    uint256 constant shift168 = 0x0000000000000000000001000000000000000000000000000000000000000000;
    uint256 constant shift192 = 0x0000000000000001000000000000000000000000000000000000000000000000;
    uint256 constant shift216 = 0x0000000001000000000000000000000000000000000000000000000000000000;

    function storeBlockNumber(uint256 indexValue, uint256 blockNumber) public pure returns (uint256) {
        blockNumber = blockNumber & 0xffffff; // 3 bytes
        uint256 currIdx = indexValue & indexF;
        if (currIdx == 0) {
            return (indexValue & empty1) | index1 | (blockNumber * shift192);
        } else
        if (currIdx == index1) {
            return (indexValue & empty2) | index2 | (blockNumber * shift168);
        } else
        if (currIdx == index2) {
            return (indexValue & empty3) | index3 | (blockNumber * shift144);
        } else
        if (currIdx == index3) {
            return (indexValue & empty4) | index4 | (blockNumber * shift120);
        } else
        if (currIdx == index4) {
            return (indexValue & empty5) | index5 | (blockNumber * shift096);
        } else
        if (currIdx == index5) {
            return (indexValue & empty6) | index6 | (blockNumber * shift072);
        } else
        if (currIdx == index6) {
            return (indexValue & empty7) | index7 | (blockNumber * shift048);
        } else
        if (currIdx == index7) {
            return (indexValue & empty8) | index8 | (blockNumber * shift024);
        } else
        if (currIdx == index8) {
            return (indexValue & empty9) | index9 | blockNumber;
        } else {
            return (indexValue & empty0) | (blockNumber * shift216);
        }
    }
}

struct RegistryEntryV6 {
    uint256 previousEventsIndex;
    uint256 publicKey;
    uint64 block;
    uint64 timestamp;
    uint32 keyVersion;
    uint32 registrar;
}

contract YlideRegistryV6 is Owned, Terminatable, BlockNumberRingBufferIndex {
    uint256 public version = 6;

    event KeyAttached(address indexed addr, uint256 publicKey, uint32 keyVersion, uint32 registrar, uint256 previousEventsIndex);
    
    mapping(address => RegistryEntryV6) public addressToPublicKey;
    mapping(address => bool) public bonucers;

    uint256 public newcomerBonus = 0;
    uint256 public referrerBonus = 0;

    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    constructor() {
        bonucers[msg.sender] = true;
    }

    function getPublicKey(address addr) view public returns (RegistryEntryV6 memory entry) {
        entry = addressToPublicKey[addr];
    }

    modifier onlyBonucer() {
        if (bonucers[msg.sender] != true) {
            revert();
        }
        _;
    }

    function setBonucer(address newBonucer, bool val) public onlyOwner notTerminated {
        if (newBonucer != address(0)) {
            bonucers[newBonucer] = val;
        }
    }

    function setBonuses(uint256 _newcomerBonus, uint256 _referrerBonus) public onlyOwner notTerminated {
        newcomerBonus = _newcomerBonus;
        referrerBonus = _referrerBonus;
    }

    function uint256ToHex(bytes32 buffer) public pure returns (bytes memory) {
        bytes memory converted = new bytes(64);
        bytes memory _base = "0123456789abcdef";

        for (uint8 i = 0; i < 32; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return converted;
    }

    function uint32ToHex(bytes4 buffer) public pure returns (bytes memory) {
        bytes memory converted = new bytes(8);
        bytes memory _base = "0123456789abcdef";

        for (uint8 i = 0; i < 4; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return converted;
    }

    function uint64ToHex(bytes8 buffer) public pure returns (bytes memory) {
        bytes memory converted = new bytes(16);
        bytes memory _base = "0123456789abcdef";

        for (uint8 i = 0; i < 8; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return converted;
    }

    function verifyMessage(bytes32 publicKey, uint8 _v, bytes32 _r, bytes32 _s, uint32 registrar, uint64 timestampLock) public view returns (address) {
        if (timestampLock > block.timestamp) {
            revert('Timestamp lock is in future');
        }
        if (block.timestamp - timestampLock > 5 * 60) {
            revert('Timestamp lock is too old');
        }
        bytes memory prefix = "\x19Ethereum Signed Message:\n330";
        // (121 + 2) + (14 + 64 + 1) + (13 + 8 + 1) + (12 + 64 + 1) + (13 + 16 + 0)
        bytes memory _msg = abi.encodePacked(
            "I authorize Ylide Faucet to publish my public key on my behalf to eliminate gas costs on my transaction for five minutes.\n\n", 
            "Public key: 0x", uint256ToHex(publicKey), "\n",
            "Registrar: 0x", uint32ToHex(bytes4(registrar)), "\n",
            "Chain ID: 0x", uint256ToHex(bytes32(block.chainid)), "\n",
            "Timestamp: 0x", uint64ToHex(bytes8(timestampLock))
        );
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _msg));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    receive() external payable {
        // do nothing
    }

    function internalKeyAttach(address addr, uint256 publicKey, uint32 keyVersion, uint32 registrar) internal {
        uint256 index = 0;
        if (addressToPublicKey[addr].keyVersion != 0) {
            index = storeBlockNumber(addressToPublicKey[addr].previousEventsIndex, addressToPublicKey[addr].block / 128);
        }

        addressToPublicKey[addr] = RegistryEntryV6(index, publicKey, uint64(block.number), uint64(block.timestamp), keyVersion, registrar);
        emit KeyAttached(addr, publicKey, keyVersion, registrar, index);
    }

    function attachPublicKey(uint256 publicKey, uint32 keyVersion, uint32 registrar) public notTerminated {
        require(keyVersion != 0, 'Key version must be above zero');

        internalKeyAttach(msg.sender, publicKey, keyVersion, registrar);
    }

    function attachPublicKeyByAdmin(uint8 _v, bytes32 _r, bytes32 _s, address payable addr, uint256 publicKey, uint32 keyVersion, uint32 registrar, uint64 timestampLock, address payable referrer, bool payBonus) external payable onlyBonucer notTerminated {
        require(keyVersion != 0, 'Key version must be above zero');
        require(verifyMessage(bytes32(publicKey), _v, _r, _s, registrar, timestampLock) == addr, 'Signature does not match the user''s address');
        require(referrer == address(0x0) || addressToPublicKey[referrer].keyVersion != 0, 'Referrer must be registered');
        require(addr != address(0x0) && addressToPublicKey[addr].keyVersion == 0, 'Only new user key can be assigned by admin');

        internalKeyAttach(addr, publicKey, keyVersion, registrar);

        if (payBonus && newcomerBonus != 0) {
            addr.transfer(newcomerBonus);
        }
        if (referrer != address(0x0) && referrerBonus != 0) {
            referrer.transfer(referrerBonus);
        }
    }
}