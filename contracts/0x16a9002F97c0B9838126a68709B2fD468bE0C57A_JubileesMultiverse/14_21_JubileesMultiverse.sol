//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../interfaces/ILayerZeroReceiver.sol";

contract JubileesMultiverse is
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    ILayerZeroReceiver
{
    using Strings for uint256;

    bytes32 public presaleMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    mapping(address => uint256) public presaleClaims;
    mapping(address => uint256) public whitelistMints;
    mapping(address => uint256) public walletTokenCount;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public constant PRESALE_CLAIM_PRICE = 0.00 ether;
    uint256 public constant WHITELIST_SALE_PRICE = 0.0088 ether;
    uint256 public constant PUBLIC_SALE_PRICE = 0.0099 ether;

    uint256 public constant MAX_WHITELIST_MINTS = 25;
    uint256 public constant MAX_PRESALE_CLAIM = 1;

    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 private constant TOKENS_RESERVED = 500;

    bool public presaleClaim = false;
    bool public whitelistSale = false;
    bool public publicSale = false;

    bool public paused = true;
    bool public revealed = false;

    uint256 counter = 0;
    uint256 nextId = 0;
    uint256 gas = 350000;
    ILayerZeroEndpoint public endpoint;
    mapping(uint256 => bytes) public uaMap;

    event ReceiveNFT(
        uint16 _srcChainId,
        address _from,
        uint256 _tokenId,
        uint256 counter
    );

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri,
        address _endpoint,
        uint256 startId
    ) ERC721A(_tokenName, _tokenSymbol) {
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
        endpoint = ILayerZeroEndpoint(_endpoint);
        nextId = startId;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistSale, "The whitelist sale is not enabled!");
        require(
            (whitelistMints[_msgSender()] + _mintAmount) <= MAX_WHITELIST_MINTS,
            "Your wallet is out of whitelist mints!"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Invalid proof!"
        );
        require(
            msg.value >= (WHITELIST_SALE_PRICE),
            "Ether value sent is not correct"
        );
        whitelistMints[_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function PublicMint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
    {
        require(!paused, "Minting is paused.");
        require(publicSale, "Public sale is not Yet Active.");
        require(
            (totalSupply() + _mintAmount) <= maxSupply,
            "Beyond Max Supply"
        );
        require(
            msg.value >= (PUBLIC_SALE_PRICE),
            "Ether value sent is not correct"
        );
        _safeMint(msg.sender, _mintAmount);
        walletTokenCount[msg.sender] += _mintAmount;
    }

    function claimPresale(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
    {
        require(!paused, "Minting is paused.");
        require(presaleClaim, "The claiming process hasn't begun!");
        require(
            (presaleClaims[_msgSender()] + 1) <= MAX_PRESALE_CLAIM,
            "Your wallet is out of whitelist mints!"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf),
            "Invalid proof!"
        );
        require(
            (totalSupply() + _mintAmount) <= maxSupply,
            "Cannot mint beyond max supply"
        );
        require(
            (presaleClaims[msg.sender] + 1) <= 1,
            "You've already claimed your Jubilee!"
        );
        presaleClaims[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
        walletTokenCount[msg.sender] += _mintAmount;
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
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

    function setUaAddress(uint256 _dstId, bytes calldata _uaAddress)
        public
        onlyOwner
    {
        uaMap[_dstId] = _uaAddress;
    }

    // Default Mint Function for this Repo
    // function mint() external payable {
    //     require(nextId + 1 <= MAX, "Exceeds supply");
    //     nextId += 1;
    //     _safeMint(msg.sender, nextId);
    //     counter += 1;
    // }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
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

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setPresaleMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        presaleMerkleRoot = _merkleRoot;
    }

    function togglePresaleClaim() external onlyOwner {
        presaleClaim = !presaleClaim;
    }

    function toggleWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function reserveTokens() public onlyOwner {
        require(!paused, "Minting is paused.");
        require(
            (totalSupply() + TOKENS_RESERVED) <= maxSupply,
            "Cannot mint beyond max supply"
        );
        _safeMint(msg.sender, TOKENS_RESERVED);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function crossChain(
        uint16 _dstChainId,
        bytes calldata _destination,
        uint256 tokenId
    ) public payable {
        require(msg.sender == ownerOf(tokenId), "Not the owner");
        // burn NFT
        _burn(tokenId);
        counter -= 1;
        bytes memory payload = abi.encode(msg.sender, tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gas);

        (uint256 messageFee, ) = endpoint.estimateFees(
            _dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );

        require(
            msg.value >= messageFee,
            "Must send enough value to cover messageFee"
        );

        endpoint.send{value: msg.value}(
            _dstChainId,
            _destination,
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _from,
        uint64,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint));
        require(
            _from.length == uaMap[_srcChainId].length &&
                keccak256(_from) == keccak256(uaMap[_srcChainId]),
            "Call must send from valid user application"
        );
        address from;
        assembly {
            from := mload(add(_from, 20))
        }
        (address toAddress, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        // mint the tokens
        _safeMint(toAddress, tokenId);
        counter += 1;
        emit ReceiveNFT(_srcChainId, toAddress, tokenId, counter);
    }

    // Endpoint.sol estimateFees() returns the fees for the message
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        return
            endpoint.estimateFees(
                _dstChainId,
                _userApplication,
                _payload,
                _payInZRO,
                _adapterParams
            );
    }
}