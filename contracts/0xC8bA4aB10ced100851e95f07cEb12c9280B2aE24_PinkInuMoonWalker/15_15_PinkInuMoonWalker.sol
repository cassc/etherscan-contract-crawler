// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PinkInuMoonWalker is ERC721Enumerable, Ownable, ReentrancyGuard {
    // Events
    event Mint(
        address user,
        uint256 tokenId
    );

    string baseURI;
    uint256 public maxSupply = 1800;
    mapping(uint256 => uint256) public sessions;
    mapping(address => bool) public minted;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint() external nonReentrant payable {
        uint256 _tokenId = totalSupply() + 1;
        uint256 _currentSession = block.timestamp / 7200;
        require(_tokenId <= maxSupply, "NFT max supply reached");
        require(sessions[_currentSession] < 10, "NFT max session reached");
        require(!minted[msg.sender], "Already minted");
        _safeMint(msg.sender, _tokenId);
        sessions[_currentSession] += 1;
        minted[msg.sender] = true;
        emit Mint(msg.sender, _tokenId);
    }

    function sessionInfo()
    public
    view
    returns (uint256 _endTime, uint256 _totalNft)
    {
        uint256 _currentSession = block.timestamp / 7200;
        return ((_currentSession + 1) * 7200, sessions[_currentSession]);
    }

    function tokensOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
}