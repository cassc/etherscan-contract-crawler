// SPDX-License-Identifier: MIT
// Taipe Experience Contracts
pragma solidity ^0.8.9;

// Import this file to use console.log
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { TaipeLib } from '../lib/TaipeLib.sol';

contract TaipeNFT is ERC721Enumerable, ERC2981, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private constant taipeName = "TaipeNFT";
    string private constant taipeSymbol = "TPE";

    address private openseaAddress;
    string private baseContractURI;
    string private baseURI;

    uint96 constant INITIAL_PERCENTAGE = 800; // 8%

    constructor() ERC721(taipeName, taipeSymbol) {
        _setDefaultRoyalty(_msgSender(), INITIAL_PERCENTAGE);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // MODIFIERS

    modifier permissionToMint() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Only minters can mint tokens"
        );
        _;
    }

    function transferOwnership(address newOwner)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super.transferOwnership(newOwner);
    }

    function setDefaultRoyalty(address recipient, uint96 percentage)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(recipient, percentage);
    }

    function setOpenseaAddress(address _openseaAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        openseaAddress = _openseaAddress;
    }

    function setContractURI(string memory uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseContractURI = uri;
    }

    function setBaseURI(string memory uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = uri;
    }

    // MINTING

    function mintTo(address to, uint tokenId) public virtual permissionToMint {
        require(_insideTokenMintCap(tokenId), "Token ID is not available");
        _mint(to, tokenId);
    }

    function _insideTokenMintCap(uint tokenId)
        internal
        pure
        virtual
        returns (bool)
    {
        return
            tokenId >= 1 &&
            tokenId <=
            TaipeLib.TOTAL_TIER_1 +
                TaipeLib.TOTAL_TIER_2 +
                TaipeLib.TOTAL_TIER_3;
    }

    // we approve opensea to transfer our tokens
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        if (_operator == openseaAddress) {
            return true;
        }

        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}