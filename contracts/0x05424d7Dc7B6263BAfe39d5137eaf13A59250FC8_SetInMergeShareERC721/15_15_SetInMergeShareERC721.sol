// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SetInMergeShareERC721 is IERC2981, ERC721Enumerable, Ownable {

    Counters.Counter public counter;

    mapping(address => bool) public managers;

    address public royaltyReceiver;
    uint public royaltyFraction = 1000;

    mapping(uint256 => uint32) public tokenShare;
    uint32 public totalShare;

    string public apiUrl;

    /**
     * Constructor
     */

    constructor(string memory _apiUrl) ERC721("SIM Share", "SIMS") {
        managers[msg.sender] = true;
        royaltyReceiver = msg.sender;
        apiUrl = _apiUrl;
    }

    /**
     * Only owner access
     */

    function setRoyaltyData(address _royaltyReceiver, uint _royaltyFraction) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
        royaltyFraction = _royaltyFraction;
    }

    /**
     * Only manager access
     */

    modifier onlyManager() {
        require(managers[msg.sender], "SIMS: only manager can access");
        _;
    }

    function setApiUrl(string memory _apiUrl) external onlyManager {
        apiUrl = _apiUrl;
    }

    function setManager(address manager, bool enabled) external onlyManager {
        managers[manager] = enabled;
    }

    function mint(address receiver, uint32 share) external onlyManager {
        _mintInternal(receiver, share);
    }

    function mintBulk(address[] memory receivers, uint32[] memory shares) external onlyManager {
        require(receivers.length == shares.length, "SIMS: arrays should be of the same size");
        for (uint i = 0; i < receivers.length; i++) {
            address receiver = receivers[i];
            uint32 share = shares[i];
            _mintInternal(receiver, share);
        }
    }

    /**
     * Only token owner access
     */

    modifier onlyTokenOwner(uint tokenId) {
        require(ownerOf(tokenId) == msg.sender, "SIMS: only token owner can access");
        _;
    }


    function burn(uint tokenId) external onlyTokenOwner(tokenId) {
        _burnInternal(tokenId);
    }

    function merge(uint[] memory tokenIds) external {
        
        uint32 share;
        require(tokenIds.length >= 2, "SIMS: can't merge less than 2");
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "SIMS: only token owner can access");
            share += tokenShare[tokenId];
            _burnInternal(tokenId);
        }
        _mintInternal(msg.sender, share);
    }

    function split(uint sourceTokenId, uint32 share) external onlyTokenOwner(sourceTokenId) {

        require(share > 0, "SIMS: share should be more than 0");
        
        uint32 sourceShare = tokenShare[sourceTokenId];

        require(share < sourceShare, "SIMS: split share cannot be more than shource token's share");

        uint32 share1 = share;
        uint32 share2 = sourceShare - share;

        _burnInternal(sourceTokenId);
        _mintInternal(msg.sender, share1);
        _mintInternal(msg.sender, share2);
    }

    /**
     * Public access
     */

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, IERC165) returns (bool) {

        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {

        uint256 royaltyAmount = (_salePrice * royaltyFraction) / 10000;
        return (royaltyReceiver, royaltyAmount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenShareStr = Strings.toString(tokenShare[tokenId]);

        return string(abi.encodePacked(apiUrl, tokenShareStr));
    }

    /**
     * Internal
     */

    function _mintInternal(address receiver, uint32 share) internal {

        require(receiver != address(0), "SIMS: reciever should not be zero address");
        require(share > 0, "SIMS: share should be more than 0");

        totalShare = totalShare + share;
        require(totalShare <= 10000, "SIMS: exceeded 100%");

        Counters.increment(counter);
        uint256 tokenId = Counters.current(counter);

        tokenShare[tokenId] = share;

        _safeMint(receiver, tokenId);
    }

    function _burnInternal(uint256 tokenId) internal {
        uint32 share = tokenShare[tokenId];
        totalShare -= share;
        _burn(tokenId);
    }
}