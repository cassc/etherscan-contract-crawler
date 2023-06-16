// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IBNVTokenBase.sol";

/// @title BNV Token Base Contract 
/// @author Sensible Lab
/// @dev based on a standard ERC721, drop id is enforced for each token
abstract contract BNVTokenBase is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, IBNVTokenBase {

    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 constant PERCENTAGE_DECIMAL = 10000;

    // Mapping of drop id to drop URI
    mapping (uint256 => string) private _dropURIs;

    // Mapping of token id to drop id
    mapping(uint256 => uint256) private _dropIds;

    // Mapping of drop Id to beneficiaries address
    mapping(uint256 => EnumerableSet.AddressSet) private _beneficiarySets;

    // Mapping of drop Id to beneficiaries rate
    mapping(uint256 => uint256[]) private _beneficiarySplitSets;

    // royalty rate
    mapping(uint256 => uint256) private _royaltyRate;

    // royalty balance
    mapping(uint256 => uint256) private _royaltyBalance;

    // Last sold price of token
    mapping(uint256 => uint256) private _lastSoldPrice;

    // token lock
    mapping(uint256 => uint256) private _tokenLocked;
    
    // minter
    EnumerableSet.AddressSet private _minters;

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        require(!_isTokenLocked(tokenId), "Token locked");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _dropURI(uint256 tokenId) internal view virtual returns (string memory) {
        if (_dropIds[tokenId] > 0) {
            return _dropURIs[_dropIds[tokenId]];
        }
        return "";
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /// @notice get token URI with drop ID
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory dropURI = _dropURI(tokenId);
        string memory baseTokenURI = super.tokenURI(tokenId);

        // If there is no drop URI, return the token URI from ERC-721. It shouldn't happened.
        if (bytes(dropURI).length == 0) {
            return baseTokenURI;
        }

        if (bytes(baseTokenURI).length > 0) {
            // If both are set, concatenate the drop and tokenURI (via abi.encodePacked).
            return string(abi.encodePacked(dropURI, baseTokenURI));
        } else {
            return dropURI;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice disable approve
    function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        require(!_isTokenLocked(tokenId), "Token locked");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721) {
        super.setApprovalForAll(operator, approved);
    }

    /// @notice disable transfer from
    function transferFrom(address /* from */, address /* to */, uint256 /* tokenId */) public virtual override(ERC721, IERC721) {
        revert("Use transferWithRoyalty");
    }

    /// @notice safe transfer from only allow for whitelist and us
    function safeTransferFrom(address /* from */, address /* to */, uint256 /* tokenId */, bytes memory /* _data */) public virtual override(ERC721, IERC721) {
        revert("Use transferWithRoyalty");
    }

    /// @notice set last sold price
    function setLastSoldPrice(uint256 tokenId, uint256 lastSoldPrice) public virtual override onlyOwner {
        _lastSoldPrice[tokenId] = lastSoldPrice;
    }
    /// @notice mint token
    /// @dev Only `Owner` or `BNV address` can mint
    function mint(address to, uint256 tokenId, uint256 dropId, string memory uri, uint lastSoldPrice) public virtual override {
        require(owner() == _msgSender() || _minters.contains(_msgSender()), "Minting not allowed");
        // check parameters are valid
        require(!_exists(tokenId), "Token already exists");
        require(bytes(uri).length > 0, "URI is empty");
        // call ERC721 safe mint
        _safeMint(to, tokenId);
        // set token URI
        _setTokenURI(tokenId, uri);
        // map token Id to drop Id
        _dropIds[tokenId] = dropId;

        _lastSoldPrice[tokenId] = lastSoldPrice;
    }

    /// @notice burn token
    /// @dev Only `Owner` or `BNV address` can mint
    function burn(uint256 tokenId) public virtual onlyOwner {
        require(!_isTokenLocked(tokenId), "Token locked");
        // call ERC721 burn
        _burn(tokenId);
        // set drop id for this token to 0
        _dropIds[tokenId] = 0;
        // set last sold price to 0
        _lastSoldPrice[tokenId] = 0;
    }

    /// @notice transfer with royalty fee paid
    function transferWithRoyalty(address to, uint256 tokenId) public payable virtual override {
        require(_exists(tokenId), "Token does not exist");
        require(!_isTokenLocked(tokenId), "Token locked");
        require(royaltyPayableOf(tokenId) <= msg.value, "Insufficient royalty");
        // transfer token, check whether token approved
        super.safeTransferFrom(_msgSender(), to, tokenId, "");
        // add value to royalty balance
        _royaltyBalance[tokenId] += msg.value;
        // split royalty to beneficiaries
        _splitRoyaltyForBeneficiaries(tokenId, _royaltyBalance[tokenId]);
    }

    /// @notice allow anyone to paid for royalty
    function payRoyalty(uint256 tokenId) public payable virtual override {
        require(!_isTokenLocked(tokenId), "Token locked");
        // add value to royalty balance
        _royaltyBalance[tokenId] += msg.value;
        // emit royalty added event
        emit RoyaltyPaid(tokenId, _msgSender(), msg.value);
    }

    // VIEW ONLY =======================================

    /// @notice get royalty fee of token
    /// @dev equation: (price * rate / decimal) - balance = remaining royalty that needs to pay
    function royaltyPayableOf(uint256 tokenId) public view virtual override returns (uint256) {
        uint256 royaltyPayable = _lastSoldPrice[tokenId] * _royaltyRate[_dropIds[tokenId]] / PERCENTAGE_DECIMAL;
        if (royaltyPayable >= _royaltyBalance[tokenId]) {
            return royaltyPayable - _royaltyBalance[tokenId];
        } else {
            return 0;
        }
    }

    /// @notice get royalty rate of drop
    function royaltyRateOf(uint256 dropId) public view virtual override returns (uint256) {
        return _royaltyRate[dropId];
    }

    /// @notice check token id exists
    function exists(uint256 tokenId) public view virtual override returns (bool) {
        return _exists(tokenId);
    }

    /// @notice drop id of that token
    function dropOf(uint256 tokenId) public view virtual override returns (uint256) {
        return _dropIds[tokenId];
    }

    /// @notice beneficiaries of `dropId`
    function beneficiariesOf(uint256 dropId) public view virtual override returns (address[] memory) {
        address[] memory arr = new address[](_beneficiarySets[dropId].length());
        for (uint i = 0; i < _beneficiarySets[dropId].length(); i++) {
            arr[i] = _beneficiarySets[dropId].at(i);
        }
        return arr;
    }

    /// @notice beneficiaries splits of `dropId`
    function beneficiarySplitsOf(uint256 dropId) public view virtual override returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](_beneficiarySplitSets[dropId].length);
        for (uint i = 0; i < _beneficiarySplitSets[dropId].length; i++) {
            arr[i] = _beneficiarySplitSets[dropId][i];
        }
        return arr;
    }

    /// @notice get last sold price
    function lastSoldPriceOf(uint256 tokenId) public view virtual override returns (uint256) {
        return _lastSoldPrice[tokenId];
    }

    /// @notice get token lock
    function getTokenLock(uint256 tokenId) public view virtual override returns (uint256) {
        return _tokenLocked[tokenId];
    }

    // ADMIN =======================================

    /// @notice Set drop URI, onlyOwner
    function _setDropURI(uint256 dropId, string memory newUri) public virtual onlyOwner {
        _dropURIs[dropId] = newUri;
    }

    /// @notice allow owner of this contract to transfer any token for the sake of emergency use
    function _transferFrom(address from, address to, uint256 tokenId) public virtual onlyOwner {
        require(!_isTokenLocked(tokenId), "Token locked");
        _transfer(from, to, tokenId);
    }

    /// @notice update token royalty balance
    function _setRoyaltyBalance(uint256 tokenId, uint256 balance) public virtual onlyOwner {
        _royaltyBalance[tokenId] = balance;
    }

    /// @notice withdraw from this contract
    function _withdraw(uint256 amount) public virtual onlyOwner {
        Address.sendValue(payable(owner()), amount);
    }

    /// @notice add drop info
    function _addDrop(uint256 dropId, uint256 rate, address[] memory beneficiaries, uint256[] memory beneficiarySplits) public virtual onlyOwner {
        require(beneficiaries.length == beneficiarySplits.length, "Invalid beneficiary data");
        // set royalty rate for drop
        _royaltyRate[dropId] = rate;

        // add to beneficiaries
        _addBeneficiaries(dropId, beneficiaries, beneficiarySplits);
    }

    /// @notice set beneficiaries
    function _setBeneficiaries(uint256 dropId, address[] memory beneficiaries, uint256[] memory beneficiarySplits) public virtual onlyOwner {
        // remove existing
        while (_beneficiarySets[dropId].length() > 0) {
            _beneficiarySets[dropId].remove(_beneficiarySets[dropId].at(0));
            _beneficiarySplitSets[dropId].pop();
        }
        // add to beneficiaries
        _addBeneficiaries(dropId, beneficiaries, beneficiarySplits);
    }


    /// @notice lock token for doing things
    /// @dev 0 = unlock, 1 or more = locked by some parties
    function _setTokenLock(uint256 tokenId, uint256 parties) public virtual onlyOwner {
        _tokenLocked[tokenId] = parties;
        // Clear approval
        _approve(address(0), tokenId);
    }

    // PRIVATE =======================================

    /// @notice add beneficiaries
    function _addBeneficiaries(uint256 dropId, address[] memory beneficiaries, uint256[] memory beneficiarySplits) internal virtual {
        // add beneficiaries
        for (uint i = 0; i < beneficiaries.length; i++) {
            _beneficiarySets[dropId].add(beneficiaries[i]);
            _beneficiarySplitSets[dropId].push(beneficiarySplits[i]);
        }
    }

    /// @notice calculate beneficiaries split
    function _splitRoyaltyForBeneficiaries(uint256 tokenId, uint256 amount) internal virtual {
        // distribute to each beneficiary address
        for (uint i = 0; i < _beneficiarySets[_dropIds[tokenId]].length(); i++) {
            uint256 splitAmount = amount * _beneficiarySplitSets[_dropIds[tokenId]][i] / PERCENTAGE_DECIMAL;
            Address.sendValue(payable(_beneficiarySets[_dropIds[tokenId]].at(i)), splitAmount);

            // emit royalty distributed event
            emit RoyaltyDistributed(tokenId, _beneficiarySets[_dropIds[tokenId]].at(i), splitAmount);
        }
        // reset royalty balance to zero
        _royaltyBalance[tokenId] = 0;
    }

    /// @notice check is token get locked
    function _isTokenLocked(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenLocked[tokenId] != 0;
    }
    
    // Adding minter
    function _addMinter(address minter) external onlyOwner {
        _minters.add(minter);
    }

    // Assign Token Owner
    function _assignTokenOwner(uint256 tokenId, address newOwner) external onlyOwner {
        super._transfer(ownerOf(tokenId), newOwner, tokenId);
    }

}