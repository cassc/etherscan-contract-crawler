//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./IMinter.sol";

contract PNP is IMinter, ERC721A, Ownable {

    uint256 constant OVERALL = 2000;
    uint256 maxSupply;
    uint256 public maxRevealedId;
    // Base URI
    string public notRevealedURI;
    mapping(address => bool) public minter;

    // ERC721A
    uint256 constant maxBatchSize_ = 2000;
    uint256 constant collectionSize_ = 1;

    uint public immutable devReserve;
    uint16 public devMinted;
    uint16 public publicMinted;

    bool public publicMintActive = false;

    event SetMinter(address minter, bool enabled);
    event Revealed(uint256 curTokenId, uint256 tokenId);
    event BaseURIChanged(string uri);
    event NotRevealedURIChanged(string uri);
    event SetMaxSupply(uint256 amount0, uint256 amount1);

    struct MintConf {
        uint16 maxMint;
        uint16 maxPerAddrMint;
        uint256 price;
    }

    MintConf public publicMintConf;
    mapping(address => uint16) public publicAddrMinted;

    constructor(string memory _initNotRevealedUri) 
        ERC721A("PiXiu Never Poop", "PNP", maxBatchSize_, collectionSize_) {
        notRevealedURI = _initNotRevealedUri;

        // TODO: need be change for mainnet.
        maxSupply = 2000;
        devReserve = 500;

        publicMintConf = MintConf(1500, 1, 0);
    }

    function getOverall() external pure returns (uint256) {
        return OVERALL;
    }

    function getMaxSupply() external view returns (uint256) {
        return maxSupply;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        require(amount >= totalSupply(), "Less than already mint");
        require(amount <= OVERALL, "Overall supply exceeded");
        emit SetMaxSupply(maxSupply, amount);

        maxSupply = amount;
    }

    // ====== Minter ======
    function setMinter(address minter_, bool enabled) external onlyOwner {
        require(minter_ != address(0), "Invalid minter");
        minter[minter_] = enabled;
        emit SetMinter(minter_, enabled);
    }

    modifier onlyMinter() {
        require(minter[msg.sender], "Only minter");
        _;
    }

    function setNotRevealedURI(string memory notRevealedURI_)
        external
        onlyOwner
    {
        notRevealedURI = notRevealedURI_;
    }


    function mint(address to, uint256 quantity) external onlyMinter {
        _batchMint(to, quantity);
    }  


    function _batchMint(address to, uint256 quantity) internal {
        require(quantity > 0, "Invalid quantity");
        require(to != address(0), "Mint to the zero address");
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");

        _safeMint(to, quantity);
    }


    function setBaseURI(string calldata uri) external onlyOwner {
        _baseURI = uri;
    }

    function reveal(uint256 tokenId) external onlyOwner {
        maxRevealedId = tokenId;
        emit Revealed(totalSupply(), tokenId);
    }

    function _isRevealed(uint256 tokenId) private view returns (bool) {
        return tokenId <= maxRevealedId;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!_isRevealed(tokenId)) {
            return notRevealedURI;
        }

        if (bytes(_baseURI).length == 0) {
            return notRevealedURI;
        }

        return super.tokenURI(tokenId);
    }

    function burn(uint256 tokenId) external {
        transferFrom(
            msg.sender,
            address(0x000000000000000000000000000000000000dEaD),
            tokenId
        );
    }


    /// *****  mint  *****
    function togglePublicMintStatus() external override onlyOwner {
        publicMintActive = !publicMintActive;
    }

    function devMint(uint16 quantity, address to) external override onlyOwner {
        _devMint(quantity, to);
    }

    function devMintToMultiAddr(uint16 quantity, address[] calldata addresses)
        external
        override
        onlyOwner
    {
        require(addresses.length > 0, "Invalid addresses");

        for (uint256 i = 0; i < addresses.length; i++) {
            _devMint(quantity, addresses[i]);
        }
    }

    function setPublicMintConf(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    ) external onlyOwner {
        require((maxMint <= maxSupply), "Max supply exceeded");
        publicMintConf = MintConf(maxMint, maxPerAddrMint, price);
    }


    function publicMint(uint16 quantity) external {
        require(publicMintActive && publicMintConf.price == 0, "Public mint is not active");
        doPublicMint(msg.sender, quantity);
    }

    function payMint(uint16 quantity) external payable {
        require(publicMintActive, "Public mint is not active");
        doPublicMint(msg.sender, quantity);
        _refundIfOver(uint256(publicMintConf.price) * quantity);
    }

    function doPublicMint(address to, uint16 quantity) internal {
        require(
            publicAddrMinted[to] + quantity <= publicMintConf.maxPerAddrMint,
            "Max mint amount per account exceeded");

        publicMinted += quantity;
        publicAddrMinted[to] += quantity;

        _batchMint(to, quantity);
    }


    function withdraw() external override onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function _devMint(uint16 quantity, address to) private {
        require(devMinted + quantity <= devReserve, "Max reserve exceeded");

        devMinted += quantity;
        _batchMint(to, quantity);
    }


    function _refundIfOver(uint256 spend) private {
        require(msg.value >= spend, "Need to send more ETH");

        if (msg.value > spend) {
            payable(msg.sender).transfer(msg.value - spend);
        }
    }
}