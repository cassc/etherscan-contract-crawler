// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract HookedHalloweenParty is Ownable{

    bytes32 public constant PICK_HASH_TYPE = keccak256("pick");
    address immutable public _passNFT;
    address private _signer;
    mapping(address => uint256) public pickNonce;

    event Pick(address indexed from, address indexed to, uint256 indexed nonce); 
    constructor(address passNFT, address signer) {
        _passNFT = passNFT;
        _signer = signer;
    }

    function setSigner(address signer) public onlyOwner {
        require(signer != address(0),"Invalid signer");
        _signer = signer;
    }

    function pick(address target, bytes calldata signature) public {
        require(hasPass(msg.sender) && hasPass(target), "Halloween Party Pass needed");
        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(PICK_HASH_TYPE, msg.sender, target, pickNonce[msg.sender])));
        require(SignatureChecker.isValidSignatureNow(_signer, message, signature),"Invalid signature");
        emit Pick(msg.sender, target, pickNonce[msg.sender]);
        pickNonce[msg.sender]++;
    }

    function hasPass(address owner) public view returns (bool){
        if(owner == address(0)) return false;
        return IERC721(_passNFT).balanceOf(owner) > 0;
    }
}

library AddressChecker {
    function isAddressContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}