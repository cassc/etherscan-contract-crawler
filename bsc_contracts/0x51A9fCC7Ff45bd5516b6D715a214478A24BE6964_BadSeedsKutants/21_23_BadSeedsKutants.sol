// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../ClaimableBurning.sol";
import "../../utils/Recoverable.sol";


contract BadSeedsKutants is
    ERC721Enumerable,
    ClaimableBurning,
    ReentrancyGuard,
    Recoverable
{
    using Counters for Counters.Counter;
    
    address public constant rareboard = 0xB951645D400919b1A09a9dcaf07E26F2Be38576c;
    address public constant ooze = 0xFef6B2404FbdFed8D116C0b800Ad4d2149510DB8;
    uint256 public constant maxSupply = 5000;
    uint256 public constant maxMintPerTx = 50;
    uint256 public constant price = 0 ether;

    Counters.Counter private tokenIds;
    bool public mintActive = false;
    string private baseURI;

    constructor() 
        ERC721("Bad Seeds Kutants", "KUTE")
        Claimable(ooze) {}


    function claim(address _to, uint256[] memory _tokenIds) public nonReentrant {
        require(
            msg.sender == _to ||
            (msg.sender == rareboard && tx.origin == _to), 
            "Only self claimable"
        );
        _claim(_to, _tokenIds);
    }


    /**
     * @notice Set mintActive to `_mintActive`. Only callable by owner.
     */
    function setMintActive(bool _mintActive) external onlyOwner {
        mintActive = _mintActive;
    }

    /**
     * @notice Allows the owner to set the base URI to be used for all not revealed token IDs
     * @param _uri: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _mintTo(address _to, uint256 _amount) internal override {
        require(mintActive, "Mint not started yet");
        require(_amount > 0 && _amount <= maxMintPerTx, "Invalid amount");
        
        for (uint256 i = 0; i < _amount; ++i) {
            tokenIds.increment();
            _safeMint(_to, tokenIds.current());
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}