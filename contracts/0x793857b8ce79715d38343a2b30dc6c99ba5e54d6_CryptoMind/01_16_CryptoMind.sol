// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CryptoMind is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ECDSA for bytes32;

    Counters.Counter private soldCounter;
    Counters.Counter private reservedMintedCounter;

    bool public isAuctionActive = false;
    bool public isWhitelistSaleActive = false;
    bool public isPublicSaleActive = false;

    bytes32 public whitelistMerkleRoot;
    address public signerAddress;

    uint256 public maxSupply;
    uint256 public reserved;
    uint256 public whitelistPrice = 0.5 ether;
    uint256 public publicSalePrice = 0.5 ether;
    uint256 public tierSupply;
    uint256 public maxMintPerTx;

    uint256 public publicSaleStartTime;
    uint256 public whitelistSaleStartTime;
    uint256 public whitelistSaleEndTime;

    string private contractURI_;
    string private baseTokenURI;
    mapping(address => bool) public whitelistClaimed;
    mapping(string => bool) private nonceUsed;

    struct Auction {
        uint256 startTime;
        uint256 timeStep;
        uint256 startPrice;
        uint256 endPrice;
        uint256 priceStep;
        uint256 stepNumber;
    }

    Auction public auction;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        string memory _uri,
        uint256 _maxMintPerTx,
        uint256 _maxSupply,
        uint256 _reserved,
        uint256 _tierSupply,
        bytes32 _whitelistMerkleRoot,
        address _signerAddress
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
        contractURI_ = _uri;
        maxMintPerTx = _maxMintPerTx;
        maxSupply = _maxSupply;
        reserved = _reserved;
        tierSupply = _tierSupply;
        whitelistMerkleRoot = _whitelistMerkleRoot;
        signerAddress = _signerAddress;
    }

    modifier onlyWhitelistActive() {
        require(isWhitelistSaleActive, "Whitelist must be active to mint");
        require(
            block.timestamp >= whitelistSaleStartTime &&
                block.timestamp <= whitelistSaleEndTime,
            "Not in whitelist sale period"
        );
        _;
    }
    modifier onlyPublicSaleActive() {
        require(isPublicSaleActive, "Public sale must be active to mint");
        require(
            block.timestamp >= publicSaleStartTime,
            "Public sale has not started yet"
        );
        _;
    }
    modifier onlyInWhitelist(bytes32[] calldata _proofs) {
        require(!whitelistClaimed[msg.sender], "Address has already claimed.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proofs, whitelistMerkleRoot, leaf),
            "Invalid proof."
        );
        _;
    }

    modifier onlyAuctionActive() {
        require(isAuctionActive, "Auction must be active to mint");
        require(
            block.timestamp >= auction.startTime,
            "Auction has not started yet."
        );
        _;
    }
    modifier onlyValidSignature(
        uint256 _quantity,
        bytes32 _hash,
        bytes memory _signature,
        string memory _nonce,
        uint256 _expiredAt
    ) {
        require(!nonceUsed[_nonce], "Hash used");
        require(block.timestamp < _expiredAt, "signature expired");
        require(
            matchAddressSigner(_hash, _signature),
            "Not allow mint directly"
        );
        require(
            hashTransaction(msg.sender, _quantity, _nonce, _expiredAt) == _hash,
            "Hash not match"
        );
        _;
    }
    modifier onlySufficientEther(uint256 _quantity, uint256 _price) {
        require(msg.value >= _quantity * _price, "Insufficient ether");
        _;
    }
    modifier onlySufficientSupply(uint256 _quantity) {
        require(
            reservedMintedCounter.current() +
                soldCounter.current() +
                _quantity <=
                maxSupply,
            "Exceed max supply"
        );
        require(
            reservedMintedCounter.current() +
                soldCounter.current() +
                _quantity <=
                tierSupply,
            "Exceed tier supply"
        );
        _;
    }
    modifier onlySufficientReservedSupply(uint256 _quantity) {
        require(
            reservedMintedCounter.current() + _quantity <= reserved,
            "Exceeds reserved supply"
        );
        _;
    }
    modifier onlyValidQuantity(uint256 _quantity) {
        require(_quantity > 0 && _quantity <= maxMintPerTx, "Invalid quantity");
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setContractURI(string calldata _uri) external onlyOwner {
        contractURI_ = _uri;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setWhitelistSaleActive(bool _isWhitelistSaleActive)
        public
        onlyOwner
    {
        require(isWhitelistSaleActive != _isWhitelistSaleActive, "Already set");
        isWhitelistSaleActive = _isWhitelistSaleActive;
    }

    function setAuctionActive(bool _isAuctionActive) public onlyOwner {
        require(isAuctionActive != _isAuctionActive, "Already set");
        isAuctionActive = _isAuctionActive;
    }

    function setPublicSaleActive(bool _isPublicSaleActive) public onlyOwner {
        require(isPublicSaleActive != _isPublicSaleActive, "Already set");
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setTierSupply(uint256 _tierSupply) public onlyOwner {
        require(
            maxSupply >= _tierSupply,
            "Tier supply must be less than max supply"
        );
        tierSupply = _tierSupply;
    }

    function setAuction(Auction memory _auction) public onlyOwner {
        require(_auction.startTime > auction.startTime, "Invalid start time");
        auction = _auction;
    }

    function setWhitelistPrice(uint256 _whitelistPrice) public onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    function setPublicSalePrice(uint256 _publicSalePrice) public onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function setPublicSaleStartTime(uint256 _publicSaleStartTime)
        public
        onlyOwner
    {
        publicSaleStartTime = _publicSaleStartTime;
    }

    function setWhitelistSaleTime(
        uint256 _whitelistSaleStartTime,
        uint256 _whitelistSaleEndTime
    ) public onlyOwner {
        whitelistSaleStartTime = _whitelistSaleStartTime;
        whitelistSaleEndTime = _whitelistSaleEndTime;
    }

    function getAuctionPrice() public view returns (uint256) {
        Auction memory currentAuction = auction;
        if (!isAuctionActive) {
            return 0;
        }
        if (block.timestamp < currentAuction.startTime) {
            return currentAuction.startPrice;
        }
        uint256 step = (block.timestamp - currentAuction.startTime) /
            currentAuction.timeStep;
        if (step > currentAuction.stepNumber) {
            step = currentAuction.stepNumber;
        }
        return
            currentAuction.startPrice > step * currentAuction.priceStep
                ? currentAuction.startPrice - step * currentAuction.priceStep
                : currentAuction.endPrice;
    }

    function reservedClaim(address[] calldata _addresses)
        public
        onlyOwner
        onlySufficientSupply(_addresses.length)
        onlySufficientReservedSupply(_addresses.length)
    {
        require(
            !isWhitelistSaleActive && !isAuctionActive && !isPublicSaleActive,
            "Can't claim during sale"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            uint256 tokenId = reservedMintedCounter.current() +
                soldCounter.current() +
                1;
            _safeMint(_addresses[i], tokenId);
            reservedMintedCounter.increment();
        }
    }

    function publicMint(
        bytes32 _hash,
        bytes memory _signature,
        string memory _nonce,
        uint256 _expiredAt
    )
        public
        payable
        onlyPublicSaleActive
        onlyValidSignature(1, _hash, _signature, _nonce, _expiredAt)
        onlySufficientEther(1, publicSalePrice)
        onlySufficientSupply(1)
        onlyValidQuantity(1)
    {
        saleMint(msg.sender);

        nonceUsed[_nonce] = true;
    }

    function auctionMint(
        bytes32 _hash,
        bytes memory _signature,
        string memory _nonce,
        uint256 _expiredAt
    )
        public
        payable
        onlyAuctionActive
        onlyValidSignature(1, _hash, _signature, _nonce, _expiredAt)
        onlySufficientEther(1, getAuctionPrice())
        onlySufficientSupply(1)
        onlyValidQuantity(1)
    {
        saleMint(msg.sender);

        nonceUsed[_nonce] = true;
    }

    function whitelistMint(bytes32[] calldata _proofs)
        public
        payable
        onlyWhitelistActive
        onlyInWhitelist(_proofs)
        onlySufficientEther(1, whitelistPrice)
        onlySufficientSupply(1)
        onlyValidQuantity(1)
    {
        saleMint(msg.sender);

        whitelistClaimed[msg.sender] = true;
    }

    function saleMint(address to) internal {
        uint256 tokenId = reservedMintedCounter.current() +
            soldCounter.current() +
            1;
        _safeMint(to, tokenId);
        soldCounter.increment();
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 index;
        uint256 loopThrough = totalSupply();
        for (uint256 i; i < loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == _owner) {
                    tokenIds[index] = i;
                    index++;
                }
            } else if (!_exists && tokenIds[tokenCount - 1] == 0) {
                loopThrough++;
            }
        }
        return tokenIds;
    }

    function withdraw(address _to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
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
        return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
    }

    function contractURI() public view returns (string memory) {
        return contractURI_;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function hashTransaction(
        address _sender,
        uint256 _quantity,
        string memory _nonce,
        uint256 _expiredAt
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(_sender, _quantity, _nonce, _expiredAt)
                )
            )
        );

        return hash;
    }

    function matchAddressSigner(bytes32 _hash, bytes memory _signature)
        private
        view
        returns (bool)
    {
        return signerAddress == _hash.recover(_signature);
    }
}