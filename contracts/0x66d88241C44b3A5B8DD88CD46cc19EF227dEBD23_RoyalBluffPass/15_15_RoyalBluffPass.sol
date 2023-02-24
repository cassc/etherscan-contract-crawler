// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import './ERC1155A.sol';

error AntiBot();
error SaleNotStarted();
error ExceedMaxPerTransaction();
error ExceedMaxPerWallet();
error ExceedMaxSupply();
error ValueTooLow();
error NotWhitelisted();
error NotTokenOwner();

contract RoyalBluffPass is ERC1155A {
    using Strings for uint256;

    uint256 public epoch;
    uint256 public saleStartTime;
    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 public maxPerTransaction;
    uint256 public maxPerWallet;
    mapping(address => uint256) walletTokens;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _epoch,
        uint256 _saleStartTime,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint256 _maxPerTransaction,
        uint256 _maxPerWallet
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
        epoch = _epoch;
        saleStartTime = _saleStartTime;
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        maxPerTransaction = _maxPerTransaction;
        maxPerWallet = _maxPerWallet;
    }

    /* Modifiers */
    modifier verifyMint(uint256 amount) {
        uint256 currentTime = block.timestamp;

        if (msg.sender != tx.origin) revert AntiBot();
        if (currentTime < saleStartTime) revert SaleNotStarted();
        if (totalSupply(epoch) + amount > maxSupply) revert ExceedMaxSupply();
        if (amount > maxPerTransaction) revert ExceedMaxPerTransaction();
        if (walletTokens[msg.sender] + amount > maxPerWallet) revert ExceedMaxPerWallet();
        if (msg.value < amount * mintPrice) revert ValueTooLow();
        _;
    }

    /* Setters */
    function setUri(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    function setEpoch(uint256 _epoch) public onlyOwner {
        epoch = _epoch;
    }

    function setSaleStartTime(uint256 _saleStartTime) public onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMapPerTransaction(uint256 _maxPerTransaction) public onlyOwner {
        maxPerTransaction = _maxPerTransaction;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /* Transactions */
    function mintToken(uint256 amount) external payable verifyMint(amount) {
        walletTokens[msg.sender] += amount;
        _mint(msg.sender, epoch, amount, '');
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed.');
    }
}