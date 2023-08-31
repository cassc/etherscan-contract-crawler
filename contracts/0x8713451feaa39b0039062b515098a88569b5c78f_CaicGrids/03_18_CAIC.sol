//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './BaseOpenSea.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/// @title CAIC (Cellular Automaton In Chain)
/// @author Tfs128 (@trickerfs128)
/// @dev most of the code borrowed from [sol]Seedlings contract written by Simon Fremaux (@dievardump)
contract CAIC is BaseOpenSea, ERC721Enumerable,Ownable,ReentrancyGuard {

    event SeedChangeRequest(uint256 indexed tokenId, address indexed operator);
    event Collected(address indexed operator, uint256 indexed count,uint256 value);
    event Claimed(address indexed operator);
    event SizeUpdated(uint32 size);

    // Last Token Id Generated.
    uint256 public LAST_TOKEN_ID;

    //public minting start time.
    uint256 public PUBLIC_MINTING_TIME = block.timestamp + 36 hours;

    // 0.00768
    uint256 public PRICE = 7680000000000000;

    // Max Available for mint `Available` - `Reserved`
    uint256 public AVAILABLE = 509;

    // 257 reserved for blockglyphs holders + 2 for owner
    uint256 public BG_RESERVED_LEFT = 259;

    // Max mints allowed in single transaction
    uint256 public MAX_MINT = 11;

    // Last Seed Generated
    bytes32 public LAST_SEED; 

    // Size of image height:=SIZE, width:=SIZE
    uint32 public SIZE = 256;

    // each token seed
    mapping(uint256 => bytes32) internal _tokenSeed;

    // tokenIds with a request for seeds change
    mapping(uint256 => bool) private _seedChangeRequests;

    // blockGlyph holders
    mapping(address => bool) public _bgHolders;

    /// @notice constructor
    /// @param contractURI can be empty
    /// @param openseaProxyRegistry can be address zero
    constructor(
        string memory contractURI,
        address openseaProxyRegistry
    ) ERC721('CAIC', 'CAIC') { //CAIC (Cellular Automaton In Chain)

        if (bytes(contractURI).length > 0) {
            _setContractURI(contractURI);
        }

        if (address(0) != openseaProxyRegistry) {
            _setOpenSeaRegistry(openseaProxyRegistry);
        }
    }

    /// @notice function to mint `count` token(s) to `msg.sender`
    /// @param count numbers of tokens
    function mint(uint256 count) external payable nonReentrant {
        require (block.timestamp >= PUBLIC_MINTING_TIME, 'Wait');
        require(count > 0, 'Must be greater than 0');
        require(count <= MAX_MINT, 'More Than Max Allowed.' );
        require(count <= AVAILABLE, 'Too Many Requested.');
        require(msg.value == PRICE * count , 'Not Enough Amount.');

        uint256 tokenId = LAST_TOKEN_ID;
        bytes32 blockHash = blockhash(block.number - 1);
        bytes32 nextSeed;
        for (uint256 i; i < count; i++) {
            tokenId++;
            _safeMint(msg.sender, tokenId);
            nextSeed = keccak256(
                abi.encodePacked(
                    LAST_SEED,
                    block.timestamp,
                    msg.sender,
                    blockHash,
                    block.coinbase,
                    block.difficulty,
                    tx.gasprice
                    )
                );
            LAST_SEED = nextSeed;
            _tokenSeed[tokenId] = nextSeed;
        }
        LAST_TOKEN_ID = tokenId;
        AVAILABLE -= count;
        emit Collected(msg.sender, count, msg.value);
    }

    /// @notice func for free token claim for blockglyph holders
    function claim() external {
        require (block.timestamp < PUBLIC_MINTING_TIME, 'You are late.');
        //I had made a blunder in previouse deployment, so had to redeploy again. 
        //rather than storing whole reserve list again, will use it from 
        //previouse contract.
        require (CAIC(0xb742848B5971cE5D0628E351714AF5F1F4e4A8A2)._bgHolders(msg.sender) == true, 'Not a bg holder.');
        require (_bgHolders[msg.sender] == false , 'Already claimed.');
        uint256 tokenId = LAST_TOKEN_ID + 1;
        _safeMint(msg.sender, tokenId);
        bytes32 blockHash = blockhash(block.number - 1);
        bytes32 nextSeed = keccak256(
            abi.encodePacked(
                LAST_SEED,
                block.timestamp,
                msg.sender,
                blockHash,
                block.coinbase,
                block.difficulty,
                tx.gasprice
                )
            );
        LAST_TOKEN_ID = tokenId;
        LAST_SEED = nextSeed;
        _tokenSeed[tokenId] = nextSeed;
        BG_RESERVED_LEFT -= 1;
        _bgHolders[msg.sender] = true;
        emit Claimed(msg.sender);
    }

    /// @notice function to request seed change by token owner.
    /// @param tokenId of which seed change requested
    function requestSeedChange(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, 'Not token owner.');
        _seedChangeRequests[tokenId] = true;
        emit SeedChangeRequest(tokenId, msg.sender);
    }

    /// opensea config (https://docs.opensea.io/docs/contract-level-metadata)
    function setContractURI(string memory contractURI) external onlyOwner {
        _setContractURI(contractURI);
    }

    ///@notice function to update image res
    ///@param imageSize height X width = 'imageSize * imageSize'
    function updateImageSize(uint32 imageSize) external onlyOwner {
        require(imageSize % 4 == 0, 'Should be a multiple of 4');
        require(imageSize > 63 && imageSize < 513, 'Must be between 64-512');
        SIZE = imageSize;
        emit SizeUpdated(imageSize);
    }

    /// @dev blockglyphs holders struct.
    struct bgHolderAddresses {
        address addr;
        bool available;
    }

    /// @notice function to add blockglyph holders + 2 owner reserved
    function addBgHolders(bgHolderAddresses[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _bgHolders[addresses[i].addr] = addresses[i].available;
        }
    }

    ///@notice function to respond to seed change requests
    ///@param tokenId of which seed needs to be change
    function changeSeedAfterRequest(uint256 tokenId) external onlyOwner {
        require(_seedChangeRequests[tokenId] == true, 'No request for token.');
        _seedChangeRequests[tokenId] = false;
        _tokenSeed[tokenId] = keccak256(
            abi.encode(
                _tokenSeed[tokenId],
                block.timestamp,
                block.difficulty,
                blockhash(block.number - 1)
            )
        );
    }

    /// @notice function to withdraw balance.
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "0 Balance.");
        bool success;
        (success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Failed');
    }

    /// @notice this function returns the seed associated to a tokenId
    /// @param tokenId to get the seed of
    function getTokenSeed(uint256 tokenId) external view returns (bytes32) {
        require(_exists(tokenId), 'TokenSeed query for nonexistent token');
        return _tokenSeed[tokenId];
    }

    /// @notice function to get raw based64 encoded image
    /// @param tokenId id of token
    function getRaw(uint256 tokenId) public view returns (string memory) {
        require(
            _exists(tokenId),
            'Query for nonexistent token'
            );
        return _render(tokenId, _tokenSeed[tokenId],false);
    }

    /// @notice tokenURI override that returns a data:json application
    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
            );
        return _render(tokenId, _tokenSeed[tokenId],true);
    }

    /// @notice Called with the sale price to determine how much royalty
    /// @param tokenId - the NFT asset queried for royalty information
    /// @param value - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 tokenId, uint256 value) public view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = owner();
        royaltyAmount = (value * 300) / 10000;
    }

    /// @notice Function allowing to check the rendering for a given seed
    /// @param seed the seed to render
    function renderSeed(bytes32 seed) public view returns (string memory) {
        return _render(1, seed, false);
    }

    /// @dev Rendering function;
    /// @param tokenId which needs to be render
    /// @param seed seed which needs to be render
    /// @param isSvg true=svg, false=base64 encoded
    function _render(uint256 tokenId, bytes32 seed, bool isSvg) internal view virtual returns (string memory) {
        seed;
        return
            string(
                abi.encodePacked(
                    'data:application/json,{"name":"',
                    tokenId,
                    '"}'
                )
            );
    }

}