// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IONFT721.sol";
import "./ONFT721Core.sol";
import "../interfaces/IERC2981Royalties.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ONFT721 is ONFT721Core, ERC721, IONFT721, IERC2981Royalties {
    using Strings for uint256;

    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    string public collectionURI;
    string public tokensURI;
    RoyaltyInfo private _royalties;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _collectionURI,
        string memory _tokensURI,
        address _owner,
        uint256 _minGasToTransfer,
        address _lzEndpoint
    ) ERC721(_name, _symbol) ONFT721Core(_minGasToTransfer, _lzEndpoint) {
        collectionURI = _collectionURI;
        tokensURI = _tokensURI;
        owner = _owner;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), collectionURI));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), tokensURI, "/", tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ONFT721Core, ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981Royalties).interfaceId
        || interfaceId == type(IONFT721).interfaceId
        || super.supportsInterface(interfaceId);
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _tokenId) internal virtual override {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "send caller is not owner nor approved");
        require(ERC721.ownerOf(_tokenId) == _from, "send from incorrect owner");
        _transfer(_from, address(this), _tokenId);
    }

    function _creditTo(uint16, address _toAddress, uint _tokenId) internal virtual override {
        require(!_exists(_tokenId) || (_exists(_tokenId) && ERC721.ownerOf(_tokenId) == address(this)));
        if (!_exists(_tokenId)) {
            _safeMint(_toAddress, _tokenId);
        } else {
            _transfer(address(this), _toAddress, _tokenId);
        }
    }

    function setTrustedRemoteAndLimits(
        uint16 _remoteChainId,
        bytes calldata _remoteAddress,
        uint256 _dstChainIdToTransferGas,
        uint256 _dstChainIdToBatchLimit
    ) external onlyOwner {
        require(_dstChainIdToTransferGas > 0, "dstChainIdToTransferGas must be > 0");
        dstChainIdToTransferGas[_remoteChainId] = _dstChainIdToTransferGas;
        require(_dstChainIdToBatchLimit > 0, "dstChainIdToBatchLimit must be > 0");
        dstChainIdToBatchLimit[_remoteChainId] = _dstChainIdToBatchLimit;
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }

    function setRoyaltyAmount(uint24 _amount) external onlyOwner {
        _royalties.amount = _amount;
    }
}