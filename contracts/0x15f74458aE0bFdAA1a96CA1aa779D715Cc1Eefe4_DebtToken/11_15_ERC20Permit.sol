// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../Interfaces/IERC2612Permit.sol";

abstract contract ERC20Permit is ERC20, IERC2612Permit {
	using Counters for Counters.Counter;
	bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;

	mapping(address => Counters.Counter) private _nonces;

	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 public constant PERMIT_TYPEHASH =
		0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

	constructor() {
		bytes32 hashedName = keccak256(bytes(name()));
        bytes32 hashedVersion = keccak256(bytes("1"));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(hashedName, hashedVersion);
        _CACHED_THIS = address(this);
	}

	function domainSeparator() public view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(PERMIT_TYPEHASH, nameHash, versionHash, block.chainid, address(this)));
    }
	

	/**
	 * @dev See {IERC2612Permit-permit}.
	 *
	 */
	function permit(
		address owner,
		address spender,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external virtual override {
		require(block.timestamp <= deadline, "Permit: expired deadline");

		Counters.Counter storage nonce = _nonces[owner];

		bytes32 hashStruct = keccak256(
			abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonce.current(), deadline)
		);

		bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), domainSeparator(), hashStruct));

		address signer = ECDSA.recover(_hash, v, r, s);
		require(signer != address(0) && signer == owner, "ERC20Permit: Invalid signature");

		nonce.increment();

		_approve(owner, spender, amount);
	}

	/**
	 * @dev See {IERC2612Permit-nonces}.
	 */
	function nonces(address owner) external view override returns (uint256) {
		return _nonces[owner].current();
	}
}