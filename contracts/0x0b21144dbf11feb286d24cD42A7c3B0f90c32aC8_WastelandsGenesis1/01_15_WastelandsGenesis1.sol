// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./utils/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IToken.sol";

contract WastelandsGenesis1 is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;

    string private uriPrefix;
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;

    uint256 public constant maxSupply = 1111;
    uint256 public maxMintAmountPerTx = 10;
    uint256 public maxMintAmountPerWallet = 10;
    uint256 public maxTokenIdPerPhase = 1111;

    bool public publicMintEnabled;
    bool public whitelistMintEnabled;
    bool public revealed;

    bool public mintWithETH = false;
    bool public mintWithToken = true;

    uint256 public tokenCost;
    IToken public token;

    address public dev;

    mapping(address => uint8) public userMintAmount;

    constructor(
        bytes32 _merkleRoot,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _ethCost,
        IToken _tokenAddress,
        uint256 _tokenCost,
        string memory _uriPrefix,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        merkleRoot = _merkleRoot;
        cost = _ethCost;
        dev = msg.sender;
        token = _tokenAddress;
        tokenCost = _tokenCost;
        uriPrefix = _uriPrefix;
        hiddenMetadataUri = _hiddenMetadataUri;
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
        require(
            totalSupply() + _mintAmount <= maxTokenIdPerPhase,
            "Exceeds max supply for current phase!"
        );
        require(
            userMintAmount[msg.sender] + _mintAmount <= maxMintAmountPerWallet, 
            "Max NFTs per wallet"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
            require(msg.value == cost * _mintAmount, "Incorrect payment amount");
            _;
    }

    modifier tokenMintPriceCompliance(uint256 _mintAmount, uint256 _tokenamount) {
            require(_tokenamount == tokenCost * _mintAmount, "Incorrect payment amount");
            _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
        nonReentrant
    {
        require(mintWithETH, "Mint with ETH is turned off");

        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        require(
            balanceOf(_msgSender()) <= maxMintAmountPerWallet,
            "Max NFTs per wallet"
        );    

        _safeMint(_msgSender(), _mintAmount);
    }

    function whitelistTokenMint(uint256 _mintAmount, uint256 _tokenamount, bytes32[] calldata _merkleProof)
        external
        mintCompliance(_mintAmount)
        tokenMintPriceCompliance(_mintAmount, _tokenamount)
        nonReentrant
    {
        require(mintWithToken, "Mint with Token is turned off");

        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        token.burnFrom(msg.sender, _tokenamount);

        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        external
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
        nonReentrant
    {
        require(publicMintEnabled, "Public minting not active.");
        require(mintWithETH, "Mint with ETH is turned off");
        _safeMint(_msgSender(), _mintAmount);
        userMintAmount[msg.sender] = userMintAmount[msg.sender] + uint8(_mintAmount);
    }

    function tokenMint(uint256 _mintAmount, uint256 _tokenamount)
        external
        mintCompliance(_mintAmount)
        tokenMintPriceCompliance(_mintAmount, _tokenamount)
        nonReentrant
    {
        require(publicMintEnabled, "Public minting not active.");
        require(mintWithToken, "Mint with Token is turned off");
        token.burnFrom(msg.sender, _tokenamount);
            
        _safeMint(_msgSender(), _mintAmount);
        userMintAmount[msg.sender] = userMintAmount[msg.sender] + uint8(_mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        external
        onlyOwner
        nonReentrant
    {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        external
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

    function setRevealed(bool _flag) external onlyOwner {
        revealed = _flag;
    }

    function setMintWithETH() external onlyOwner {
        mintWithETH = true;
        mintWithToken = false;
    }

    function setMintWithToken() external onlyOwner {
        mintWithToken = true;
        mintWithETH = false;
    }

    function setMintWithEthAndToken() external onlyOwner {
        mintWithToken = true;
        mintWithETH = true;
    }

    function setToken(IToken _token, uint256 _tokenCost) external onlyOwner {
        token = _token;
        tokenCost = _tokenCost;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        external
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
    
    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        external
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused() external onlyOwner {
        publicMintEnabled = false;
        whitelistMintEnabled = false;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _flag) external onlyOwner {
        whitelistMintEnabled = _flag;
    }

    function setPublicMintEnabled(bool _flag) external onlyOwner {
        publicMintEnabled = _flag;
    }

    function setMaxTokenIdPerPhase(uint256 _tokenId) external onlyOwner {
        maxTokenIdPerPhase = _tokenId;
    }

    function setDev(address _newDev) external onlyOwner {
        dev = _newDev;
    }

    function withdrawETH() external onlyOwner nonReentrant {
        (bool os, ) = payable(dev).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawTokens(address _token) external onlyOwner nonReentrant {
        uint256 contractBalance = IToken(_token).balanceOf(address(this));
        IToken(_token).transfer(dev, contractBalance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}