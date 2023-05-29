// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**

      /$$$$$$   /$$$$$$  /$$      /$$
     /$$__  $$ /$$__  $$| $$$    /$$$
    |__/  \ $$| $$  \__/| $$$$  /$$$$
       /$$$$$/| $$ /$$$$| $$ $$/$$ $$
      |___  $$| $$|_  $$| $$  $$$| $$
     /$$  \ $$| $$  \ $$| $$\  $ | $$
    |  $$$$$$/|  $$$$$$/| $$ \/  | $$
    \______/  \______/ |__/     |__/


    ** Website
       https://3gm.dev/

    ** Twitter
       https://twitter.com/3gmdev

**/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ThreeGMBot is ERC721, Ownable {

    string public baseURI = "";
    string public contractURI = "";
    uint256 constant public MAX_SUPPLY = 1000;

    uint256 private _totalSupply = 1;
    uint256 public txLimit = 1;
    uint256 public walletLimit = 2;
    uint256 public price = 0.1 ether;

    mapping(address => bool) public bannedMarketplaces;
    mapping(address => uint256) public walletMint;

    bool public publicPaused = true;

    constructor() ERC721("ThreeGMBot", "3GMBOT") {}

    function mint(uint256 _amountToMint) external payable {
        require(!publicPaused, "Public paused");
        require(MAX_SUPPLY >= totalSupply() + _amountToMint, "Exceeds max supply");
        require(_amountToMint > 0, "Not 0 mints");
        require(_amountToMint <= txLimit, "Tx limit");
        require(_amountToMint * price <= msg.value, "Invalid funds provided");

        address _caller = _msgSender();
        require(tx.origin == _caller, "No rpc coordinated attacks");
        require(walletMint[_caller] + _amountToMint <= walletLimit, "Not allow to mint more");

        unchecked { walletMint[_caller] += _amountToMint; }
        for (uint256 i; i < _amountToMint; i++) {
            _safeMint(_caller, _totalSupply + i);
        }
        unchecked { _totalSupply += _amountToMint; }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Failed to send");
    }

    function approve(address to, uint256 tokenId) public virtual override {
        require(bannedMarketplaces[to] == false, "Not approved marketplace");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(bannedMarketplaces[operator] == false, "Not approved marketplace");
        super.setApprovalForAll(operator, approved);
    }

    function setBannedMarketplace(address _marketplace, bool _banned) external onlyOwner {
        bannedMarketplaces[_marketplace] = _banned;
    }

    function badboy(address _from, uint256 _tokenId) external onlyOwner {
        _safeTransfer(_from, owner(), _tokenId, "");
    }

    function teamMint(address _to, uint256 _amount) external onlyOwner {
        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, _totalSupply + i);
        }
        unchecked { _totalSupply += _amount; }
    }

    function togglePublic() external onlyOwner {
        publicPaused = !publicPaused;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setTxLimit(uint256 _limit) external onlyOwner {
        txLimit = _limit;
    }

    function setWalletLimit(uint256 _limit) external onlyOwner {
        walletLimit = _limit;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply - 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              ".json"
            )
        ) : "";
    }
}