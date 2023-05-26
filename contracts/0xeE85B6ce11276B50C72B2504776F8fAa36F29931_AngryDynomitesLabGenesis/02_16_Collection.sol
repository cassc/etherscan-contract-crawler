// contracts/Collection.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract Collection is ERC721, IERC2981, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public immutable MAX_SUPPLY;
    string public PROVENANCE;

    string private _baseTokenURI;
    string private _contractURI;
    address private _beneficiary;

    Counters.Counter _totalSupply;

    constructor(
        string memory name,
        string memory symbol,
        uint256 MAX_SUPPLY_,
        string memory PROVENANCE_,
        string memory baseTokenURI,
        string memory contractURI_
    ) ERC721(name, symbol) {
        MAX_SUPPLY = MAX_SUPPLY_;
        PROVENANCE = PROVENANCE_;
        _baseTokenURI = baseTokenURI;
        _contractURI = contractURI_;

        _beneficiary = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.current();
    }

    function mint(address to, uint256 quantity)
        external
        nonReentrant
        onlyRole(MINTER_ROLE)
    {
        require(
            _totalSupply.current() + quantity <= MAX_SUPPLY,
            "COLLECTION: AMOUNT_EXCEEDS_MAX_SUPPLY"
        );

        for (uint256 i = 0; i < quantity; i++) {
            _totalSupply.increment();
            _mint(to, _totalSupply.current());
        }
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        royaltyAmount = (_salePrice / 100) * 5;
        return (_beneficiary, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl, IERC165)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = uri;
    }

    function setContractURI(string memory uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _contractURI = uri;
    }

    function setBeneficiary(address beneficiary)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _beneficiary = beneficiary;
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return _baseTokenURI;
    }
}