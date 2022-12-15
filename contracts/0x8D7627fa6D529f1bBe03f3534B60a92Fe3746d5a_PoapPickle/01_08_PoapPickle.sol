// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IPickleEditions {
    function mint(address _to, uint _itemId, uint _count) external;
}

contract PoapPickle is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bool public open = true;
    IPickleEditions pickleEditions;
    mapping(address => bool) public minted;
    bytes32 public root = 0xf93afe7a03fff2c31e0a88a0b3756d76b6ed8b8d09b559c9fe46735d523e09f2;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        pickleEditions = IPickleEditions(0x8b79B97bf6b88Ec7D145E44d0fC2CDB37E7A5a72);  //mainnet
        // pickleEditions = IPickleEditions(0x02135a9Ad377cC86EE77C07CcB95D97046cF24Fe);  //testnet
    }

    function mint(bytes32[] memory _proof, address _addr) public {
        require(open, "Mint not open");
        require(!minted[_addr], "Already minted");
        require(verify(_proof, _addr), "Not on whitelist");
        minted[_addr] = true;
        pickleEditions.mint(_addr, 5, 1);
    }

    function verify(bytes32[] memory _proof, address _addr) public view returns (bool) {
        bytes32 _leaf = keccak256(bytes.concat(keccak256(abi.encode(_addr))));
        return MerkleProof.verify(_proof, root, _leaf);
    }

    function toggleOpen() public onlyRole(MINTER_ROLE) {
        open = !open;
    }

    function setRoot(bytes32 _root) public onlyRole(MINTER_ROLE) {
        root = _root;
    }
}