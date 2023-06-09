// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract TinyTrashcans is ERC721A, Ownable {
	using Strings for uint256;
	enum SaleStatus {
		PAUSED,
		PUBLIC
	}

	uint256 public constant COLLECTION_SIZE = 3333;
	uint256 public constant TOKENS_PER_TRAN_LIMIT = 10;
	uint256 public constant MINT_PRICE = 0.01 ether;

	SaleStatus public saleStatus = SaleStatus.PAUSED;
    bool public revealFinalized = false;
	string public placeholderURL = "ipfs://QmaDTeyoJquSin3xvctL69pg9Su1mKrEdFqhVWz24BwtYv";
    string private _baseURL;
	mapping(address => uint256) private _mintedCount;

	constructor() ERC721A("TinyTrashcans", "TT") {}

	function contractURI() public pure returns (string memory) {
		return
			"ipfs://Qmb1VryuiSUnpF7q9KMiK8r8m9j1XbnMtp6F1ujYfdDA3x";
	}

    function finalizeReveal() external onlyOwner {
        revealFinalized = true;
    }

	/// @notice Reveal metadata for all the tokens
	function reveal(string memory url) external onlyOwner {
        require(!revealFinalized, "TinyTrashcans: Metadata is finalized");
		_baseURL = url;
	}

	/// @dev override base uri. It will be combined with token ID
	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint256) {
		return 1;
	}

    function mintedCount(address wallet) external view returns (uint) {
        return _mintedCount[wallet];
    }

	/// @notice Update current sale stage
	function setSaleStatus(SaleStatus status) external onlyOwner {
		saleStatus = status;
	}

	/// @notice Withdraw contract balance
	function withdraw() external onlyOwner {
		uint256 balance = address(this).balance;
		require(balance > 0, "TinyTrashcans: No balance");
		payable(0xEA8c06275d6Bb509c353C5Fb843eF16ebDDE643A).transfer(balance);
	}

	/// @notice Allows owner to mint tokens to a specified address
	function airdrop(address to, uint256 count) external onlyOwner {
		require(
			_totalMinted() + count <= COLLECTION_SIZE,
			"TinyTrashcans: Request exceeds collection size"
		);
		_safeMint(to, count);
	}

	/// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
	/// @param tokenId token ID
	function tokenURI(uint256 tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : placeholderURL;
	}

	/// @notice Mints specified amount of tokens
	/// @param count How many tokens to mint
	function mint(uint256 count) external payable {
		require(saleStatus != SaleStatus.PAUSED, "TinyTrashcans: Sales are off");
		require(
			count <= TOKENS_PER_TRAN_LIMIT,
			"TinyTrashcans: Number of requested tokens exceeds allowance (10)"
		);
		require(
			_totalMinted() + count <= COLLECTION_SIZE,
			"TinyTrashcans: Number of requested tokens will exceed collection size"
		);

        uint payForCount = count;
        if(_mintedCount[msg.sender] == 0) {
            payForCount--; // 1st can free
        }

		require(
			msg.value >= payForCount * MINT_PRICE,
			"TinyTrashcans: Ether value sent is not sufficient"
		);

		_mintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}