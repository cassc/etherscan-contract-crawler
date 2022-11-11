// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Juti is
    ERC721A,
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    ReentrancyGuard
{
    uint256 public maxMintAmount = 10; //Total number of tokens a wallet can have for public mint
    uint256 public maxSupply = 2000;
    uint256 public mintRate = 0.06 ether; //0.25 ether;
    uint256 public exclusiveMintRate = 0 ether; //0.25 ether;
    uint256 public whitelistMintrate = 0.03 ether; //price for whitelisted buyers
    uint256 public maxMintAmountWhiteList = 5;
    uint256 public maxFreeMintAmount = 2;
    uint256 public immutable maxTeamMint = 200; //Amount reserved for team

    bool public revealed = false;
    bool public isWhitelistMintState = false;
    bool public isPublicMintState = false;
    bool public isFreeMintState = false;
    bool public isExclusiveMintState = false;

    string public baseURI;
    string public contractURIstring;

    bytes32 public merkleRoot;
    bytes32 public merkleRootExclusive;

    //mapping(address => uint256) public whitelistClaimed;
    //mapping(address => uint256) public freemintClaimed;

    //Contract Base

    constructor() ERC721A("Planet Juti", "JP") {}

    //Minting Functions

    function teamMint(uint256 _mintAmount) public onlyOwner {
        require(
            numberMinted(msg.sender) + _mintAmount <= maxTeamMint,
            "Can't Mint more than 200 for the team"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Not enough tokens left"
        );
        _safeMint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) external payable onlyAccounts {
        require(isPublicMintState, "Public Mint is not active!"); //Check public minting status
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Not enough tokens left"
        );
        require(msg.value >= mintRate * _mintAmount, "Not enough ether sent");
        require(
            numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
            "Exceeded the limit"
        );
        _safeMint(_msgSender(), _mintAmount);
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        onlyAccounts
        isValidMerkleProof(_merkleProof)
        mintCompliance(_mintAmount)
        mintPriceComplianceWL(_mintAmount)
    {
        // Verify whitelist requirements
        require(isWhitelistMintState, "The whitelist sale is not enabled!");
        _safeMint(_msgSender(), _mintAmount);
    }

    function freeMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        onlyAccounts
        isValidMerkleProof(_merkleProof)
        freeMintCompliance(_mintAmount)
    {
        require(isFreeMintState, "FreeMint is not enabled!");
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintExclusive(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        onlyAccounts
        isValidMerkleProofExclusive(_merkleProof)
    {
        require(isExclusiveMintState, "Exclusive Mint is not active!"); //Check public minting status
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Not enough tokens left"
        );
        require(
            msg.value >= exclusiveMintRate * _mintAmount,
            "Not enough ether sent"
        );

        _safeMint(_msgSender(), _mintAmount);
    }

    //Modifiers where apply the conditions to methods

    modifier freeMintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxFreeMintAmount,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount < maxMintAmountWhiteList,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceComplianceWL(uint256 _mintAmount) {
        require(
            msg.value >= whitelistMintrate * _mintAmount,
            "Insufficient funds!"
        );
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata proof) {
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ) == true,
            "Not Whitelisted"
        );
        _;
    }

    modifier isValidMerkleProofExclusive(bytes32[] calldata proof) {
        require(
            MerkleProof.verify(
                proof,
                merkleRootExclusive,
                keccak256(abi.encodePacked(msg.sender))
            ) == true,
            "Not Whitelisted"
        );
        _;
    }

    modifier onlyAccounts() {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    //End Modifiers

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    //Transfer tokens to another wallet using tokenIDs, ex: [1,3,6,7]
    function bulkTransfer(uint256[] memory tokenIds, address _to)
        external
        onlyOwner
        nonReentrant
    {
        for (uint256 i; i < tokenIds.length; ) {
            safeTransferFrom(msg.sender, _to, tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    //Set the Merkle Root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMerkleRootExclusive(bytes32 _merkleRoot) external onlyOwner {
        merkleRootExclusive = _merkleRoot;
    }

    //Change the number of allowed NFTs to mint per wallet for whitelist
    function setMaxMintAmountWhiteList(uint256 _limit) external onlyOwner {
        maxMintAmountWhiteList = _limit;
    }

    //Change the number of allowed NFTs to mint per wallet for whitelist
    function setMaxMintAmountFreeMint(uint256 _limit) external onlyOwner {
        maxFreeMintAmount = _limit;
    }

    //Change the Max Supply
    function setMaxSupply(uint256 _limit) external onlyOwner {
        maxSupply = _limit;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _changeBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function contractURI() public view returns (string memory) {
        return contractURIstring;
    }

    function _ChangeContractURI(string calldata contractURI_)
        external
        onlyOwner
    {
        contractURIstring = contractURI_;
    }

    //Unreveal function
    function _reveal(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    //Set Mint Price
    function setMintRate(uint256 _mintRate) external onlyOwner {
        mintRate = _mintRate;
    }

    //Set Whitelist Mint Price
    function setWhitelistMintRate(uint256 _whitelistMintrate)
        external
        onlyOwner
    {
        whitelistMintrate = _whitelistMintrate;
    }

    //Set Exclusive Mint Price
    function setExclusiveMintRate(uint256 _exclusiveMintrate)
        external
        onlyOwner
    {
        exclusiveMintRate = _exclusiveMintrate;
    }

    //Set number of Mint can be done at once
    function setMaxMint(uint256 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    //Mint state for Public Mint, WhiteList Mint & FreeMint
    function setPublicMintState(bool _state) external onlyOwner {
        isPublicMintState = _state;
    }

    function setWhitelistMintState(bool _state) external onlyOwner {
        isWhitelistMintState = _state;
    }

    function setFreeMintState(bool _state) external onlyOwner {
        isFreeMintState = _state;
    }

    function setExclusiveMintState(bool _state) external onlyOwner {
        isExclusiveMintState = _state;
    }

    //Get single toekn ownership and return tuple

    function getTokenOwnership(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    //Override start token ID to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //Returning token URI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI_ = _baseURI();
        if (revealed) {
            return
                bytes(baseURI_).length != 0
                    ? string(
                        abi.encodePacked(baseURI, _toString(tokenId), ".json")
                    )
                    : "";
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }
}