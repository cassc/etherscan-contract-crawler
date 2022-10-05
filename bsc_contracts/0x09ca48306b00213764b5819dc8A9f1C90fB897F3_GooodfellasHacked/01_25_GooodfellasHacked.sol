// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./erc721/ERC721Base.sol";
import "./erc721/ERC721Reservable.sol";
import "./erc721/ERC721Whitelist.sol";
import "./MintpassMintable.sol";
import "./interfaces/IRenderer.sol";
import "./interfaces/IERC721Listener.sol";


/**
 * @title Gooodfellas Hacked Contract
 */
contract GooodfellasHacked is ERC721Base, MintpassMintable, ERC721Reservable, ERC721Whitelist, ReentrancyGuard {
	using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address payable;

    Counters.Counter private tokenIds;
    string private baseURI;

    uint256 public maxMintPerTx = 50;
    uint256 public immutable maxSupply;
    address payable public paymentReceiver;
    address public renderer;
    address public listener;

    uint256 public price = 0.27 ether;
    uint256 public priceWithMintpass = 0.22 ether;
    bool public mintActive = false;
    bool public whitelistOnly = true;
    string public provenance = "";
    uint256 public preminted;


    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _maxReserved,
        uint256 _maxWhitelistSpots,
        address payable _paymentReceiver,
        address _mintpass
    )
        ERC721(_name, _symbol)
        ERC721Reservable(_maxReserved)
        ERC721Whitelist(_maxWhitelistSpots)
        MintpassMintable(_mintpass)
    {
        require(_paymentReceiver != address(0), "Payment receiver not set");
        maxSupply = _maxSupply;
        paymentReceiver = _paymentReceiver;
    }


    // forward any BNB send to this contract to paymentReceiver
    receive() external payable {
        paymentReceiver.sendValue(msg.value);
    }


    /**
     * @notice Mint `_amount` nfts.
     * @param _amount: amount of nfts to mint
     */
    function mint(uint256 _amount) external payable {
        uint256 _price = priceFor(msg.sender);
        if (whitelistOnly) consumeWhitelistSpots(msg.sender, _amount);
        require(msg.value == _price * _amount, "Value sent does not match price");

        paymentReceiver.sendValue(msg.value);

        _mintTo(msg.sender, _amount);
    }

    /**
     * @notice Mint `_amount` nfts for `_to`.
     * @param _to: wallet to mint nfts to
     * @param _amount: amount of nfts to mint
     * @dev Used by other contracts to mint nfts for user
     */
    function mintFor(address _to, uint256 _amount) external payable {
        uint256 _price = priceFor(_to);
        if (whitelistOnly) consumeWhitelistSpots(_to, _amount);
        require(msg.value == _price * _amount, "Value sent does not match price");

        paymentReceiver.sendValue(msg.value);

        _mintTo(_to, _amount);
    }

    /**
     * @notice Premint `_amount` nfts for `_to`.
     * @param _to: wallet to mint nfts to
     * @param _amount: amount of nfts to mint
     * @dev Used by owner to premint nfts for marketplaces which require preminted tokens. Premints are not reserved!
     */
    function premint(address _to, uint256 _amount) external onlyOwner {
        preminted += _amount;
        _mintTo(_to, _amount);
    }

    /**
     * @notice Forward BNB which ended up in this contract by accident to paymentReceiver. Only owner.
     */
    function forwardFunds() external onlyOwner nonReentrant {
        uint256 available = address(this).balance;
        require(available > 0, "Nothing to withdraw");
        paymentReceiver.sendValue(available);
    }

    /**
     * @notice Change price to `_price` in WEI.
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Change price for minting with owning a mintpass to `_price` in WEI.
     */
    function setPriceWithMintpass(uint256 _price) external onlyOwner {
        priceWithMintpass = _price;
    }

    /**
     * @notice Change max minting amount per transaction
     */
    function setMaxMintPerTx(uint256 _maxMintPerTx) external onlyOwner {
        require(_maxMintPerTx > 0, "Invalid maxMintPerTx");
        maxMintPerTx = _maxMintPerTx;
    }

    /**
     * @notice Set whitelistOnly to `_whitelistOnly`. Only callable by owner.
     */
    function setWhitelistOnly(bool _whitelistOnly) external onlyOwner {
        whitelistOnly = _whitelistOnly;
    }

    /**
     * @notice Set mintActive to `_mintActive`. Only callable by owner.
     */
    function setMintActive(bool _mintActive) external onlyOwner {
        mintActive = _mintActive;
    }

    /**
     * @notice Set payment receiver to `_paymentReceiver`. Only callable by owner.
     */
    function setPaymentReceiver(address payable _paymentReceiver) external onlyOwner {
        require(_paymentReceiver != address(0), "Invalid payment receiver");
        paymentReceiver = _paymentReceiver;
    }

    /**
     * @notice Allows the owner to set the base URI to be used for all not revealed token IDs
     * @param _uri: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        provenance = provenanceHash;
    }

    function setRenderer(address _renderer) external onlyOwner {
        renderer = _renderer;
    }
    
    function setListener(address _listener) external onlyOwner {
        listener = _listener;
    }

    function _mintTo(address _to, uint256 _amount) internal override(ERC721Reservable, MintpassMintable) nonReentrant {
        require(mintActive || msg.sender == owner(), "Mint not started yet");
        require(_amount > 0 && _amount <= maxMintPerTx, "Invalid amount");
        require((totalSupply() + _amount + reservedOpen + _mintpassMintsOpen()) <= maxSupply, "Exceeds maxSupply");
        
        for (uint256 i = 0; i < _amount; ++i) {
            tokenIds.increment();
            _safeMint(_to, tokenIds.current());
        }
    }

    /** 
     * @notice returns current price for user, applying current whitelist spots.
     */
    function priceFor(address _user) public view returns (uint256) {
        return _hasMintpass(_user) ? priceWithMintpass : price;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (renderer == address(0)) {
            return super.tokenURI(tokenId);
        }
        return IRenderer(renderer).tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (listener != address(0)) {
            IERC721Listener(listener).beforeTokenTransfer(from, to, tokenId);
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._afterTokenTransfer(from, to, tokenId);
        if (listener != address(0)) {
            IERC721Listener(listener).afterTokenTransfer(from, to, tokenId);
        }
    }
}