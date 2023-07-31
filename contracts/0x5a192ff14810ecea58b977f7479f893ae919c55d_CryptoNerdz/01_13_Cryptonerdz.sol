// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "./ControlledAccess.sol";

interface iIQ {
    function updateReward(address _from, address _to) external;
}

contract CryptoNerdz is ERC721A, ReentrancyGuard, ControlledAccess {
    using Strings for uint256; 
    uint256 public constant maxPublicMint = 8;
    uint256 public constant maxPresaleMint = 4;
    uint256 public constant collectionSize = 4444;

    uint256 public mintPrice = 0.05 ether;
    uint256 public presaleMintPrice = 0.04 ether;
    bool public publicSaleActive = false;
    bool public presaleActive = false;
    iIQ public IQToken;

    /** URI Variables */
    string private constant uriSuffix = ".json";
    string private _baseTokenURI = "";
    string private hiddenMetadataUri;

    constructor() ERC721A( "CryptoNerdz", "CN") {
        setHiddenMetadataURI("ipfs://__CID__/hidden.json");
    }

    modifier mintCompliance(uint256 _quantity) {
        require(totalSupply() + _quantity <= collectionSize, "MaxSupplyReached");
        require(tx.origin == msg.sender, "CallerIsContract");
        require(_quantity > 0, "CannotMintZero");
        _;
    }

    function mint(uint256 quantity) external payable nonReentrant mintCompliance(quantity)
    {
        require(publicSaleActive, "PublicSaleNotLive");
        uint256 numPresaleMinted = _getAux(msg.sender);
        require(_numberMinted(msg.sender) - numPresaleMinted + quantity <= maxPublicMint, "MintMaxExceeded");

        _safeMint(msg.sender, quantity);
        refundIfOver(quantity * mintPrice);
    }

    function presaleMint(uint256 quantity, bytes32 _r, bytes32 _s, uint8 _v)
        external
        payable
        onlyValidAccess(_r, _s, _v)
        nonReentrant 
        mintCompliance(quantity)
    {
        require(presaleActive, "PresaleNotLive");
        uint256 numPresaleMinted = _getAux(msg.sender) + quantity;
        require(numPresaleMinted <= maxPresaleMint, "MintMaxExceeded");

        _safeMint(msg.sender, quantity);
        _setAux(msg.sender, uint64(numPresaleMinted));
        refundIfOver(quantity * presaleMintPrice);
    }

    /**
        @notice Total number of NFTs minted from the contract for a given address. Value can only increase and
        does not depend on how many NFTs are in your wallet
    */
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
        @notice Number of NFTs minted via presale.
    */
    function numberPresaleMinted(address owner) external view returns(uint256) {
        return uint256(_getAux(owner));
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "NonexistentToken");

        if (keccak256(abi.encodePacked(_baseTokenURI)) == keccak256(abi.encodePacked(""))) {
            return hiddenMetadataUri;
        }

        return
            bytes(_baseTokenURI).length > 0
                ? string(
                    bytes.concat(bytes(_baseTokenURI), bytes(_tokenId.toString()), bytes(uriSuffix))
                )
                : "";
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if(address(IQToken) != address(0)) {
            IQToken.updateReward(from, to);
        }
        ERC721A.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        if(address(IQToken) != address(0)) {
            IQToken.updateReward(from, to);
        }
        ERC721A.safeTransferFrom(from, to, tokenId, _data);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "InsufficientFunds");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

/// OWNER FUNCTIONS ///

    function withdraw() external onlyOwner nonReentrant {
        uint256 sendAmount = address(this).balance;

        address otto = payable(0x6dd0b33745f4a43CE331DAa315FA308c1fFD1048);
        address rains = payable(0xebE7E229783dC3fadfa4dD8b2e3C42e5E9180337);
        address dj = payable(0x9aa61a5084fEA26238aed17D37eef4cbe8014320);
        address yeti = payable(0x66c17Dcef1B364014573Ae0F869ad1c05fe01c89);
        address ninja = payable(0x9a4069cD84bF8654c329d87cE4102855359FBcE5);
        address community = payable(0x163AAD4539Cb8D6F1d940956c0D57e163158474F);

        bool success;
        (success, ) = otto.call{value: ((sendAmount * 30)/100)}("");
        require(success, "WithdrawFailed");
        (success, ) = rains.call{value: ((sendAmount * 30)/100)}("");
        require(success, "WithdrawFailed");
        (success, ) = dj.call{value: ((sendAmount * 10)/100)}("");
        require(success, "WithdrawFailed");
        (success, ) = yeti.call{value: ((sendAmount * 12)/100)}("");
        require(success, "WithdrawFailed");
        (success, ) = ninja.call{value: ((sendAmount * 3)/100)}("");
        require(success, "WithdrawFailed");
        (success, ) = community.call{value: ((sendAmount * 15)/100)}("");
        require(success, "WithdrawFailed");
    }

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        require(quantity + totalSupply() <= collectionSize, 'MaxSupplyReached');
        _safeMint(to, quantity);
    }

    function setIQToken(address iqAddress) external onlyOwner {
        IQToken = iIQ(iqAddress);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setHiddenMetadataURI(string memory _hiddenMetadataURI) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataURI;
    }

    function setPresaleMintPrice(uint256 price) external onlyOwner {
        presaleMintPrice = price;
    }

    function setPublicSaleMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }
}