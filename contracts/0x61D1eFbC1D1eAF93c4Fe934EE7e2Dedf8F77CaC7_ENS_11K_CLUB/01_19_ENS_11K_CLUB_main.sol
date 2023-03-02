// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./DefaultOperatorFilterer.sol";

contract ENS_11K_CLUB is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    DefaultOperatorFilterer
{
    mapping(uint256 => uint256) public digitHash;
    IERC721 private immutable _ENS;
    string private _baseURIextended;

    constructor(IERC721 contractENS, string memory ensBaseURI) ERC721("ENS 11K CLUB", "W11K") {
        _ENS = contractENS;
        _baseURIextended = ensBaseURI;
    }

    function ENS() public view virtual returns (IERC721) {
        return _ENS;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(digitHash[tokenId])
                    )
                )
                : "";
    }

    function wrap999(string[] calldata digits)
        external
        whenNotPaused
        returns (bool)
    {
        uint256 length = digits.length;
        for (uint256 i = 0; i < length; ++i) {
            (uint256 digit, bool hasError) = strToUint(digits[i]);
            require(
                bytes(digits[i]).length == 3 &&
                    hasError == false &&
                    digit < 1000,
                "invalid string"
            );
            uint256 tokenId = digit + 10_000;
            digitHash[tokenId] = uint256(keccak256(bytes(digits[i])));
            // This is an "unsafe" transfer that doesn't call any hook on the receiver. With ENS() being trusted
            // (by design of this contract) and no other contracts expected to be called from there, we are safe.
            // slither-disable-next-line reentrancy-no-eth
            ENS().transferFrom(msg.sender, address(this), digitHash[tokenId]);
            if (_exists(tokenId) == true) {
                _burn(tokenId);
            }
            _safeMint(msg.sender, tokenId);
        }

        return true;
    }

    function wrap10k(string[] calldata digits)
        external
        whenNotPaused
        returns (bool)
    {
        uint256 length = digits.length;
        for (uint256 i = 0; i < length; ++i) {
            (uint256 tokenId, bool hasError) = strToUint(digits[i]);
            require(
                bytes(digits[i]).length == 4 &&
                    hasError == false &&
                    tokenId < 10_000,
                "invalid string"
            );
            digitHash[tokenId] = uint256(keccak256(bytes(digits[i])));
            // This is an "unsafe" transfer that doesn't call any hook on the receiver. With underlying() being trusted
            // (by design of this contract) and no other contracts expected to be called from there, we are safe.
            // slither-disable-next-line reentrancy-no-eth
            ENS().transferFrom(msg.sender, address(this), digitHash[tokenId]);
            if (_exists(tokenId) == true) {
                _burn(tokenId);
            }
            _safeMint(msg.sender, tokenId);
        }

        return true;
    }

    function unwrap(uint256[] calldata tokenIds) external returns (bool) {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            require(
                _isApprovedOrOwner(msg.sender, tokenIds[i]),
                "ERC721: caller is not token owner or approved"
            );
            _burn(tokenIds[i]);
            ENS().safeTransferFrom(
                address(this),
                msg.sender,
                digitHash[tokenIds[i]]
            );
        }

        return true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function strToUint(string calldata _str)
        internal
        pure
        returns (uint256 res, bool err)
    {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if (
                (uint8(bytes(_str)[i]) - 48) < 0 ||
                (uint8(bytes(_str)[i]) - 48) > 9
            ) {
                return (0, true);
            }
            res +=
                (uint8(bytes(_str)[i]) - 48) *
                10**(bytes(_str).length - i - 1);
        }
        return (res, false);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        require(
            ENS().ownerOf(digitHash[tokenId]) == address(this),
            "domain expired"
        );
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}