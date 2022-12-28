// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract uHGToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant HASH_TYPE = keccak256("claim");
    address public identityNFT;
    address private _signer;

    mapping(address => uint256) public claimNonce;
    mapping(address => bool) public identified;

    event Claim(address indexed to, uint256 amount);

    constructor(address identity,address signer) ERC20("unlocked Hooked Gold Token", "uHGT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        identityNFT = identity;
        _signer = signer;
    }

    function setIdentityNFT(address identity) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(AddressChecker.isAddressContract(identity), "Not a contract");
        require((IERC721(identity).supportsInterface(type(IERC721).interfaceId)), "Not an ERC721");
        identityNFT = identity;
    }

    function setSigner(address signer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(signer != address(0),"Invalid signer");
        _signer = signer;
    }

    function addIdentifiedAddress(address addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        identified[addr] = true;
    }

    function removeIdentifiedAddress(address addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete identified[addr];
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function hasIdentity(address owner) public view returns (bool){
        if(owner == address(0)) return true;
        return IERC721(identityNFT).balanceOf(owner) > 0 || identified[owner];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override
    {
        require(hasIdentity(to) && hasIdentity(from), "Token transfer restricted");
        super._beforeTokenTransfer(from, to, amount);
    }

    function claim(address to, bytes calldata signature, uint256 amount) public {
        require(verifySignature(to, signature, amount, claimNonce[to]), "Invalid signature");
        claimNonce[to]++;
        _mint(to, amount);
        emit Claim(to, amount);
    }

    function verifySignature(address owner, bytes memory signature, uint256 amount, uint256 nonce) internal view returns (bool) {
        bytes32 message = SignatureChecker.prefixed(keccak256(abi.encodePacked(HASH_TYPE, owner, amount, nonce)));
        return SignatureChecker.isValidSignature(message, signature, _signer);
    }
}

library AddressChecker {
    function isAddressContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library SignatureChecker {
    function isValidSignature(bytes32 hash, bytes memory signature, address signer) internal pure returns (bool) {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return signer == ecrecover(hash, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}