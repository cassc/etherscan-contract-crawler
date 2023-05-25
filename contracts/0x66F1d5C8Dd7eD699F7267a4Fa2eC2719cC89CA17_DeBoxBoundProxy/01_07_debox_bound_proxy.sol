// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IERC5192.sol";

contract DeBoxBoundProxy is Ownable {

    mapping(address => uint256) public _nonces;
    mapping(uint256 => address) public _boundContract;

    address public _signOwner;
    
    event Mint(address indexed sender, uint256 mtype, uint256 id, string meta, uint256 period);

    constructor() {
        _signOwner = msg.sender;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function modifySignOwner(address owner) external onlyOwner {
        require(owner != address(0), "Invalid address");
        _signOwner = owner;
    }

    function modifyBoundContract(uint256 mtype, address ca) external onlyOwner {
        require(ca != address(0), "Invalid bound contract address");
        _boundContract[mtype] = ca;
    }

    function getBoundContract(uint256 mtype) internal view returns (IERC5192){
        require(_boundContract[mtype] != address(0), "Invalid mint type");
        return IERC5192(_boundContract[mtype]);
    }

    function verifyToken(uint256 id, string memory meta, uint256 mtype) external view returns (bool) {
        return getBoundContract(mtype).verifyToken(id, meta, mtype);
    }

    function mint(uint256 mtype, string memory meta, uint256 period, bytes memory signature) external callerIsUser {
        bytes32 message = keccak256(abi.encodePacked(_msgSender(), meta, period, mtype, _nonces[_msgSender()]));
        require(ECDSA.recover(message, signature) == _signOwner, "The signature is invalid");
        uint256 id = getBoundContract(mtype).safeMint(meta, period, mtype);
        _nonces[_msgSender()]++;
        emit Mint(_msgSender(), mtype, id, meta, period);
    }
}