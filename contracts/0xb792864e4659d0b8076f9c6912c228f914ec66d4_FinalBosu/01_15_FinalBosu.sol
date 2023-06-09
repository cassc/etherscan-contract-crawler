// SPDX-License-Identifier: MIT
//
// ███████╗██╗███╗░░██╗░█████╗░██╗░░░░░██████╗░░█████╗░░██████╗██╗░░░██╗
// ██╔════╝██║████╗░██║██╔══██╗██║░░░░░██╔══██╗██╔══██╗██╔════╝██║░░░██║
// █████╗░░██║██╔██╗██║███████║██║░░░░░██████╦╝██║░░██║╚█████╗░██║░░░██║
// ██╔══╝░░██║██║╚████║██╔══██║██║░░░░░██╔══██╗██║░░██║░╚═══██╗██║░░░██║
// ██║░░░░░██║██║░╚███║██║░░██║███████╗██████╦╝╚█████╔╝██████╔╝╚██████╔╝
// ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚══════╝╚═════╝░░╚════╝░╚═════╝░░╚═════╝░

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract FinalBosu is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using Strings for uint256;
    using Address for address;

    enum TokenStatus { NEW, REQUESTED, FULFILLED }

    string private _baseUri;
    
    uint256 public constant MAX_SUPPLY = 555;
    uint256 public PRICE = 0.3 ether;
    uint256 public MAX_MINT = 2;
    uint256 public WHITELIST_MAX_MINT = 2;

    /**
     * 0: Sale is not active
     * 1: Private sale
     * 2: Public sale
     */
    uint8 public saleStatus = 0;
    
    mapping(address => uint256) public whitelist;
    mapping(uint16 => TokenStatus) public tokenStatus;

    event ChangeTokenStatus(address indexed _address, uint256 indexed _tokenId, TokenStatus _prevStatus, TokenStatus _currStatus, string _meta);

    constructor() ERC721("FinalBosu", "FINALBOSU") {}

    /**
     * Returns base URI of tokens.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /**
     * Set or change baseUri.
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }

    /**
     * Set price.
     */
    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    /**
     * Set max mint count.
     */
    function setMaxMint(uint256 _maxMint) external onlyOwner {
        MAX_MINT = _maxMint;
    }

    /**
     * Set max mint count for whitelisted users.
     */
    function setWhitelistMaxMint(uint256 _whitelistMaxMint) external onlyOwner {
        WHITELIST_MAX_MINT = _whitelistMaxMint;
    }

    /**
     * Set sale status.
     */
    function setSaleStatus(uint8 _saleStatus) external onlyOwner {
        saleStatus = _saleStatus;
    }

    /**
     * Add addresses to whitelist.
     */
    function addWhitelists(address[] calldata addresses) external onlyOwner {
        for (uint16 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "FinalBosu: invalid address");
            whitelist[addresses[i]] = WHITELIST_MAX_MINT;
        }
    }

    /**
     * Internal function to set token id
     */
    function _setTokenStatus(uint256 tokenId, TokenStatus status, string memory meta) internal {
        require(_exists(tokenId), "FinalBosu: invalid token id");

        if (tokenStatus[tokenId.toUint16()] != status) {
            TokenStatus prevStatus = tokenStatus[tokenId.toUint16()];
            tokenStatus[tokenId.toUint16()] = status;
            emit ChangeTokenStatus(_msgSender(), tokenId, prevStatus, status, meta);
        }
    }

    /**
     * Request ticket for custom drawing with photo url
     */
    function request(uint256 tokenId, string calldata uploadImageUrl) external {
        require(_msgSender() == ownerOf(tokenId), "FinalBosu: only token owner can request");
        require(tokenStatus[tokenId.toUint16()] == TokenStatus.NEW, "FinalBosu: cannot use this token to request");
        require(bytes(uploadImageUrl).length > 0, "FinalBosu: uploadImageUrl cannot be empty");

        // TODO: check if uploadImageUrl is valid url

        _setTokenStatus(tokenId, TokenStatus.REQUESTED, uploadImageUrl);
    }

    /**
     * Fulfill multiple tickets
     */
    function fulfillMultiple(uint256[] calldata tokenIds) external onlyOwner {
        for (uint16 i = 0; i < tokenIds.length; i++) {
            _fulfill(tokenIds[i]);
        }
    }

    /**
     * Fulfull a ticket
     */
    function fulfill(uint256 tokenId) external onlyOwner {
        _fulfill(tokenId);
    }

    /**
     * Fullfill a ticket
     */
    function _fulfill(uint256 tokenId) internal {
        require(tokenStatus[tokenId.toUint16()] == TokenStatus.REQUESTED, "FinalBosu: invalid token status");

        _setTokenStatus(tokenId, TokenStatus.FULFILLED, "");
    }

    /**
     * Mint in public sale
     */
    function mint(uint quantity) external payable {
        require(saleStatus == 2, "FinalBosu: sale is not active");
        require(quantity > 0, "FinalBosu: invalid quantity");
        require(quantity <= MAX_MINT, "FinalBosu: quantity exceeds max mint");
        require(totalSupply().add(quantity) <= MAX_SUPPLY, "FinalBosu: quantity exceed max supply");
        require(PRICE.mul(quantity) <= msg.value, "FinalBosu: insufficient value");

        for (uint i = 0; i < quantity; i++) {
            _safeMint(_msgSender(), totalSupply() + 1);
        }
    }

    /**
     * Mint in private sale
     */
    function mintPresale(uint quantity) external payable {
        require(saleStatus == 1, "FinalBosu: sale is not active");
        require(quantity > 0, "FinalBosu: invalid quantity");
        require(whitelist[_msgSender()] >= quantity, "FinalBosu: not allowed to mint");
        require(totalSupply().add(quantity) <= MAX_SUPPLY, "FinalBosu: quantity exceed max supply");
        require(PRICE.mul(quantity) <= msg.value, "FinalBosu: insufficient value");

        whitelist[_msgSender()] -= quantity;
        for (uint i = 0; i < quantity; i++) {
            _safeMint(_msgSender(), totalSupply() + 1);
        }
    }

    /**
     * Mint for admin
     */
    function mintReserve(uint quantity, address to) external onlyOwner {
        require(quantity > 0, "FinalBosu: invalid quantity");
        require(to != address(0), "FinalBosu: invalid address");
        require(totalSupply().add(quantity) <= MAX_SUPPLY, "FinalBosu: quantity exceed max supply");
        for (uint i = 0; i < quantity; i++) {
            _safeMint(to, totalSupply() + 1);
        }
    }

    /**
     * Withdraw values in this contract to withdrawer address and caller must be withdrawer.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "zero balance");
        payable(_msgSender()).transfer(balance);
    }

    /**
     * Get the array of token for owner.
     */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * Check if token is locked
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(tokenStatus[tokenId.toUint16()] != TokenStatus.REQUESTED, "FinalBosu: token is locked");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}