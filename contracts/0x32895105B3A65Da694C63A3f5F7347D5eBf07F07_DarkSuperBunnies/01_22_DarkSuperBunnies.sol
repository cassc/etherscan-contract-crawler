// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./ERC721Tradable.sol";

contract DarkSuperBunnies is ERC721Tradable {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _reservedTokenIdCounter;

    /**
     * 🐯
     */
    address public superTigerContract;

    uint256 public constant NFT_PRICE = 80000000000000000; // 0.08 ETH
    uint public constant MAX_NFT_PURCHASE = 100;

    uint256 public constant NFT_PRICE_PRE_SALE = 58000000000000000; // 0.058 ETH for pre-sale
    uint public constant MAX_NFT_PURCHASE_PRE_SALE = 10;

    uint256 public constant NFT_PRICE_LOVE = 69000000000000000; // 0.069 ETH for the best community
    uint public constant MAX_NFT_PURCHASE_LOVE = 100;

    uint256 public MAX_SUPPLY = 10000;
    /**
     * Reserve tokens for the team and community giveaways
     */
    uint public constant RESERVED_TOTAL = 325;

    bool public isSaleActive = false;
    bool public isPreSaleActive = false;

    bool public isRevealed = false;

    string public provenanceHash;

    string private _baseURIExtended;
    string private _placeholderURIExtended;

    constructor(
        address _proxyRegistryAddress
    ) ERC721Tradable('DarkSuperBunnies', 'DSB', _proxyRegistryAddress) {
        /**
         * Start counting tokens with a reserved shift
         */
        _tokenIdCounter._value = 5000;
    }

    /**
     * @dev Withdraw ether from the contract
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
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
            return _placeholderURIExtended;
        }

        string memory base = _baseURI();

        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function setSuperTigerContractAddress(address contractAddress) public onlyOwner {
        superTigerContract = contractAddress;
    }

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }
    function flipPreSaleState() public onlyOwner {
        isPreSaleActive = !isPreSaleActive;
    }
    function flipAllSaleStates() external onlyOwner {
       flipSaleState();
       flipPreSaleState();
    }
    function flipReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function _mintGeneric(
        uint256 CURRENT_NFT_PRICE,
        uint CURRENT_TOKENS_NUMBER_LIMIT,
        uint numberOfTokens
    ) internal {
        require(isSaleActive, "Sale is not active at the moment");
        require(numberOfTokens > 0, "Number of tokens can not be less than or equal to 0");
        require(_tokenIdCounter.current().add(numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply");

        if (isPreSaleActive) {
            CURRENT_NFT_PRICE = NFT_PRICE_PRE_SALE;
            CURRENT_TOKENS_NUMBER_LIMIT = MAX_NFT_PURCHASE_PRE_SALE;
        }

        require(numberOfTokens <= CURRENT_TOKENS_NUMBER_LIMIT, "Tokens amount is out of limit");
        require(CURRENT_NFT_PRICE.mul(numberOfTokens) == msg.value, "Sent ether value is incorrect");

        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMintGeneric(msg.sender, _tokenIdCounter);
        }
    }


    function mint(uint numberOfTokens) public payable {
        _mintGeneric(NFT_PRICE, MAX_NFT_PURCHASE, numberOfTokens);
    }

    function mintLove(uint numberOfTokens) public payable {
        _mintGeneric(NFT_PRICE_LOVE, MAX_NFT_PURCHASE_LOVE, numberOfTokens);
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

    function levelUp(uint256 useTokenId1, uint256 useTokenId2, uint256 useTokenId3) public {
        require(superTigerContract != address(0), "SuperTiger contract address need be set");

        address from = msg.sender;
        require(ERC721.ownerOf(useTokenId1) == from, "ERC721: use of token1 that is not own");
        require(ERC721.ownerOf(useTokenId2) == from, "ERC721: use of token2 that is not own");
        require(ERC721.ownerOf(useTokenId3) == from, "ERC721: use of token3 that is not own");

        burn(useTokenId1);
        burn(useTokenId2);
        burn(useTokenId3);

        SuperTiger superTiger = SuperTiger(superTigerContract);
        bool result = superTiger.composeSuperTiger(from);
        require(result, "SuperTiger compose failed");
    }
}

interface SuperTiger {
    function composeSuperTiger(address owner) external returns (bool);
}