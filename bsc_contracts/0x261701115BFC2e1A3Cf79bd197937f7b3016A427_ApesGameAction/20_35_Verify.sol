// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract Verify is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    address private publicKey;


    function verify(bytes32 hashMessage, bytes memory _data)internal view returns (bool) {
        bool auth;
        bytes32 _r = bytes2bytes32(slice(_data, 0, 32));
        bytes32 _s = bytes2bytes32(slice(_data, 32, 32));
        bytes1 v = slice(_data, 64, 1)[0];
        uint8 _v = uint8(v) + 27;

        address addr = ecrecover(hashMessage, _v, _r, _s);
        if (publicKey == addr) {
            auth = true;
        }
        return auth;
    }

    function slice(bytes memory data, uint256 start, uint256 len) internal pure returns (bytes memory) {
        bytes memory b = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            b[i] = data[i + start];
        }
        return b;
    }

    function bytes2bytes32(bytes memory _source) internal pure returns (bytes32 result){
        assembly {
            result := mload(add(_source, 32))
        }
    }

    function setPublicKey(address _key) external onlyOwner {
        publicKey = _key;
    }
    
    function getPublicKey() external view onlyOwner returns (address){
        return publicKey;
    }
}