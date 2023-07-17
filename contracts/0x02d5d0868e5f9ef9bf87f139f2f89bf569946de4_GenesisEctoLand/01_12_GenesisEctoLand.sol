// SPDX-License-Identifier: MIT


// Ectoverse Genese Land

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error SalePaused();
error NotEnoughETH();
error NotOnClaimList();
error LandAlreadyMinted();
error ExceedsMaxLand();
error DoesNotExist();
error SoulAlreadyClaimed();
error SoulNotYours();
error OnDenyList();
error Max4Only();
error ClaimPeriodOver();
error ClaimPeriodMaxReached();

contract GenesisEctoLand is ERC721A, Ownable {

	uint256 public constant MAX_SUPPLY = 15e3;
	uint256 public constant MAX_CLAIM_SUPPLY = 10e3;

	// price
	uint256 public price = 0.088 ether;

	// Mint Supply tracker
	uint256 public mintSupply = 0;

	// Merkle Root
	bytes32 public merkleRoot;

	// E Gnosis
	address eWallet;

	// Utils
	string _baseTokenURI;

	// Sale State
	bool public salePaused;

	// Claim Peroid
	uint256 immutable public claimEndTimestamp;

	// Lost Souls address
	address collectionAddress;

	// Souls Claimed
	mapping (uint256 => bool) public soulClaimed;

	constructor(
		string memory _baseURIIn,
		string memory _name,
		string memory _symbol,
		bool _salePaused,
		address _eWallet,
		address _collectionAddress,
		bytes32 _merkleRoot

		) ERC721A(_name,_symbol) {
			_baseTokenURI = _baseURIIn;
			eWallet = _eWallet;
			salePaused = _salePaused;
			claimEndTimestamp = block.timestamp + 2 days;
			collectionAddress = _collectionAddress;
			merkleRoot = _merkleRoot;
	}

	/**
	 * @notice Allows mint of Land
	 * @param quantity amount of Land to Mint
	 * 
	 */
	function mint(uint256 quantity) external payable {
		if(salePaused) revert SalePaused();
		if(quantity > 4) revert Max4Only();
		if(quantity * price > msg.value) revert NotEnoughETH();
		if(totalSupply() + quantity >= MAX_SUPPLY) revert ExceedsMaxLand();
		if(block.timestamp < claimEndTimestamp && mintSupply + quantity >= MAX_SUPPLY - MAX_CLAIM_SUPPLY) revert ClaimPeriodMaxReached();
		//increment Mint SUPPLY
		mintSupply = mintSupply + quantity;
		_safeMint(msg.sender,quantity);
	}


	/**
	 * @notice Claim Land, if address is in Claim List Merkle Tree
	 * @param _merkleProof merkle proof of address and soularray
	 * @param soulArray Array of Lost Soul tokenIds
	 */
	function claimAll(bytes32[] memory _merkleProof, uint256[] memory soulArray) public {
		// 48 hours after contract is live, cut off claim
		if(block.timestamp > claimEndTimestamp) revert ClaimPeriodOver();
		// check if you still own that soul
		for(uint256 i;i<soulArray.length;i++){
			if(IERC721(collectionAddress).ownerOf(soulArray[i]) != msg.sender) revert SoulNotYours();
		}
		// Revert if any 1 Soul has been claimed before
		for(uint256 i; i < soulArray.length; i++){
            if(!soulClaimed[soulArray[i]]){
                soulClaimed[soulArray[i]] = true;
            }
            else{
            	revert SoulAlreadyClaimed();
            }
        }
		// Check if your address + tokenid combo is on denylist
		if(MerkleProof.verify(_merkleProof,merkleRoot,keccak256(abi.encodePacked(msg.sender,soulArray))) == true) revert OnDenyList();
		// ERC721A Mint
		_safeMint(msg.sender,soulArray.length);


	}
	/**
	 * @notice Claim One Land
	 * @param _merkleProof merkle proof of address and soul
	 * @param soul Lost Soul tokenId
	 * 
	 */
	function claimOne(bytes32[] calldata _merkleProof, uint256 soul) public {
		// 48 hours after contract is live, cut off claim
		if(block.timestamp > claimEndTimestamp) revert ClaimPeriodOver();
		// Check if your address + tokenid combo is on denylist
		if(MerkleProof.verify(_merkleProof,merkleRoot,keccak256(abi.encodePacked(msg.sender,soul))) == true) revert OnDenyList();
		// check if you still own that soul
		if(IERC721(collectionAddress).ownerOf(soul) != msg.sender) revert SoulNotYours();
		// Revert if any 1 Soul has been claimed before
        if(!soulClaimed[soul]){
        	soulClaimed[soul] = true;
        }
        else{
          	revert SoulAlreadyClaimed();
        }
		_safeMint(msg.sender,1);
	}

	// Check Soul's claim status
	function checkClaimStatus(uint256 soul) public view returns (bool) {
		if(soulClaimed[soul]){
			return true;
			}
		else{
			return false;
		}
	}

    function setPause(bool val) public onlyOwner {
        salePaused = val;
    }

    function setPrice(uint256 _updatedPrice) public onlyOwner {
        price = _updatedPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    	merkleRoot = _merkleRoot;
    }

    function retrieveFunds() public payable onlyOwner {
    	payable(eWallet).transfer(address(this).balance);
    }

    /// @dev Returns the tokenIds of the address. O(totalSupply) in complexity.
	function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
        uint256[] memory a = new uint256[](balanceOf(owner)); 
        uint256 end = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for (uint256 i; i < end; i++) {
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                a[tokenIdsIdx++] = i;
            }
        }
        return a;    
    }
}
}