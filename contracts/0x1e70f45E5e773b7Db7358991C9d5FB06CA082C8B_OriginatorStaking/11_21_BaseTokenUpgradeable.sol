// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;

import '../ERCs/ERC677/ERC677Upgradeable.sol';
import '../ERCs/ERC2612/ERC2612Upgradeable.sol';

import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';
contract BaseTokenUpgradeable is Initializable, ERC677Upgradeable, ERC2612Upgradeable {

    function __BaseTokenUpgradeable_init(
        address _initialAccount,
        uint256 _initialBalance,
        string memory _name,
        string memory _symbol,
        string memory _EIP712Name
    ) public initializer {
        __ERC677_init(_initialAccount, _initialBalance, _name, _symbol);
        __ERC2612_init(_EIP712Name);
    }

    function permit(
        address _holder,
        address _spender,
        uint256 _nonce,
        uint256 _expiry,
        bool _allowed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public override {
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(PERMIT_TYPEHASH, _holder, _spender, _nonce, _expiry, _allowed)
                    )
                )
            );
        require(_holder != address(0), 'Token: invalid-address-0');
        require(_holder == ecrecover(digest, _v, _r, _s), 'Token: invalid-permit');
        require(_expiry == 0 || block.timestamp <= _expiry, 'Token: permit-expired');
        require(_nonce == nonces[_holder]++, 'Token: invalid-nonce');
        uint256 _amount =
            _allowed ? 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff : 0;
        _approve(_holder, _spender, _amount);
    }
}