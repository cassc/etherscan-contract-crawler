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

import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract Silhouette is ERC721A, Ownable, DefaultOperatorFilterer {

    IERC721 public genesisNFT = IERC721(0xbB52d85C8dE311A031770b48dC9F91083E6D12B1);

    string public baseURI = "";
    uint256 constant public MAX_SUPPLY = 2000;

    uint256 public mintLimit = 3;
    uint256 public price = 0.02 ether;
    uint256 public genesisPrice = 0.015 ether;

    bool public paused = true;

    constructor() ERC721A("Silhouette", "Silhouette") {}

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function mint(uint256 _amountToMint, bytes4 _check) external payable {
        address _caller = _msgSender();
        require(!paused, "Public paused");
        require(tx.origin == _caller, "No contracts");
        require(checkWebMint(_caller, _check), "Not from web");
        require(MAX_SUPPLY >= totalSupply() + _amountToMint, "Exceeds max supply");
        require(_amountToMint > 0, "Not 0 mints");
        require(_numberMinted(_caller) + _amountToMint <= mintLimit, "Mint limit");

        if(genesisNFT.balanceOf(_caller) > 0){
            require(_amountToMint * genesisPrice <= msg.value, "Invalid funds provided");
        }else{
            require(_amountToMint * price <= msg.value, "Invalid funds provided");
        }

        _safeMint(_caller, _amountToMint);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Failed to send");
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function teamMint(address _to, uint256 _amount) external onlyOwner {
        _safeMint(_to, _amount);
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 _price, uint256 _genesis) external onlyOwner {
        price = _price;
        genesisPrice = _genesis;
    }

    function setMintLimit(uint256 _limit) external onlyOwner {
        mintLimit = _limit;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
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

    function checkWebMint(address _sender, bytes4 _check) internal pure returns(bool){
        return bytes4(keccak256(abi.encodePacked(_sender))) == _check;
    }
}