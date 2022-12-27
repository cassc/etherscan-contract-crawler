// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./ResolverBase.sol";
import "./IAddressResolver.sol";

// import "hardhat/console.sol";

contract AddressResolverStorage {
    mapping(bytes32 => mapping(uint256 => bytes)) _addresses;
    mapping(bytes32 => EnumerableSetUpgradeable.UintSet) _nameTypes;
    uint256 public constant COIN_TYPE_ETH = 60;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * The size of the __gap array is calculated so that the amount of storage used by a
     * contract always adds up to the same number (in this case 50 storage slots).
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

abstract contract AddressResolver is AddressResolverStorage, IAddressResolver, ResolverBase {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using StringsUpgradeable for uint256;

    function makeAddrMessage(
        string memory name,
        uint256 coinType,
        address a,
        uint256 timestamp,
        uint256 nonce
    ) public pure override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Click sign to allow setting address for ",
                    name,
                    " to ",
                    StringsUpgradeable.toHexString(a),
                    "\n\n"
                    "This request will not trigger a blockchain transaction or cost any gas fees."
                    "\n\n"
                    "This message will expire after 24 hours."
                    "\n\n"
                    "Coin type: ",
                    coinType.toHexString(),
                    "\nTimestamp: ",
                    timestamp.toString(),
                    "\nNonce: ",
                    nonce.toHexString()
                )
            );
    }

    function recoverAddr(
        string memory name,
        uint256 coinType,
        address a,
        uint256 timestamp,
        uint256 nonce,
        bytes memory signature
    ) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        string memory message = makeAddrMessage(name, coinType, a, timestamp, nonce);
        bytes32 _hashMessage = keccak256(
            abi.encodePacked(prefix, bytes(message).length.toString(), message)
        );
        return recoverSigner(_hashMessage, signature);
    }

    function recoverSigner(
        bytes32 _hashMessage,
        bytes memory _sig
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        return ecrecover(_hashMessage, v, r, s);
    }

    function setAddr(
        string memory name,
        uint256 coinType,
        address a,
        uint256 timestamp,
        uint256 nonce,
        bytes memory signature
    ) public override {
        bytes32 node = keccak256(bytes(name));
        require(isAuthorised(node), "NO");
        require(block.timestamp - timestamp < 86400, "EXP");
        address recoverdAddress = recoverAddr(name, coinType, a, timestamp, nonce, signature);
        require(a == recoverdAddress, "IA");
        setAddr(node, coinType, addressToBytes(a));
    }

    function setAddr(bytes32 node, uint256 coinType, bytes memory a) internal {
        emit AddressChanged(node, coinType, a);
        _addresses[node][coinType] = a;
        _nameTypes[node].add(coinType);
    }

    function addrs(bytes32 node) public view virtual override returns (TypedAddress[] memory) {
        EnumerableSetUpgradeable.UintSet storage types = _nameTypes[node];
        TypedAddress[] memory ret = new TypedAddress[](types.length());

        for (uint256 index = 0; index < types.length(); index++) {
            uint coinType = types.at(index);
            ret[index].coinType = coinType;
            ret[index].addr = _addresses[node][coinType];
        }
        return ret;
    }

    function addrOfType(
        bytes32 node,
        uint256 coinType
    ) public view virtual override returns (bytes memory) {
        return _addresses[node][coinType];
    }

    function addr(bytes32 node) public view virtual override returns (address) {
        bytes memory a = addrOfType(node, COIN_TYPE_ETH);
        if (a.length == 0) {
            return address(0);
        }
        return bytesToAddress(a);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return
            interfaceID == type(IAddressResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    function bytesToAddress(bytes memory b) internal pure returns (address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}