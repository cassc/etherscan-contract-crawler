// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../zkPass/ZKPass.sol";
import "./Safebox.sol";

contract SafeboxFactory is Context {
    ZKPass public zkPass;

    event SafeboxOwner(address indexed user, address indexed safebox);

    mapping(address => address) public userToSafebox;

    mapping(address => uint) public nonceOf;

    constructor(address zkPassAddr) {
        zkPass = ZKPass(zkPassAddr);
    }

    ///////////////////////////////////
    // Safebox
    ///////////////////////////////////

    function createSafebox() public returns (address) {
        require(
            userToSafebox[_msgSender()] == address(0),
            "SafeboxFactory::createSafebox: Safebox exist"
        );

        uint nonce = nonceOf[_msgSender()] + 1;
        nonceOf[_msgSender()] = nonce;
        bytes32 salt = keccak256(abi.encodePacked(_msgSender(), nonce));

        Safebox box = new Safebox{salt: salt}();
        box.init(_msgSender());

        userToSafebox[_msgSender()] = address(box);

        emit SafeboxOwner(_msgSender(), address(box));
        return address(box);
    }

    function getSafeboxAddr(address user) public view returns (address) {
        address existAddr = userToSafebox[user];

        if (existAddr != address(0)) {
            return existAddr;
        }

        uint nonce = nonceOf[user] + 1;
        bytes32 salt = keccak256(abi.encodePacked(user, nonce));
        address predictedAddr = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(type(Safebox).creationCode)
                        )
                    )
                )
            )
        );

        return predictedAddr;
    }

    function changeSafeboxOwner(address fromOwner, address newOwner) external {
        address safeboxAddr = userToSafebox[fromOwner];
        require(
            safeboxAddr == _msgSender(),
            "SafeboxFactory::changeSafeboxOwner: fromOwner error"
        );
        require(
            userToSafebox[newOwner] == address(0),
            "SafeboxFactory::changeSafeboxOwner: newOwner's Safebox exist"
        );

        delete userToSafebox[fromOwner];
        userToSafebox[newOwner] = safeboxAddr;

        emit SafeboxOwner(fromOwner, address(0));
        emit SafeboxOwner(newOwner, safeboxAddr);
    }
}