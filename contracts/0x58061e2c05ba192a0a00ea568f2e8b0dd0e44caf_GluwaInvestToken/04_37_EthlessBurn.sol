// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

import "./SignerNonce.sol";
import "../libs/GluwacoinModels.sol";
import "../libs/Validate.sol";

contract EthlessBurn is ERC20BurnableUpgradeable, SignerNonce {
    event Burn(address indexed account, uint256 indexed amount);

    /**
     * @dev Allow a account to burn tokens of a account that allow it via ERC191 signature and collect fee
     */
    function burn(
        address burner,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig
    ) external virtual returns (bool success) {
        unchecked {
            require(
                balanceOf(burner) >= amount,
                "EthlessBurn: burn amount exceed balance"
            );
            _useNonce(burner, nonce);
            bytes32 hash = keccak256(
                abi.encodePacked(
                    GluwacoinModels.SigDomain.Burn,
                    block.chainid,
                    address(this),
                    burner,
                    amount,
                    fee,
                    nonce
                )
            );
            Validate.validateSignature(hash, burner, sig);
            _transfer(burner, _msgSender(), fee);
        }
        _burn(burner, amount - fee);
        return true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}