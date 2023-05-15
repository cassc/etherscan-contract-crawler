/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBaseNft {
    function totalSupply() external view returns (uint256);
}

contract BatchMint {
    bytes private constant initBytecode = abi.encodePacked(
        hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
        bytes20(0xa6a26Be5664Eb1F3d9241F02973F157D1fFFd90b),
        hex"5af43d82803e903d91602b57fd5bf3"
    );

    IBaseNft private constant baseNft =
        IBaseNft(0x4EBB2384CC1e86F578E37f2057b336B9027cb95a);

    uint256 private constant fee = 111000000000000;
    uint256 private constant payment = 777000000000000;

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function purchase(uint256 quantity) external payable {
        uint256 totalCost = (fee + payment) * quantity;
        require(msg.value >= totalCost, "Insufficient funds");

        bytes32 salt = bytes32(IBaseNft(baseNft).totalSupply());
        address proxy;
        for (uint256 i; i < quantity; ++i) {
            proxy = _create2Proxy(keccak256(abi.encode(salt, i)));
            (bool success, ) = proxy.call{value: payment}(
                abi.encodeWithSelector(bytes4(keccak256("mint()")))
            );
            require(success, "purchase failed");
        }
    }

    function _create2Proxy(bytes32 salt) internal returns (address newProxy) {
        bytes memory bytecode = initBytecode;
        assembly {
            newProxy := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
    }

    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        owner.transfer(address(this).balance);
    }
}