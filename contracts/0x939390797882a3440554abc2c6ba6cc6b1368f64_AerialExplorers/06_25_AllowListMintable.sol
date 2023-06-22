// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./Mintable.sol";
import "../allowlist/AllowList.sol";

abstract contract AllowListMintable is AllowList, Mintable {
    constructor() {}

    /**
     * @dev Mint tokens using a signature
     * @param _count how many tokens to mint
     * @param _signature the signature by the allowance signer wallet
     * @param _nonce the nonce associated to this allowance
     */
    function signatureMint(
        address _address,
        uint256 _count,
        bytes calldata _signature,
        uint256 _nonce
    ) external payable {
        (bool canMint, string memory reason) = _validateSignature(
            _address,
            _count,
            _mintCount(_address),
            _signature,
            _nonce
        );
        require(canMint, reason);
        _useSignature(_address, _count, _signature, _nonce);
        _mint(_address, _count);
    }

    /**
     * @dev can the address mint with signature and nonce?
     * @param _address the address the signature was assigned to
     * @param _count how many tokens to mint
     * @param _signature the signature by the allowance signer wallet
     * @param _nonce the nonce associated to this allowance
     * @return true / false
     */
    function canSignatureMint(
        address _address,
        uint256 _count,
        bytes calldata _signature,
        uint256 _nonce
    ) external view returns (bool) {
        (bool canMint, ) = _validateSignature(
            _address,
            _count,
            _mintCount(_address),
            _signature,
            _nonce
        );
        return canMint;
    }
}