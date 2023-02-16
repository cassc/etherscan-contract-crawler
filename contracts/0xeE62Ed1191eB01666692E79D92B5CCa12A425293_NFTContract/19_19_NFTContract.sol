// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

/**
 * @title NFT Smart Contract made by Artiffine
 * @author https://artiffine.com/
 */
contract NFTContract is ERC721, ERC721Enumerable, Ownable, ERC721Royalty {
    using SafeMath for uint256;

    string private _baseURIextended;
    string public PROVENANCE;
    string public contractURI;

    bool public isSaleActive = false;
    bool public isAllowlistSaleActive = false;

    uint256 public MAX_SUPPLY;
    uint256 public MAX_PUBLIC_MINT;
    uint256 public PRICE_PER_TOKEN;
    uint256 public PRICE_PER_TOKEN_ALLOWLIST;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    mapping(address => bool) private _admins;
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

    /**
     * @dev Lets only admins to call functions, owner() is also consider an admin.
     */
    modifier onlyAdmin() {
        require(_admins[msg.sender] || msg.sender == owner(), 'Caller is not the admin/owner');
        _;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // royalties
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /* ============ External Functions ============ */

    function allowlistMintAmount(address addr) external view returns (uint8) {
        return _allowlist[addr];
    }

    function mintAllowlisted(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowlistSaleActive, 'Allowlist sale is not active');
        require(numberOfTokens <= _allowlist[msg.sender], 'Exceeded max available to purchase');
        require(ts + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens');
        require(PRICE_PER_TOKEN_ALLOWLIST * numberOfTokens <= msg.value, 'Ether value sent is not correct');

        _allowlist[msg.sender] -= numberOfTokens;
        for (uint8 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function mint(uint8 numberOfTokens, address to) public payable {
        uint256 ts = totalSupply();
        require(isSaleActive, 'Sale must be active to mint tokens');
        require(numberOfTokens <= MAX_PUBLIC_MINT, 'Exceeded max token purchase');
        require(ts + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens');
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, 'Ether value sent is not correct');

        for (uint8 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, ts + i);
        }
    }

    /* ============ External Admin/Owner Functions ============ */

    // allowlist mint
    function setIsAllowlistSaleActive(bool isActive) external onlyAdmin {
        isAllowlistSaleActive = isActive;
    }

    function setAllowlistAddresses(address[] calldata addresses, uint8 numAllowedToMint) external onlyAdmin {
        for (uint8 i = 0; i < addresses.length; i++) {
            _allowlist[addresses[i]] = numAllowedToMint;
        }
    }

    // override base functions
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
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

    function setProvenance(string memory provenance) public onlyAdmin {
        PROVENANCE = provenance;
    }

    function setContractURI(string memory contractUri_) external onlyAdmin {
        contractURI = contractUri_;
    }

    function setDefaultRoyalty(address recipient, uint96 fraction) public onlyAdmin {
        _setDefaultRoyalty(recipient, fraction);
    }

    // public mint
    function setIsSaleActive(bool isActive) public onlyAdmin {
        isSaleActive = isActive;
    }

    // free mint
    function freeMint(uint256 numberOfTokens, address to) public onlyAdmin {
        uint256 ts = totalSupply();
        require(ts + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, ts + i);
        }
    }

    /* ============ External Owner Functions ============ */

    // withdraw functions
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'Contract balance must be > 0');
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        require(address(this).balance >= _amount, 'Contract balance must be >= _amount');
        (bool success, ) = _address.call{value: _amount}('');
        require(success, 'Transfer failed.');
    }

    /**
     * @dev Recovers ERC20 token back to the owner.
     */
    function recoverToken(IERC20 _token) external onlyOwner {
        require(address(_token) != address(0), 'Token is address zero');
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, 'Token balance must be > 0');
        _token.transfer(owner(), balance);
    }

    /**
     * @dev Adds address to _admins.
     */
    function addAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), 'Admin cannot be address zero');
        require(!_admins[_admin], 'Admin already exists');
        _admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    /**
     * @dev Removes address from _admins.
     */
    function removeAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), 'Admin cannot be address zero');
        require(_admins[_admin], 'Admin does not exist');
        _admins[_admin] = false;
        emit AdminRemoved(_admin);
    }
}