// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Strings.sol";// .toString()
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";//onlyOwner
import "@openzeppelin/contracts/security/Pausable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

//Todo check ReentrancyGuard
contract Walruses is ERC721A, Ownable, Pausable, DefaultOperatorFilterer {

    using Strings for uint256;

    //Image and metadata,
    bool public uriLocked; //baseURI & contractURI lock '/
    string public _contractBaseURI = "ipfs://QmXHQWxBs9Pfm5qXCvKvzJg2o8TRQXzaPknwD48o3SYJhG/";
    string public _contractURI = "";
    string public uriSuffix = ".json";
    uint256 public maxMintAmountPerTx = 10;
    uint256 public maxPerAddressDuringMint = 10;
    uint256 public tokenPrice = 0.11 ether; //price per token
    address proxyRegistryAddress;

    uint256 public maxSupply = 250; //tokenIDs start from 1
    constructor() ERC721A("WestsideWalruses", "WALRUS") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }
    function mint(uint256 quantity) external payable callerIsUser{
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        require(
            quantity > 0 && quantity <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            balanceOf(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        require(msg.value >= tokenPrice * quantity, "Insufficient funds!");
        _safeMint(msg.sender, quantity);
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function getHoldTokenIdsByOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 index = 0;
        uint256 hasMinted = _totalMinted();
        uint256 tokenIdsLen = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLen);
        for (
            uint256 tokenId = 1;
            index < tokenIdsLen && tokenId <= hasMinted;
            tokenId++
        ) {
            if (_owner == ownerOf(tokenId)) {
                tokenIds[index] = tokenId;
                index++;
            }
        }
        return tokenIds;
    }


    function _startTokenId()  internal pure override returns (uint256){
        return 1;
    }

    //Typically, OpenSea use the tokenURI method
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_contractBaseURI, _tokenId.toString(), uriSuffix));
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        require(!uriLocked, "locked functions");
        _contractBaseURI = newBaseURI;
    }

    // and for the eternity!
    function lockBaseURIandContractURI() external onlyOwner {
        uriLocked = true;
    }

    //I'm not sure what is the benefit of _contractURI!
    function setContractURI(string memory newuri) external onlyOwner {
        require(!uriLocked, "locked functions");
        _contractURI = newuri;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }


    //change the price per token
    function setCost(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    //change the max supply
    function setMaxMintAmount(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    //blocks staking but doesn't block unstaking / claiming
    function setPaused(bool _setPaused) public onlyOwner {
        return (_setPaused) ? _pause() : _unpause();
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    /**
   * @dev can airdrop tokens
	 */
    function airdrop(address to, uint256 qty) external onlyOwner {
        require(totalSupply() + qty <= maxSupply, "out of stock");
        _safeMint(to, qty);
    }

    //----------------------------------
    //    tokensOfOwner todo later []



    // earnings withdrawal

    function withdraw() external onlyOwner {
        // This forwards all available gas. Be sure to check the return value!
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    
}