// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PEPEGAME is ERC20, ERC20Burnable, Pausable, Ownable {
    uint256 public rewardMultiplier;
    mapping(bytes32 => bool) private _processedClaims;

    constructor() ERC20("PEPEGAME", "PPG") {
        _mint(msg.sender, 200_000_000_000_000 * 10 ** 18); // 200 trillion tokens, 18 decimal places
        rewardMultiplier = 1000 * 10 ** 18; // initialize with 1000 tokens per toad
    }

    function burn(uint256 amount) public override onlyOwner {
        super.burn(amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function setRewardMultiplier(uint256 newMultiplier) external onlyOwner {
        rewardMultiplier = newMultiplier;
    }

    function claimTokens(
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(
            verifySignature(msg.sender, amount, nonce, signature),
            "Invalid signature"
        );
        bytes32 signatureHash = keccak256(signature);
        require(!_processedClaims[signatureHash], "Signature already used");
        _processedClaims[signatureHash] = true;

        uint256 rewardAmount = amount * rewardMultiplier;

        // Ensure the contract has enough tokens to distribute
        require(
            balanceOf(owner()) >= rewardAmount,
            "Not enough tokens to distribute"
        );

        _transfer(owner(), msg.sender, rewardAmount);
    }

    function verifySignature(
        address claimer,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) public view returns (bool) {
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(claimer, amount, nonce))
        );

        return recoverSigner(message, signature) == owner();
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(
        bytes32 message,
        bytes memory sig
    ) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}