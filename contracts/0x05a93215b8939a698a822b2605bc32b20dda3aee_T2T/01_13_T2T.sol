// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol"; // ERC721A standard by Azuki (Chiru Labs)
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract T2T is ERC721A, Ownable  {
    using SafeMath for uint256;
    bytes32 public merkleRoot;
    uint256 public MAX_SUPPLY= 386;
	uint256 public WL_SUPPLY= 0;
    uint256 public WL_PRICE = 0.21 ether;
    uint256 public PRICE = 0.21 ether;
    uint256 public giveawayLimit = 50;
    string public baseTokenURI;
    bool public whitelistSaleIsActive;
    bool public saleIsActive;
    address public ownerWallet1;
    address public ownerWallet2;
    mapping(address => bool) isWhitelisted;

    constructor() ERC721A("Tes2ment", "T2T") { }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return string(abi.encodePacked(uri, ".json"));
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }
	
	function updateWhitelistSupply(uint256 _whitelistSupply) external onlyOwner {
        WL_SUPPLY = _whitelistSupply;
    }

    function updateGiveawayLimit(uint256 _giveawayLimit) external onlyOwner {
        giveawayLimit = _giveawayLimit;
    }
      function updatePrice(uint256 _publicPrice) external onlyOwner {
        PRICE = _publicPrice;
    }
      function updateWLPrice(uint256 _whitelistPrice) external onlyOwner {
        WL_PRICE = _whitelistPrice;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipWhitelistSaleState() external onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }  

    function setOnChainWhitelist(address[] calldata _whitelistAddresses) external onlyOwner {
        for (uint i=0; i<_whitelistAddresses.length; i++) {
            isWhitelisted[_whitelistAddresses[i]] = true;
        }
    }

    function updateMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function whitelistMint(uint256 numberOfTokens, bytes32[] calldata merkleProof ) payable external callerIsUser {
        require(whitelistSaleIsActive, "Whitelist Sale must be active to mint");
        require(WL_SUPPLY.sub(numberOfTokens)>=0, "Total WL Quota has been minted");
        require(numberOfTokens > 0 && numberOfTokens <= 10, "Can only mint upto 10 NFTs in a transaction");
        require(msg.value == WL_PRICE.mul(numberOfTokens), "Ether value sent is not correct");
        require(numberMinted(msg.sender).add(numberOfTokens) <= 10,"Max 10 mints allowed per whitelisted wallet");

        // Verify the merkle proof
        require(isWhitelisted[msg.sender] || MerkleProof.verify(merkleProof, merkleRoot,  keccak256(abi.encodePacked(msg.sender))  ), "Not whitelisted");
		
		_safeMint(msg.sender, numberOfTokens);
		WL_SUPPLY = WL_SUPPLY.sub(numberOfTokens);
		 
    }

    function mint(uint256 numberOfTokens) external payable callerIsUser {
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Total Supply has been minted");
        require(msg.value == PRICE.mul(numberOfTokens), "Ether value sent is not correct");
        require(numberMinted(msg.sender).add(numberOfTokens) <= 10,"Max 10 mints allowed per wallet");

        _safeMint(msg.sender, numberOfTokens);
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw.");
        uint256 _amount = address(this).balance;
        uint256 _wallet1bal = _amount.mul(40).div(100);
        uint256 _wallet2bal = _amount.sub(_wallet1bal);
        (bool wallet1Success, ) = ownerWallet1.call{value: _wallet1bal}("");
        (bool wallet2Success, ) = ownerWallet2.call{value: _wallet2bal}("");

        require(wallet1Success && wallet2Success, "Withdrawal failed.");
    }


    function giveAway(uint256 numberOfTokens, address to) external onlyOwner {
        require(giveawayLimit.sub(numberOfTokens) >= 0,"Giveaways exhausted");
        _safeMint(to, numberOfTokens);
        giveawayLimit = giveawayLimit.sub(numberOfTokens);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setOwnerWaller(address _ownerWallet1, address _ownerWallet2) external onlyOwner {
        ownerWallet1 = _ownerWallet1;
        ownerWallet2 = _ownerWallet2;
    }

}