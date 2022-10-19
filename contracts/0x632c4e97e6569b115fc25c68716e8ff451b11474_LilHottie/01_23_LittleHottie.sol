// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/// @custom:security-contact [email protected]
contract LilHottie is Initializable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdCounter;
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    address private withdrawWallet;
    string baseURI;
    string public baseExtension;    
    string public notRevealedUri;
    bool public presale;
    uint256 public maxFreeMintAmount;

    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isFreeMinter;
    mapping(address => uint256) public freeMintAllocations;
    

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        presale = true;
        cost = 0.025 ether;
        maxSupply = 5100;
        maxMintAmount = 10;
        maxFreeMintAmount = 1;
        notRevealedUri = "";
        baseExtension = ".json";
        baseURI = "";
        withdrawWallet = address(msg.sender);

        __ERC721_init("Lil Hotties", "LHT");
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPresale(bool _presale) public onlyOwner {
        presale = _presale;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWithdrawWallet(address wallet) public onlyOwner {
        withdrawWallet = wallet;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool os, ) = payable(withdrawWallet).call{value: address(this).balance}("");
        require(os);
    }
    
    function addWhitelist(bool isFree, address[] calldata _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            if (isFree) {
                isFreeMinter[_addresses[i]] = true;
            } else {
                isWhitelisted[_addresses[i]] = true;
            }
            
        }
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId;
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    
    function mint(uint256 _mintAmount) public payable whenNotPaused {
        uint256 tokenId;

        if (presale) {
            require(isWhitelisted[msg.sender] == true, "EWL");
        }
        require(_mintAmount > 0, "EZER");
        require(_mintAmount <= maxMintAmount, "EMAX");
        require(totalSupply() + _mintAmount <= maxSupply, "ENONE");
        require(balanceOf(msg.sender) + _mintAmount <= maxMintAmount, "ELIM");

        if (msg.sender != owner()) {
            if (isFreeMinter[msg.sender]) {
                require(msg.value >= cost * (_mintAmount - (maxFreeMintAmount - freeMintAllocations[msg.sender])));
                freeMintAllocations[msg.sender] += (maxFreeMintAmount - freeMintAllocations[msg.sender]);
            } else {
                require(msg.value >= cost * _mintAmount);
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _tokenIdCounter.increment();
            tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
        }
    }    

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }
    

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : notRevealedUri;
    }
}