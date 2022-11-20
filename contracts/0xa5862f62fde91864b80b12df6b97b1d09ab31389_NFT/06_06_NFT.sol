// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "solmate/tokens/ERC721.sol";
import "@oz/contracts/utils/Strings.sol";
import "@oz/contracts/access/Ownable.sol";

error MintPriceNotPaid();
error MaxSupply();
error NonExistentTokenURI();
error WithdrawTransfer();

contract NFT is ERC721, Ownable {
    using Strings for uint256;

    mapping(uint256 => string) private _tokenURIs;

    string public baseURI;
    uint256 public currentTokenId;
    uint256 public constant TOTAL_SUPPLY = 10_000;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address recipient, string memory _tokenURI) public onlyOwner returns (uint256) {
        require(currentTokenId + 1 <= TOTAL_SUPPLY, "Max Supply Exceeded");
        uint256 newTokenId = ++currentTokenId;
        _safeMint(recipient, newTokenId);
        _tokenURIs[newTokenId] = _tokenURI;
        return newTokenId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Non Existent Token URI");
        return _tokenURIs[tokenId];
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx,) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }
}