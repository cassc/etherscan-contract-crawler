// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";


/// @custom:security-contact [email protected]
contract ElseVerseMysteryBoxes is Initializable, ERC721Upgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable  {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for ERC20Upgradeable;

    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

	int public totalMints;	
	bytes32 public participationMerkleRoot;
	mapping(address => bool) public whiteListClaimed;
	uint256 public startDate;
	int public maxMints;
	mapping(address => uint256) public whiteListClaimedCount;
	bool public publicMintOpen;
	uint256 public maxMintsPerWalletPublic;
	
    event NewBox(
        uint256 indexed id,
        address indexed owner
    );	

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("ElseVerseMysteryBoxes", "EVMB");
        __ERC721Burnable_init();
        __Ownable_init();
		startDate = 1673621985; // 13 Jan, 15-00 UTC
		maxMints = 15000; 
    }
	
	function setStartDate(uint256 _startDate) external onlyOwner {
        startDate = _startDate;
	}
	
	function setMaxMints(int _maxMints) external onlyOwner {
        maxMints = _maxMints;
	}

	function setParticipationMerkleRoot(bytes32 newParticipationMerkleRoot) external onlyOwner {
		participationMerkleRoot = newParticipationMerkleRoot;
	}

	function openForPublic(bool _mintOpen, uint256 _mintsPerWallet) external onlyOwner {
		publicMintOpen = _mintOpen;
		maxMintsPerWalletPublic = _mintsPerWallet;
	}
	
	function bulkSafeMint(address[] memory tos) external onlyOwner {
		for (uint i = 0; i < tos.length; i++) {
			uint256 tokenId = _tokenIdCounter.current();
			_tokenIdCounter.increment();
			_safeMint(tos[i], tokenId);
		}
	}

    function safeMint(bytes32[] calldata _merkleProof, uint256 mintCount, uint256 maxMintCount) public {
		require(block.timestamp > startDate, "Mint not started");
		require(totalMints < maxMints, "Mint is over");	
		if (publicMintOpen) {
			require((whiteListClaimed[msg.sender] ? 1 : 0) + whiteListClaimedCount[msg.sender] + mintCount <= maxMintsPerWalletPublic, "Address has already claimed max amount of boxes");
		} else {
			require((whiteListClaimed[msg.sender] ? 1 : 0) + whiteListClaimedCount[msg.sender] + mintCount <= maxMintCount, "Address has already claimed max amount of boxes");
			bytes32 leaf = keccak256(abi.encode(msg.sender, maxMintCount));
			require(MerkleProofUpgradeable.verify(_merkleProof, participationMerkleRoot, leaf), "invalid proof");
		}
		
		for (uint i = 0; i < mintCount; i++) {
			uint256 tokenId = _tokenIdCounter.current();
			_tokenIdCounter.increment();
			_safeMint(msg.sender, tokenId);
			
			emit NewBox(
				tokenId,
				msg.sender
			);
		}
		
		whiteListClaimedCount[msg.sender] += mintCount;
		totalMints += int(mintCount);
    }
	
    function withdraw(address _currency, address _to, uint256 _amount) external onlyOwner  {
        IERC20Upgradeable(_currency).safeTransfer(_to, _amount);
    }
	
	function _baseURI() internal view override virtual returns (string memory) {
		return "https://api.elseverse.io/nft/mystery-box/";
	}
	
    function version() external pure returns (uint256) {
        return 101; // 1.0.1
    }

}