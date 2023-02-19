// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

error ErrorSaleNotStarted();
error ErrorInsufficientFund();
error ErrorExceedTransactionLimit();
error ErrorExceedFreeLimit();

interface IBLDCoin {
    function holderClaim(address holder, uint64 amount) external;
}

contract BlurDAO is ERC2981, ERC721A, Ownable {
    using Address for address payable;
    using ECDSA for bytes32;
    using Strings for uint256;

    IBLDCoin public immutable _bldCoin;

    uint256 public _mintPrice = 0.0033 ether;
    uint64 public _txLimit = 30;
    uint64 public _freeLimit = 2;

    bool public _started;
    bool public _revealed;
    string public _metadataURI = "https://aptoki.mypinata.cloud/ipfs/QmXq8wYiutbx6VeGi1MFbzcfdbcNHM6AVtdjuFWSh9Gt3f";

    constructor(address bldCoin) ERC721A("BlurDAO", "BDAO") {
      require(bldCoin != address(0));
      _bldCoin = IBLDCoin(bldCoin);
       _setDefaultRoyalty(owner(), 800);
    }

    function mint(uint64 amount) external payable {
        if (!_started) revert ErrorSaleNotStarted();
        if (amount > _txLimit) revert ErrorExceedTransactionLimit();

        uint256 requiredValue = amount * _mintPrice;
        uint64 userMinted = _getAux(msg.sender);
        if (userMinted < _freeLimit) {
            uint64 diff = _freeLimit - userMinted;
            if (amount > diff) {
                requiredValue -= diff * _mintPrice;
            } else {
                requiredValue = 0;
            }
        }

        userMinted += amount;
        _setAux(msg.sender, uint64(userMinted));

        if (msg.value < requiredValue) revert ErrorInsufficientFund();
        _bldCoin.holderClaim(msg.sender, amount);
        _safeMint(msg.sender, amount);
    }

    struct State {
        uint256 mintPrice;
        uint64 txLimit;
        uint64 freeLimit;
        uint256 totalMinted;
        uint64 userMinted;
        bool started;
    }

    function _state(address minter) external view returns (State memory) {
        return
            State({
                mintPrice: _mintPrice,
                txLimit: _txLimit,
                freeLimit: _freeLimit,
                totalMinted: ERC721A._totalMinted(),
                userMinted: _getAux(minter),
                started: _started
            });
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return
            _revealed
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function godMint(address to, uint32 amount) external onlyOwner {
        _safeMint(to, amount);
    }

    function setFeeNumerator(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setMintPrice(uint256 mintPrice) external onlyOwner {
        _mintPrice = mintPrice;
    }

    function setTxLimit(uint64 txLimit) external onlyOwner {
      _txLimit = txLimit;
    }

    function setFreeLimit(uint64 freeLimit) external onlyOwner {
      if (freeLimit >= _txLimit) revert ErrorExceedTransactionLimit();
      _freeLimit = freeLimit;
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function setRevealed(bool revealed) external onlyOwner {
        _revealed = revealed;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}