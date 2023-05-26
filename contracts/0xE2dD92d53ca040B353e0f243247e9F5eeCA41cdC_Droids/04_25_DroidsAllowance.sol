// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DroidsAllowance is Ownable {
    using ECDSA for bytes32;
    mapping(bytes32 => bool) public usedAllowances;

    address private _allowancesSigner;
    
    function allowancesSigner() public view virtual returns (address) {
        return _allowancesSigner;
    }

    function _setAllowancesSigner(address newSigner) internal {
        _allowancesSigner = newSigner;
    }
    
    function composeMessage(address account, uint256 limit,uint256 isClaim, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account,"#",limit,"#",isClaim,"#",nonce));
    }

    function validateSignature(
        address account,
        uint256 limit,
        uint256 isClaim,
        uint256 nonce,
        bytes memory signature
    ) internal {
        bytes32 message = composeMessage(account, limit, isClaim, nonce).toEthSignedMessageHash();
        // verifies that the sha3(account, nonce, address(this)) has been signed by signer
        require(message.recover(signature) == _allowancesSigner, '!INVALID_SIGNATURE!');

        // verifies that the allowances was not already used
        require(usedAllowances[message] == false, '!ALREADY_USED!');

        usedAllowances[message] = true;
    }
}