// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tag.sol";

contract DCaveBulovaDrip is ERC721, ERC721Enumerable, Ownable {

    enum SaleState {
        Off,
        Public1,
        Public2
    }

    struct SaleData {
        uint256 maxMintPerTransaction;
        uint256 maxTokensInSale;
        uint256 counter;
        uint256 price;
    }

    using SafeMath for uint256;

    SaleData[] public saleData;
    SaleState public saleState;

    address public beneficiary;
    string public baseURI;

    modifier whenPublicSaleStarted() {
        require(
            saleState == SaleState.Public1 || saleState == SaleState.Public2, "whenPublicSaleStarted: Incorrect sale state");
        _;
    }
    
    constructor(
        address _beneficiary,
        string memory _uri
    ) 
    ERC721("D-CAVE Computron", "COMP") 
    {

        beneficiary = _beneficiary;
        baseURI = _uri;

        saleState = SaleState.Off;
        saleData.push();

        createSale(3, 500, 0.5 ether);
        createSale(3, 500, 0.75 ether);

    }

    function mintPublic(uint256 _numTokens) 
        external 
        payable 
        whenPublicSaleStarted() 
    {
        uint256 counter = getSale(saleState).counter;
        
        require(
            _numTokens <= getSale(saleState).maxMintPerTransaction, 
            "mintPublic: Minting more than max per transaction!"
        );

        require(
            counter.add(_numTokens) <= getSale(saleState).maxTokensInSale, 
            "mintPublic: Not enough Tokens remaining."
        );

        require(
            _numTokens.mul(getSale(saleState).price) <= msg.value, 
            "mintPublic: Incorrect amount sent!"
        );

        uint256 supply = totalSupply();
        uint256 nextTokenId = supply.add(1);

        for (uint256 i; i < _numTokens; i++) {
            _safeMint(msg.sender, nextTokenId.add(i));
        }

        saleData[uint(saleState)].counter += _numTokens;

        if(saleState == SaleState.Public1 && getSale(SaleState.Public1).counter == 500){
            saleState = SaleState.Public2;
        }

    }

    function mintReserveTokens(address _to, uint256 _numTokens) public onlyOwner {
        uint256 counter = getSale(SaleState.Public2).counter;
        require(counter.add(_numTokens) <= getSale(SaleState.Public2).maxTokensInSale, "mintReserveTokens: Cannot mint more than max supply");
        require(_numTokens <= 50,"mintReserveTokens: Gas limit protection");

        uint256 supply = totalSupply();
        uint256 nextTokenId = supply.add(1);

        for (uint256 i; i < _numTokens; i++) {
            _safeMint(_to, nextTokenId.add(i));
        }

        saleData[uint(SaleState.Public2)].counter += _numTokens;
    }

    function setSaleState(SaleState _saleState) external onlyOwner() {
        saleState = _saleState;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}