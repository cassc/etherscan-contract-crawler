// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC721A.sol";

import { AccessControl }     from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import { ReentrancyGuard }   from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { Strings }           from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import { IAccessControl }    from "../lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import { IERC20 }            from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 }         from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 }           from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata }   from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC721Enumerable } from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Cronicle is AccessControl, ERC721A, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public allowlist;
    uint256 public allowlistCounter;
    string private _baseTokenURI;

    bytes32 public constant ALLOWER_ROLE = keccak256("ALLOWER_ROLE");

    constructor(address owner)
        ERC721A(
            "Cronicle",
            "CRONIC",
            1,
            15 
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(ALLOWER_ROLE, owner);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "The caller does not have the ADMIN role");
        _;
    }

    modifier onlyAllower() {
        require(hasRole(ALLOWER_ROLE, msg.sender), "The caller does not have the ALLOWER role");
        _;
    }

    receive() external payable {
        revert("Contract does not accept ether transfers");
    }

    fallback() external payable {
        revert("Contract does not accept ether transfers");
    }

    function mintCronicle() external callerIsUser {
        require(allowlist[msg.sender] > 0, "Not eligible for mint or already has minted");
        require(numberMinted(msg.sender) == 0, "You've already minted your NFT");
        require(totalSupply() + 1 <= collectionSize, "Reached max supply");
        allowlist[msg.sender]--;
        allowlistCounter--;
        _safeMint(msg.sender, 1);
    }

    function batchAllowAndMint(address[] memory addresses) external onlyAllower {
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 mints = allowlist[addresses[i]];
            require(mints == 0, "One of the passed addresses is already on the allow list");
            require(numberMinted(addresses[i]) == 0, "One of the passed addresses already own the NFT");
            require(totalSupply() + 1 <= collectionSize, "Reached max supply");
            _safeMint(addresses[i], 1);
        }
    }

    function addToAllowlist(address[] memory addresses) external onlyAllower {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = 1;
            allowlistCounter++;
        }
    }

    function isEligible(address user) external view returns (bool) {
        return numberMinted(msg.sender) == 0 && allowlist[user] > 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyAdmin {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return _baseURI();
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyAdmin
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool)
    {
        return
        interfaceId == type(IAccessControl).interfaceId ||
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function grantAllowerRole(address to) external onlyAdmin {
        grantRole(ALLOWER_ROLE, to);
    }

    function revokeAllowerRole(address from) external onlyAdmin {
        revokeRole(ALLOWER_ROLE, from);
    }

    function transferAdmin(address to) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, to);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function rescueTokens(address tokenAddress) external onlyAdmin {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        require(balance > 0, "No tokens for given address");
        token.safeTransfer(msg.sender, balance);
    }
}