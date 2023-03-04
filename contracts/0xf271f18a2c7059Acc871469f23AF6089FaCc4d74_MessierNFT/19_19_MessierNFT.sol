// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract MessierNFT is Context, AccessControlEnumerable, ERC721Enumerable, ERC721URIStorage {
    using Strings for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public constant MAX_SUPPLY = 110;

    string private _internalBaseURI ;

    constructor(string memory _url) ERC721("Messier NFT", "MNFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
         _internalBaseURI = _url;
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function maxSupply() public view virtual  returns (uint256) {
        return MAX_SUPPLY;
    }

    function burn(uint256 tokenId) public virtual {
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
    override(ERC721Enumerable, AccessControlEnumerable, ERC721)
    returns (bool)
    {
        return
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newBaseUri) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721: must have admin role to change baseUri"
        );
        _internalBaseURI = newBaseUri;
    }

    function mint(address to, uint256 tokenId) public virtual {
        // require(
        //     hasRole(MINTER_ROLE, _msgSender()),
        //     "ERC721: must have minter role to mint"
        // );

        require(totalSupply() < MAX_SUPPLY, "Exceeds the max supply");

        _mint(to, tokenId);
    }

    // function tokenURI(uint256 tokenId)
    // public
    // view
    // virtual
    // override(ERC721URIStorage, ERC721)
    // returns (string memory)
    // {
    //     return super.tokenURI(tokenId);
    // }
function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721URIStorage, ERC721)
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721: must have admin role to set Token URIs"
        );
        super._setTokenURI(tokenId, _tokenURI);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
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

}