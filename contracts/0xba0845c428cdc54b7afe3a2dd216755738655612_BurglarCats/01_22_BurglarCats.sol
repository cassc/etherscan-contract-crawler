// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721Tradable.sol";

contract BurglarCats is ERC721Tradable {

    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _reservedTokenIdCounter;

    uint256 public constant NFT_PRICE_SALE = 60000000000000000; // 0.06 ETH
    uint public constant MAX_NFT_PURCHASE_SALE = 20;
    uint256 public MAX_SUPPLY = 10000;

    /**
     * Reserve some tokens for the team and community giveaways
     */
    uint public constant RESERVED_TOTAL = 325;

    bool public isSaleActive = false;
    bool public isRevealed = false;

    string public provenanceHash;

    /**
     * 🆒 Evolutions
     */
    address public evoContractAddress;

    string private _baseURIExtended;
    string private _placeholderURIExtended;

    constructor(
        address _proxyRegistryAddress
    ) ERC721Tradable('BurglarCats', 'BUCA', _proxyRegistryAddress) {
        /**
         * Start counting tokens from
         */
        _tokenIdCounter._value = RESERVED_TOTAL;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setPlaceholderURI(string memory placeholderURI_) external onlyOwner {
        _placeholderURIExtended = placeholderURI_;
    }

    function setProvenanceHash(string memory provenanceHash_) external onlyOwner {
        provenanceHash = provenanceHash_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!isRevealed) {
            return string(abi.encodePacked(_placeholderURIExtended, tokenId.toString()));
        }

        string memory base = _baseURI();

        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function flipReveal() public onlyOwner {
        isRevealed = !isRevealed;
    }

    function setEvolutionAddress(address contractAddress) public onlyOwner {
        evoContractAddress = contractAddress;
    }

    function _mintGeneric(
        uint256 CURRENT_NFT_PRICE,
        uint CURRENT_TOKENS_NUMBER_LIMIT,
        uint numberOfTokens
    ) internal {
        require(isSaleActive, "Sale is not active at the moment");
        require(numberOfTokens > 0, "Number of tokens can not be less than or equal to 0");
        require(_tokenIdCounter.current().add(numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply");

        if (isSaleActive) {
            CURRENT_NFT_PRICE = NFT_PRICE_SALE;
            CURRENT_TOKENS_NUMBER_LIMIT = MAX_NFT_PURCHASE_SALE;
        }

        require(numberOfTokens <= CURRENT_TOKENS_NUMBER_LIMIT, "Tokens amount is out of limit");
        require(CURRENT_NFT_PRICE.mul(numberOfTokens) == msg.value, "Sent ether value is incorrect");

        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMintGeneric(msg.sender, _tokenIdCounter);
        }
    }

    function mint(uint numberOfTokens) public payable {
        _mintGeneric(NFT_PRICE_SALE, MAX_NFT_PURCHASE_SALE, numberOfTokens);
    }

    /**
     * Lazily mint some reserved tokens
     */
    function mintReserved(uint numberOfTokens) public onlyOwner {
        require(
            _reservedTokenIdCounter.current().add(numberOfTokens) <= RESERVED_TOTAL,
            "Minting would exceed max reserved supply"
        );

        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMintGeneric(msg.sender, _reservedTokenIdCounter);
        }
    }

    function burnTokenForAddress(uint256 tokenId, address burnerAddress) external {
        require(msg.sender == evoContractAddress, "Invalid sender address");
        require(msg.sender != burnerAddress, "Invalid burner address");

        _burn(tokenId);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}