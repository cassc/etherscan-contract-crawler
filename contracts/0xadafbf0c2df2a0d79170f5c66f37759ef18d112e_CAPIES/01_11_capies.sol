pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/extensions/ERC721ABurnable.sol";
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * Only EOA accounts permitted
*/
error EOAOnly();
/**
 * Address exceeding allowance
*/
error AllowanceExceeded();
/**
 * Maximum supply reached
*/
error MaxSupplyExceeded();
/**
 * User provided incorrect merkle proof
*/
error IncorrectProof();
/**
 * Exceeding whitelist supply
*/
error WhitelistSupplyExceeded();

contract CAPIES is ERC721ABurnable, ERC721AQueryable, Ownable, Pausable {
    constructor(
        string memory _baseTokenURI
    ) ERC721A("Capies", "CAPIES") {
        baseTokenURI = _baseTokenURI;
        merkleRoot[0] = 0x4a9e28a1615f7480a2cf10423357dbea63a2eeb72b106c97589f2e54385846fb;
        merkleRoot[1] = 0x953ba90ea587a1e5fd8a831aacc5f6de88a819e02849864c803b74e369500d8b;
        _pause();
    }

    ////////////////////////////////////////////////
    /// Variables
    ////////////////////////////////////////////////
    mapping(address => uint) public amountMinted;
    mapping(uint => bytes32) private merkleRoot;
    string private baseTokenURI;
    uint private MAX_SUPPLY = 10000;
    uint private WL_ALLOCATION = 8000;
    uint private ACC_LIMIT = 2;
    bool private revealed;
    bool public skipPremint;

    ////////////////////////////////////////////////
    /// Modifiers
    ////////////////////////////////////////////////
    modifier onlyEOA {
        if (msg.sender != tx.origin) revert EOAOnly();
        _;
    }

    ////////////////////////////////////////////////
    /// Public Functions
    ////////////////////////////////////////////////
    function mint(bytes32[] calldata _merkleProof, uint _amount) public whenNotPaused onlyEOA {
        uint supply = totalSupply();
        if (amountMinted[msg.sender] + _amount > ACC_LIMIT) revert AllowanceExceeded();
        if (supply + _amount > MAX_SUPPLY) revert MaxSupplyExceeded();

        if (supply < WL_ALLOCATION) {                   // First 8000 (Haus + Muri holders)
            if (supply + _amount <= WL_ALLOCATION) {
                _WLVerify(_merkleProof, 0);
            } else {
                revert WhitelistSupplyExceeded();
            }
        } else if (supply >= WL_ALLOCATION && !skipPremint) {            // NEXT 2000 (Premint)
            if (amountMinted[msg.sender] + _amount > 1) revert AllowanceExceeded();
            _WLVerify(_merkleProof, 1);
        }

        unchecked { amountMinted[msg.sender] += _amount; }
        _mint(msg.sender, _amount);
    }

    function mintAdmin(uint _amount) public onlyOwner {
        uint supply = totalSupply();
        if (supply + _amount > MAX_SUPPLY) revert MaxSupplyExceeded();
        _mint(msg.sender, _amount);
    }

    function _WLVerify(bytes32[] calldata _merkleProof, uint stage) internal view {
        if (
            !MerkleProof.verify(
                _merkleProof,
                merkleRoot[stage],
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert IncorrectProof();
    }

    ////////////////////////////////////////////////
    /// Overrides
    ////////////////////////////////////////////////
    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        if (!revealed) return baseURI;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    ////////////////////////////////////////////////
    /// Owner functions
    ///////////////////////////////////////////////
    function doSkipPremint() external onlyOwner {
        skipPremint = true;
    }

    function setMerkleRoot(bytes32 _newRoot, uint256 stage) external onlyOwner {
        merkleRoot[stage] = _newRoot;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function reveal() external onlyOwner {
        revealed = true;
    }
}