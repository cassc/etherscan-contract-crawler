// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TBBGenesis is
	ERC721,
	ERC721Enumerable,
	ERC721URIStorage,
	Pausable,
	Ownable,
	ERC721Burnable
{
	using Counters for Counters.Counter;
	using Strings for uint;

	string private baseExtension = ".json";

	uint168 public constant PRICE = 0.2 ether;

	uint public MAX_SUPPLY = 300;

	bool public MINT_IS_LIVE = false;
	bool public MINT_IS_PUBLIC = false;

	bool public revealed = false;

	string private unrevealedUri;
	string private baseURI;

	uint8 public WALLET_MINT_MAX = 2;
	bytes32 public merkleRoot =
		0xc333f6a4980ec2ac8baef02d95703eabd11630af326dcb7601de07f53bd02d17;

	address payable private OneTreePlanted =
		payable(0x67CE09d244D8CD9Ac49878B76f5955AB4aC0A478);
	address payable private VRDev =
		payable(0x3DE81D7A75eB6f9E9eF74dF637f5Ff5B6F7ba41c);
	address payable private Marketing =
		payable(0x672014ac279B8BCc9c65Cc37012fba4820Bb404d);
	address payable private Treasury =
		payable(0x0fDA31E3454F429701082A20380D9CfAaDfefb54);
	address payable private Founder1 =
		payable(0xA1e6509424faBc6fd503999A29F61346149CbCaB);
	address payable private Founder2 =
		payable(0x650227FC46B84A64fFC271d1F0E508641314fd8a);
	address payable private Founder3 =
		payable(0x8245508E4eeE2Ec32200DeeCD7E85A3050Af7C49);
	address payable private Founder4 =
		payable(0x1954e9bE7E604Ff1A0f6D20dabC54F4DD86d8e46);
	address payable private Founder5 =
		payable(0x644580B17fd98F42B37B56773e71dcfD81eff4cB);
	address payable private Founder6 =
		payable(0xF5048836E6F1D2fbcA2E9A9a8FBbbd7b73c39F83);
	address payable private Ops =
		payable(0xf9B423eCafc7c01ceE6E07EFDDa4fFaa907f9e01);

	mapping(address => bool) private isAdmin;
	mapping(address => bool) private inKingsCourt;
	mapping(address => uint8) private tokensMinted;

	modifier onlyAdmin() {
		if (isAdmin[msg.sender]) {
			_;
		} else {
			revert("This action is reserved for Admins");
		}
	}

	modifier onlyKingsCourt(bytes32[] memory proof) {
		if (
			(MINT_IS_PUBLIC == true) ||
			(
				MerkleProof.verify(
					proof,
					merkleRoot,
					keccak256(abi.encodePacked(msg.sender))
				)
			) ||
			isAdmin[msg.sender] ||
			inKingsCourt[msg.sender]
		) {
			_;
		} else {
			revert("This action is reserved for members of the Kings Court");
		}
	}

	modifier onlyWhen(bool b) {
		if (b == true) {
			_;
		} else {
			revert("This function isnt available right now");
		}
	}

	Counters.Counter private _tokenIdCounter;

	event Mint(uint date, uint supply, string message);

	receive() external payable {}

	fallback() external payable {}

	constructor(string memory _initNotRevealedUri) ERC721("TBBGenesis", "TBBG") {
		setUnrevealedUri(_initNotRevealedUri);
		isAdmin[msg.sender] = true;
		isAdmin[Founder1] = true;
		isAdmin[Ops] = true;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setUnrevealedUri(string memory _notRevealedURI) public onlyOwner {
		unrevealedUri = _notRevealedURI;
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function reveal() public onlyOwner {
		revealed = true;
	}

	function getRemainingSupply() public view returns (uint) {
		return MAX_SUPPLY - _tokenIdCounter.current();
	}

	function setMintLive(bool live) public onlyAdmin {
		MINT_IS_LIVE = live;
	}

	function setMintPublic(bool live) public onlyAdmin {
		MINT_IS_PUBLIC = live;
	}

	function getTokensMintedBy(address _owner) public view returns (uint8) {
		return tokensMinted[_owner];
	}

	function safeMint(address to, string memory uri) public onlyOwner {
		_tokenIdCounter.increment();
		uint tokenId = _tokenIdCounter.current();
		_safeMint(to, tokenId);
		_setTokenURI(tokenId, uri);
	}

	function setAdmin(address addr, bool shouldAdmin) public onlyOwner {
		require(
			isAdmin[addr] != shouldAdmin,
			"Cannot change user to the same state."
		);
		isAdmin[addr] = shouldAdmin;
	}

	function isUserAdmin(address addr) public view returns (bool) {
		return isAdmin[addr];
	}

	function setKingsCourt(address[] memory addr, bool should) public onlyAdmin {
		{
			for (uint i = 0; i < addr.length; i++) {
				require(
					inKingsCourt[addr[i]] != should,
					"Cannot change user to the same state. "
				);
				inKingsCourt[addr[i]] = should;
			}
		}
	}

	function isInKingsCourt(address addr) public view returns (bool) {
		return inKingsCourt[addr];
	}

	function mint(uint amount, bytes32[] memory proof)
		public
		payable
		onlyKingsCourt(proof)
		onlyWhen(MINT_IS_LIVE || MINT_IS_PUBLIC)
	{
		require(msg.value == (PRICE * amount), "Insufficient payment");
		require(
			amount + _tokenIdCounter.current() <= MAX_SUPPLY,
			"Cannot mint more than remaining tokens in supply"
		);
		require(
			tokensMinted[msg.sender] + amount <= WALLET_MINT_MAX,
			"Minting this many tokens would exceed your wallet limit! Save some bunnies for your friends!"
		);
		if (msg.value == (PRICE * amount)) {
			for (uint i = 0; i < amount; i++) {
				_tokenIdCounter.increment();
				uint tokenId = _tokenIdCounter.current();
				tokensMinted[msg.sender]++;
				_safeMint(msg.sender, tokenId);
				handleCounters();
			}
		} else {
			revert("Invalid payment");
		}
	}

	function handleCounters() internal {
		uint currentToken = _tokenIdCounter.current();
		if (currentToken == MAX_SUPPLY) {
			withdraw();
			MINT_IS_LIVE = false;
			MINT_IS_PUBLIC = false;
			emit Mint(block.timestamp, currentToken, "Mint Has Ended");
		} else {
			emit Mint(block.timestamp, currentToken, "Battle Bunny Minted");
		}
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint tokenId
	) internal override(ERC721, ERC721Enumerable) whenNotPaused {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function _burn(uint tokenId) internal override(ERC721, ERC721URIStorage) {
		super._burn(tokenId);
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function tokenURI(uint tokenId)
		public
		view
		override(ERC721, ERC721URIStorage)
		returns (string memory)
	{
		require(_exists(tokenId), "URI query for nonexistent token");
		string memory tokenBaseURI = _baseURI();
		if (revealed == false) {
			return unrevealedUri;
		}

		return
			bytes(tokenBaseURI).length > 0
				? string(
					abi.encodePacked(tokenBaseURI, tokenId.toString(), baseExtension)
				)
				: "";
	}

	function withdraw() public onlyOwner {
		if (!MINT_IS_LIVE && !MINT_IS_PUBLIC) {
			withdrawRoyalties(address(this).balance);
		} else {
			withdrawGeneral(address(this).balance);
		}
	}

	function withdrawGeneral(uint balance) internal onlyOwner {
		(bool ts1, ) = OneTreePlanted.call{value: (balance / 100) * 4}("");
		require(ts1, "OneTreePlanted wallet transfer error");
		(bool ts2, ) = VRDev.call{value: (balance / 100) * 15}("");
		require(ts2, "VRdev wallet transfer error");
		(bool ts3, ) = Marketing.call{value: (balance / 100) * 15}("");
		require(ts3, "Marketing wallet transfer error");
		(bool ts4, ) = Treasury.call{value: (balance / 100) * 33}("");
		require(ts4, "Marketing wallet transfer error");
		withdrawRoyalties((balance / 100) * 33);
	}

	function ownerWithdraw() public payable onlyOwner {
		(bool os, ) = payable(owner()).call{value: address(this).balance}("");
		require(os);
	}

	function withdrawRoyalties(uint balance) internal onlyOwner {
		(bool ts1, ) = Founder1.call{value: (balance / 100) * 5}("");
		require(ts1, "Founder1 wallet transfer error");
		(bool ts2, ) = Founder2.call{value: (balance / 100) * 5}("");
		require(ts2, "Founder2 wallet transfer error");
		(bool ts3, ) = Founder3.call{value: (balance / 100) * 10}("");
		require(ts3, "Founder3 wallet transfer error");
		(bool ts4, ) = Founder4.call{value: (balance / 100) * 12}("");
		require(ts4, "Founder4 wallet transfer error");
		(bool ts6, ) = Founder6.call{value: (balance / 100) * 34}("");
		require(ts6, "Founder6 wallet transfer error");
		(bool ts5, ) = Founder5.call{value: (balance / 100) * 34}("");
		require(ts5, "Founder5 wallet transfer error");
	}

	function setMerkleRoot(bytes32 _newRoot) public onlyAdmin {
		require(_newRoot.length > 0, "Invalid merkle root");
		merkleRoot = _newRoot;
	}

	function setWithdrawalAccounts(
		uint _account,
		address payable _previousAddress,
		address payable _newAddress
	) external onlyOwner {
		string
			memory errMessage = "Your previous address does not match the address of the role you are trying to set please confirm you are trying to set the correct role";
		require(
			_account >= 1 && _account <= 10,
			"You must designate a valid account number, enter 1 through 6 for founder accounts and 7 through 10 for general accounts"
		);
		require(
			_previousAddress != _newAddress,
			"You cannot set the same address as the previous address"
		);
		if (_account == 1) {
			require(Founder1 == _previousAddress, errMessage);
			Founder1 = _newAddress;
		} else if (_account == 2) {
			require(Founder2 == _previousAddress, errMessage);
			Founder2 = _newAddress;
		} else if (_account == 3) {
			require(Founder3 == _previousAddress, errMessage);
			Founder3 = _newAddress;
		} else if (_account == 4) {
			require(Founder4 == _previousAddress, errMessage);
			Founder4 = _newAddress;
		} else if (_account == 5) {
			require(Founder5 == _previousAddress, errMessage);
			Founder5 = _newAddress;
		} else if (_account == 6) {
			require(Founder6 == _previousAddress, errMessage);
			Founder6 = _newAddress;
		} else if (_account == 7) {
			require(OneTreePlanted == _previousAddress, errMessage);
			OneTreePlanted = _newAddress;
		} else if (_account == 8) {
			require(VRDev == _previousAddress, errMessage);
			VRDev = _newAddress;
		} else if (_account == 9) {
			require(Marketing == _previousAddress, errMessage);
			Marketing = _newAddress;
		} else if (_account == 10) {
			require(Treasury == _previousAddress, errMessage);
			Treasury = _newAddress;
		} else {
			revert("payee reset failed");
		}
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}