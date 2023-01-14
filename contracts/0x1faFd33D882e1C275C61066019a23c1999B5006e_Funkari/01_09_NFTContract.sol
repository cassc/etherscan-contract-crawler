// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Funkari is ERC721A("Funkari", "FUNK"), Ownable, DefaultOperatorFilterer {

	uint256 public MAX_SUPPLY = 200;
	uint256 public mintPrice;
	bytes32 public merkleRoot;
	string internal baseURI;
	bool public saleStarted = false;

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

    function setMintPrice(uint256 _mintPrice) public onlyOwner { 
        mintPrice = _mintPrice;
    }

	function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner { 
        merkleRoot = _merkleRoot;
    }

	function verifyWhitelist(address wallet, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);       
    }

	function setBaseURI(string memory _newURI) external onlyOwner {
		baseURI = _newURI;
	}

	function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function adminMint(address to, uint256 amount) external onlyOwner {
        require(_totalMinted() + amount <= MAX_SUPPLY, "Max supply exceeded");
        require(amount <= 30, "Mint amount too large for one transaction");
        _mint(to, amount);       
    }

    function toggleSaleStatus() external onlyOwner {
		saleStarted = !saleStarted;
    }

    function mint(bytes32[] calldata _merkleProof) external payable {
        require(saleStarted, "Sale not started");
		require(verifyWhitelist(msg.sender, _merkleProof));
        require(tx.origin == msg.sender, "Caller is not origin");
        require(msg.value >= mintPrice, "Insufficient funds");
        require(_totalMinted() < MAX_SUPPLY, "Max supply exceeded");
		require(_numberMinted(msg.sender) == 0, "Max mints for this wallet exceeded");
        _mint(msg.sender, 1);
	}

    function withdrawFunds(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool callSuccess, ) = payable(to).call{value: balance}("");
        require(callSuccess, "Call failed");
    }

	function numMinted(address wallet) public view returns (uint256) {
		return _numberMinted(wallet);
	}

	//Opensea Operator Filter Registry Overrides

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
}