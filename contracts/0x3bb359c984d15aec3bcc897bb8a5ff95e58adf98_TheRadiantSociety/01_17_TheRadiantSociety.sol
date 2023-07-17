// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TheRadiantSociety is ERC721Enumerable, Ownable, ERC721URIStorage, ERC721Burnable {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32;

    enum SalePeriod { NoMinting, FreeMinting, PreSale, PublicSale}

    uint256 public totalFreeMint = 0;
    uint256 public totalPresaleMint = 0;
    uint256 public constant MAX_ELEMENTS = 8875;
    uint256 public constant MAX_FREE_ELEMENTS = 850;
    uint256 public constant MAX_PRESALE_ELEMENTS = 4000;
    uint256 public constant PRICE = 0.07 ether;
    uint256 public constant MAX_BY_MINT = 20;
    uint8 public constant MAX_PRESALE_MINTING_PASSES = 3;
    address public constant creatorAddress1 = 0xc5cDC512fDB6Fab972965f6E4f9Ed64c7b5e7221;
    address public constant creatorAddress2 = 0x9b999DFeC690985AaD0DF7F38dA62486D2001E5F;
    address public constant devAddress1 = 0xbd3774Ec6D5AA8Bdcf77D989BF13f6BCA73FF0C1;
    address public constant devAddress2 = 0x1F93F7FF280C4672b735da056Cb109c8D30D5272;
    bool public revealed = false;
    bool public paused = false;
    string public baseURI;
    string public notRevealedUri;
    uint8 public period;

    mapping(address => bool) public freeMintingPasses;
    mapping(address => uint8) public presaleMintingPasses;

    event JoinedSociety(uint256 indexed id);
    constructor(
        string memory _initNotRevealedUri
    ) ERC721("TheRadiantSociety", "TRS") {
        setNotRevealedURI(_initNotRevealedUri);
    }

    modifier saleIsOpen {
        require(totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused, "Paused");
        }
        _;
    }
    
    function freeMint(
        bytes memory _signature
    ) external payable saleIsOpen {
        require(
            period == uint8(SalePeriod.FreeMinting),
            "Period not active"
        );
        require(freeMintingPasses[msg.sender] == false, "Pass already used");
        require(
            totalFreeMint < MAX_FREE_ELEMENTS,
            "Soldout"
        );

        address signerOwner = signatureWallet(
            msg.sender, 
            "chosen", 
            _signature
        );
        require(signerOwner == owner(), "Not authorized");
        
        _mintAnElement(msg.sender);
        freeMintingPasses[msg.sender] = true;
        totalFreeMint += 1;
    }

    function presale(
        uint8 _count, 
        bytes memory _signature
    ) external payable saleIsOpen {
        require(
            period == uint8(SalePeriod.PreSale),
            "Presale not active"
        );
        require(
            _count + presaleMintingPasses[msg.sender] <= MAX_PRESALE_MINTING_PASSES,
            "Maximum limit of passes exceeded"
        );
        require(
            _count + totalPresaleMint <= MAX_PRESALE_ELEMENTS,
            "Presale soldout"
        );
        require(
            msg.value >= price(_count),
            "Price not matched"
        );

        address signerOwner = signatureWallet(
            msg.sender, 
            "ancestor", 
            _signature
        );
        require(signerOwner == owner(), "Not authorized to mint");
        
        _mintList(msg.sender, _count);
        presaleMintingPasses[msg.sender] += _count;
        totalPresaleMint += uint256(_count);
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        require(
            period == uint8(SalePeriod.PublicSale),
            "Public sale not started"
        );
        uint256 total = totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds max per call");
        require(msg.value >= price(_count), "Value below price");

        _mintList(_to, _count);
    }

    function signatureWallet(address _address, string memory _role, bytes memory _signature) public pure returns (address){
        bytes32 data = keccak256(abi.encodePacked(_address, _role));
        return data.toEthSignedMessageHash().recover(_signature);
    }

    function _mintList(address _to, uint256 _num) private {
        for (uint256 i = 0; i < _num; i++) {
            _mintAnElement(_to);
        }
    }

    function _mintAnElement(address _to) private {
        uint mintIndex = totalSupply();
        _safeMint(_to, mintIndex + 1);
        emit JoinedSociety(mintIndex + 1);
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(devAddress1, balance.mul(15).div(100));
        _widthdraw(devAddress2, balance.mul(15).div(100));
        _widthdraw(creatorAddress1, balance.mul(35).div(100));
        _widthdraw(creatorAddress2, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function reserve(uint256 _count) public onlyOwner {
        uint256 total = totalSupply();
        require(total + _count <= 25, "Exceeded");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_msgSender());
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : "";
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURIAndReveal(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        revealed = true;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPeriod(SalePeriod _period) public onlyOwner {
        period = uint8(_period);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}