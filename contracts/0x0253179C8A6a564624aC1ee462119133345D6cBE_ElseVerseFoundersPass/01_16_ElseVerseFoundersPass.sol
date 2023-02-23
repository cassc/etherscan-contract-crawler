// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";



/// @custom:security-contact [email protected]
contract ElseVerseFoundersPass is Initializable, ERC721Upgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable  {

    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
	
    struct Stage {
		uint256 id;
        uint256 startDate;
        uint256 price;
        bytes32 merkleRoot;
        bool isPublic;
		uint256 publicMaxMintsPerWallet;
		address currency;
		uint256 mintPerStage;
    }

	uint256 public totalMints;	
	uint256 public reservedMints;	
	uint256 public maxMints;
	
	mapping(address => uint256) public whiteListClaimedCount;
	mapping(uint256 => Stage) public stages;
    
	address public beneficiaryAddress;
	bool public mintClosed;
	string tokenUri;
	
    event NewFoundersPass(
        uint256 indexed id,
        address indexed owner
    );	

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("ElseVerseFoundersPass", "EVFP");
        __ERC721Burnable_init();
        __Ownable_init();
		maxMints = 3333; 
		reservedMints = 150;
        beneficiaryAddress = msg.sender;
		tokenUri = "https://api.elseverse.io/nft/founders-pass/";
    }
	
	function setMaxMints(uint256 _maxMints, uint256 _reserved) external onlyOwner {
        maxMints = _maxMints;
		reservedMints = _reserved;
	}
	
	function setTokenUri(string memory _uri) external onlyOwner {
        tokenUri = _uri;
	}
	
	function setCloseMint(bool _closeMint) external onlyOwner {
        mintClosed = _closeMint;
	}

    function changeBeneficiary(
        address _beneficiaryAddress
    ) external onlyOwner {
        beneficiaryAddress = _beneficiaryAddress;
    }
	
	function bulkSafeMint(address[] memory tos) external onlyOwner {
		require(totalMints + tos.length <= maxMints, "Mint is over");	
		require(tos.length <= reservedMints, "Reserved limit exceeded");	
		for (uint i = 0; i < tos.length; i++) {
			uint256 tokenId = _tokenIdCounter.current();
			_tokenIdCounter.increment();
			_safeMint(tos[i], tokenId);
			
			emit NewFoundersPass(
				tokenId,
				tos[i]
			);
		}
		totalMints += tos.length;
		reservedMints -= tos.length;
		
		if (totalMints + reservedMints == maxMints) {
			mintClosed = true;
		}
	}

    function safeBuy(bytes32[] calldata _merkleProof, uint256 mintCount, uint256 maxMintCountStep1, uint256 maxMintCountStep2) public payable {
		require(!mintClosed, "Mint is closed");	
		require(totalMints + mintCount + reservedMints <= maxMints, "Mint is over");	
		
		Stage memory currStage = _getCurrentStage();
		require(block.timestamp > currStage.startDate && currStage.startDate > 0, "Mint not started");
		require(currStage.mintPerStage >= totalMints + mintCount, "All NFTs are sold at this step");
		
		if (currStage.isPublic) {	
			require(whiteListClaimedCount[msg.sender] + mintCount <= currStage.publicMaxMintsPerWallet, "Address has already claimed max amount of founders pass");			
		} else {
			if (currStage.id == 0) {
				require(whiteListClaimedCount[msg.sender] + mintCount <= maxMintCountStep1, "Address has already claimed max amount of founders pass");			
			} else {
				require(whiteListClaimedCount[msg.sender] + mintCount <= maxMintCountStep1 + maxMintCountStep2, "Address has already claimed max amount of founders pass");			
			}
			bytes32 leaf = keccak256(abi.encode(msg.sender, maxMintCountStep1, maxMintCountStep2));
			require(MerkleProofUpgradeable.verify(_merkleProof, currStage.merkleRoot, leaf), "invalid proof");	
		}
		
        transfer(beneficiaryAddress, currStage.price * mintCount);
		
		
		for (uint i = 0; i < mintCount; i++) {
			uint256 tokenId = _tokenIdCounter.current();
			_tokenIdCounter.increment();
			_safeMint(msg.sender, tokenId);
			
			emit NewFoundersPass(
				tokenId,
				msg.sender
			);
		}
		
		whiteListClaimedCount[msg.sender] += mintCount;
		totalMints += mintCount;
		
		
		if (totalMints + reservedMints == maxMints) {
			mintClosed = true;
		}
    }
	
    function addOrUpdateStage(uint256 id, uint256 startDate, uint256 price, bytes32 merkleRoot, bool isPublic, uint256 publicMaxMintsPerWallet, uint256 mintPerStage) external onlyOwner  {
        stages[id] = Stage(
			id,
			startDate,
			price,
			merkleRoot,
			isPublic,
			publicMaxMintsPerWallet,
			0x0000000000000000000000000000000000000000 ,
			mintPerStage
		);
    }

    function transfer(
        address _to,
        uint256 _price
    ) internal {
		require(msg.value >= _price, "Insufficient balance.");
		
        bool sent = payable(_to).send(_price);
        require(sent, "Failed to send Ether");
    }
	
	function _getCurrentStage() internal view returns (Stage memory) {
		Stage memory currStage = stages[0];
		uint256 maxNotHappenedDate = currStage.startDate;
		
		for (uint256 i = 0; i < 10; i++) {
			if (stages[i].startDate > maxNotHappenedDate && stages[i].startDate < block.timestamp) {
				currStage = stages[i];
				maxNotHappenedDate = currStage.startDate;
			}
		}
		
		return currStage;
	}
	
    function removeStage(uint256 id) external onlyOwner  {
        delete stages[id];
    }
	
	function _baseURI() internal view override virtual returns (string memory) {
		return tokenUri;
	} 
	
	function baseTokenURI() public view returns (string memory) {
		return tokenUri;
	}

    function totalSupply() public view virtual returns (uint256) {
        return totalMints;
    }

	function ownerOfAny(address _user) external view returns (bool) {
		bool result = false;

		for (uint256 i = 0; i <= _tokenIdCounter.current(); i++) {
			if (_ownerOf(i) == _user) {
				result = true;
				break;
			}
		}

		return result;
	}
	
    function version() external pure returns (uint256) {
        return 100; // 1.0.0
    }

}