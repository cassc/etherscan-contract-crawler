//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NiftyKitCollection is
    ERC721,
    ERC721URIStorage,
    Ownable,
    AccessControl
{
    using Counters for Counters.Counter;

    Counters.Counter private _ids;

    uint256 internal _commission = 0; // parts per 10,000

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address recipient, string memory metadata)
        public
        onlyAdmin
        returns (uint256)
    {
        _ids.increment();
        uint256 id = _ids.current();
        _mint(recipient, id);
        _setTokenURI(id, metadata);
        return id;
    }

    function burn(uint256 id) public onlyAdmin {
        _burn(id);
    }

    function transfer(
        address from,
        address to,
        uint256 tokenId
    ) public onlyAdmin {
        _transfer(from, to, tokenId);
    }

    function setCommission(uint256 commission) public onlyAdmin {
        _commission = commission;
    }

    function getCommission() public view returns (uint256) {
        return _commission;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}