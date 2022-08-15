//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PuzzledSpaceWallet is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using ERC165Checker for address;

    event Deposited(address indexed from, address indexed to, uint256 amount);

    event Withdrawn(
        address indexed to,
        uint256 indexed operationId,
        uint256 amount
    );
    mapping(uint256 => bool) public operationStatus;

    function deposit(address to) external payable nonReentrant {
        emit Deposited(msg.sender, to, msg.value);
    }

    function withdrawal(
        address payable to,
        uint256 amount,
        uint256 signatureExpirationTime,
        uint256 operationId,
        bytes memory signature
    ) external {
        require(!operationStatus[operationId], "operation executed");
        operationStatus[operationId] = true;
        
        bytes32 hash = keccak256(
            abi.encodePacked(
                to,
                amount,
                signatureExpirationTime,
                operationId,
                msg.sender,
                block.chainid,
                address(this)
            )
        );
        bytes32 hashEth = hash.toEthSignedMessageHash();
        require(
            hashEth.recover(signature) == owner(),
            "withdrawal: wrong signature"
        );
        
        require(
            signatureExpirationTime > block.timestamp,
            "withdrawal: signature expired"
        );

        Address.sendValue(to, amount);

        emit Withdrawn(to, operationId, amount);
    }
}