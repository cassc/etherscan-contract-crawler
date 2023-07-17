// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

struct DPVoucher {
    uint256 tokenId;
    address creator;
    string tokenURI;
    uint256 expiration;
}

contract DigitalPaintVoucher is EIP712 {
    constructor(string memory name, string memory version)
        EIP712(name, version)
    {}

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _getVoucherHash(DPVoucher memory voucher)
        public
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "DPVoucher(uint256 tokenId,address creator,string tokenURI,uint256 expiration)"
                        ),
                        voucher.tokenId,
                        voucher.creator,
                        keccak256(bytes(voucher.tokenURI)),
                        voucher.expiration
                    )
                )
            );
    }

    function _recoverSigner(DPVoucher memory voucher, bytes memory signature)
        internal
        view
        returns (address)
    {
        bytes32 digest = _getVoucherHash(voucher);
        return ECDSA.recover(digest, signature);
    }
}