// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract OpenSeaStorefront {
    function balanceOf(address owner, uint256 cardId)
        external
        view
        virtual
        returns (uint256 balance);
}

contract MythDivisionExclusiveAccess is Ownable {
    using SafeMath for uint256;

    OpenSeaStorefront private opensea;

    uint256[] _mythDivisionOpenseaTokens;
    mapping(uint256 => uint256) private _mythDivisionOpenseaTokensIndex;

    address[] _eligibleERC721Contracts;
    mapping(address => uint256) private _eligibleERC721ContractsIndex;

    constructor(address osStorefront) {
        opensea = OpenSeaStorefront(osStorefront);
    }

    function addMythDivisionOpenSeaToken(uint256 tokenId) public onlyOwner {
        if (
            _mythDivisionOpenseaTokens.length > 0 &&
            _mythDivisionOpenseaTokensIndex[tokenId] == 0
        ) {
            require(
                tokenId != _mythDivisionOpenseaTokens[0],
                "Already present in the list"
            );
        }

        _mythDivisionOpenseaTokensIndex[tokenId] = _mythDivisionOpenseaTokens
            .length;
        _mythDivisionOpenseaTokens.push(tokenId);
    }

    function removeMythDivisionOpenSeaToken(uint256 tokenId) public onlyOwner {
        if (_mythDivisionOpenseaTokensIndex[tokenId] == 0) {
            require(
                tokenId == _mythDivisionOpenseaTokens[0],
                "Does not exist in the list"
            );
        }
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = _mythDivisionOpenseaTokens.length - 1;
        uint256 tokenIndex = _mythDivisionOpenseaTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _mythDivisionOpenseaTokens[lastTokenIndex];

        _mythDivisionOpenseaTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _mythDivisionOpenseaTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _mythDivisionOpenseaTokensIndex[tokenId];
        _mythDivisionOpenseaTokens.pop();
    }

    function mythDivisionOpenSeaTokens()
        public
        view
        returns (uint256[] memory)
    {
        return _mythDivisionOpenseaTokens;
    }

    function balanceOfOpenseaTokens(address owner)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        for (uint256 i; i < _mythDivisionOpenseaTokens.length; i++) {
            total += opensea.balanceOf(owner, _mythDivisionOpenseaTokens[i]);
        }

        return total;
    }

    function uniqueMythDivisionTokens(address owner)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        for (uint256 i; i < _mythDivisionOpenseaTokens.length; i++) {
            if (opensea.balanceOf(owner, _mythDivisionOpenseaTokens[i]) > 0) {
                total += 1;
            }
        }

        return total;
    }

    function isOpenseaTokenHolder(address owner) public view returns (bool) {
        for (uint256 i; i < _mythDivisionOpenseaTokens.length; i++) {
            if (opensea.balanceOf(owner, _mythDivisionOpenseaTokens[i]) > 0) {
                return true;
            }
        }

        return false;
    }

    function addEligibleERC721Contract(address addr) public onlyOwner {
        if (
            _eligibleERC721Contracts.length > 0 &&
            _eligibleERC721ContractsIndex[addr] == 0
        ) {
            require(
                addr != _eligibleERC721Contracts[0],
                "Already present in the list"
            );
        }

        _eligibleERC721ContractsIndex[addr] = _eligibleERC721Contracts.length;
        _eligibleERC721Contracts.push(addr);
    }

    function removeEligibleERC721Contract(address addr) public onlyOwner {
        if (_eligibleERC721ContractsIndex[addr] == 0) {
            require(
                addr == _eligibleERC721Contracts[0],
                "Does not exist in the list"
            );
        }
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = _eligibleERC721Contracts.length - 1;
        uint256 tokenIndex = _eligibleERC721ContractsIndex[addr];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        address lastAddress = _eligibleERC721Contracts[lastTokenIndex];

        _eligibleERC721Contracts[tokenIndex] = lastAddress; // Move the last token to the slot of the to-delete token
        _eligibleERC721ContractsIndex[lastAddress] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _eligibleERC721ContractsIndex[addr];
        _eligibleERC721Contracts.pop();
    }

    function eligibleERC721Contracts() public view returns (address[] memory) {
        return _eligibleERC721Contracts;
    }

    function balanceOfEligibleERC721ContractTokens(address owner)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        for (uint256 i; i < _eligibleERC721Contracts.length; i++) {
            total += ERC721(_eligibleERC721Contracts[i]).balanceOf(owner);
        }

        return total;
    }

    function isEligibleERC721TokenHolder(address owner)
        public
        view
        returns (bool)
    {
        for (uint256 i; i < _eligibleERC721Contracts.length; i++) {
            if (ERC721(_eligibleERC721Contracts[i]).balanceOf(owner) > 0) {
                return true;
            }
        }

        return false;
    }

    function balanceOfMythDivisionExclusiveAccessTokens(address owner)
        public
        view
        virtual
        returns (uint256)
    {
        return
            balanceOfOpenseaTokens(owner).add(
                balanceOfEligibleERC721ContractTokens(owner)
            );
    }

    function hasMythDivisionExclusiveAccess(address owner)
        public
        view
        returns (bool)
    {
        return
            isOpenseaTokenHolder(owner) || isEligibleERC721TokenHolder(owner);
    }
}