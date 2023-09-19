// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// Supply Error
error ExceedsMaxSupply();
// Address Error
error InvalidAddress();
// Minter Error
error unauthorizedMinter();

// @title Racehorse NFT
contract Racehorse is AccessControl, Ownable, ERC721A {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    struct AirdropRecipient {
        address to;
        uint256 quantity;
    }

    string private baseTokenURI;

    event Mint(address indexed to, uint256 quantity);
    event UpdateBaseURI(string oldBaseURI, string newBaseURI);

    modifier onlyMinter() {
        if (!hasRole(MINTER_ROLE, msg.sender)) revert unauthorizedMinter();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) ERC721A(_name, _symbol) {
        baseTokenURI = _baseTokenURI;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function airdrop(AirdropRecipient[] calldata recipients) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i].to, recipients[i].quantity);

            emit Mint(recipients[i].to, recipients[i].quantity);
        }
    }

    function mint(address to, uint256 quantity) external onlyMinter {
        if (address(0) == to) revert InvalidAddress();

        _mint(to, quantity);

        emit Mint(to, quantity);
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        string memory oldBaseURI = baseTokenURI;

        baseTokenURI = _baseTokenURI;

        emit UpdateBaseURI(oldBaseURI, _baseTokenURI);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721A)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == 0x7965db0b;   // ERC165 interface ID for AccessControl.
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}