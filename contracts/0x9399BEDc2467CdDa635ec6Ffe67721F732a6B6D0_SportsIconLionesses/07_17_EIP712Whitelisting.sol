//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EIP712Whitelisting is Ownable {
    using ECDSA for bytes32;

    uint16 private constant MAX_WHITELIST_LENGTH = 512;
    string private constant CONTRACT_NAME = "SportsIconLionesses";

    address private whitelistSigner;
    bytes32 private domainSeparator;
    // EVM uses 8 bits to store one boolean.
    // Instead of using array of booleans we use array of uint8.
    // Thanks to this we store 8 times less data.
    uint8[MAX_WHITELIST_LENGTH / 8] private alreadyWithdrawn;

    error InvalidSignature();
    error AlreadyWithdrawn();
    error IndexAboveLimit();

    constructor(address _whitelistSigner) {
        domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(CONTRACT_NAME)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        whitelistSigner = _whitelistSigner;
    }

    modifier onlyWhitelisted(
        bytes calldata signature,
        uint8 amount,
        uint16 index,
        uint256 salt
    ) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        keccak256(
                            "Minter(address wallet,uint8 amount,uint16 index,uint256 salt)"
                        ),
                        msg.sender,
                        amount,
                        index,
                        salt
                    )
                )
            )
        );

        address recoveredAddress = digest.recover(signature);
        if (recoveredAddress != whitelistSigner) {
            revert InvalidSignature();
        }
        _;
    }

    modifier onlyNotWithdrawn(uint16 whitelistIndex_) {
        if (isAlreadyWithdrawn(whitelistIndex_)) {
            revert AlreadyWithdrawn();
        }
        _setAlreadyWithdrawn(whitelistIndex_);
        _;
    }

    function isAlreadyWithdrawn(uint16 whitelistAccountIndex_)
        public
        view
        returns (bool)
    {
        if (whitelistAccountIndex_ >= MAX_WHITELIST_LENGTH) {
            revert IndexAboveLimit();
        }
        uint16 groupIndex = whitelistAccountIndex_ / 8;
        uint8 elementIndex = uint8(whitelistAccountIndex_ % 8);
        uint8 flag = (alreadyWithdrawn[groupIndex] >> elementIndex) & uint8(1);

        return flag == 1;
    }

    function getAlreadyWithdrawn()
        public
        view
        returns (uint8[MAX_WHITELIST_LENGTH / 8] memory)
    {
        return alreadyWithdrawn;
    }

    function _setAlreadyWithdrawn(uint16 whitelistAccountIndex_) private {
        uint16 groupIndex = whitelistAccountIndex_ / 8;
        uint8 elementIndex = uint8(whitelistAccountIndex_ % 8);
        uint8 bitMask = uint8(1) << elementIndex;

        alreadyWithdrawn[groupIndex] |= bitMask;
    }
}