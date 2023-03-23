// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";

error NotEnoughSupply();
error WhitelistMintNotActive();
error AddressNotWhitelisted();
error PublicMintNotActive();
error SoldOut();
error ExceedsMaxPerWallet();
error InvalidTokenId();

contract BordersOfVariety is Ownable, ReentrancyGuard, ERC721A {
    receive() external payable {}
    constructor() payable ERC721A("BordersOfVariety", "BOV") {}

    /*/////////////////////////////
        Variables
    /*/
    
    uint256 public maxSupply = 555;
    uint256 public maxPerWallet = 2;

    string public baseTokenUri;

    bytes32 public root;

    mapping(address => uint256) public mintsToWallet;

    /*////////
        Reminder that enums are 0 indexed, meaning:
        0 = CLOSED
        1 = WHITELIST
        2 = PUBLIC
    /*/
    enum MintStatus { CLOSED, WHITELIST, PUBLIC }
    MintStatus mintStatus;


    /*/////////////////////////////
        Setters
    /*/
    function setMintStatus(MintStatus _status) external onlyOwner {
        mintStatus = _status;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply < totalSupply()) revert NotEnoughSupply();
        maxSupply = _maxSupply;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setBaseTokenUri(string calldata _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function getMintStatus() external view returns(MintStatus) {
        return mintStatus;
    }

    /*/////////////////////////////
        Mint Functions
    /*/
    function whitelistMint(uint256 _amount, bytes32[] memory _proof)
        external
        payable
        nonReentrant
    {
        if (mintStatus != MintStatus.WHITELIST) revert WhitelistMintNotActive();
        if (!MerkleProof.verify(_proof, root, keccak256(abi.encodePacked(msg.sender)))) revert AddressNotWhitelisted();
        

        internalMint(_amount);
    }

    function publicMint(uint256 _amount) external payable nonReentrant {
        if (mintStatus != MintStatus.PUBLIC) revert PublicMintNotActive();
        internalMint(_amount);
    }

    function internalMint(uint256 _amount) internal {
        if (totalSupply() >= maxSupply) revert SoldOut();
        if (totalSupply() + _amount > maxSupply) revert NotEnoughSupply();
        if (mintsToWallet[msg.sender] + _amount > maxPerWallet) revert ExceedsMaxPerWallet();

        mintsToWallet[msg.sender] += _amount;
        _mint(msg.sender, _amount);
    }

    /*/////////////////////////////
        Admin Stuff
    /*/
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function teamMint(uint256 _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert InvalidTokenId();

        return
            string(
                abi.encodePacked(
                    baseTokenUri,
                    "/",
                    _toString(_tokenId),
                    ".json"
                )
            );
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed");
    }
}