// SPDX-License-Identifier: MIT

//██████╗  ██████╗  ██████╗ ██████╗ ██████╗
//██╔══██╗██╔═══██╗██╔═══██╗╚════██╗██╔══██╗
//██████╔╝██║   ██║██║   ██║ █████╔╝██║  ██║
//██╔══██╗██║   ██║██║   ██║ ╚═══██╗██║  ██║
//██████╔╝╚██████╔╝╚██████╔╝██████╔╝██████╔╝
//╚═════╝  ╚═════╝  ╚═════╝ ╚═════╝ ╚═════╝

// ERC721A Smart Contract & Web3 Technology developed by NFT Elite Consulting x MisterSausage for BOO3D FRENS

// First person to send a screenshot of this line of code gets a FREE BOO3D fren, open a ticket in the discord. #B003DUp

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./ERC721A.sol"; //
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BOO3DFrens is ERC721A, Ownable  {
  using SafeMath for uint256;
	using Strings for uint256;
    bytes32 public merkleRoot;
    bytes32 public vipMerkleRoot;
    uint256 constant public MAX_SUPPLY= 4444;
	  uint256 constant public MAX_WL_SUPPLY = 4444;
    uint256 constant public MAX_VIPWL_SUPPLY = 4444;
    uint256 public WL_PRICE = 0.035 ether;
    uint256 public VIPWL_PRICE = 0.03 ether;
    uint256 public PRICE = 0.044 ether;
    uint256 public giveawayLimit = 100;
    string public baseTokenURI;
    bool public whitelistSaleIsActive;
    bool public saleIsActive;
    address private wallet1 = 0xA2D5616eEf6c03e9dcDa714399BdF7D5eB3ce003; // BOO3D 54%
    address private wallet2 = 0x7731BF1EbEeB49685b330b4CeDD2D1D79306d1A9; // BJow 3%
    address private wallet3 = 0x335cD97c5449857CCb1f067C5C3A3a8052cd56bf; // J 2%
    address private wallet4 = 0xD06D43F520264dC0c6c7c4468B97b5E6a5C556e0; // M 10%
    address private wallet5 = 0x48fFbBe1b591F481536A30c9ffCB0256a07498fc; // K 14%
    address private wallet6 = 0xA34481f6B5765f6d7cB34C0A4730bF18d190feF2; // Ma 13%
    address private wallet7 = 0xEDaa10d69588ecf47652a461AcD69B1bCeA6BA7a; // Refund Wallet 4%
    address public Authorized = 0x7a29d9a21A45E269F1bFFFa15a84c16BA0050E27; // Dev Wallet for Testing (no percentage)

    uint256 public maxPurchase = 2;
    uint256 public maxWLPurchase = 2;
    uint256 public maxVIPPurchase = 2;
	  uint256 public maxTxWL = 2;
	  uint256 public maxTxVIP = 2;
    uint256 public maxTx = 2;

    constructor() ERC721A("BOO3DFrens", "B3DF") { }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyAuthorized {
        require(msg.sender == owner() || msg.sender == Authorized , "Not authorized");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipWhitelistSaleState() external onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }

    function updateMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function updateVIPMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        vipMerkleRoot = newMerkleRoot;
    }

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }

	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    function whitelistMint(uint256 numberOfTokens, bytes32[] calldata merkleProof ) payable external callerIsUser {
        require(whitelistSaleIsActive, "Whitelist Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_WL_SUPPLY, "Total WL Supply has been minted");
        require(numberOfTokens > 0 && numberOfTokens <= maxTxWL, "Can only mint upto 1 NFTs in a transaction");
        require(msg.value == WL_PRICE.mul(numberOfTokens), "Ether value sent is not correct");
        require(numberMinted(msg.sender).add(numberOfTokens) <= maxWLPurchase,"Exceeds Max mints allowed per whitelisted wallet");

        // Verify the merkle proof
        require(MerkleProof.verify(merkleProof, merkleRoot,  keccak256(abi.encodePacked(msg.sender))  ), "Invalid proof");

		_safeMint(msg.sender, numberOfTokens);
    }

    function vipMint(uint256 numberOfTokens, bytes32[] calldata merkleProof ) payable external callerIsUser {
        require(whitelistSaleIsActive, "Whitelist Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_VIPWL_SUPPLY, "Total VIPWL Supply has been minted");
        require(numberOfTokens > 0 && numberOfTokens <= maxTxVIP, "Can only mint upto 2 NFTs in a transaction");
        require(msg.value == VIPWL_PRICE.mul(numberOfTokens), "Ether value sent is not correct");
        require(numberMinted(msg.sender).add(numberOfTokens) <= maxVIPPurchase,"Exceeds Max mints allowed per whitelisted wallet");

        // Verify the merkle proof
        require(MerkleProof.verify(merkleProof, vipMerkleRoot,  keccak256(abi.encodePacked(msg.sender))  ), "Invalid proof");

		_safeMint(msg.sender, numberOfTokens);
    }

    function mint(uint256 numberOfTokens) external payable callerIsUser {
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Total Supply has been minted");
        require(msg.value == PRICE.mul(numberOfTokens), "Ether value sent is not correct");
		require(numberOfTokens > 0 && numberOfTokens <= maxTx, "1 pTX allowed");
        require(numberMinted(msg.sender).add(numberOfTokens) <= maxPurchase,"Exceeds Max mints allowed per wallet");

        _safeMint(msg.sender, numberOfTokens);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

	    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No balance");
        uint256 _amount = address(this).balance;
        (bool wallet1Success, ) = wallet1.call{value: _amount.mul(54).div(100)}("");
        (bool wallet2Success, ) = wallet2.call{value: _amount.mul(3).div(100)}("");
        (bool wallet3Success, ) = wallet3.call{value: _amount.mul(2).div(100)}("");
        (bool wallet4Success, ) = wallet4.call{value: _amount.mul(10).div(100)}("");
        (bool wallet5Success, ) = wallet5.call{value: _amount.mul(14).div(100)}("");
        (bool wallet6Success, ) = wallet6.call{value: _amount.mul(13).div(100)}("");
        (bool wallet7Success, ) = wallet7.call{value: _amount.mul(4).div(100)}("");
        require(wallet1Success && wallet2Success && wallet3Success && wallet4Success && wallet5Success && wallet6Success && wallet7Success, "Withdrawal failed.");
    }

    function giveAway(uint256 numberOfTokens, address to) external onlyOwner {
        require(giveawayLimit.sub(numberOfTokens) >= 0,"Giveaways exhausted");
        _safeMint(to, numberOfTokens);
        giveawayLimit = giveawayLimit.sub(numberOfTokens);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setPriceWL(uint256 _wlPrice) public onlyAuthorized {
        WL_PRICE = _wlPrice;
    }

    function setPriceVIPWL(uint256 _vipwlPrice) public onlyAuthorized {
        VIPWL_PRICE = _vipwlPrice;
    }

    function setPrice(uint256 _price) public onlyAuthorized {
        PRICE = _price;
    }

    function setMaxTxLimit(uint256 _txLimit) public onlyAuthorized {
        maxTx = _txLimit;
    }

	function setMaxTxWL(uint256 _txLimit) public onlyAuthorized {
        maxTxWL = _txLimit;
    }

	function setMaxTxVIP(uint256 _txLimit) public onlyAuthorized {
        maxTxVIP = _txLimit;
    }

    function setMaxPurchaseLimit(uint256 _limit) public onlyAuthorized {
        maxPurchase = _limit;
    }

    function setMaxWLPurchaseLimit(uint256 _limit) public onlyAuthorized {
        maxWLPurchase = _limit;
    }

    function setMaxVIPPurchaseLimit(uint256 _limit) public onlyAuthorized {
        maxVIPPurchase = _limit;
    }

}