// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Whitelist is Ownable, EIP712 {
    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(address buyer,uint256 signedQty,uint256 nonce)");
    address public whitelistSigner;

    modifier isSenderWhitelisted(
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    ) {
        require(
            getSigner(msg.sender, _signedQty, _nonce, _signature) ==
                whitelistSigner,
            "Whitelist: Invalid signature"
        );
        _;
    }

    constructor(string memory name, string memory version)
        EIP712(name, version)
    {}

    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }

    function getSigner(
        address _buyer,
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(WHITELIST_TYPEHASH, _buyer, _signedQty, _nonce)
            )
        );
        return ECDSA.recover(digest, _signature);
    }
}