// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";  

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./DefaultOperatorFilterer.sol";
import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";


contract SEAK is ERC721A, Ownable, Pausable, ERC2981, DefaultOperatorFilterer {
	using Address for address;
	using Strings for uint256;
	using MerkleProof for bytes32[];

	address proxyRegistryAddress;

	//merkle roots
	bytes32 public ogRoot;
	bytes32 public sklistRoot;
	bytes32 public reserveRoot;

	// metadata
	string public _contractBaseURI;
	string public _contractURI;

	// price per token
	uint256 public ogPrice = 0.20 ether;
	uint256 public sklistPrice = 0.25 ether;
	uint256 public reservePrice = 0.25 ether;

	mapping(address => uint256) public usedAddresses; //who has minted.

	uint256 public maxSupply = 333; //tokenIDs start from 0

	uint256 public maxPerWallet = 1;

	// Sale state:
	// 0: Closed
	// 1: OG
	// 2: SKLIST
	// 3: Reserve List
	// 4: General

	uint256 public saleState = 0;

	constructor() ERC721A("SEAK", "SEAK") {
		//_safeMint(msg.sender, 1); //mints 1 nft to the owner for configuring opensea
	}

	function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // IERC165: 0x01ffc9a7, IERC721: 0x80ac58cd, IERC721Metadata: 0x5b5e139f, IERC29081: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

	/// Set royalties for EIP 2981.
    function setRoyalties(
        address _recipient,
        uint96 _amount
    ) external onlyOwner {
        _setDefaultRoyalty(_recipient, _amount);
    }

	// minting methods.

	function ogMint(
		bytes32[] calldata proof
	) external payable whenNotPaused {
        require(saleState >= 1, "OG mint is not open");
		require(totalSupply() + 1 <= maxSupply, "Sold out");
		require(ogPrice * 1 == msg.value, "Exact ETH amount needed");
		require(usedAddresses[msg.sender] + 1 <= maxPerWallet, "Max per wallet reached");
		require(isTokenValid(ogRoot, msg.sender, proof), "Invalid merkle proof");

		usedAddresses[msg.sender] += 1;

		_safeMint(msg.sender, 1);
	}

	function sklistMint(
		bytes32[] calldata proof
	) external payable whenNotPaused {
        require(saleState >= 2, "SEAKList mint is not open");
		require(totalSupply() + 1 <= maxSupply, "Sold out");
		require(sklistPrice * 1 == msg.value, "Exact ETH amount needed");
		require(usedAddresses[msg.sender] + 1 <= maxPerWallet, "Max per wallet reached");
		require(isTokenValid(sklistRoot, msg.sender, proof), "Invalid merkle proof");

		usedAddresses[msg.sender] += 1;

		_safeMint(msg.sender, 1);
	}

	function reserveMint(
		bytes32[] calldata proof
	) external payable whenNotPaused {
        require(saleState >= 3, "Reserve mint is not open");
		require(totalSupply() + 1 <= maxSupply, "Sold out");
		require(reservePrice * 1 == msg.value, "Exact ETH amount needed");
		require(usedAddresses[msg.sender] + 1 <= maxPerWallet, "Max per wallet reached");
		require(isTokenValid(reserveRoot, msg.sender, proof), "Invalid merkle proof");

		usedAddresses[msg.sender] += 1;

		_safeMint(msg.sender, 1);
	}

	function mint() external payable whenNotPaused {
        require(saleState >= 4, "Public mint is not open");
		require(totalSupply() + 1 <= maxSupply, "Sold out");
		require(reservePrice * 1 == msg.value, "Exact ETH amount needed");
		require(usedAddresses[msg.sender] + 1 <= maxPerWallet, "Max per wallet reached");

		usedAddresses[msg.sender] += 1;

		_safeMint(msg.sender, 1);
	}

	/**
	 * Admin Mint
	 */
	function adminMint(address to, uint256 qty) external onlyOwner {
		require(totalSupply() + qty <= maxSupply, "Sold out");
		_safeMint(to, qty);
	}

	function devMint(uint256 qty) external onlyOwner {
		require(totalSupply() + qty <= maxSupply, "Sold out");
		_safeMint(msg.sender, qty);
	}

	/**
	 * @dev verification function for merkle root
	 */
	function isTokenValid(
		bytes32 _root,
		address _to,
		bytes32[] memory _proof
	) public pure returns (bool) {
		// construct Merkle tree leaf from the inputs supplied
		bytes32 leaf = keccak256(abi.encodePacked(_to));
		// verify the proof supplied, and return the verification result
		return _proof.verify(_root, leaf);
	}

	// set merkle root methods
	function setOGMerkleRoot(bytes32 _root) external onlyOwner {
		ogRoot = _root;
	}

	function setSklistMerkleRoot(bytes32 _root) external onlyOwner {
		sklistRoot = _root;
	}

	function setReserveMerkleRoot(bytes32 _root) external onlyOwner {
		reserveRoot = _root;
	}

	// set price methods
	function setOGPrice(uint256 newPrice) external onlyOwner {
		ogPrice = newPrice;
	}

	function setSklistPrice(uint256 newPrice) external onlyOwner {
		sklistPrice = newPrice;
	}

	function setReservePrice(uint256 newPrice) external onlyOwner {
		reservePrice = newPrice;
	}

	//----------------------------------
	//----------- other code -----------
	//----------------------------------

    /*function ownedTokensByAddress(address owner) external view returns (uint256[] memory) {
        uint256 totalTokensOwned = balanceOf(owner);
        uint256[] memory allTokenIds = new uint256[](totalTokensOwned);
        for (uint256 i = 0; i < totalTokensOwned; i++) {
            allTokenIds[i] = (tokenOfOwnerByIndex(owner, i));
        }
        return allTokenIds;
    }*/

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString(), ".json"));
	}

	function setBaseURI(string memory newBaseURI) external onlyOwner {
		_contractBaseURI = newBaseURI;
	}

	function setContractURI(string memory newURI) external onlyOwner {
		_contractURI = newURI;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721A erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	function setSaleState(uint newState) public onlyOwner {
        require(newState >= 0 && newState <= 4, "Invalid state");
        saleState = newState;
    }

	//change the max supply
	function setMaxSupplyAmount(uint256 newMaxSupply) public onlyOwner {
		maxSupply = newMaxSupply;
	}

	//change the max per wallet
	function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
		maxPerWallet = _maxPerWallet;
	}

	function setPaused(bool _setPaused) public onlyOwner {
		return (_setPaused) ? _pause() : _unpause();
	}

	//sets the opensea proxy
	function setProxyRegistry(address _newRegistry) external onlyOwner {
		proxyRegistryAddress = _newRegistry;
	}

	// earnings withdrawal
	function withdraw() public payable onlyOwner {
		uint balance = address(this).balance;
    	payable(msg.sender).transfer(balance);
	}

	// Override the start token id to 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

	// OS filter functions.
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperator(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

	// Operator Registry Controls
    function setOperatorFilterRegistry(address _registry) public onlyOwner {
        operatorFilterRegistry = IOperatorFilterRegistry(_registry);
    }

    function updateOperator(address _operator, bool _filtered) public onlyOwner {
        operatorFilterRegistry.updateOperator(address(this), _operator, _filtered);
    }

	/**
	 * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
	 */
	/*function isApprovedForAll(address owner, address operator) public view override returns (bool) {
		// Whitelist OpenSea proxy contract for easy trading.
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(owner)) == operator) {
			return true;
		}
		return super.isApprovedForAll(owner, operator);
	}*/
}

//opensea removal of approvals
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}