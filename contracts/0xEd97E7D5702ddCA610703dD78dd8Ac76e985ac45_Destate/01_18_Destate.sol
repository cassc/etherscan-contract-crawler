// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "../util/ERC721Lockable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IViriumDestate.sol";

contract Destate is IDestate, AccessControl, ERC721Lockable {
    bytes32 public constant MAINTAIN_ROLE = keccak256("MAINTAIN_ROLE");
    uint256 public constant MAX_TOTAL_SUPPLY = 588;
    uint256[MAX_TOTAL_SUPPLY] private _tokenIds;
    string public baseTokenURI = "https://ipfs.virium.io/destate/metadata/";
    using Counters for Counters.Counter;
    Counters.Counter private _mintedCounter;
    address public constant PROJECT_MANAGER = 0x1540602fA43D9b4237aa67c640DC8Bb8C4693dCD;

    constructor() ERC721Lockable("Destate", "DESTATE"){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, PROJECT_MANAGER);

        _grantRole(MAINTAIN_ROLE, msg.sender);
        _grantRole(MAINTAIN_ROLE, PROJECT_MANAGER);

        _mint(msg.sender, 0);
    }

    function setTokenLockStatus(uint256[] calldata tokenIds, bool isLock) public override(ERC721Lockable) onlyRole(MAINTAIN_ROLE) {
        return super.setTokenLockStatus(tokenIds, isLock);
    }

    function mint(address to) external onlyRole(MAINTAIN_ROLE) {
        require(_mintedCounter.current() < MAX_TOTAL_SUPPLY, "Destate: Mint would exceed max supply");

        uint256 tokenId = _randomTokenId();
        _mint(to, tokenId);
    }

    function mintForTest(address to) external onlyRole(MAINTAIN_ROLE) { //todo prod
        require(_mintedCounter.current() < MAX_TOTAL_SUPPLY, "Destate: Mint would exceed max supply");
        _mintedCounter.increment();
        uint256 tokenId = _mintedCounter.current();
        _mint(to, tokenId);
    }

    function _randomTokenId() private returns (uint256){
        uint256 current = _mintedCounter.current();
        uint256 pos = current + random() % (MAX_TOTAL_SUPPLY - current);
        uint256 tokenId;
        if (_tokenIds[pos] == 0) {
            tokenId = pos + 1;
        } else {
            tokenId = _tokenIds[pos];
        }
        if (_tokenIds[current] == 0) {
            _tokenIds[pos] = current + 1;
        } else {
            _tokenIds[pos] = _tokenIds[current];
        }
        _mintedCounter.increment();
        return tokenId;
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender)));
    }

    function mintedCount() external view returns (uint256){
        return _mintedCounter.current();
    }

    function setURI(string memory newuri) external onlyRole(MAINTAIN_ROLE) {
        baseTokenURI = newuri;
    }

    function _baseURI()
    internal
    view
    override
    returns (string memory) {
        return baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(IERC165, ERC721, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}