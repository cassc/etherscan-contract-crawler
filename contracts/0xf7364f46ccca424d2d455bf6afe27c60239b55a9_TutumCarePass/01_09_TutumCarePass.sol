// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error MintTotalLimitExceed();
error MintWalletLimitExceed();
error MintSignatureMismatch();
error MintStageMismatch();
error MintTimeTooLate();

contract TutumCarePass is ERC721A, Ownable {
    using ECDSA for bytes32;

    uint256 immutable validityPeriod = 30 days;

    uint256 immutable maxSupply = 1000;

    uint256 private immutable _timeUnit = 1 hours;

    uint256 private immutable _startTimestamp;

    string private _imageURI;

    string private _expiredImageURI;

    address private _signer;

    event InsuranceClaimed(bytes32 transactionHash);

    constructor(
        address signer,
        string memory imageURI,
        string memory expiredImageURI
    ) ERC721A("TutumCarePass", "TCP") {
        _startTimestamp = block.timestamp;
        _signer = signer;
        _imageURI = imageURI;
        _expiredImageURI = expiredImageURI;
        _mint();
    }

    function _expireAt(uint256 tokenId) internal view returns (uint256) {
        return _ownershipOf(tokenId).extraData * _timeUnit + _startTimestamp;
    }

    function _mint() internal {
        if (_numberMinted(msg.sender) > 0) {
            revert MintWalletLimitExceed();
        }

        uint256 tokenId = _nextTokenId();
        if (tokenId >= maxSupply) {
            revert MintTotalLimitExceed();
        }

        uint256 extraData = (block.timestamp +
            validityPeriod -
            _startTimestamp) / _timeUnit;
        if (extraData > type(uint24).max) {
            revert MintTimeTooLate();
        }

        _mint(msg.sender, 1);
        _setExtraDataAt(tokenId, uint24(extraData));
    }

    function privateMint(bytes calldata signature) external {
        if (
            keccak256(abi.encodePacked(msg.sender))
                .toEthSignedMessageHash()
                .recover(signature) != _signer
        ) {
            revert MintSignatureMismatch();
        }

        _mint();
    }

    function publicMint() external {
        if (_signer != address(0)) {
            revert MintStageMismatch();
        }

        _mint();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 expireAt = _expireAt(tokenId);
        bool expired = block.timestamp > expireAt;
        bytes memory dataURI = abi.encodePacked(
            '{"name":"Tutum Care Pass #',
            _toString(tokenId),
            '","image":"',
            expired ? _expiredImageURI : _imageURI,
            '","attributes":[{"display_type":"date","trait_type":"Expire At","value":',
            _toString(expireAt),
            '},{"trait_type":"Status","value":"',
            expired ? "Expired" : "Valid",
            '"}]}'
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function setImageURI(string calldata imageURI) external onlyOwner {
        _imageURI = imageURI;
    }

    function setExpiredImageURI(string calldata expiredImageURI)
        external
        onlyOwner
    {
        _expiredImageURI = expiredImageURI;
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }
}