// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../libs/GluwacoinModels.sol";
import "../libs/Validate.sol";
import "./SignerNonce.sol";

contract EthlessTransfer is ERC20Upgradeable, SignerNonce {
    /**
     * @dev Allow a account to transfer tokens of a account that allow it via ERC191 signature and collect fee
     */
    function transfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 fee,
        uint256 gluwaNonce,
        bytes memory sig
    ) external virtual returns (bool success) {
        unchecked {
            _useNonce(sender, gluwaNonce);
            _beforeTokenTransfer(sender, recipient, amount + fee);
            bytes32 hash = keccak256(
                abi.encodePacked(
                    GluwacoinModels.SigDomain.Transfer,
                    block.chainid,
                    address(this),
                    sender,
                    recipient,
                    amount,
                    fee,
                    gluwaNonce
                )
            );
            Validate.validateSignature(hash, sender, sig);
            _transfer(sender, _msgSender(), fee);
            _transfer(sender, recipient, amount);
            return true;
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}