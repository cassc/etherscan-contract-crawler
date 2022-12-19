// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IPicklePeople {
    function mint(address _to) external;
}

contract PickleSale is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public root = 0x32256aff767a3943b419941fa8630d200364b6cb74144adb40a729e7ec28f787;
    // IPicklePeople public picklePeopleNFT = IPicklePeople(0xf38d176348CaF8e97f55C6Fb5B8b774876d5C87b); //testnet
    IPicklePeople public picklePeopleNFT = IPicklePeople(0x13f0f522ce1dBe2025DadC332E11d6b511614bc0); //mainnet
    bool public open = false;
    mapping(address => uint256) public minted;

    event Mint(address addr, uint256 numberOfTokens);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }
// Mint 

    function mint(bytes32[] memory _proof, uint256 _quota, uint numberOfTokens) public {
        require(open, "Mint not open");
        require(_quota > 0, "Something funky");
        require(verifyAddr(_proof, _msgSender(), _quota), "Not on whitelist");
        if (_quota > 0) {
            minted[_msgSender()] += numberOfTokens;
            require(minted[_msgSender()] <= _quota, 'Whitelist quota reached');
        }
        // mint batch
        for (uint256 i = 0; i < numberOfTokens; ++i) {
            picklePeopleNFT.mint(_msgSender());
        }
        emit Mint(_msgSender(), numberOfTokens);
    }

// View

    function verify(bytes32[] memory _proof, bytes32 _leaf) public view returns (bool) {
        return MerkleProof.verify(_proof, root, _leaf);
    }

    function verifyAddr(bytes32[] memory _proof, address _addr, uint256 _quota) public view returns (bool) {
        bytes32 _leaf = keccak256(bytes.concat(keccak256(abi.encode(_addr, _quota))));
        return MerkleProof.verify(_proof, root, _leaf);
    }

// Admin

    function setRoot(bytes32 _root) public onlyRole(MINTER_ROLE) {
        root = _root;
    }

    function toggleOpen() public onlyRole(MINTER_ROLE) {
        open = !open;
    }

    function setPicklePplAddr(address _addr) public onlyRole(MINTER_ROLE) {
        picklePeopleNFT = IPicklePeople(_addr);
    }
}