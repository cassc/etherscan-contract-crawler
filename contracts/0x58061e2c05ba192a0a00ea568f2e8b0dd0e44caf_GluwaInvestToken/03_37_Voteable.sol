// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

import "./SignerNonce.sol";

contract Voteable is ERC20VotesUpgradeable, SignerNonce {
    bytes32 private constant _DELEGATE_TYPEHASH =
        keccak256(
            "delegateBySig(address delegatee,uint256 fee,uint256 gluwaNonce,uint256 expiry)"
        );

    /**
     * @dev Initialise the ERC20 token
     */
    function __Voteable_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
    }

    /**
     * @dev Allow a account to delegate voting power of a account that allow it via ERC712 signature and collect fee
     */
    function delegateBySig(
        address delegatee,
        uint256 fee,
        uint256 gluwaNonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (bool) {
        require(expiry > block.timestamp, "Voteable: Signature expired");
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _DELEGATE_TYPEHASH,
                        delegatee,
                        fee,
                        gluwaNonce,
                        expiry
                    )
                )
            ),
            v,
            r,
            s
        );
        _useNonce(signer, gluwaNonce);
        _transfer(signer, _msgSender(), fee);
        _delegate(signer, delegatee);
        return true;
    }

    /**
     * @dev Override original delegateBySig() in favor of delegateBySig() with fee
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        revert("Voteable: Not supported");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}