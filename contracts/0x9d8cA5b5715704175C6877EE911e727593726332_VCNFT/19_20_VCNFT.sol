// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./Grantable.sol";

contract VCNFT is ERC721Enumerable, AccessControl, Grantable {

    using Counters for Counters.Counter;
    using Address for address;
    using Strings for uint256;
    using Strings for address;

    Counters.Counter internal _tokenIds;

    bytes32 public constant TOKEN_ADMIN = keccak256("TOKEN_ADMIN");
    bytes32 public constant DEAL_ADMIN = keccak256("DEAL_ADMIN");

    struct Deal {
        address manager;
        address currency; // the token used for the raise
    }

    mapping(bytes32 => Deal) public deals;

    mapping(uint256 => bool) public lockedTokens;

    mapping(address => bool) public allowedContracts;

    string public tokenURIprefix;
    string public tokenURIsuffix;

    constructor(string memory name,
                string memory symbol,
                address super_admin,
                string memory _tokenURIprefix,
                string memory _tokenURIsuffix
                )
        ERC721(name, symbol)
    {
        tokenURIprefix = _tokenURIprefix;
        tokenURIsuffix = _tokenURIsuffix;
        _grantRole(DEFAULT_ADMIN_ROLE, super_admin);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // returns a token URI in the form
    // https://ventureclub.club/tokenmeta/1/{contractAddress}/{tokenId}.json
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // token uri scheme
        // {prefix(https://ventureclub.club/api/nft)}{chainId}/{contractAddress}/{tokenId}{suffix(/meta)}
        return string.concat(tokenURIprefix, // https://ventureclub.club/api/nft/
                             block.chainid.toString(), "/",
                             address(this).toHexString(), "/",
                             Strings.toString(tokenId),
                             tokenURIsuffix // /meta
                             );
    }

    event URIupdated(string exampleURI);
    function setTokenURI(string memory prefix, string memory suffix, bytes memory grant) external
        granted(abi.encode(msg.sender, prefix, suffix), grant, TOKEN_ADMIN) {
        tokenURIprefix = prefix;
        tokenURIsuffix = suffix;
        emit URIupdated(tokenURI(0));
    }

    event DealCreated(bytes32 id, address dealManager, address currency);

    // createDeal registers details for a Deal allowing people to claim an
    // opportunity to invest
    function createDeal(bytes32 id,
                        address dealManager,
                        address currency,
                        bytes memory grant
                        )
        granted(abi.encode(msg.sender, id, dealManager, currency), grant, DEAL_ADMIN)
        external
    {
        require(deals[id].manager == address(0), "VCNFT: Deal exists");

        Deal storage deal = deals[id];
        deal.manager = dealManager;
        deal.currency = currency;

        emit DealCreated(id, dealManager, currency);
    }

    event Mint(address to, uint256 tokenId, bytes32 dealId, uint256 price);

    function mint(address to, bytes32 dealId, uint256 price, bytes memory grant)
        granted(abi.encode(msg.sender, to, dealId, price), grant, TOKEN_ADMIN)
        external
    {
        require(deals[dealId].manager != address(0), "VCNFT: Deal does not exist");
        IERC20 erc20 = IERC20(deals[dealId].currency);
        require(erc20.transferFrom(msg.sender, deals[dealId].manager, price),
                "VCNFT: Payment failed");

        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        _mint(to, tokenId);
        lockedTokens[tokenId] = true;

        emit Mint(to, tokenId, dealId, price);
    }

    event Burn(uint256 tokenId, string reason);
    function burn(uint256 tokenId, string calldata reason, bytes memory grant) external
        granted(abi.encode(msg.sender, tokenId, reason), grant, TOKEN_ADMIN) {
        lockedTokens[tokenId] = false;
        _burn(tokenId);
        emit Burn(tokenId, reason);
    }

    event SetLocked(uint256 tokenId, bool locked, string reason);
    function setLocked(uint256 tokenId, bool locked, string calldata reason, bytes memory grant) external
        granted(abi.encode(msg.sender, tokenId, locked, reason), grant, TOKEN_ADMIN)
    {
        lockedTokens[tokenId] = locked;
        emit SetLocked(tokenId, locked, reason);
    }

    event SetContractAllowed(address contractAddress, bool allowed, string reason);
    function setContractAllowed(address contractAddress, bool allowed, string calldata reason, bytes memory grant)
        external
        granted(abi.encode(msg.sender, contractAddress, allowed, reason), grant, TOKEN_ADMIN)
    {
        allowedContracts[contractAddress] = allowed;
        emit SetContractAllowed(contractAddress, allowed, reason);
    }

    // we need check our contract allow list, and for locked tokens
    // before transfers
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        require(lockedTokens[firstTokenId] == false, "VCNFT: Token is locked");
        if(to.isContract()) {
            require(allowedContracts[to] == true, "VCNFT: Contract not allowed");
        }
    }
}