// contracts/King.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract KingTreasury is Ownable {
    using ECDSA for bytes32;

    address public signer;
    IERC20 public kingToken;
    mapping(uint256 => bool) public usedNonces;

    constructor(address _signer, address _kingToken) {
        signer = _signer;
        kingToken = IERC20(_kingToken);
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function withdraw(
        uint256 expiry,
        uint256 amount,
        uint256 nonce,
        bytes memory sig
    ) public {
        require(!usedNonces[nonce], "KingTreasury: nonce already used");
        bytes32 message = getMessageHash(expiry, amount, nonce, msg.sender);
        address recoveredSigner = message.recover(sig);
        require(recoveredSigner == signer, "KingTreasury: invalid sig");
        require(expiry >= block.timestamp, "KingTreasury: sig expired");
        usedNonces[nonce] = true;
        require(kingToken.transfer(msg.sender, amount), "Transfer failed");
    }

    function close() public onlyOwner {
        uint256 amount = kingToken.balanceOf(address(this));
        require(kingToken.transfer(msg.sender, amount), "Transfer failed");
    }

    function getMessageHash(
        uint256 expiry,
        uint256 amount,
        uint256 nonce,
        address to
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(expiry, amount, nonce, to));
    }
}