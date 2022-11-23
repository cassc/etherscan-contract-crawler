// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

error MintNotOpened();
error NotWhitelisted();
error NoSupplyLeft();
error InsufficientAmount();

contract StudioJacquemars is ERC721AUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Constants
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    uint256 public constant MAX_SUPPLY = 1111;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Storage
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    string private _tokenBaseURI;
    uint256 public mintStartTimestamp;
    uint256 public publicMintPrice;
    bytes32 internal whitelistMerkleRoot;
    uint256 public whitelistStartTimestamp;
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Events
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Constructor
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) initializerERC721A initializer public {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        __Pausable_init();
        _tokenBaseURI = _uri;
        publicMintPrice = 0.05 ether;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Modifiers
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    modifier whenMintActive() {
        if (!isMintActive()) {
            revert MintNotOpened();
        }
        _;
    }

    function isMintActive() public view returns (bool) {
        return
            mintStartTimestamp > 0
                ? block.timestamp >= (mintStartTimestamp)
                : false;
    }

    modifier whenWhitelistActive() {
        if (!isWhitelistActive()) {
            revert MintNotOpened();
        }
        _;
    }

    function isWhitelistActive() public view returns (bool) {
        return
            whitelistStartTimestamp > 0
                ? block.timestamp >= (whitelistStartTimestamp)
                : false;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Admin
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
     
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setURI(string calldata _newURI) external onlyOwner {
        _tokenBaseURI = _newURI;
    }

    function setMintStartTimestamp(uint256 _timestamp) external onlyOwner {
        mintStartTimestamp = _timestamp;
    }

    function setWhitelistStartTimestamp(uint256 _timestamp) external onlyOwner {
        whitelistStartTimestamp = _timestamp;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        publicMintPrice = _price;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Admin Mint
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function adminMint(uint256 _count, address _recipient)
        external
        onlyOwner
    {
        if (totalSupply() + _count > MAX_SUPPLY) {
            revert NoSupplyLeft();
        }

        _mint(_recipient, _count);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Getters
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }


    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Whitelist Mint
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function whitelistMint(uint256 _count, bytes32[] calldata merkleProof)
        external
        payable
        whenWhitelistActive
        whenNotPaused
    {

        // Validate Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if(
            !MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf)
        ) {
            revert NotWhitelisted();
        }

        if (totalSupply() + _count > MAX_SUPPLY) {
            revert NoSupplyLeft();
        }
        if ( msg.value < _count * publicMintPrice ) {
            revert InsufficientAmount();
        }

        _mint(msg.sender, _count);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Public Mint
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function publicMint(uint256 _count)
        external
        payable
        whenMintActive
        whenNotPaused
    {

        if (totalSupply() + _count > MAX_SUPPLY) {
            revert NoSupplyLeft();
        }
        if ( msg.value < _count * publicMintPrice ) {
            revert InsufficientAmount();
        }

        _mint(msg.sender, _count);
    }


    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Withdrawls
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function withdrawAmount(address payable recipient, uint256 amount)
        external
        onlyOwner
    {
        (bool succeed,) = recipient.call{value: amount}("");
        require(succeed, "Failed to withdraw Ether");
    }
}