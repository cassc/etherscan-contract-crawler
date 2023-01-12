// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import ".././Library/EnumerableSet.sol";

abstract contract Verify {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(string => bool) public VERIFY_MESSAGE;
    EnumerableSet.AddressSet private OPERATOR;

    modifier onlyOperator() {
        require(OPERATOR.contains(msg.sender), "NOT OPERATOR.");
        _;
    }

    constructor() internal {
        OPERATOR.add(msg.sender);
    }
  
    modifier verifySignature(string memory message, uint8 v, bytes32 r, bytes32 s) {
        address signer = verifyString(message, v, r, s);
        require(OPERATOR.contains(signer), "INVALID SIGNATURE.");
        _;
    }

    modifier rejectDoubleMessage(string memory message) {
        require(!VERIFY_MESSAGE[message], "SIGNATURE ALREADY USED.");
        _;
    }

    function verifyString(string memory message, uint8 v, bytes32 r, bytes32 s) private pure returns(address signer){
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length:= mload(message)
            lengthOffset:= add(header, 57)
        }
        require(length <= 999999, "NOT PROVIDED.");
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    function getOperator() external view returns (address[] memory) {
        return OPERATOR.values();
    }

    function updateOperator(address _operatorAddr, bool _flag) public onlyOperator {
        require(_operatorAddr != address(0), "ZERO ADDRESS.");
        if (_flag) {
            OPERATOR.add(_operatorAddr);
        } else {
            OPERATOR.remove(_operatorAddr);
        }
    }
}