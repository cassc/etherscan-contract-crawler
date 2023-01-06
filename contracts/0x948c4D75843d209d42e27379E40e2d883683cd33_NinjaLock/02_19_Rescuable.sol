// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

// @author peker.eth - twitter.com/peker_eth

/*
    An untrusted rescue token implementation for ERC721 tokens inspired by ERC20 Permit.

    This implementation allows tokens to be rescued
    - Without the need for previous approval transaction for rescue by staker
    - Without giving the contract owner or support team access to the all staked tokens

    Good for rescuing tokens staked by a hacked/compromised wallet.
    This implementation only allows the trusted entities to execute the rescue
    To prevent the use of signatures gained by social engineering, etc.
*/
abstract contract Rescuable is EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_RESCUE_TYPEHASH =
        keccak256("PermitRescue(address staker,address recipient,uint256 nonce)");

    constructor(string memory name) EIP712(name, "1") {}

    function checkRescuePermit(
        address staker,
        address recipient,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (bool) {
        bytes32 structHash = keccak256(abi.encode(_PERMIT_RESCUE_TYPEHASH, staker, recipient, _useNonce(staker)));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == staker, "Rescuable: invalid signature");

        return true;
    }

    function nonces(address staker) public view virtual returns (uint256) {
        return _nonces[staker].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _useNonce(address staker) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[staker];
        current = nonce.current();
        nonce.increment();
    }
}