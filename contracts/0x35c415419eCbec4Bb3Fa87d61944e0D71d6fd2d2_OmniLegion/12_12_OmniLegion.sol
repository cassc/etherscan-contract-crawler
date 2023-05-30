pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

//All Intellectual property of the OmniLegion 1 of 1s remains the property of OmniLegion

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OmniLegion is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private constant _maxTokens = 9999;
    uint256 private _maxPresaleTokens = 9999;
    uint256 private constant _maxMint = 9999;
    uint256 public constant _premintPrice = 50000000000000000; //0.05 ETH
    uint256 public constant _price = 60000000000000000; // 0.06 ETH
    bool private _presaleActive = false;
    bool private _saleActive = false;

    string public _prefixURI;

    mapping(address => bool) private _freelist;
    mapping(address => bool) private _whitelist;

    constructor() ERC721("Omni Legion", "OMNI") {}

    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _prefixURI = _uri;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function setMaxPresaleTokens(uint256 newMaxPresaleMint) public onlyOwner {
        _maxPresaleTokens = newMaxPresaleMint;
    }

    function togglePreSale() public onlyOwner {
        _presaleActive = !_presaleActive;
    }

    function preSale() public view returns (bool) {
        return _presaleActive;
    }

    function Sale() public view returns (bool) {
        return _saleActive;
    }

    function toggleSale() public onlyOwner {
        _saleActive = !_saleActive;
        _presaleActive = false;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function mintItems(uint256 amount) public payable {
        require(amount <= _maxMint);
        require(_saleActive);

        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + amount <= _maxTokens);

        require(msg.value >= amount * _price);

        for (uint256 i = 0; i < amount; i++) {
            _mintItem(msg.sender);
        }
    }

    function freeListMany(address[] memory accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _freelist[accounts[i]] = true;
        }
    }

    function whiteListMany(address[] memory accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _whitelist[accounts[i]] = true;
        }
    }

    function freeMint() public {
        require(_presaleActive);
        require(_freelist[_msgSender()], "Mint: Unauthorized Access");
        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + 1 <= _maxTokens);
        _mintItem(msg.sender);
        _freelist[_msgSender()] = false;
    }

    function presaleMintItems(uint256 amount) public payable {
        require(amount <= _maxMint);
        require(_presaleActive);

        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + amount <= _maxPresaleTokens);

        require(msg.value >= amount * _premintPrice);

        for (uint256 i = 0; i < amount; i++) {
            _mintItem(msg.sender);
        }
    }

    function _mintItem(address to) internal returns (uint256) {
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(to, id);

        return id;
    }

    function reserve(uint256 quantity) public onlyOwner {
        for(uint i = _tokenIds.current(); i < quantity; i++) {
            if (i < _maxTokens) {
                _tokenIds.increment();
                _safeMint(msg.sender, i + 1);
            }
        }
    }

    function withdraw(address payee) public payable onlyOwner {
        require(payable(payee).send(address(this).balance));
    }

    function withdrawAmount(address payee, uint256 amount) public payable onlyOwner {
        require(payable(payee).send(amount));
    }
}