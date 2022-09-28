// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IERC20Permit.sol";
import "./BaseERC20.sol";
import "../utils/EIP712.sol";

/**
 * @title ERC20Permit
 */
abstract contract ERC20Permit is IERC20Permit, BaseERC20, EIP712 {
    // EIP2612 permit typehash
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    // Custom "salted" permit typehash
    // Works exactly the same as EIP2612 permit, except that includes an additional salt,
    // which should be explicitly signed by the user, as part of the permit message.
    bytes32 public constant SALTED_PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline,bytes32 salt)");

    mapping(address => uint256) public nonces;

    constructor(address _self) EIP712(_self, name(), "1") {}

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev Allows to spend holder's unlimited amount by the specified spender according to EIP2612.
     * The function can be called by anyone, but requires having allowance parameters
     * signed by the holder according to EIP712.
     * @param _holder The holder's address.
     * @param _spender The spender's address.
     * @param _value Allowance value to set as a result of the call.
     * @param _deadline The deadline timestamp to call the permit function. Must be a timestamp in the future.
     * Note that timestamps are not precise, malicious miner/validator can manipulate them to some extend.
     * Assume that there can be a 900 seconds time delta between the desired timestamp and the actual expiration.
     * @param _v A final byte of signature (ECDSA component).
     * @param _r The first 32 bytes of signature (ECDSA component).
     * @param _s The second 32 bytes of signature (ECDSA component).
     */
    function permit(
        address _holder,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        _checkPermit(_holder, _spender, _value, _deadline, _v, _r, _s);
        _approve(_holder, _spender, _value);
    }

    /**
     * @dev Cheap shortcut for making sequential calls to permit() + transferFrom() functions.
     */
    function receiveWithPermit(
        address _holder,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        virtual
    {
        _checkPermit(_holder, msg.sender, _value, _deadline, _v, _r, _s);

        // we don't make calls to _approve to avoid unnecessary storage writes
        // however, emitting ERC20 events is still desired
        emit Approval(_holder, msg.sender, _value);
        emit Approval(_holder, msg.sender, 0);

        _transfer(_holder, msg.sender, _value);
    }

    /**
     * @dev Salted permit modification.
     */
    function saltedPermit(
        address _holder,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        bytes32 _salt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        _checkSaltedPermit(_holder, _spender, _value, _deadline, _salt, _v, _r, _s);
        _approve(_holder, _spender, _value);
    }

    /**
     * @dev Cheap shortcut for making sequential calls to saltedPermit() + transferFrom() functions.
     */
    function receiveWithSaltedPermit(
        address _holder,
        uint256 _value,
        uint256 _deadline,
        bytes32 _salt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        virtual
    {
        _checkSaltedPermit(_holder, msg.sender, _value, _deadline, _salt, _v, _r, _s);

        // we don't make calls to _approve to avoid unnecessary storage writes
        // however, emitting ERC20 events is still desired
        emit Approval(_holder, msg.sender, _value);
        emit Approval(_holder, msg.sender, 0);

        _transfer(_holder, msg.sender, _value);
    }

    function _checkPermit(
        address _holder,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        private
    {
        require(block.timestamp <= _deadline, "ERC20Permit: expired permit");

        uint256 nonce = nonces[_holder]++;
        bytes32 digest = ECDSA.toTypedDataHash(
            _domainSeparatorV4(), keccak256(abi.encode(PERMIT_TYPEHASH, _holder, _spender, _value, nonce, _deadline))
        );

        require(_holder == ECDSA.recover(digest, _v, _r, _s), "ERC20Permit: invalid ERC2612 signature");
    }

    function _checkSaltedPermit(
        address _holder,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        bytes32 _salt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        private
    {
        require(block.timestamp <= _deadline, "ERC20Permit: expired permit");

        uint256 nonce = nonces[_holder]++;
        bytes32 digest = ECDSA.toTypedDataHash(
            _domainSeparatorV4(),
            keccak256(abi.encode(SALTED_PERMIT_TYPEHASH, _holder, _spender, _value, nonce, _deadline, _salt))
        );

        require(_holder == ECDSA.recover(digest, _v, _r, _s), "ERC20Permit: invalid signature");
    }
}