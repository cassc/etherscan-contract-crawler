// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Consumable.sol";
import "./HasSecondarySaleFees.sol";
import "./Verifier.sol";

contract GravitonTorrentERC721 is
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Consumable,
    Ownable,
    HasSecondarySaleFees,
    Verifier
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    // Mapping from token ID to creator address;
    mapping(uint256 => address) public creatorOf;

    // Mapping from token ID to torrent magnet links
    mapping(uint256 => string) public torrentMagnetLinkOf;

    Fee[] public collectionFees;

    // Graviton tNFT signer address
    address private _tnftSigner;

    event GravitonTorrentERC721TokenMinted(
        uint256 tokenId,
        string tokenURI,
        address receiver,
        uint256 time
    );

    modifier onlyCreator(uint256 tokenId) {
        require(msg.sender == creatorOf[tokenId], "E01");
        _;
    }

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _signer,
        address payable[] memory _feeRecipients,
        uint96[] memory _feeValues
    ) ERC721(_tokenName, _tokenSymbol) {
        _tnftSigner = _signer;
        require(_feeRecipients.length == _feeValues.length, "E06");
        uint256 sum = 0;
        for (uint256 i = 0; i < _feeRecipients.length; i++) {
            require(_feeRecipients[i] != address(0x0), "E03");
            require(_feeValues[i] != 0, "E04");
            sum = sum + _feeValues[i];
            collectionFees.push(Fee({
                recipient: _feeRecipients[i],
                value: _feeValues[i]
            }));
        }
        require(sum <= 10000, "E05");
    }

    function updateTorrentMagnetLink(
        uint256 _tokenId,
        string memory _torrentMagnetLink
    ) external virtual onlyCreator(_tokenId) returns (string memory) {
        torrentMagnetLinkOf[_tokenId] = _torrentMagnetLink;

        return _torrentMagnetLink;
    }

    function ownedTokens(address ownerAddress)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenBalance = balanceOf(ownerAddress);
        uint256[] memory tokens = new uint256[](tokenBalance);

        for (uint256 i = 0; i < tokenBalance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(ownerAddress, i);
            tokens[i] = tokenId;
        }

        return tokens;
    }

    function mint(
        address receiver,
        string memory newTokenURI,
        Fee[] memory fees,
        string memory torrentMagnetLink,
        Verifier.Signature memory signature
    ) public virtual onlyOwner returns (uint256) {
        return
            _mintTorrent(
                receiver,
                newTokenURI,
                fees,
                torrentMagnetLink,
                signature
            );
    }

    function _mintTorrent(
        address receiver,
        string memory newTokenURI,
        Fee[] memory fees,
        string memory torrentMagnetLink,
        Verifier.Signature memory signature
    ) internal returns (uint256) {
        _tokenIds.increment();
        address signer = _verifyString(torrentMagnetLink, signature);
        require(signer == _tnftSigner, "E07");

        uint256 newItemId = _tokenIds.current();
        _mint(receiver, newItemId);
        _setTokenURI(newItemId, newTokenURI);
        if (fees.length > 0 || collectionFees.length > 0) {
            _registerFees(newItemId, fees);
        }
        // We use tx.origin to set the creator, as there are cases when a contract can call this funciton
        creatorOf[newItemId] = tx.origin;
        torrentMagnetLinkOf[newItemId] = torrentMagnetLink;

        emit GravitonTorrentERC721TokenMinted(
            newItemId,
            newTokenURI,
            receiver,
            block.timestamp
        );
        return newItemId;
    }

    function _registerFees(uint256 _tokenId, Fee[] memory _fees) internal {
        require((_fees.length + collectionFees.length) <= 6, "E02");
        address[] memory recipients = new address[](_fees.length + collectionFees.length);
        uint256[] memory bps = new uint256[](_fees.length + collectionFees.length);
        uint256 sum = 0;
        for (uint256 i = 0; i < _fees.length; i++) {
            require(_fees[i].recipient != address(0x0), "E03");
            require(_fees[i].value != 0, "E04");
            sum = sum + _fees[i].value;
            fees[_tokenId].push(_fees[i]);
            recipients[i] = _fees[i].recipient;
            bps[i] = _fees[i].value;
        }
        for (uint256 i = 0; i < collectionFees.length; i++) {
            sum = sum + collectionFees[i].value;
            fees[_tokenId].push(collectionFees[i]);
            recipients[i] = collectionFees[i].recipient;
            bps[i] = collectionFees[i].value;
        }
        require(sum <= 10000, "E05");
        if ((_fees.length + collectionFees.length) > 0) {
            emit SecondarySaleFees(_tokenId, recipients, bps);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721, ERC721Enumerable, ERC721Consumable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721URIStorage, ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721URIStorage, ERC721)
    {
        return super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721, ERC721Consumable) {
        return super._beforeTokenTransfer(from, to, tokenId);
    }
}