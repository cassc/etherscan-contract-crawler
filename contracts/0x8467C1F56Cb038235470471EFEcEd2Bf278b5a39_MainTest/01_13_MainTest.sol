// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MainTest is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRootPhaseOne;
    bytes32 public merkleRootPhaseTwo;
    bytes32 public merkleRootPhaseThree;
    mapping(address => bool) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupplyPhaseOne;
    uint256 public maxSupplyPhaseTwo;
    uint256 public maxSupplyPhaseThree;
    uint256 public maxMintAmountPerTx;

    bool public paused = true;
    bool public phaseOneEnabled = false;
    bool public phaseTwoEnabled = false;
    bool public phaseThreeEnabled = false;
    bool public revealed = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupplyPhaseOne,
        uint256 _maxSupplyPhaseTwo,
        uint256 _maxSupplyPhaseThree,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        maxSupplyPhaseOne = _maxSupplyPhaseOne;
        maxSupplyPhaseTwo = _maxSupplyPhaseTwo;
        maxSupplyPhaseThree = _maxSupplyPhaseThree;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupplyPhaseThree,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintCompliancePhaseOne(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupplyPhaseOne,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintCompliancePhaseTwo(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupplyPhaseTwo,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintCompliancePhaseThree(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupplyPhaseThree,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function phaseOneWhitelistMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    )
        public
        payable
        mintCompliancePhaseOne(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(phaseOneEnabled, "Phase one sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRootPhaseOne, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function phaseTwoWhitelistMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    )
        public
        payable
        mintCompliancePhaseTwo(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(phaseTwoEnabled, "Phase two sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRootPhaseTwo, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function phaseThreeWhitelistMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    )
        public
        payable
        mintCompliancePhaseThree(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(phaseThreeEnabled, "Phase three sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRootPhaseThree, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliancePhaseThree(_mintAmount)
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
            ownedTokenIndex < ownerTokenCount &&
            currentTokenId <= maxSupplyPhaseThree
        ) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
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

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
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

    function setMerkleRootPhaseOne(bytes32 _merkleRootPhaseOne)
        public
        onlyOwner
    {
        merkleRootPhaseOne = _merkleRootPhaseOne;
    }

    function setMerkleRootPhaseTwo(bytes32 _merkleRootPhaseTwo)
        public
        onlyOwner
    {
        merkleRootPhaseTwo = _merkleRootPhaseTwo;
    }

    function setMerkleRootPhaseThree(bytes32 _merkleRootPhaseThree)
        public
        onlyOwner
    {
        merkleRootPhaseThree = _merkleRootPhaseThree;
    }

    function setPhaseOneEnabled(bool _state) public onlyOwner {
        phaseOneEnabled = _state;
    }

    function setPhaseTwoEnabled(bool _state) public onlyOwner {
        phaseTwoEnabled = _state;
    }

    function setPhaseThreeEnabled(bool _state) public onlyOwner {
        phaseThreeEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}