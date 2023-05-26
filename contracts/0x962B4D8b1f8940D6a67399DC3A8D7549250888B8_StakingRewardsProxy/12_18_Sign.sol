// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

abstract contract Sign is EIP712 {
    constructor() EIP712("RADAR Cross-Chain Staking", "1") {}

    struct StakeData {
        string action;
        uint256 amount;
    }

    struct ClaimWithdrawData {
        string action;
    }

    bytes32 private constant STAKE_DATA_TYPEHASH = keccak256("StakeData(string action,uint256 amount)");
    bytes32 private constant CLAIM_WITHDRAW_DATA_TYPEHASH = keccak256("ClaimWithdrawData(string action)");
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version)");
    bytes32 private constant DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256("RADAR Cross-Chain Staking"),
            keccak256("1")
        ));

    function hashActionData(StakeData memory actionData) private view returns (bytes32) {
        return keccak256(abi.encode(
                STAKE_DATA_TYPEHASH,
                keccak256(abi.encodePacked(actionData.action)),
                actionData.amount
            ));
    }

    function hashActionData(ClaimWithdrawData memory actionData) private view returns (bytes32) {
        return keccak256(abi.encode(
                CLAIM_WITHDRAW_DATA_TYPEHASH,
                keccak256(abi.encodePacked(actionData.action))
            ));
    }

    function verify(address user, StakeData memory actionData, bytes memory signature) public view virtual {
        bytes32 digest = _hashTypedDataV4(hashActionData(actionData));
        _verify(user, digest, signature);
    }

    function verify(address user, ClaimWithdrawData memory actionData, bytes memory signature) public view virtual {
        bytes32 digest = _hashTypedDataV4(hashActionData(actionData));
        _verify(user, digest, signature);
    }

    function _verify(address user, bytes32 digest, bytes memory signature) internal view virtual {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(digest, signature);
        require(error == ECDSA.RecoverError.NoError && recovered == user, "Sign: Invalid signature");
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}