// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ICompassCollect.sol";
import "./CompassWallet.sol";


contract CompassCollect is ICompassCollect, Ownable {

    bytes32 public constant WALLET_INIT_CODE_HASH = keccak256(abi.encodePacked(type(CompassWallet).creationCode));

    address payable public override recipient;
    address public override useToken;
    bool private lock;

    constructor(address payable _recipient) {
        recipient = _recipient;
    }

    function setRecipient(address payable _recipient) external override onlyOwner {
        recipient = _recipient;
    }

    modifier ensure(address token) {
        require(!lock, "CompassCollect: locked");
        useToken = token;
        lock = true;
        _;
        useToken = address(0);
        lock = false;
    }

    function collect(address token, bytes32[] memory salts) external override ensure(token) {
        bytes memory bytecode = type(CompassWallet).creationCode;
        for (uint8 i = 0; i < salts.length; i++) {
            bytes32 salt = salts[i];
            address addr;
            assembly {
                addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            }
            require(addr != address(0), "Create2: Failed on deploy");
        }
    }

    function getBalance(address token, bytes32[] memory salts) external override view returns (uint[] memory){
        uint[] memory balance = new uint[](salts.length);
        for (uint8 i = 0; i < salts.length; i++) {
            bytes32 salt = salts[i];
            address addr = computeAddress(salt);
            balance[i] = IERC20(token).balanceOf(addr);
        }
        return balance;
    }

    function computeAddress(bytes32 salt) public override view returns (address addr) {
        address deployer = address(this);
        bytes32 bytecodeHash = WALLET_INIT_CODE_HASH;
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer)
            let start := add(ptr, 0x0b)
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }

}