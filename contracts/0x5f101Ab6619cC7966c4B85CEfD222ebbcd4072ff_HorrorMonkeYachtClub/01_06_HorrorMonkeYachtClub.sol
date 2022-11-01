// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ERC721
interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract HorrorMonkeYachtClub is ERC721A, Ownable {

  using Strings for uint256;
  IERC721 public immutable bmyc = IERC721(0x51E689fE99cf0AF93846a7100eD3669E63175115);
  string public           baseURI;
  uint256 public          price             = 0.0015 ether;
  uint256 public          maxPerWallet      = 50;
  uint256 public          maxPerTx          = 10;
  uint256 public          freeMints         = 0;
  uint256 public constant maxSupply         = 4000;
  uint256 public constant maxFree           = 2000;
  bool public             mintEnabled       = false;

  mapping(address => uint256) private _walletMints;
  mapping(address => uint256) private _freeMints;

  constructor() ERC721A("Horror Monke Yacht Club", "HMYC"){
  }

  function mint(uint256 tokens, bool holder) external payable {
    require(mintEnabled, "Mint not open yet");
    require(tokens > 0, "Must mint at least 1");
    require(totalSupply() + tokens <= maxSupply, "Sold out");
    require(_walletMints[_msgSender()] + tokens <= maxPerWallet, "Max per wallet");
    require(tokens <= maxPerTx, "Too many per tx");
    uint256 paidTokens = tokens;
    if (holder) {
        uint256 balance = bmyc.balanceOf(msg.sender);
        if (balance > 0) {
            uint256 freeTokens = balance - _freeMints[_msgSender()];
            if (freeTokens > 10) {
                freeTokens = 10;
            }
            if (freeMints + freeTokens <= maxFree) {
                _freeMints[_msgSender()] += freeTokens;
                paidTokens = paidTokens - freeTokens;
                freeMints += freeTokens;
            }
        }
    }
    require(price * paidTokens <= msg.value, "Insufficient funds");

    _walletMints[_msgSender()] += paidTokens;
    _safeMint(msg.sender, tokens);
  }

  function ownerMint(uint256 tokens, address to) external onlyOwner {
    require(totalSupply() + tokens <= maxSupply, "Sold out");

    _safeMint(to, tokens);
  }

  function setMaxPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
    maxPerWallet = _newMaxPerWallet;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
  }

  function toggleMinting() external onlyOwner {
      mintEnabled = !mintEnabled;
  }

  function setPrice(uint256 price_) external onlyOwner {
      price = price_;
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function freeMinted(address wallet) external view returns (uint256) {
    return _freeMints[wallet];
  }

  function withdrawAll() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "Insufficent balance");
    _withdraw(_msgSender(), address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Failed to withdraw Ether");
  }

}