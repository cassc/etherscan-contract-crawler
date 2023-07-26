// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Cope is ERC20, IERC721Receiver, AccessControl, ReentrancyGuard {
    address public copeBearContractAddress;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _copeBearContractAddress) ERC20("Cope", "COPE") {
        copeBearContractAddress = _copeBearContractAddress;
    }

    function mintCopeForBurn(uint256[] calldata tokenIds) external nonReentrant {
        uint256 totalAmount = 0;

        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(copeBearContractAddress).safeTransferFrom(msg.sender, address(this), tokenIds[i], '');
            uint256 amount = 369 + (uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                msg.sender,
                totalAmount,
                tokenIds[i]
            ))) % 630);
            totalAmount = totalAmount + (amount > 999 ? 999 : amount);
        }

        _mint(msg.sender, totalAmount * (10 ** 18));
    }

    function burnCope(uint256 amount) external nonReentrant {
        _burn(msg.sender, amount);
    }

    function mintCopeStimulus(address receiver, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(receiver, amount);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}