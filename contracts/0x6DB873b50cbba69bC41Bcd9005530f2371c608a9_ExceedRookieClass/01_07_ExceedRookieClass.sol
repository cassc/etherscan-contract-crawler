// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ExceedRookieClass is ERC721A, Ownable {
    string _baseTokenURI;
    uint256 private NFT_TYPE_UNCOMMON = 1;
    uint256 private NFT_TYPE_RARE = 2;
    uint256 private NFT_TYPE_LEGENDARY = 3;

    /**
     * @notice A mapping between token id and the token type, tokens with the same type will have the same URI
     */
    mapping(uint256 => uint256) private _tokenIdsToTokenTypes;

    string baseUri;

    struct TokenType {
        uint256 id;
        uint256 price;
        uint256 maxSupply;
        uint256 totalMinted;
    }

    TokenType public uncommonTokenType = TokenType(NFT_TYPE_UNCOMMON, 0 ether, 2000, 0);
    TokenType public rareTokenType = TokenType(NFT_TYPE_RARE, 0 ether, 1000, 0);
    TokenType public legendaryTokenType = TokenType(NFT_TYPE_LEGENDARY, 0 ether, 333, 0);

    bool public isPublicSale = false;
    bool public isOGFinish = false;

    uint256 public MAX_SUPPLY = 3333;
    uint256 public maxAllowedTokensPerWallet = 3;

    mapping(address => bool) public OgWhitelist;
    mapping(address => bool) public whitelist;

    constructor(string memory baseUri_) ERC721A("Exceed Rookie Class", "EXC") {
        baseUri = baseUri_;
    }

    modifier saleIsOpen() {
        require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
        _;
    }

    modifier onlyAuthorized() {
        require(owner() == msg.sender);
        _;
    }

    function setBaseUri(string memory uri) external onlyOwner {
        baseUri = uri;
    }

    function addToOgWhitelist(address[] memory _address) public onlyAuthorized {
        for (uint256 index = 0; index < _address.length; index++) {
            OgWhitelist[_address[index]] = true;
        }
    }

    function addToWhitelist(address[] memory _address) public onlyAuthorized {
        for (uint256 index = 0; index < _address.length; index++) {
            whitelist[_address[index]] = true;
        }
    }

    function toggleSale() public onlyAuthorized {
        isPublicSale = !isPublicSale;
    }

    function setOGFinish() public onlyAuthorized {
        isOGFinish = true;
    }

    function setMaximumAllowedTokensPerWallet(uint256 _count) public onlyAuthorized {
        maxAllowedTokensPerWallet = _count;
    }

    function setMaxMintSupply(uint256 maxMintSupply) external onlyAuthorized {
        MAX_SUPPLY = maxMintSupply;
    }

    function totalSupply() public view override returns (uint256) {
        return uncommonTokenType.totalMinted + rareTokenType.totalMinted + legendaryTokenType.totalMinted;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token Id Non-existent");

        uint256 tokenType = _tokenIdsToTokenTypes[_tokenId];
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, "/", Strings.toString(tokenType), ".json")) : "";
    }

    function mint(uint256 _count, uint256 tokenType) public payable saleIsOpen {
        uint256 mintIndexBeforeMint = totalSupply();

        if (msg.sender != owner()) {
            require(balanceOf(msg.sender) + _count <= maxAllowedTokensPerWallet, "Exceeds maximum tokens allowed per wallet");
            require(mintIndexBeforeMint + _count <= MAX_SUPPLY, "Total supply exceeded.");

            if (!isPublicSale) {
                if ( mintIndexBeforeMint  + _count <= 333 && !isOGFinish) {
                    require(OgWhitelist[msg.sender], "NFT:Sender is not OG whitelisted");
                } else {
                    require(whitelist[msg.sender], "NFT:Sender is not whitelisted");
                }
            }

            if (tokenType == uncommonTokenType.id) {
                require(uncommonTokenType.totalMinted + _count <= uncommonTokenType.maxSupply, "Total uncommon supply exceeded.");
            } else if (tokenType == rareTokenType.id) {
                require(rareTokenType.totalMinted + _count <= rareTokenType.maxSupply, "Total rare supply exceeded.");
            } else if (tokenType == legendaryTokenType.id) {
                require(legendaryTokenType.totalMinted + _count <= legendaryTokenType.maxSupply, "Total legendary supply exceeded.");
            }
        }

        _safeMint(msg.sender, _count);

        // update total after mint
        if (tokenType == uncommonTokenType.id) {
            uncommonTokenType.totalMinted += _count;
        } else if (tokenType == rareTokenType.id) {
            rareTokenType.totalMinted += _count;
        } else if (tokenType == legendaryTokenType.id) {
            legendaryTokenType.totalMinted += _count;
        }

        // update the mapping bwtween token id and token type
        uint256 totalSupplyAfterMint = totalSupply();
        for (uint256 i = mintIndexBeforeMint; i < totalSupplyAfterMint; i++){
            _setTokenIdToTokenType(i, tokenType);
        }
    }

    function withdraw() external onlyAuthorized {
        uint256 balance = address(this).balance;
        address payable to = payable(msg.sender);
        to.transfer(balance);
    }

    function _setTokenIdToTokenType(uint256 tokenId, uint256 tokenType) internal {
        require(_exists(tokenId), "token type mapping set of nonexistent token");
        _tokenIdsToTokenTypes[tokenId] = tokenType;
    }
}