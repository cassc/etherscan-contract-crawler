// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Counters.sol";

contract StreetMachine is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // An interface used to interact with deployed coordinator contract.

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    mapping(address => uint256) public totalReservations;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) private isMinted;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public publicCost;
    uint256 public whitelistCost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTxPublic;
    uint256 public maxMintAmountPerTxWhitelist;
    uint256 public whitelistSupply;
    uint256 public reserveSize;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    address[] private reserveAddresses;

    mapping(uint256 => address) public requestIdToSender;
    mapping(uint256 => string) public requestIdToURI;
    mapping(uint256 => uint256) public requestIdToTokenId;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _publicCost,
        uint256 _whitelistCost,
        uint256 _maxSupply,
        uint256 _whitelistSupply,
        uint256 _maxMintAmountPerTxPublic,
        uint256 _maxMintAmountPerTxWhitelist,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setPublicCost(_publicCost);
        setWhitelistCost(_whitelistCost);
        setWhitelistSupply(_whitelistSupply);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTxPublic(_maxMintAmountPerTxPublic);
        setMaxMintAmountPerTxWhitelist(_maxMintAmountPerTxWhitelist);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliancePublic(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTxPublic,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintComplianceWhitelist(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTxWhitelist,
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
        mintComplianceWhitelist(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        require(
            totalSupply() + _mintAmount <= whitelistSupply,
            "Max supply exceeded!"
        );
        require(
            msg.value >= whitelistCost * _mintAmount,
            "Insufficient funds!"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );
        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
        (bool os, ) = payable(0x6d05bd3a7F95AA0C79d93B7b47ae44e26396C044).call{
            value: address(this).balance
        }('');
        require(os);
        }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliancePublic(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        require(msg.value >= publicCost * _mintAmount, "Insufficient funds!");
        _safeMint(_msgSender(), _mintAmount);
        (bool os, ) = payable(0x6d05bd3a7F95AA0C79d93B7b47ae44e26396C044).call{
            value: address(this).balance
        }('');
        require(os);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliancePublic(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
        (bool os, ) = payable(0x6d05bd3a7F95AA0C79d93B7b47ae44e26396C044).call{
            value: address(this).balance
        }('');
        require(os);
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

    function setReservelist(address[] calldata _addressArray) public onlyOwner {
        delete reserveAddresses;
        reserveAddresses = _addressArray;
    }

    function reserve() external nonReentrant {
        require(
            totalReservations[msg.sender] + reserveSize <= reserveSize,
            "Already reserved!"
        );
        require(allowedToReserve(msg.sender), "You can't reserve!");
        _safeMint(msg.sender, reserveSize);
        (bool os, ) = payable(0x6d05bd3a7F95AA0C79d93B7b47ae44e26396C044).call{
            value: address(this).balance
        }('');
        require(os);
        totalReservations[msg.sender] += reserveSize;
    }

    function allowedToReserve(address _user) private view returns (bool) {
        uint256 i = 0;
        while (i < reserveAddresses.length) {
            if (reserveAddresses[i] == _user) {
                return true;
            }
            i++;
        }
        return false;
    }

    function setReserveSize(uint256 _reserveSize) public onlyOwner {
        reserveSize = _reserveSize;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPublicCost(uint256 _cost) public onlyOwner {
        publicCost = _cost;
    }

    function setWhitelistCost(uint256 _cost) public onlyOwner {
        whitelistCost = _cost;
    }

    function setWhitelistSupply(uint256 _whitelistSupply) public onlyOwner {
        whitelistSupply = _whitelistSupply;
    }

    function getPublicCost() public view returns (uint256) {
        return publicCost;
    }

    function getWhitelistCost() public view returns (uint256) {
        return whitelistCost;
    }

    function setMaxMintAmountPerTxPublic(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTxPublic = _maxMintAmountPerTx;
    }

    function setMaxMintAmountPerTxWhitelist(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTxWhitelist = _maxMintAmountPerTx;
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

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getCanUseWhite() public view returns (bool) {
        if(whitelistClaimed[_msgSender()]){
            return false;
        }
        return true;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

/*     function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(0x6d05bd3a7F95AA0C79d93B7b47ae44e26396C044).call{
            value: address(this).balance
        }('');
        require(os);
        // =============================================================================
    }
 */
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}