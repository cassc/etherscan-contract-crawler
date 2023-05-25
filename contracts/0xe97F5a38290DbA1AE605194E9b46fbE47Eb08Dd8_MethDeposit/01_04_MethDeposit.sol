// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IMasterContract.sol";

/// @title Bulls and Apes Project - Deposit to METH Bank
/// @author BAP Dev Team
/// @notice Helper Contract to handle METH deposits to the bank
contract MethDeposit is Ownable {
    /// @notice BAP Apes contract
    IMasterContract public masterContract;
    /// @notice Address of the signer wallet
    address public secret;

    /// @notice Event emitted when METH is deposited
    event Deposit(uint256 amount, address recipient, address operator);
    event MethBagBought(uint256 amount, uint256 price, address to);

    /// @notice Deploys the contract
    /// @param _masterContract BAP Master contract
    constructor(address _masterContract, address _secret) {
        masterContract = IMasterContract(_masterContract);
        secret = _secret;
    }

    /// @notice Helper function to deposit METH through master contract
    /// @param amount Amount of METH to deposit
    /// @param recipient Address to deposit METH to
    function deposit(uint256 amount, address recipient) external {
        require(msg.sender == tx.origin, "Only direct calls allowed");
        masterContract.pay(amount, 0);

        emit Deposit(amount, recipient, msg.sender);
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

        emit Deposit(amount, to, msg.sender);
        emit MethBagBought(amount, price, to);
    }

    /// @notice Set new contracts addresses for BAP Master contract
    /// @param _masterContract New address for BAP Master contract
    /// @dev Can only be called by the contract owner
    function setContracts(address _masterContract) external onlyOwner {
        masterContract = IMasterContract(_masterContract);
    }

    /// @notice Change the signer address
    /// @param _secret new signer for encrypted signatures
    /// @dev Can only be called by the contract owner
    function setSecret(address _secret) external onlyOwner {
        secret = _secret;
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