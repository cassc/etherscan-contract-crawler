// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../dependencies/openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./PoolERC20.sol";

///@title Pool ERC20 Permit to use with proxy. Inspired by OpenZeppelin ERC20Permit
// solhint-disable var-name-mixedcase
abstract contract PoolERC20Permit is PoolERC20, IERC20Permit {
    bytes32 private constant _EIP712_VERSION = keccak256(bytes("1"));
    bytes32 private constant _EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 private _CACHED_DOMAIN_SEPARATOR;
    bytes32 private _HASHED_NAME;
    uint256 private _CACHED_CHAIN_ID;

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    mapping(address => uint256) public override nonces;

    /**
     * @dev Initializes the domain separator using the `name` parameter, and setting `version` to `"1"`.
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __ERC20Permit_init(string memory name_) internal {
        _HASHED_NAME = keccak256(bytes(name_));
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(_EIP712_DOMAIN_TYPEHASH, _HASHED_NAME, _EIP712_VERSION);
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");
        uint256 _currentNonce = nonces[owner];
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _currentNonce, deadline));
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");
        nonces[owner] = _currentNonce + 1;
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() private view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_EIP712_DOMAIN_TYPEHASH, _HASHED_NAME, _EIP712_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 name,
        bytes32 version
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, name, version, block.chainid, address(this)));
    }
}