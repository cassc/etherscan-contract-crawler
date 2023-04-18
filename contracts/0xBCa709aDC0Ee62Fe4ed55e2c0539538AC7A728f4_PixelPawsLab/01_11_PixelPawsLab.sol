// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

struct FactoryLab {
    uint256 publicMintPrice;
    uint16  totalSupply;
    uint16  maxSupplyForPublic;
    uint16  maxSupplyForWhitelist;
    uint8   publicMintPerWallet;
    uint8   whitelistMintPerWallet;
    uint8   numberTokensToUpgrade;
}

contract PixelPawsLab is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable, ReentrancyGuard {
    enum FactoryState {
        PUBLIC,
        WHITELIST,
        UPGRADE,
        CLOSED
    }

    string private _currentBaseURI;

    FactoryLab public _labState = FactoryLab({
        publicMintPrice: 9000000000000000,
        totalSupply: 3333,
        maxSupplyForPublic: 2983,
        maxSupplyForWhitelist: 350,
        publicMintPerWallet: 6,
        whitelistMintPerWallet: 1,
        numberTokensToUpgrade: 3
    });
    FactoryState public _factoryState = FactoryState.CLOSED;

    bytes32 public _merkleRoot;

    mapping(uint256 => bool) private upgradedTokens;
    mapping(address => uint8) private publicMints;
    mapping(address => uint8) private whitelistMints;

    constructor(string memory baseURI) ERC721A("Pixel Paws Lab", "PPL") {
        setBaseURI(baseURI);
    }

    // events
    event UpdateFactoryState(FactoryState indexed _state);
    event UpgradablePaws(uint256[] indexed _tokenIds);
    event BurnablePaws(uint256[] indexed _tokenIds);

    // modifiers
    modifier publicSale(uint16 _quantity) {
        uint256 _totalSupply = totalSupply();

        require(
            _factoryState == FactoryState.PUBLIC,
            "Public sale is not active"
        );
        require(
            _totalSupply + _quantity <= _labState.maxSupplyForPublic,
            "Public was Sold Out!"
        );
        _;
    }
    modifier whitelistSale() {
        require(
            _factoryState == FactoryState.WHITELIST,
            "Whitelist sale is not active"
        );
        _;
    }
    modifier whenUpgradeIsOpen() {
        require(
            _factoryState == FactoryState.UPGRADE,
            "Upgrade is not active"
        );
        _;
    }
    modifier whenSoldOut(uint16 _quantity) {
        uint256 _totalSupply = totalSupply();
        
        require(_totalSupply + _quantity <= _labState.totalSupply, "Sold out!");
        _;
    }

    // Mint
    function mint(uint8 _quantity)
        public
        payable
        nonReentrant
        publicSale(_quantity)
        whenSoldOut(_quantity)
    {
        require(
            publicMints[msg.sender] + _quantity  <= _labState.publicMintPerWallet,
            "Allowed mints exceeded."
        );
        require(
            msg.value == _labState.publicMintPrice * _quantity,
            "Ether sent is not correct"
        );

        publicMints[msg.sender]++;
        _safeMint(msg.sender, _quantity);
    }

    function verify(bytes32[] memory _proof) private view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));

        return MerkleProof.verify(_proof, _merkleRoot, _leaf);
    }

    function whitelistMint(bytes32[] calldata _proof, uint8 _quantity)
        public
        nonReentrant
        whitelistSale
        whenSoldOut(_quantity)
    {
        require(verify(_proof), "Address not on Whitelist");
        require(
            whitelistMints[msg.sender] + _quantity  <= _labState.whitelistMintPerWallet,
            "Allowed mints exceeded."
        );

        whitelistMints[msg.sender]++;
        _safeMint(msg.sender, _quantity);
    }

    function upgrade(uint256[] memory _tokenIds)
        public
        nonReentrant
        whenUpgradeIsOpen
    {
        uint256 tokenLength = _tokenIds.length;

        require(tokenLength > 0, "Incorrect number of tokens");
        require(
            tokenLength % _labState.numberTokensToUpgrade == 0,
            "Incorrect number of tokens"
        );

        uint256 amountUpgradeTokens = tokenLength / _labState.numberTokensToUpgrade;

        uint256[] memory burnedTokens = new uint[](tokenLength - amountUpgradeTokens);
        uint256[] memory upgradeTokens = new uint[](amountUpgradeTokens);

        for(uint8 i = 0; i < tokenLength; ++i) {
            require(ownerOf(_tokenIds[i]) == msg.sender, "Must own all tokens!");
            require(!upgradedTokens[_tokenIds[i]], "You can't upgrade a token!");

            if (i < amountUpgradeTokens) {
                upgradedTokens[_tokenIds[i]] = true;
                upgradeTokens[i] = _tokenIds[i];
                continue;
            }
            
            burnedTokens[i - amountUpgradeTokens] = _tokenIds[i];
            _burn(_tokenIds[i]);
        }

        emit UpgradablePaws(upgradeTokens);
        emit BurnablePaws(burnedTokens);
    }

    // by owner
    function setBaseURI(string memory baseURI) public onlyOwner {
        _currentBaseURI = baseURI;
    }

    function toggleState(FactoryState _state) public onlyOwner {
        _factoryState = _state;
        emit UpdateFactoryState(_factoryState);
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        _merkleRoot = root;
    }

    function setPublicPerWallet(uint8 _quantity) public onlyOwner {
        _labState.publicMintPerWallet = _quantity;
    }

    function setWhitelistPerWallet(uint8 _quantity) public onlyOwner {
        _labState.whitelistMintPerWallet = _quantity;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os, "Transfer failed.");
    }

    // override
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}