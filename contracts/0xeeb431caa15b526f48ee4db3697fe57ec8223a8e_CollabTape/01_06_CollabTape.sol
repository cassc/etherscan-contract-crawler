// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

error FailedTransfer();
error InsufficientFunds();
error ExceedsMaxSupply();
error BeforeSaleStart();
error BeforePremintStart();
error InvalidProof();
error AlreadyClaimed();

/// @title ERC721 contract for https://heds.io/ collabTAPE
/// @author https://github.com/kadenzipfel
contract CollabTape is ERC721A, Ownable {
    struct SaleConfig {
        uint64 price;
        uint32 maxSupply;
        uint32 startTime;
        uint32 premintStartTime;
    }

    /// @notice NFT sale data
    /// @dev Sale data packed into single storage slot
    SaleConfig public saleConfig;

    string public baseUri = "https://www.heds.cloud/ipfs/QmXa9SVpeSEHocM7po981kakoRNP34knNZHrAEgnn8DSqQ/";
    address public withdrawAddress = 0x9E9320E6d78C0493EdDf1c760dc50D0D27f58767;
    bytes32 public constant merkleRoot = 0xd6ecfd8d33e85dab6092748736a3edc5adaa3122fd2ab888d1153fd25e26c23b;

    /// @notice Tracking whitelisted address claims
    mapping(address => bool) public claimed;

    constructor() ERC721A("collabTAPE", "CLBT") {
        saleConfig.price = 0.1 ether;
        saleConfig.maxSupply = 100;
        saleConfig.startTime = 1661626770;
        saleConfig.premintStartTime = 1661540370;
    }

    ////////////////////////////////////////////////////////////////
    /*                PUBLIC/EXTERNAL FUNCTIONS                   */
    ////////////////////////////////////////////////////////////////

    /// @notice Premint a collabTAPE token
    /// @param _merkleProof Merkle proof for whitelist verification
    function preMint(bytes32[] calldata _merkleProof) external {
        SaleConfig memory config = saleConfig;
        uint _maxSupply = uint(config.maxSupply);
        uint _premintStartTime = uint(config.premintStartTime);

        if (_nextTokenId() > _maxSupply) revert ExceedsMaxSupply();
        if (block.timestamp < _premintStartTime) revert BeforePremintStart();
        if (claimed[msg.sender]) revert AlreadyClaimed();
        if (
            MerkleProof.verify(
                _merkleProof, merkleRoot, _toBytes32(msg.sender)) == false
        ) revert InvalidProof();

        claimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    /// @notice Mint a collabTAPE token
    /// @param _amount Number of tokens to mint
    function mint(uint _amount) external payable {
        SaleConfig memory config = saleConfig;
        uint _price = uint(config.price);
        uint _maxSupply = uint(config.maxSupply);
        uint _startTime = uint(config.startTime);

        if (_amount * _price != msg.value) revert InsufficientFunds();
        if (_nextTokenId() + _amount > _maxSupply + 1) revert ExceedsMaxSupply();
        if (block.timestamp < _startTime) revert BeforeSaleStart();

        _safeMint(msg.sender, _amount);
    }

    ////////////////////////////////////////////////////////////////
    /*                   AUTHORIZED FUNCTIONS                     */
    ////////////////////////////////////////////////////////////////

    /// @notice Update baseUri - must be contract owner
    function setBaseUri(string calldata _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    /// @notice Update withdrawAddress - must be contract owner
    function setWithdrawAddress(address _withdrawAddress) external onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    /// @notice Update sale start time - must be contract owner
    function updateStartTime(uint32 _startTime) external onlyOwner {
        saleConfig.startTime = _startTime;
    }

    /// @notice Update max supply - must be contract owner
    function updateMaxSupply(uint32 _maxSupply) external onlyOwner {
        saleConfig.maxSupply = _maxSupply;
    }

    /// @notice Update premint start time - must be contract owner
    function updatePremintStartTime(uint32 _premintStartTime) external onlyOwner {
        saleConfig.premintStartTime = _premintStartTime;
    }

    /// @notice Withdraw contract balance - must be contract owner
    function withdraw() external onlyOwner {
        (bool success, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        if (!success) revert FailedTransfer();
    }

    ////////////////////////////////////////////////////////////////
    /*                    INTERNAL FUNCTIONS                      */
    ////////////////////////////////////////////////////////////////

    function _toBytes32(address addr) pure internal returns (bytes32){
        return bytes32(uint256(uint160(addr)));
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
}