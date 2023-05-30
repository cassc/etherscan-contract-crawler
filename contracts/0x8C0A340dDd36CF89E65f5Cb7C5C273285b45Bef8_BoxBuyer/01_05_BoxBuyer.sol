// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IMasterContract.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Bulls and Apes Project - Buy Special LootBoxes
/// @author BAP Dev Team
/// @notice Helper Contract to buy special LootBoxes
contract BoxBuyer is Ownable, ReentrancyGuard {
    /// @notice Address of the signer wallet
    address public secret;

    // @notice mapping for used signatures
    mapping(bytes => bool) public isSignatureUsed;

    /// @notice Event emitted when lootbox is bought
    event BoxBought(
        uint256 amount,
        uint256 boxType,
        address recipient,
        address operator
    );

    /// @notice Event emitted when METH bag is buyed
    event MethBagBought(uint256 amount, uint256 price, address to);

    /// @notice Deploys the contract
    /// @param _secret Address of the signer wallet
    constructor(address _secret) {
        secret = _secret;
    }

    /// @notice Helper function to buy a special lootbox
    /// @param amount Amount of boxes to buy
    /// @param boxType Type of the lootbox to buy
    /// @param price Price to be paid for the lootbox (in ETH)
    /// @param timeOut Timestamp for signature expiration
    /// @param recipient Address to send the lootbox to
    /// @param signature Signature to verify above parameters
    function buyLootbox(
        uint256 amount,
        uint256 boxType,
        uint256 price,
        uint256 timeOut,
        address recipient,
        bytes memory signature
    ) external payable {
        require(
            timeOut > block.timestamp,
            "buyLootbox: Seed is no longer valid"
        );
        require(price > 0, "buyLootbox: amount is not valid");
        require(msg.value >= price, "buyLootbox: not enough ETH to buy");
        // check signature
        require(
            !isSignatureUsed[signature],
            "buyLootbox: Signature is already used"
        );
        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(amount, boxType, price, timeOut, recipient)
                ),
                signature
            ),
            "buyLootbox: Signature is invalid"
        );

        isSignatureUsed[signature] = true;

        if (msg.value > price) {
            (bool success, ) = msg.sender.call{value: msg.value - price}("");
            require(success, "buyLootbox: Unable to send refund eth");
        }

        emit BoxBought(amount, boxType, recipient, msg.sender);
    }

    /// @notice Buy METH bags to be deposited to the bank
    /// @param amount Amount of METH to buy
    /// @param to Address to send the METH
    /// @param price Price to be paid for the METH (in ETH)
    /// @param timeOut Timestamp for signature expiration
    /// @param signature Signature to verify above parameters
    /// @dev Mints amount METH to selected address
    function buyMethBag(
        uint256 amount,
        address to,
        uint256 price,
        uint256 timeOut,
        bytes calldata signature
    ) external payable {
        require(
            timeOut > block.timestamp,
            "buyMethBag: Seed is no longer valid"
        );
        require(
            _verifyHashSignature(
                keccak256(abi.encode(amount, to, price, timeOut)),
                signature
            ),
            "buyMethBag: Signature is invalid"
        );
        require(price > 0, "buyMethBag: amount is not valid");
        require(msg.value >= price, "buyMethBag: not enough ETH to buy");

        if (msg.value > price) {
            (bool success, ) = msg.sender.call{value: msg.value - price}("");
            require(success, "buyMethBag: Unable to send refund eth");
        }

        emit MethBagBought(amount, price, to);
    }

    /// @notice Change the signer address
    /// @param _secret new signer for encrypted signatures
    /// @dev Can only be called by the contract owner
    function setSecret(address _secret) external onlyOwner {
        secret = _secret;
    }

    function withdrawETH(
        address _address,
        uint256 amount
    ) public nonReentrant onlyOwner {
        require(amount <= address(this).balance, "Insufficient funds");
        (bool success, ) = _address.call{value: amount}("");
        require(success, "Unable to send eth");
    }

    function _verifyHashSignature(
        bytes32 freshHash,
        bytes memory signature
    ) internal view returns (bool) {
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
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}