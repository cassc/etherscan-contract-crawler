// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./Tag.sol";

contract UnETHicalCupids is ERC721, ERC721Enumerable, AccessControlEnumerable {

    enum SaleState {
        Off,
        Public
    }

    struct SaleData {
        uint256 maxMintPerAddress;
        uint256 maxMintPerTransaction;
        uint256 maxTokensInSale;
        uint256 counter;
        uint256 price;
    }

    using SafeMath for uint256;

    bytes32 public constant SALE_MANAGER_ROLE = keccak256("SALE_MANAGER_ROLE");

    SaleData[] public saleData;
    SaleState public saleState;

    address public beneficiary;
    string public baseURI;
    string public provenance;

    modifier whenPublicSaleStarted() {
        require(saleState == SaleState.Public, "whenPublicSaleStarted: Incorrect sale state");
        _;
    }
    
    constructor(
        address _beneficiary,
        string memory _uri,
        string memory _provenance
    ) 
    ERC721("UnETHical Cupids", "UEC") 
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SALE_MANAGER_ROLE, msg.sender);

        beneficiary = _beneficiary;
        baseURI = _uri;
        provenance = _provenance;

        saleState = SaleState.Off;
        saleData.push();

        createSale(50, 10000, 0.05 ether);

    }

    function mintPublic(uint256 _numTokens) 
        external 
        payable 
        whenPublicSaleStarted() 
    {
        uint256 supply = totalSupply();
        
        require(
            _numTokens <= getSale(SaleState.Public).maxMintPerTransaction, 
            "mintPublic: Minting more than max per transaction!"
        );

        require(
            supply.add(_numTokens) <= getSale(SaleState.Public).maxTokensInSale, 
            "mintPublic: Not enough Tokens remaining."
        );

        require(
            _numTokens.mul(getSale(SaleState.Public).price) <= msg.value, 
            "mintPublic: Incorrect amount sent!"
        );

        uint256 nextTokenId = supply.add(1);

        for (uint256 i; i < _numTokens; i++) {
            _safeMint(msg.sender, nextTokenId.add(i));
        }
    }

    function mintReserveTokens(address _to, uint256 _numTokens) public onlyRole(SALE_MANAGER_ROLE) {
        require(saleState==SaleState.Off,"mintReserveTokens: Sale must be off to reserve tokens");
        uint256 supply = totalSupply();
        require(supply.add(_numTokens) <= getSale(SaleState.Public).maxTokensInSale, "mintReserveTokens: Cannot mint more than max supply");
        require(_numTokens <= 50,"mintReserveTokens: Gas limit protection");

        uint256 nextTokenId = supply.add(1);

        for (uint256 i; i < _numTokens; i++) {
            _safeMint(_to, nextTokenId.add(i));
        }
    }

    function startPublicSale() external onlyRole(SALE_MANAGER_ROLE) {
        saleState = SaleState.Public;
    }

    function stopSale() external onlyRole(SALE_MANAGER_ROLE) {
        require(saleState != SaleState.Off, "stopSale: Sale is off");
        saleState = SaleState.Off;
    }

    function updateProvenance(string calldata _provenance) external onlyRole(SALE_MANAGER_ROLE) {
        provenance = _provenance;
    }

    function setBaseURI(string memory _URI) external onlyRole(SALE_MANAGER_ROLE) {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        require(payable(beneficiary).send(balance));
    }

    function tokensInWallet(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getSale(SaleState _saleNumber) private view returns (SaleData storage) {
        return saleData[uint(_saleNumber)];
    }

    function createSale(
        uint256 _maxMintPerTransaction,
        uint256 _maxTokensInSale,
        uint256 _price
    )
        private
    {
        SaleData storage sale = saleData.push();

        sale.maxMintPerTransaction = _maxMintPerTransaction;
        sale.maxTokensInSale = _maxTokensInSale;
        sale.price = _price;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}