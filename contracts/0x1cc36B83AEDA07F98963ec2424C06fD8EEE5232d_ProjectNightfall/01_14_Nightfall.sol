// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract ProjectNightfall is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
	using Strings for uint;

	uint public maxWatcherSupply = 333;
	uint public maxSummons = 1;

	uint public summonCost = 0.01 ether;

	bool public summoningEnabled = false;

    string public _baseURL = "ipfs://bafybeiflcarb3r53jvxk76j5pghgpgk3xn42d2rztnzah2dhcn634psdqy/";
	string public prerevealURL = "";

	mapping(address => uint) private _walletMintedCount;

	constructor() ERC721A("Project Nightfall", "NTFL") { }
    
    //===============================================================
    //                      Essential Functions
    //===============================================================

    function mintedCount(address owner) external view returns (uint) {
        return _walletMintedCount[owner];
    }

    //===============================================================
    //                        Watcher Metadata
    //===============================================================

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

	function contractURI() public pure returns (string memory) {
		return "";
	}

	function reveal(string memory url) external onlyOwner {
		_baseURL = url;
	}

	function tokenURI(uint tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : prerevealURL;
	}

    //===============================================================
    //                           Setters
    //===============================================================

    function setSummonCost(uint _cost) external onlyOwner {
		summonCost = _cost;
	}

	function toggleSummoning() external onlyOwner {
		summoningEnabled = !summoningEnabled;
	}

	function setMaxWatchers(uint _newMax) external onlyOwner {
		maxWatcherSupply = _newMax;
	}

    //===============================================================
    //                          Summoning
    //===============================================================

    function summonWatcher(uint count) external payable {
		require(summoningEnabled, "Summoning watchers is not yet active.");

		require(_totalMinted() + count <= maxWatcherSupply, "Exceeds max watcher supply.");
        require(_walletMintedCount[msg.sender] + count <= maxSummons, "You have already summoned your watcher.");

		require(
			msg.value >= count * summonCost,
			"You have not provided enough ether to summon a watcher."
		);

		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}

    //===============================================================
    //                       Owner Functions
    //===============================================================

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxWatcherSupply,
			"Exceeds max watcher supply."
		);
		_safeMint(to, count);
	}

    //===============================================================
    //                      Operator Filterer
    //===============================================================

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}