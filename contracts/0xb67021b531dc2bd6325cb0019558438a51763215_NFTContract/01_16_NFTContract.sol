// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import './utils/Adminable.sol';

/**
 * @title NFT Smart Contract made by Artiffine
 * @author https://artiffine.com/
 */
contract NFTContract is ERC721Enumerable, Adminable {
    string private _baseURIextended;
    string public PROVENANCE;
    string public contractURI;

    bool public isSaleActive = false;
    bool public isAllowlistSaleActive = false;

    uint256 public MAX_SUPPLY;
    uint256 public MAX_PUBLIC_MINT;
    uint256 public PRICE_PER_TOKEN;
    uint256 public PRICE_PER_TOKEN_ALLOWLIST;

    error SaleNotActive();
    error ExceedsMintLimit();
    error ExceedsMaxSupply();
    error EtherValueSentNotExact();
    error ArgumentIsAddressZero();
    error ContractBalanceIsZero();
    error TransferFailed();

    mapping(address => uint8) private _allowlist;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 maxPublicMint,
        uint256 pricePerToken
    ) ERC721(name, symbol) {
        MAX_SUPPLY = maxSupply;
        MAX_PUBLIC_MINT = maxPublicMint;
        PRICE_PER_TOKEN = pricePerToken;
        PRICE_PER_TOKEN_ALLOWLIST = pricePerToken;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /* ============ External Functions ============ */

    function allowlistMintAmount(address addr) external view returns (uint8) {
        return _allowlist[addr];
    }

    function mintAllowlisted(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        if (!isAllowlistSaleActive) revert SaleNotActive();
        if (numberOfTokens > _allowlist[msg.sender]) revert ExceedsMintLimit();
        if (ts + numberOfTokens > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (PRICE_PER_TOKEN_ALLOWLIST * numberOfTokens != msg.value) revert EtherValueSentNotExact();

        _allowlist[msg.sender] -= numberOfTokens;
        for (uint8 i = 0; i < numberOfTokens; ++i) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function mint(uint8 numberOfTokens, address to) public payable {
        uint256 ts = totalSupply();
        if (!isSaleActive) revert SaleNotActive();
        if (numberOfTokens > MAX_PUBLIC_MINT) revert ExceedsMintLimit();
        if (ts + numberOfTokens > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (PRICE_PER_TOKEN * numberOfTokens != msg.value) revert EtherValueSentNotExact();

        for (uint8 i = 0; i < numberOfTokens; ++i) {
            _safeMint(to, ts + i);
        }
    }

    /* ============ External Admin/Owner Functions ============ */

    // allowlist mint
    function setIsAllowlistSaleActive(bool isActive) external onlyAdmin {
        isAllowlistSaleActive = isActive;
    }

    function setAllowlistAddresses(address[] calldata addresses, uint8 numAllowedToMint) external onlyAdmin {
        for (uint8 i = 0; i < addresses.length; ++i) {
            _allowlist[addresses[i]] = numAllowedToMint;
        }
    }

    // override base functions
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // setters
    function setMaxSupply(uint256 maxSupply_) external onlyAdmin {
        MAX_SUPPLY = maxSupply_;
    }

    function setMaxPublicMint(uint256 maxPublicMint_) external onlyAdmin {
        MAX_PUBLIC_MINT = maxPublicMint_;
    }

    function setPricePerToken(uint256 pricePerToken_) external onlyAdmin {
        PRICE_PER_TOKEN = pricePerToken_;
    }

    function setPricePerTokenAllowlist(uint256 pricePerTokenAllowlist_) external onlyAdmin {
        PRICE_PER_TOKEN_ALLOWLIST = pricePerTokenAllowlist_;
    }

    function setBaseURI(string memory baseURI_) external onlyAdmin {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) external onlyAdmin {
        PROVENANCE = provenance;
    }

    function setContractURI(string memory contractUri_) external onlyAdmin {
        contractURI = contractUri_;
    }

    // public mint
    function setIsSaleActive(bool isActive) public onlyAdmin {
        isSaleActive = isActive;
    }

    // free mint
    function freeMint(uint256 numberOfTokens, address to) public onlyAdmin {
        uint256 ts = totalSupply();
        if (ts + numberOfTokens > MAX_SUPPLY) revert ExceedsMaxSupply();

        for (uint256 i = 0; i < numberOfTokens; ++i) {
            _safeMint(to, ts + i);
        }
    }

    /* ============ External Owner Functions ============ */

    // withdraw functions
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert ContractBalanceIsZero();
        (bool success, ) = msg.sender.call{value: balance}('');
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Recovers ERC20 token back to the owner.
     */
    function recoverToken(IERC20 _token) external onlyOwner {
        if (address(_token) == address(0)) revert ArgumentIsAddressZero();
        uint256 balance = _token.balanceOf(address(this));
        if (balance == 0) revert ContractBalanceIsZero();
        _token.transfer(owner(), balance);
    }
}