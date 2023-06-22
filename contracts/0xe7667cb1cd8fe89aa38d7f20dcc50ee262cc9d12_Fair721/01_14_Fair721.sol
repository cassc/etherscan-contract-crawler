// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Fair721 is ERC721, ERC721Burnable {
    using Strings for uint256;

    uint256 public constant MAX_MINT = 10240;

    uint256 public _currentTokenId = 0;

    mapping(uint256 => uint256) public _tokenAmounts;
    mapping(address => uint256) public  _userMinted;

    address public creator;

    constructor() ERC721("Fair 721", "F721") {
        creator = msg.sender;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://QmVWVWF4S64GfXHBvfkyL3sMxBNWjG1rhSCUajdcQuoUE7/";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        uint256 tokenAmount = _tokenAmounts[tokenId];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenAmount.toString())) : "";
    }

    function amountOf(uint256 tokenId) public view returns (uint256) {
        _requireMinted(tokenId);
        return _tokenAmounts[tokenId];
    }

    function split(uint256 tokenId) external {
        require(_currentTokenId >= MAX_MINT, "minting");
        require(ownerOf(tokenId) == msg.sender, "owner");
        require(msg.sender == tx.origin, "EOA");
        _burn(tokenId);
        uint256 tokenAmount = _tokenAmounts[tokenId];
        require(tokenAmount != 1, "1");
        _tokenAmounts[tokenId] = 0;
        uint256 unitAmount = tokenAmount / 4;
        for (uint256 i = 0; i < 4; i++) {
            _tokenAmounts[_currentTokenId] = unitAmount;
            _safeMint(msg.sender, _currentTokenId);
            unchecked {
                _currentTokenId += 1;
            }
        }
    }

    receive() external payable {
        require(_userMinted[msg.sender] < 5, "limit");
        require(msg.sender == tx.origin, "EOA");
        require(_currentTokenId < MAX_MINT, "done");
        _userMinted[msg.sender] += 1;
        _tokenAmounts[_currentTokenId] = 1024;
        _safeMint(msg.sender, _currentTokenId);
        unchecked {
            _currentTokenId += 1;
        }
    }

    function mint() external {
        require(_userMinted[msg.sender] < 5, "limit");
        require(msg.sender == tx.origin, "EOA");
        require(_currentTokenId < MAX_MINT, "done");
        _userMinted[msg.sender] += 1;
        _tokenAmounts[_currentTokenId] = 1024;
        _safeMint(msg.sender, _currentTokenId);
        unchecked {
            _currentTokenId += 1;
        }
    }

    function withdrawToken(address _token) external {
        IERC20 token = IERC20(_token);
        require(token.transfer(creator, token.balanceOf(address(this))));
    }

    function withdrawETH() external {
        (bool s,) = creator.call{value: address(this).balance}("");
        require(s, "transfer failed");
    }
}