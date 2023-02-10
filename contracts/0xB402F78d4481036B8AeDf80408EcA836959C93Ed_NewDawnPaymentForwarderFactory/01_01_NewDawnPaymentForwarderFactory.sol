// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface INewDawnPaymentForwarder {
    function initialize(
        address payable treasuryAddress,
        address _admin,
        uint directOfferPriceInWei,
        uint directAcceptancePriceInWei,
        uint globalOfferPriceInWei,
        uint globalAcceptancePriceInWei
    ) external;
}

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * uses a vanity address starting with four zeros 
 */
library Cloner {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function createClone(address implementation) internal returns (address instance) {
        bytes20 target = bytes20(implementation)<<16;
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602b80600a3d3981f3363d3d373d3d3d363d71000000000000000000000000)
            mstore(add(clone, 0x14), target)
            mstore(add(clone, 0x26), 0x5af43d82803e903d91602957fd5bf30000000000000000000000000000000000)
            instance := create(0, clone, 0x35)
        }
        require(instance != address(0), "ERC1167: create failed");
    }
}

contract NewDawnPaymentForwarderFactory {

    address admin;
    address implementation;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewContract(address contractAddress);

    constructor(address impl) {
        require(bytes2(bytes20(impl)) == bytes2(0), "Must be a vanity address!");
        admin = msg.sender;
        implementation = impl;
    }

    function changeAdmin(address newAdmin) external {
        require(msg.sender == admin, "Only Admin");
        require(newAdmin != address(0), "Admin cannot be set to zero");
        address oldAdmin = admin;
        admin = newAdmin;
        emit NewAdmin(oldAdmin, newAdmin);
    }

    function createNewContract(
        address payable treasuryAddress,
        address _admin,
        uint directOfferPriceInWei,
        uint directAcceptancePriceInWei,
        uint globalOfferPriceInWei,
        uint globalAcceptancePriceInWei
    ) external {
        require(msg.sender == admin, "Only Admin");

        address addr = Cloner.createClone(implementation);
        INewDawnPaymentForwarder instance = INewDawnPaymentForwarder(addr);
        instance.initialize(
            treasuryAddress,
            _admin,
            directOfferPriceInWei,
            directAcceptancePriceInWei,
            globalOfferPriceInWei,
            globalAcceptancePriceInWei
        );

        emit NewContract(addr);
    }
}