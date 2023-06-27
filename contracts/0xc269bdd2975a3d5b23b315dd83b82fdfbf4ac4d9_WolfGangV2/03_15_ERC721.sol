// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/[email protected]/GSN/Context.sol";
import "@openzeppelin/[email protected]/token/ERC721/IERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/[email protected]/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/[email protected]/introspection/ERC165.sol";
import "@openzeppelin/[email protected]/math/SafeMath.sol";
import "@openzeppelin/[email protected]/utils/Address.sol";
import "@openzeppelin/[email protected]/utils/EnumerableSet.sol";
import "@openzeppelin/[email protected]/utils/EnumerableMap.sol";
import "@openzeppelin/[email protected]/utils/Strings.sol";

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    EnumerableMap.UintToAddressMap private _tokenOwners;
    
    mapping (uint256 => bool) private _burntTokens;
    
    uint private _burntTokensLength = 0;
    
    uint internal _nextTokenId = 10000;
    
    mapping (uint256 => bool) private _tokenMigrated;

    mapping (uint256 => address) private _tokenApprovals;

    mapping (address => mapping (address => bool)) private _operatorApprovals;

    string private _name;

    string private _symbol;

    mapping (uint256 => string) private _tokenURIs;

    string private _baseURI;
    
    ERC721 private _oldContract;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor (string memory name_, string memory symbol_, ERC721 oldContract_) public {
        _name = name_;
        _symbol = symbol_;
        _oldContract = oldContract_;

        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        uint oldBalance = _oldContract.balanceOf(owner);
        uint oldActive = 0;
        for (uint i = 0; i < oldBalance; i++) {
            uint tokenId = _oldContract.tokenOfOwnerByIndex(owner, i);
            if (!_tokenMigrated[tokenId]) oldActive++;
        }
        return _holderTokens[owner].length().add(oldActive);
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (tokenId < 10000) {
            if (_tokenOwners.contains(tokenId) || _burntTokens[tokenId]) {
                return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
            } else {
                return _oldContract.ownerOf(tokenId);
            }
        }
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }
    
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (_holderTokens[owner].length() > index) return _holderTokens[owner].at(index);
        uint newIndex = index - _holderTokens[owner].length();
        uint oldBalance = _oldContract.balanceOf(owner);
        uint oldActive = 0;
        uint i;
        for (i = 0; i < oldBalance; i++) {
            if (!_tokenMigrated[_oldContract.tokenOfOwnerByIndex(owner, i)]) {
                if (oldActive == newIndex) return _oldContract.tokenOfOwnerByIndex(owner, i);
                oldActive++;
            }
        }
        
        return _holderTokens[owner].at(index);
    }

    function totalSupply() public view override virtual returns (uint256) {
        return _nextTokenId - _burntTokensLength;
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < totalSupply(), "out of bounds");
        uint active = 0;
        uint i;
        for (i = 0; i < index; i++) {
            if (!_burntTokens[i]) active++;
        }
        return active;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        if (tokenId < 10000 && !_burntTokens[tokenId]) return true;
        return _tokenOwners.contains(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);
        
        _burntTokens[tokenId] = true;
        _tokenMigrated[tokenId] = true;
        _burntTokensLength++;

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);
        
        _tokenMigrated[tokenId] = true;

        emit Transfer(from, to, tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}