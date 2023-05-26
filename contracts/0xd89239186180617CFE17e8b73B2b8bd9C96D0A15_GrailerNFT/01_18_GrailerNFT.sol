// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Tradable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IGrailer {
    function ownerOf(uint256 tokenId) external returns(address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract GrailerNFT is ERC721Tradable {
    bool public salePublicIsActive;
    bool public claimIsActive;
    bool public saleHoldersOnlyIsActive;
    uint256 public maxByMint;
    uint256 public maxSupply;
    uint256 public maxPublicSupply;
    uint256 public nextTokenId;
    uint256 public fixedPrice;
    address public daoAddress;
    string internal baseTokenURI;
    IGrailer public GrailerOG;
    
    using Counters for Counters.Counter;
    Counters.Counter private _totalSupply;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        maxByMint = 10;
        maxSupply = 999;
        maxPublicSupply = 969;
        nextTokenId = 821;
        fixedPrice = 2 ether;
        daoAddress = 0x63fE60e3373De8480eBe56Db5B153baB1A431E38;
        baseTokenURI = "https://www.grailers.com/api/meta/2/";
        GrailerOG = IGrailer(0x8bb186371D019a190e4Fc01584DD164Ae10063a8);
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.grailers.com/api/contract/2";
    }

    function claim(uint256[] memory _tokenIds) public {
        require(claimIsActive, "Claim not active");
        for (uint256 i=0; i<_tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(GrailerOG.ownerOf(_tokenId) == _msgSender(), "Not grailer");
            GrailerOG.safeTransferFrom(_msgSender(), daoAddress, _tokenId);
            _safeMint(_msgSender(), _tokenId);
        }
    }

    function _mintN(address _to, uint numberOfTokens) private {
        require(numberOfTokens <= maxByMint, "Max mint exceeded");
        require(_totalSupply.current() + numberOfTokens <= maxPublicSupply, "Max reached");
        for(uint i = 0; i < numberOfTokens; i++) {
            nextTokenId = nextTokenId + i;
            _totalSupply.increment();
            _safeMint(_to, nextTokenId);
        }
    }

    function mintPublic(uint numberOfTokens) external payable {
        require(salePublicIsActive, "Sale not active");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        _mintN(_msgSender(), numberOfTokens);
    }

    function mintHoldersOnly(uint numberOfTokens) external payable {
        require(saleHoldersOnlyIsActive, "Holders sale not active");
        require(this.balanceOf(_msgSender()) > 0, "Must be a holder");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        _mintN(_msgSender(), numberOfTokens);
    }

    function mintReserved(uint numberOfTokens, address _to) external onlyOwner {
        _mintN(_to, numberOfTokens);
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.current();
    }

    function flipSalePublicStatus() external onlyOwner {
        salePublicIsActive = !salePublicIsActive;
    }

    function flipClaimStatus() external onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function flipSaleHoldersOnlyStatus() external onlyOwner {
        saleHoldersOnlyIsActive = !saleHoldersOnlyIsActive;
    }

    function setDaoAddress(address _daoAddress) external onlyOwner {
        daoAddress = _daoAddress;
    }

    function setGrailerOG(address _address) external onlyOwner {
        GrailerOG = IGrailer(_address);
    }

    function setSupply(uint256 _nextTokenId, uint256 _maxPublicSupply, uint256 _maxSupply) external onlyOwner {
        require(_maxSupply >= _maxPublicSupply, "Invalid supply");
        nextTokenId = _nextTokenId;
        maxPublicSupply = _maxPublicSupply;
        maxSupply = _maxSupply;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setFixedPrice(uint256 _fixedPrice) external onlyOwner {
        fixedPrice = _fixedPrice;
    }

    function setMaxByMint(uint256 _maxByMint) external onlyOwner {
        maxByMint = _maxByMint;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);
        _withdraw(daoAddress, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Tx failed");
    }

}