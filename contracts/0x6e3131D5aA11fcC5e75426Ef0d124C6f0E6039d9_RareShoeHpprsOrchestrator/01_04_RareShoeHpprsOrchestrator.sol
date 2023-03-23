// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RareShoeHpprsInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RareShoeHpprsOrchestrator is Ownable {
    address public secret = 0x9C17E0f19f6480747436876Cee672150d39426A5;
    address public main = 0xE5f8fb26FdEe365589c622ac89d39e93625D6c09;
    address public shipping = 0xa8c3e79E3C62655Ae556C2C207E3DA1A64a2acF5;

    RareShoeHpprsInterface public rareShoe = RareShoeHpprsInterface(0x0370Ef59e3e77Bb517F2AB68dc58EC224f38a1eb);

    uint public startAt = 1679504400;

    event OrderConfirmed(uint256 orderId);

    function setSettings(
        address _rareShoe,
        address _secret,
        address _main,
        address _shipping,
        uint _startAt
    ) external onlyOwner {
        secret = _secret;
        main = _main;
        shipping = _shipping;
        rareShoe = RareShoeHpprsInterface(_rareShoe);
        startAt = _startAt;
    }

    function setStartAt(uint _startAt) external onlyOwner {
        startAt = _startAt;
    }

    function mintItems(
        uint256 orderId,
        uint256 itemsPrice,
        uint256 shippingPrice,
        uint256 timeOut,
        uint256[] calldata itemsIds,
        uint256[] calldata itemsQuantities,
        bytes calldata signature
    ) external payable {
        require(block.timestamp > startAt, "Mint is closed");
        require(timeOut > block.timestamp, "Order is expired");
        require(msg.value == itemsPrice + shippingPrice, "Wrong ETH amount");
        require(
            _verifyHashSignature(keccak256(abi.encode(
                msg.sender,
                orderId,
                itemsPrice,
                shippingPrice,
                timeOut,
                itemsIds,
                itemsQuantities
            )), signature),
            "Invalid signature"
        );

        payable(main).transfer(itemsPrice);
        payable(shipping).transfer(shippingPrice);

        rareShoe.airdrop(msg.sender, itemsIds, itemsQuantities);
        emit OrderConfirmed(orderId);
    }

      function withdraw() external onlyOwner {
        payable(main).transfer(address(this).balance);
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature) internal view returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}