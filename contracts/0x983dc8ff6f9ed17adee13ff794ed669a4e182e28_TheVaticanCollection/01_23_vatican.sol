// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ArbitraryTokenStorage {
    function unlockERC(IERC20 token) external;
}

contract ERC20Storage is Context, AccessControlEnumerable, ArbitraryTokenStorage {
    
    function unlockERC(IERC20 token) external override virtual{
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721: must have admin role to unlock ERC"
        );
        uint256 balance = token.balanceOf(address(this));
        
        require(balance > 0, "Contract has no balance");
        require(token.transfer(_msgSender(), balance), "Transfer failed");
    }
}

contract TheVaticanCollection is
    ERC20Storage,
    ERC721Enumerable,
    ERC721URIStorage
{   
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _internalBaseURI;
    string private _colName;
    string private _colSymbol;

    constructor(
        string memory cname,
        string memory csymbol,
        string memory cbaseURI
    ) ERC721(cname, csymbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _internalBaseURI = cbaseURI;
        _colName = cname;
        _colSymbol = csymbol;
    }

    function burn(uint256 tokenId) external virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721URIStorage,ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newBaseUri) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721: must have admin role to change baseUri"
        );
        _internalBaseURI = newBaseUri;
    }

    function mint(address _to, uint256 _tokenId) external virtual {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(MINTER_ROLE, _msgSender()),
            "ERC721: must have admin or minter role to mint"
        );
        _mint(_to, _tokenId);
    }

    function mintNFT(address _to, uint256 _tokenFrom,uint256 _tokenTo) external virtual {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(MINTER_ROLE, _msgSender()),
            "ERC721: must have admin or minter role to mint"
        );
        
        for (uint256 i = _tokenFrom; i < _tokenTo; i++) {
            _mint(_to, i);
        }
    }

    function mintNFTTokens(address _to,uint256[] calldata _ids)  external virtual{
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(MINTER_ROLE, _msgSender()),
            "ERC721: must have admin or minter role to mint"
        );

        for (uint256 i = 0; i < _ids.length; i++) {
            _mint(_to, _ids[i]);
        }
    }

    function tokensOfOwner(address _owner) external view returns  (uint256[] memory){
        uint256 tokenCount = balanceOf(_owner);
        
        uint256[] memory result = new uint256[](tokenCount);
            
        for(uint i = 0; i < tokenCount; i++) {
            result[i]=tokenOfOwnerByIndex(_owner,i);
        }
        return result;
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize) internal virtual override (ERC721, ERC721Enumerable) 
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _internalBaseURI;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(MINTER_ROLE, _msgSender()),
            "ERC721: must have admin or minter role to set Token URIs"
        );
        super._setTokenURI(tokenId, _tokenURI);
    }

    function setName(string memory newName) external  {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have Admin role");
        _colName = newName;
    }

    function setSymbol(string memory newSymbol) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have Admin role");
        _colSymbol = newSymbol;
    }

    function name() public view virtual override returns (string memory) {
        return _colName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _colSymbol;
    }

}