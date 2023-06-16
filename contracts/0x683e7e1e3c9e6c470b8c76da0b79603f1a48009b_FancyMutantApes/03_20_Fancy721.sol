// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./tag.sol";

contract Fancy721 is ERC721Enumerable, Ownable, AccessControlEnumerable {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    IERC721Enumerable public referenceContract;

    mapping(uint256 => bool) public tokenClaimed;

    string public baseURI;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory  _URI,
        IERC721Enumerable _referenceContract
    ) ERC721(_name, _symbol) {
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        baseURI =  _URI;

        referenceContract = _referenceContract;
    }

    function safeMint(address _to, uint256[] calldata _referenceTokenIds) public onlyRole(MINTER_ROLE) {
        for(uint256 i = 0; i < _referenceTokenIds.length; i++){
            require(referenceContract.ownerOf(_referenceTokenIds[i]) == _to, "safeMint: destination address must own token on reference contract");
            require(!tokenClaimed[_referenceTokenIds[i]], "safeMint: token already used for claim");
            _safeMint(_to, _referenceTokenIds[i]);
            tokenClaimed[_referenceTokenIds[i]] = true;
        }
    }

    function tokensInWallet(address _address) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_address);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_address, i);
        }
        return tokensId;
    }

    function setBaseURI(string memory _URI) external onlyRole(MANAGER_ROLE) {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}