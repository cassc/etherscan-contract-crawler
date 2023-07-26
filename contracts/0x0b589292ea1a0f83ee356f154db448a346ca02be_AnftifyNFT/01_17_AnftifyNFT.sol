// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AnftifyNFT is ERC721Enumerable, AccessControl, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public maxSupply;
    Counters.Counter private _tokenIdCounter;

    string public contractURI;
    string public baseTokenURI;
    bool public pause = true;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    event MaxSupplySet(uint256 maxSupply);
    event ContractURIUpdated(string contractURI);
    event BaseTokenURIUpdated(string baseTokenURI);
    event PauseUpdated(bool pause);
    event AnfitfyNFTMinted(uint256 tokenId);

    constructor(
        string memory _name, string memory _symbol,
        uint256 _maxSupply, string memory _contractURI, string memory _baseTokenURI) ERC721(_name, _symbol) {
        require(bytes(_name).length > 0, "AnftifyNFT: Cannot set empty name");
        require(bytes(_symbol).length > 0, "AnftifyNFT: Cannot set empty symbol");
        require(_maxSupply > 0, "AnftifyNFT: max supply should be greater than zero");
        require(bytes(_contractURI).length > 0, "AnftifyNFT: Cannot set empty contractURI");
        require(bytes(_baseTokenURI).length > 0, "AnftifyNFT: Cannot set empty baseTokenURI");

        maxSupply = _maxSupply;
        contractURI = _contractURI;
        baseTokenURI = _baseTokenURI;

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        emit ContractURIUpdated(contractURI);
        emit BaseTokenURIUpdated(baseTokenURI);
        emit MaxSupplySet(maxSupply);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "AnftifyNFT: only admin");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "AnftifyNFT: only minter");
        _;
    }

    modifier saleIsOpen(uint256 _amount) {
        require(totalSupply() + _amount <= maxSupply, "AnftifyNFT: Soldout");
        require(!pause, "AnftifyNFT: Paused");
        _;
    }

    function mint(uint256 _amount, address _account) public onlyMinter saleIsOpen(_amount) {
        require(_amount > 0, "AnftifyNFT: mint amount should be greater than zero");
        require(_account != address(0), "AnftifyNFT: mint address cannot be zero address");

        uint256 tokenId;
        for (uint256 i; i < _amount; i++) {
            tokenId = _tokenIdCounter.current();
            _safeMint(_account, tokenId);
            _tokenIdCounter.increment();
            emit AnfitfyNFTMinted(tokenId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setContractURI(string memory _contractURI) public onlyAdmin {
        require(bytes(_contractURI).length > 0, "AnftifyNFT: Cannot set empty contractURI");
        contractURI = _contractURI;
        emit ContractURIUpdated(contractURI);
    }

    function setBaseURI(string memory _baseTokenURI) public onlyAdmin {
        require(bytes(_baseTokenURI).length > 0, "AnftifyNFT: Cannot set empty baseURI");
        baseTokenURI = _baseTokenURI;
        emit BaseTokenURIUpdated(baseTokenURI);
    }

    function setPause(bool _pause) public onlyAdmin {
        pause = _pause;
        emit PauseUpdated(pause);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }
}