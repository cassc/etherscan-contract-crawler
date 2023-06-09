// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract WrappedHypeBears is ERC721("Wrapped HypeBears", "WHB"), ERC721Enumerable, Ownable, IERC721Receiver {
    using SafeMath for uint256;
    using Strings for uint256;

    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    string private baseURI;
    uint256 private constant TOTAL_NFT = 10000;
    IERC721 main;

    constructor(address _main,string memory _baseURI) {
        main = IERC721(_main);
        baseURI = _baseURI;
    }

    function setURIs(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function _wrapNFT(uint256 _tokenId, address _holder) private {
        require(main.ownerOf(_tokenId) == _holder, "Not the owner");
        require(main.isApprovedForAll(_holder, address(this)), "Not approved");
        main.safeTransferFrom(_holder, address(this), _tokenId);
        if (!_exists(_tokenId)) {
            _safeMint(_holder, _tokenId);
        } else if (ownerOf(_tokenId) == address(this)) {
            _approve(_holder, _tokenId);
            safeTransferFrom(address(this), _holder, _tokenId);
        }
    }

    function _unWrapNFT(uint256 _tokenId, address _holder) private {
        require(ownerOf(_tokenId) == _holder, "Not the owner");
        require(main.ownerOf(_tokenId) == address(this), "Not the owner");
        main.safeTransferFrom(address(this), _holder, _tokenId);
        safeTransferFrom(_holder, address(this), _tokenId);
    }

    function wrapNFT(uint256 _tokenId) public {
        _wrapNFT(_tokenId, msg.sender);
    }

    function unWrapNFT(uint256 _tokenId) public {
        _unWrapNFT(_tokenId, msg.sender);
    }

    function wrapNFTMulti(uint256[] memory _tokenIds) public {
        uint len = _tokenIds.length;
        require(len <= 50 && len > 0, "Can't wrap more than 50");
        for (uint256 i = 0; i < len; i++) {
            _wrapNFT(_tokenIds[i], msg.sender);
        }
    }

    function unWrapNFTMulti(uint256[] memory _tokenIds) public {
        uint len = _tokenIds.length;
        require(len <= 50 && len > 0, "Can't unwrap more than 50");
        for (uint256 i = 0; i < len; i++) {
            _unWrapNFT(_tokenIds[i], msg.sender);
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
            return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function supportsInterface(bytes4 _interfaceId) public view override (ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function isApprovedForAll(address owner, address operator) override public view returns(bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistryAddress == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}