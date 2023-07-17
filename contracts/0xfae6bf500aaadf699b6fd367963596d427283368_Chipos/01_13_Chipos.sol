// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Chipos is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public whiteListmerkleRoot =
        0x0600f4d0ada2bfd3a6d073dc0cdbc9c750786f1d067f140f5c227b1310a4acf2;
        

    mapping(address => uint256) public whiteListClaimed;
    mapping(address => uint256) public addressMintCount;

    uint256 public maxMintWL = 2;
    uint256 public maxMintAmountPerWallet = 3;
    uint256 public cost = 0.04 ether;
    uint256 public maxSupply = 3333;
    string public uriPrefix;
    string public uriSuffix = ".json";
    string public hiddenMetadataUri =
        "ipfs://QmcLUXSv7KMDgqZgaJsmW8aUdJtLurCs8keMYkZfyPq247/preReveal.json";
    bool public paused = true;
    bool public revealed = false;
    bool public whiteListMintEnabled = false;

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC721A(_tokenName, _tokenSymbol)
    {}

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 &&
                addressMintCount[msg.sender] + _mintAmount <=
                maxMintAmountPerWallet,
            "Amount bigger than allowed max mint!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function whiteListMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(whiteListMintEnabled, "The whitelist sale is not enabled!");
        require(
            whiteListClaimed[_msgSender()] + _mintAmount <= maxMintWL,
            "Address already claimed!"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, whiteListmerkleRoot, leaf),
            "Invalid proof!"
        );
        uint256 ownerMintedCountWl = whiteListClaimed[_msgSender()] +
            _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
        addressMintCount[_msgSender()] = ownerMintedCountWl;
        whiteListClaimed[_msgSender()] = ownerMintedCountWl;
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        addressMintCount[_msgSender()] =
            addressMintCount[_msgSender()] +
            _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex
        ) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];
            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }
                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;
                    ownedTokenIndex++;
                }
            }
            currentTokenId++;
        }
        return ownedTokenIds;
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
        if (revealed == false) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setmaxMintWL(uint256 _maxMintWL) public onlyOwner {
        maxMintWL = _maxMintWL;
    }

    function setmaxMintPerWallet(uint256 _maxMintAmountPerWallet)
        public
        onlyOwner
    {
        maxMintAmountPerWallet = _maxMintAmountPerWallet;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setWhiteListMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        whiteListmerkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whiteListMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}