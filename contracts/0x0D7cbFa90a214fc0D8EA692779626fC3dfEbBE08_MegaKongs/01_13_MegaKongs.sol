// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract MegaKongs is ERC721A, Ownable, ReentrancyGuard {
	uint256 public constant mintPrice = 0.05 ether;
	uint256 public constant maxSupply = 6000;

	bytes32 public claimMerkleRoot;
	bytes32 public kongListMerkleRoot;
	bytes32 public publicMerkleRoot;

	string public baseURI = "ipfs://QmdfRa8FoCmtoT6nLWhTfkA2oUCv49oTMiiQM4PcQgRuKk/";
	string public contractURI = "ipfs://QmbcAEgQYmspusVYkXJgd9k7bAkmhQ7L6hRXdrtQnWBM2Q";
	address public bankAddress = 0x454CC84a85f3E73eC5C4CFe4f618E22AEA04FE16;
	bool public publicSaleActive = false;
	uint256 public maxPerPublicMint = 0;

	mapping(address => uint256) public addressToClaimed;
	mapping(address => uint256) public addressToMinted;

	constructor() ERC721A("MegaKongs", "KONGS") {}

	modifier callerIsUser() {
		require(tx.origin == _msgSender(), "Caller is contract");
		_;
	}

	function setBankAddress(address _bankAddress) external onlyOwner {
		bankAddress = _bankAddress;
	}

	function setPublicSale(bool _state) external onlyOwner {
		publicSaleActive = _state;
	}

	function getContractURI() public view returns (string memory) {
		return contractURI;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function setBaseURI(string calldata _uri) external onlyOwner {
		baseURI = _uri;
	}

	function setContractURI(string calldata _uri) external onlyOwner {
		contractURI = _uri;
	}

	function setClaimMerkleRoot(bytes32 _claimMerkleRoot) external onlyOwner {
		require(publicSaleActive == false, "Public sale is active");
		claimMerkleRoot = _claimMerkleRoot;
	}

	function setKongListMerkleRoot(bytes32 _kongListMerkleRoot)
		external
		onlyOwner
	{
		require(publicSaleActive == false, "Public sale is active");
		kongListMerkleRoot = _kongListMerkleRoot;
	}

	function _leaf(string memory allowance, string memory payload)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked(payload, allowance));
	}

	function _verify(
		bytes32 leaf,
		bytes32[] memory proof,
		bytes32 merkleRoot
	) internal pure returns (bool) {
		return MerkleProof.verify(proof, merkleRoot, leaf);
	}

	function togglePublicSale(
		bool _publicSaleActive,
		uint256 _maxPerPublicMint,
		bytes32 _publicMerkleRoot
	) external onlyOwner {
		// Any modifications to the public sale state will remove prior Merkle proofs
		delete claimMerkleRoot;
		delete kongListMerkleRoot;
		publicMerkleRoot = _publicMerkleRoot;
		publicSaleActive = _publicSaleActive;
		maxPerPublicMint = _maxPerPublicMint;
	}

	function claimMint(
		uint256 count,
		uint256 allowance,
		bytes32[] calldata proof
	) public callerIsUser {
		string memory payload = string(abi.encodePacked(_msgSender()));
		require(
			_verify(
				_leaf(Strings.toString(allowance), payload),
				proof,
				claimMerkleRoot
			),
			"Invalid proof supplied"
		);
		require(
			addressToClaimed[_msgSender()] + count < allowance + 1,
			"Exceeds claim allocation"
		);

		addressToClaimed[_msgSender()] += count;
		_safeMint(_msgSender(), count);
	}

	function kongListMint(
		uint256 count,
		uint256 allowance,
		bytes32[] calldata proof
	) public payable callerIsUser {
		string memory payload = string(abi.encodePacked(_msgSender()));
		require(
			_verify(
				_leaf(Strings.toString(allowance), payload),
				proof,
				kongListMerkleRoot
			),
			"Invalid proof supplied"
		);
		require(
			addressToMinted[_msgSender()] + count < allowance + 1,
			"Exceeds KongList allocation"
		);
		require(count * mintPrice == msg.value, "Invalid funds provided");

		addressToMinted[_msgSender()] += count;
		_safeMint(_msgSender(), count);
	}

	function publicMint(
		uint256 count,
		bytes32[] calldata proof,
		string calldata antiBotPhrase,
		uint256 antiBotPhraseAllowance
	) public payable callerIsUser {
		require(publicSaleActive, "Sale is not active");
		string memory payload = string(abi.encodePacked(antiBotPhrase));
		require(
			_verify(
				_leaf(Strings.toString(antiBotPhraseAllowance), payload),
				proof,
				publicMerkleRoot
			),
			"Invalid proof supplied"
		);
		uint256 totalSupply = totalSupply();
		require(count < maxPerPublicMint + 1, "Exceeds max per mint");
		require(totalSupply + count < maxSupply + 1, "Exceeds max supply");
		require(count * mintPrice == msg.value, "Invalid funds provided");
		_safeMint(_msgSender(), count);
	}

	function withdraw() external onlyOwner nonReentrant {
		require(bankAddress != address(0), "No bank address set");
		(bool success, ) = bankAddress.call{ value: address(this).balance }("");
		require(success, "Failed to withdraw");
	}
}