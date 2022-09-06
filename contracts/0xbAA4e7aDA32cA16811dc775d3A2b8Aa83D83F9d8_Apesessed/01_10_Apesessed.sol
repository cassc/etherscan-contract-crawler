// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Apesessed is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    bytes32 public teamMerkleRoot;

    string public uriPrefix;
    string public baseExtension = ".json";

    uint256 public price = 0.003 ether;
    uint256 public maxSupply = 6969;
    uint256 public publicSupply = 5900;
    uint256 public whitelistDevSupply = 1069;
    uint256 public maxMintAmountPerTx = 10;
    uint256 public maxMintAmountPerWallet = 10;
    uint256 public maxFreeMint = 1;
    uint256 public maxFreeWlMint = 2;
    uint256 public totalWlMinted = 0;

    bool public paused = false;

    constructor(
        string memory _uriPrefix,
        bytes32 _merkleRoot,
        bytes32 _teamMerkleRoot
    ) ERC721A("Apesessed", "APSSD") {
        uriPrefix = _uriPrefix;
        merkleRoot = _merkleRoot;
        teamMerkleRoot = _teamMerkleRoot;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        uint256 numMinted = _numberMinted(_msgSender());
        uint256 totalSupply = totalSupply();
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            numMinted + _mintAmount <= maxMintAmountPerWallet,
            "Max mint per wallet exceeded!"
        );
        require(
            totalSupply + _mintAmount <= maxSupply - totalWlMinted,
            "Max public supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        uint256 numMinted = _numberMinted(_msgSender());
        if (numMinted < maxFreeMint && numMinted + _mintAmount > maxFreeMint) {
            require(
                msg.value == price * (numMinted + _mintAmount - maxFreeMint),
                "Insufficient funds!"
            );
        }
        if (numMinted >= maxFreeMint) {
            require(msg.value >= price * _mintAmount, "Insufficient funds!");
        }
        _;
    }
    modifier whitelistMintCompliance(uint256 _mintAmount) {
        uint256 numMinted = _numberMinted(_msgSender());
        uint256 totalSupply = totalSupply();
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            numMinted + _mintAmount <= maxMintAmountPerWallet,
            "Max mint per wallet exceeded!"
        );
        require(
            totalSupply + _mintAmount <= maxSupply,
            "Max public supply exceeded!"
        );
        _;
    }
    modifier whitelistMintPriceCompliance(uint256 _mintAmount) {
        uint256 numMinted = _numberMinted(_msgSender());
        if (
            numMinted < maxFreeWlMint && numMinted + _mintAmount > maxFreeWlMint
        ) {
            require(
                msg.value == price * (numMinted + _mintAmount - maxFreeWlMint),
                "Insufficient funds!"
            );
        }
        if (numMinted >= maxFreeWlMint) {
            require(msg.value >= price * _mintAmount, "Insufficient funds!");
        }
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        whitelistMintCompliance(_mintAmount)
        whitelistMintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(!paused, "The contract is paused!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        _safeMint(_msgSender(), _mintAmount);
        totalWlMinted++;
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        _safeMint(_msgSender(), _mintAmount);
    }

    function teamMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
    {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, teamMerkleRoot, leaf),
            "Invalid proof!"
        );

        uint256 totalSupply = totalSupply();
        uint256 numMinted = _numberMinted(_msgSender());
        require(_mintAmount + numMinted <= 300);
        require(totalSupply + _mintAmount <= maxSupply, "Max supply exceeded!");

        _safeMint(_msgSender(), _mintAmount);
    }

    function devMint(uint256 _mintAmount, address _receiver) public onlyOwner {
        uint256 totalSupply = totalSupply();
        require(_mintAmount + totalSupply <= maxSupply, "Max Supply exceeded!");
        _safeMint(_receiver, _mintAmount);
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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet)
        public
        onlyOwner
    {
        maxMintAmountPerWallet = _maxMintAmountPerWallet;
    }

    function setMaxFreeMint(uint256 _maxFreeMint) public onlyOwner {
        maxFreeMint = _maxFreeMint;
    }

    function setWhitelistDevSupply(uint256 _whitelistDevSupply)
        public
        onlyOwner
    {
        whitelistDevSupply = _whitelistDevSupply;
    }

    function setUriPrefix(string memory __baseURI) public onlyOwner {
        uriPrefix = __baseURI;
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setTeamMerkleRoot(bytes32 _teamMerkleRoot) public onlyOwner {
        teamMerkleRoot = _teamMerkleRoot;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return (_numberMinted(owner));
    }
}