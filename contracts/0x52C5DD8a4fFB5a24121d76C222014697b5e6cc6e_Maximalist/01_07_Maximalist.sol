//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Maximalist is Ownable, ERC721A {
	using ECDSA for bytes32;

	bool    private _publicSaleLive = false;
	bool    private _whitelistSaleLive = false;
	string  private _tokenBaseURI;
	address private _tierOneSignerPublicKey;
	address private _tierTwoSignerPublicKey;
	uint256 private _whitelistSupply = 9976;

	uint256 public constant TIER_ONE_MAX_QTY = 2;
	uint256 public constant TIER_TWO_MAX_QTY = 1;
	uint256 public constant PUBLIC_MAX_QTY = 1;
	uint256 public constant MAX_SUPPLY = 9976;

	constructor() ERC721A("Maximalist", "MAXI") {}

	modifier canMint(uint256 quantity, uint256 maxSupply) {
		require(tx.origin == msg.sender, "Calling from a contract is forbidden");
		require(totalSupply() + quantity <= maxSupply, "Sale has sold out");
		_;
	}

	function publicMint() external canMint(PUBLIC_MAX_QTY, MAX_SUPPLY) {
		require(_publicSaleLive, "Public sale is not live");
		require(_numberMinted(msg.sender) == 0, "Max quantity per address reached");
		_safeMint(msg.sender, PUBLIC_MAX_QTY);
	}

	function whitelistMint(uint256 quantity, bytes calldata _signature) external canMint(quantity, _whitelistSupply)
	{
		require(_whitelistSaleLive, "Whitelist sale is not live");
		require(quantity <= TIER_ONE_MAX_QTY, "Max quantity is 2");
		uint256 tier = verify(quantity, _signature);
		require(tier != 0, "You are not whitelisted or have provided an invalid signature");
		require(_numberMinted(msg.sender) + quantity <= (tier == 1 ? TIER_ONE_MAX_QTY : TIER_TWO_MAX_QTY), "Max quantity per address reached");
		_safeMint(msg.sender, quantity);
	}

	function gift(address to, uint256 quantity) external onlyOwner {
		require(totalSupply() + quantity <= MAX_SUPPLY, "Collection has sold out or quantity exceeds collection size");
		_safeMint(to, quantity);
	}

	function setWhitelistMaxSupply(uint256 max) external onlyOwner {
		require(max <= MAX_SUPPLY, "Whitelist supply can not exceed collection size");
		_whitelistSupply = max;
	}

	function togglePublicSale() external onlyOwner {
		_publicSaleLive = !_publicSaleLive;
	}

	function toggleWhitelistSale() external onlyOwner {
		_whitelistSaleLive = !_whitelistSaleLive;
	}

	function setTierOneSignerAddress(address _signer) external onlyOwner {
		_tierOneSignerPublicKey = _signer;
	}

	function setTierTwoSignerAddress(address _signer) external onlyOwner {
		_tierTwoSignerPublicKey = _signer;
	}

	function setBaseURI(string calldata baseURI) external onlyOwner {
		_tokenBaseURI = baseURI;
	}

	function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return _tokenBaseURI;
	}

    function verify(uint256 quantity, bytes calldata _signature) internal view returns(uint) {
        address signer = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(msg.sender, quantity)))).recover(_signature);
		if (_tierTwoSignerPublicKey == signer) {
			return 2;
		} else if (_tierOneSignerPublicKey == signer) {
			return 1;
		}
		return 0;
    }
}