/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

interface IKryptoriaLand {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID,
        bytes memory _data
    ) external;
}

interface IKryptoriaWeapons {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID,
        bytes memory _data
    ) external;
}

contract AssetBuyBack {
    address public _addressKryptoriaLand;
    address public _addressKryptoriaWeapons;
    address private _signerAddress;
    address private _communityAddress;
    address private _owner;

    constructor(
        address signerAddress_,
        address communityAddress_,
        address addressKryptoriaLand_,
        address addressKryptoriaWeapons_
    ) {
        _addressKryptoriaLand = addressKryptoriaLand_;
        _addressKryptoriaWeapons = addressKryptoriaWeapons_;
        _owner = msg.sender;
        setSignerAddress(signerAddress_);
        setCommunityAddress(communityAddress_);
    }

    event assetTransfer(
        uint[] landIds,
        uint[] weaponIds,
        address indexed owner,
        uint time,
        string transactionId
    );

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only Owner");
        _;
    }

    function signerAddress() public view returns (address) {
        return _signerAddress;
    }

    function communityAddress() public view returns (address) {
        return _communityAddress;
    }

    function setSignerAddress(address address_) public onlyOwner {
        _signerAddress = address_;
    }

    function setCommunityAddress(address address_) public onlyOwner {
        _communityAddress = address_;
    }

    function assetTransfers(
        uint[] calldata land_,
        uint[] calldata weapons_,
        uint256 timestamp_,
        string calldata transactionId_,
        bytes calldata sig_
    ) external {
        require(block.timestamp <= timestamp_ + (15 * 60), "stale request");
        require(
            !(land_.length == 0 && weapons_.length == 0),
            "land and weapons array are null"
        );
        require(
            isValidSignature(
                timestamp_,
                msg.sender,
                land_,
                weapons_,
                transactionId_,
                sig_
            ),
            "signature validation failed"
        );
        if (land_.length == 0) {
            transferWeapons(weapons_, msg.sender);
        } else if (weapons_.length == 0) {
            transferLand(land_, msg.sender);
        } else {
            transferLand(land_, msg.sender);
            transferWeapons(weapons_, msg.sender);
        }

        emit assetTransfer(
            land_,
            weapons_,
            msg.sender,
            block.timestamp,
            transactionId_
        );
    }

    function transferLand(uint[] calldata land_, address to_) internal {
        for (uint i = 0; i < land_.length; i++) {
            IKryptoriaLand(_addressKryptoriaLand).safeTransferFrom(
                _communityAddress,
                to_,
                land_[i],
                ""
            );
        }
    }

    function transferWeapons(uint[] calldata weapons_, address to_) internal {
        for (uint i = 0; i < weapons_.length; i++) {
            IKryptoriaWeapons(_addressKryptoriaWeapons).safeTransferFrom(
                _communityAddress,
                to_,
                weapons_[i],
                ""
            );
        }
    }

    function isValidSignature(
        uint256 timestamp_,
        address walletAddress_,
        uint[] calldata land_,
        uint[] calldata weapons_,
        string calldata transactionId_,
        bytes calldata sig_
    ) internal view returns (bool) {
        bytes32 message = keccak256(
            abi.encodePacked(
                timestamp_,
                walletAddress_,
                land_,
                weapons_,
                transactionId_
            )
        );
        return (recoverSigner(message, sig_) == _signerAddress);
    }

    function recoverSigner(
        bytes32 message_,
        bytes memory sig_
    ) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig_);
        return ecrecover(message_, v, r, s);
    }

    function splitSignature(
        bytes memory sig_
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig_.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // First 32 bytes, after the length prefix
            r := mload(add(sig_, 32))

            // Second 32 bytes
            s := mload(add(sig_, 64))

            // Sinal byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig_, 96)))
        }
        return (v, r, s);
    }
}