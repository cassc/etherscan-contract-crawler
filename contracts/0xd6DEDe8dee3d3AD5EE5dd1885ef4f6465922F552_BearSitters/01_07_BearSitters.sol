// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BearSitters is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public uriPrefix;
    string public uriSuffix = ".json";

    uint256 public cost = 0.005 ether;
    uint256 public maxSupply = 4444;
    uint256 public freeMints = 1111;
    uint256 public maxPerAddressLimit = 5;
    uint256 public maxPerTx = 5;

    bool public mintOpen = false;

    mapping(address => bool) public freeMintClaimed;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _metadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setUriPrefix(_metadataUri);
        _safeMint(msg.sender, 50);
    }

    // ~~~~~~~~~~~~~~~~~~~~ Modifiers ~~~~~~~~~~~~~~~~~~~~
    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxPerTx,
            "Too many mints in one transaction!"
        );
        require(msg.sender == tx.origin, "Contracts are not allowed");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }
    
    modifier mintPriceCompliance(uint256 _mintAmount) {
        if (!freeMintClaimed[msg.sender] && totalSupply() < freeMints) {
            if (_mintAmount > 1) {
                require(
                    msg.value >= (cost * (_mintAmount - 1)),
                    "Insufficient funds!"
                );
            }
        } else {
            require(msg.value >= (cost * _mintAmount), "Insufficient funds!");
        }
        _;
    }

    // ~~~~~~~~~~~~~~~~~~~~ Mint Functions ~~~~~~~~~~~~~~~~~~~~
    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
        nonReentrant
    {
        require(mintOpen, "The contract is not open for minting!");

        _safeMint(msg.sender, _mintAmount);
        freeMintClaimed[msg.sender] = true;
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );

        _safeMint(_receiver, _mintAmount);
    }

    // ~~~~~~~~~~~~~~~~~~~~ Various Checks ~~~~~~~~~~~~~~~~~~~~
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

      function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return bytes(uriPrefix).length > 0
                ? string(abi.encodePacked(uriPrefix, _tokenId.toString(), uriSuffix))
                : "";
    }

    // ~~~~~~~~~~~~~~~~~~~~ onlyOwner Functions ~~~~~~~~~~~~~~~~~~~~

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxPerTx(uint256 _amountPerTx) public onlyOwner {
        maxPerTx = _amountPerTx;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setMintState(bool _state) public onlyOwner {
        mintOpen = _state;
    }

    function setFreeMints(uint256 _freeQty) public onlyOwner {
        freeMints = _freeQty;
    }

    // ~~~~~~~~~~~~~~~~~~~~ Withdraw Functions ~~~~~~~~~~~~~~~~~~~~
    function withdraw() public onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        (bool hs, ) = payable(0xf4A0aE7C55AF0777668Fe6c30020520d6E4a37F6).call{
            value: (contractBalance * 90) / 100
        }("");
        (bool os, ) = payable(owner()).call{
            value: (contractBalance * 10) / 100
        }("");
        require(hs && os, "Withdraw failed");
    }
}