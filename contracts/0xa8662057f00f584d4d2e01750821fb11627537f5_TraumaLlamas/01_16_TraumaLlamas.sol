// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

pragma solidity ^0.7.0;
pragma abicoder v2;

contract TraumaLlamas is ERC721, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Max Llamas you can purchase in each transaction
    uint256 public constant MAX_PER_TRANSACTION = 20;
    uint256 public constant MAX_PER_PRESALE_TRANSACTION = 10;

    // Maximum amount of Llamas that can exist
    uint256 public constant MAX_LLAMAS = 8888;
    uint256 public constant PRESALE_LLAMAS = 1111;

    // Price of each Llama in ether
    uint256 public llamaPrice = 0.04 ether;

    // Reserved Llamas for giveaways, events, etc
    uint256 public llamasReserve = 125;

    // States of sale, presale, and whitelist sale
    bool public saleIsActive = false;
    bool public presaleIsActive = false;
    bool public whitelistSaleIsActive = false;

    // Llamas ID counter
    Counters.Counter private _tokenIdCounter;

    // Mapping to keep track of whitelisted addresses and their available Llamas
    mapping(address => uint256) public presaleReserved;

    constructor() ERC721("Trauma Llamas", "TRLM") {}

    // Modifiers
    modifier validatePurchasePrice(uint256 numberOfTokens) {
        require(
            mintPrice(numberOfTokens) == msg.value,
            "Ether value sent is not correct"
        );
        _;
    }

    modifier doesNotExceedMaxPurchaseCount(uint256 numberOfTokens) {
        require(
            MAX_PER_TRANSACTION >= numberOfTokens,
            "Can only mint 20 Llamas at a time"
        );
        _;
    }

    modifier doesNotExceedMaxPresalePurchaseCount(uint256 numberOfTokens) {
        require(
            MAX_PER_PRESALE_TRANSACTION >= numberOfTokens,
            "Can only mint 10 Llamas at a time"
        );
        _;
    }

    modifier mintCountMeetsSupply(uint256 numberOfTokens) {
        require(
            MAX_LLAMAS >= _tokenIdCounter.current().add(numberOfTokens),
            "Exceeds max supply of Llamas"
        );
        _;
    }

    modifier mintCountMeetsPresaleSupply(uint256 numberOfTokens) {
        require(
            PRESALE_LLAMAS >= _tokenIdCounter.current().add(numberOfTokens),
            "Exceeds max supply of presale Llamas"
        );
        _;
    }

    // Functions
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function flipWhitelistSaleState() public onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }

    function reservedAmountByAddress(address _addr)
        public
        view
        returns (uint256)
    {
        return presaleReserved[_addr];
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        return llamaPrice.mul(numberOfTokens);
    }

    function updateLlamaPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice >= 1, "New price must be >= 1");
        require(
            !saleIsActive && !presaleIsActive && !whitelistSaleIsActive,
            "Cannot update price while a sale is active"
        );

        llamaPrice = _newPrice;
    }

    function _mintTokens(uint256 numberOfTokens, address to) internal {
        for (uint256 i; i < numberOfTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current());
        }
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function addToWhitelist(address[] memory _addr) public onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            presaleReserved[_addr[i]] = 10;
        }
    }

    function withdrawAll() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function mintReservedLlamas(address _to, uint256 _reserveAmount)
        public
        onlyOwner
    {
        require(
            _reserveAmount > 0 && _reserveAmount <= llamasReserve,
            "Not enough reserve Llamas left"
        );

        _mintTokens(_reserveAmount, _to);

        llamasReserve = llamasReserve.sub(_reserveAmount);
    }

    function mintWhitelist(uint256 numberOfTokens)
        public
        payable
        validatePurchasePrice(numberOfTokens)
        doesNotExceedMaxPresalePurchaseCount(numberOfTokens)
        mintCountMeetsPresaleSupply(numberOfTokens)
    {
        require(whitelistSaleIsActive, "Whitelist sale is not active");
        uint256 reservedAmt = presaleReserved[msg.sender];
        require(reservedAmt > 0, "No llamas reserved for your address");
        require(reservedAmt >= numberOfTokens, "Can't mint more than reserved");

        presaleReserved[msg.sender] = reservedAmt - numberOfTokens;

        _mintTokens(numberOfTokens, msg.sender);
    }

    function mintPresale(uint256 numberOfTokens)
        public
        payable
        validatePurchasePrice(numberOfTokens)
        doesNotExceedMaxPresalePurchaseCount(numberOfTokens)
        mintCountMeetsPresaleSupply(numberOfTokens)
    {
        require(presaleIsActive, "Presale is not active");

        _mintTokens(numberOfTokens, msg.sender);
    }

    function mintLlamas(uint256 numberOfTokens)
        public
        payable
        validatePurchasePrice(numberOfTokens)
        doesNotExceedMaxPurchaseCount(numberOfTokens)
        mintCountMeetsSupply(numberOfTokens)
    {
        require(saleIsActive, "Sale is not active");

        _mintTokens(numberOfTokens, msg.sender);
    }
}