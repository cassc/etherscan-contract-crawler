/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract EtherPOAPRewards {
    address public owner;
    address public signer;
    mapping(bytes32 => bool) public evidenceUsed;
    uint public maxValuePerReward;
    bool _init;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    receive() payable external {}

    function initialize(
        address _owner,
        address _signer,
        uint _maxValuePerReward
    ) public {
        require(!_init, "the contract has been initialized");
        owner = _owner;
        signer = _signer;
        maxValuePerReward = _maxValuePerReward;
        _init = true;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setSigner(
        address _signer
    ) public onlyOwner {
        signer = _signer;
    }

    function setMaxPrice(
        uint _maxValuePerReward
    ) public onlyOwner {
        maxValuePerReward = _maxValuePerReward;
    }

    function claimRewards(
        uint value, 
        uint nonce, 
        bytes memory evidence
    ) public {
        require(
            !evidenceUsed[keccak256(evidence)] &&
                _validate(
                    keccak256(abi.encodePacked(msg.sender, value, nonce)),
                    evidence
                ),
            "invalid evidence"
        );
        require(value <= maxValuePerReward, "exceed the maximum value per reward");
        evidenceUsed[keccak256(evidence)] = true;
        payable(msg.sender).transfer(value);
    }

    function withdraw(
        address payable receiver
    ) public onlyOwner {
        receiver.transfer(address(this).balance);
    }

    function _validate(
        bytes32 message,
        bytes memory signature
    ) internal view returns (bool) {
        require(signer != address(0) && signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v = uint8(signature[64]) + 27;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
        }
        return ecrecover(message, v, r, s) == signer;
    }
}