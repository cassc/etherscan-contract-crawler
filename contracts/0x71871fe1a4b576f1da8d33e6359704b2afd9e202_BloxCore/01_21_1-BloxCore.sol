// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract BloxCore is Context, AccessControlEnumerable, ERC721Enumerable, ERC721Burnable, ERC721Pausable, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    string private _baseTokenURI;
    string private _contractTokenURI;

    struct Blox {
        uint256 genes;
        uint256 bornAt;
        uint16 generation;
        uint256 parent0Id;
        uint256 parent1Id;
        uint256 ancestorCode;
        uint8 reproduction;
    }
    mapping(uint256 => Blox) private _bloxes;

    event MintBlox(uint256 indexed tokenId, address indexed receiver);
    event BurnBlox(uint256 indexed tokenId);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory contractTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _contractTokenURI = contractTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function updateBaseURI(string memory baseTokenURI) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BloxCore: must have admin role to update baseTokenURI");

        _baseTokenURI = baseTokenURI;
    }

    function updateContractURI(string memory contractTokenURI) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BloxCore: must have admin role to update contractTokenURI");

        _contractTokenURI = contractTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public view virtual returns (string memory) {
        return _contractTokenURI;
    }

    function getBlox(uint256 tokenId)
        public
        view
        virtual
        returns (
            uint256 genes,
            uint256 bornAt,
            uint16 generation,
            uint256 parent0Id,
            uint256 parent1Id,
            uint256 ancestorCode,
            uint8 reproduction
        )
    {
        require(_exists(tokenId), "BloxCore: operator query for nonexistent token");

        Blox storage blox = _bloxes[tokenId];
        return (
            blox.genes,
            blox.bornAt,
            blox.generation,
            blox.parent0Id,
            blox.parent1Id,
            blox.ancestorCode,
            blox.reproduction
        );
    }

    function mintBlox(
        uint256 tokenId,
        uint256 genes,
        uint16 generation,
        uint256 parent0Id,
        uint256 parent1Id,
        uint256 ancestorCode,
        address receiver
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "BloxCore: must have minter role to mint");

        _mintBlox(tokenId, genes, generation, parent0Id, parent1Id, ancestorCode, receiver);
        emit MintBlox(tokenId, receiver);
    }

    function _mintBlox(
        uint256 tokenId,
        uint256 genes,
        uint16 generation,
        uint256 parent0Id,
        uint256 parent1Id,
        uint256 ancestorCode,
        address receiver
    ) internal {
        uint256 bornAt = block.timestamp;
        uint8 reproduction = 0;

        Blox memory blox = Blox(genes, bornAt, generation, parent0Id, parent1Id, ancestorCode, reproduction);
        _mint(receiver, tokenId);
        _bloxes[tokenId] = blox;
    }

    function increaseReproduction(uint256 tokenId) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "BloxCore: must have minter role to increase");

        _bloxes[tokenId].reproduction += 1;
    }

    function burnBlox(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "BloxCore: burn caller is not owner nor approved");

        _burn(tokenId);
        delete _bloxes[tokenId];
        emit BurnBlox(tokenId);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}