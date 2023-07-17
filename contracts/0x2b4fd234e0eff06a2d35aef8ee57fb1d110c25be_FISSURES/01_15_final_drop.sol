// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";



contract FISSURES is
    ERC721,
    ERC721Enumerable,
    Ownable,
    PaymentSplitter
{
    using SafeMath for uint256;
    using SafeMath for uint16;

    uint16 public MAX_SUPPLY = 256;
    uint256 public presaleAccessCount = 0;
    uint16 _maxPurchaseCount = 1;
    uint16 _maxPreSalePurchaseCount = 2;
    uint256 _mintPrice = 0.05 ether;
    string _baseURIValue;
    mapping(address => bool) _presaleAccess;
    mapping(address => bool) _canAddToPresale;
    bool public saleIsActive = false;
    bool public presaleIsActive = false;



    constructor(
        address[] memory payees,
        uint256[] memory paymentShares
    ) ERC721("Fissures", "FSSR") PaymentSplitter(payees, paymentShares) {

    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBase) public onlyOwner {
        _baseURIValue = newBase;
    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function flipPreSaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }


    function maxPurchaseCount() public view returns (uint256) {
        return _maxPurchaseCount;
    }

    function setMaxPurchaseCount(uint8 count) public onlyOwner {
        _maxPurchaseCount = count;
    }

    function baseMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function setBaseMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        return _mintPrice.mul(numberOfTokens);
    }

    // function canAccessPresale() public view returns (bool) {
    //     return _presaleAccess[msg.sender];
    // }

    function canAccessPresale(address addr) public view returns (bool) {
        return _presaleAccess[addr];
    }

    function addPresaleAddresses(address[] calldata addresses) external {
        require(
            owner() == msg.sender || _canAddToPresale[msg.sender],
            "Not authorized for that action"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            _presaleAccess[addresses[i]] = true;
        }
        presaleAccessCount += addresses.length;
    }
    
    function createPresaleAdmin(address[] calldata addresses) external {
        require(
            owner() == msg.sender,
            "Not authorized for that action"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            _canAddToPresale[addresses[i]] = true;
        }
    }

    modifier mintCountMeetsSupply(uint256 numberOfTokens) {
        require(
            totalSupply().add(numberOfTokens) <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier doesNotExceedMaxPreSalePurchaseCount(uint256 numberOfTokens) {
        require(
            numberOfTokens <= _maxPreSalePurchaseCount,
            "Cannot mint more than 2 tokens at a time for presale"
        );
        _;
    }

    modifier doesNotExceedMaxPurchaseCount(uint256 numberOfTokens) {
        require(
            numberOfTokens <= _maxPurchaseCount,
            "Cannot mint more than 1 token at a time"
        );
        _;
    }

    modifier validatePurchasePrice(uint256 numberOfTokens) {
        require(
            mintPrice(numberOfTokens) == msg.value,
            "Ether value sent is not correct"
        );
        _;
    }

    function _mintTokens(uint256 numberOfTokens, address to) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, totalSupply() + 1);
        }
    }

    function mintPresale(uint16 numberOfTokens)
        public
        payable
        mintCountMeetsSupply(numberOfTokens)
        doesNotExceedMaxPreSalePurchaseCount(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
    {
        require(presaleIsActive, "Presale has not started yet");
        require(canAccessPresale(msg.sender), "You do not have access to the presale");
        require((balanceOf(msg.sender) + numberOfTokens) <= _maxPreSalePurchaseCount, "This mint would put you above the presale limit of mints per account");

        _mintTokens(numberOfTokens, msg.sender);
    }

    function mintTokens(uint256 numberOfTokens)
        public
        payable
        mintCountMeetsSupply(numberOfTokens)
        doesNotExceedMaxPurchaseCount(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
    {
        require(saleIsActive, "Sale has not started yet");
        require((balanceOf(msg.sender) + numberOfTokens) <= _maxPurchaseCount, "This mint would put you above the sale limit of mints per account");


        _mintTokens(numberOfTokens, msg.sender);
    }



    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}