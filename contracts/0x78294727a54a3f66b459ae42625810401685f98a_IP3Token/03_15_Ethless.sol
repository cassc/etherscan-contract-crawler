// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Ethless
 */

import './ERC20Reservable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';

contract Ethless is ERC20Reservable {
    using ECDSAUpgradeable for bytes32;

    enum EthlessTxnType {
        NONE, // 0
        BURN, // 1
        MINT, // 2
        TRANSFER, // 3
        RESERVE // 4
    }

    mapping(address => mapping(uint256 => mapping(EthlessTxnType => bool))) private _nonceUsed;

    function __Ethless_init_unchained() internal onlyInitializing {}

    function _useNonce(
        address signer_,
        uint256 nonce_,
        EthlessTxnType txnType_
    ) internal {
        require(!_nonceUsed[signer_][nonce_][txnType_], 'Ethless: nonce already used');
        _nonceUsed[signer_][nonce_][txnType_] = true;
    }

    function _validateEthlessHash(
        address signer_,
        bytes32 structHash_,
        bytes memory signature_
    ) internal pure {
        bytes32 messageHash = structHash_.toEthSignedMessageHash();
        address signer = messageHash.recover(signature_);
        require(signer == signer_, 'Ethless: invalid signature');
    }

    function transfer(
        address signer_,
        address to_,
        uint256 amount_,
        uint256 fee_,
        uint256 nonce_,
        bytes calldata signature_
    ) external returns (bool succcess) {
        _useNonce(signer_, nonce_, EthlessTxnType.TRANSFER);

        bytes32 structHash = keccak256(
            abi.encodePacked(EthlessTxnType.TRANSFER, block.chainid, address(this), signer_, to_, amount_, fee_, nonce_)
        );
        _validateEthlessHash(signer_, structHash, signature_);

        if (fee_ > 0) _transfer(signer_, _msgSender(), fee_);
        _transfer(signer_, to_, amount_);
        return true;
    }

    function burn(
        address signer_,
        uint256 amount_,
        uint256 fee_,
        uint256 nonce_,
        bytes calldata signature_
    ) external returns (bool succcess) {
        _useNonce(signer_, nonce_, EthlessTxnType.BURN);

        bytes32 structHash = keccak256(
            abi.encodePacked(EthlessTxnType.BURN, block.chainid, address(this), signer_, amount_, fee_, nonce_)
        );
        _validateEthlessHash(signer_, structHash, signature_);

        if (fee_ > 0) _transfer(signer_, _msgSender(), fee_);
        _burn(signer_, amount_ - fee_);
        return true;
    }

    function reserve(
        address signer_,
        address to_,
        address executor_,
        uint256 amount_,
        uint256 fee_,
        uint256 nonce_,
        uint256 deadline_,
        bytes calldata signature_
    ) external returns (bool succcess) {
        _useNonce(signer_, nonce_, EthlessTxnType.RESERVE);

        bytes32 structHash = keccak256(
            abi.encodePacked(
                EthlessTxnType.RESERVE,
                block.chainid,
                address(this),
                signer_,
                to_,
                executor_,
                amount_,
                fee_,
                nonce_,
                deadline_
            )
        );
        _validateEthlessHash(signer_, structHash, signature_);

        _reserve(signer_, to_, executor_, amount_, fee_, nonce_, deadline_);
        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256 amount) {
        return super.balanceOf(account);
    }

    uint256[50] private __gap;
}