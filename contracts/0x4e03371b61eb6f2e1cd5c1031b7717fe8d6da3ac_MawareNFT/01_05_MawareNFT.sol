// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

error MaxSupply();
error NonExistentTokenURI();

interface ITokenURIer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract MawareNFT is ERC721, Ownable {
    using Strings for uint256;

    string public baseURI;
    uint256 public currentTokenId;
    uint256 public constant TOTAL_SUPPLY = 777;

    address public tokenURIDelegate = address(0);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address recipient) public returns (uint256) {
        uint256 newTokenId = ++currentTokenId;
        if (newTokenId > TOTAL_SUPPLY) {
            revert MaxSupply();
        }
        _safeMint(recipient, newTokenId);
        return newTokenId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert NonExistentTokenURI();
        }
        if (tokenURIDelegate != address(0)) {
            return ITokenURIer(tokenURIDelegate).tokenURI(tokenId);
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function setBaseURI(string memory _baseURI) external {
        baseURI = _baseURI;
    }

    function setDelegate(address _addr) external {
        tokenURIDelegate = _addr;
    }
}