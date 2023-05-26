// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Assignable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract EIP712Listable is Assignable {
    using ECDSA for bytes32;

    address internal sigKey = address(0);

    bytes32 internal DOM_SEP;    

    uint256 chainid = 420;

    function setDomainSeparator(string memory _name, string memory _version) internal {
        DOM_SEP = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                chainid,
                address(this)
            )
        );
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(DOM_SEP, structHash);
    }    

    function getSigningAddress() public view returns (address) {
        return sigKey;
    }

    function setSigningAddress(address _sigKey) public onlyOwner {
        sigKey = _sigKey;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner();
    }
  
}