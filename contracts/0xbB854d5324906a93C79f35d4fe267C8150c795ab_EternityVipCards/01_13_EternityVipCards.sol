// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

import "erc721a/contracts/ERC721A.sol";

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";




contract EternityVipCards is DefaultOperatorFilterer, ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;
	using Address for address payable;
	using MerkleProof for bytes32[];
	
	bytes32 whitelistMerkleRoot;

	/**
   * @notice Whitelist Item for Address
   * how many items (amount) can be minted after mint start date
   */
	struct Whitelist {
		uint16 amount;
		uint16 totalMinted;
	}

	/**
    * @notice The status enum for the tiers
    */
	enum TierStatus {
		Active, // index 0
		Inactive
	}

	/**
    * @notice The type enum for the tiers
    */
	enum TierType {
		Private, // index 0
		Public
	}

	struct Tier {
		uint16 amount;
		uint16 totalMinted;
		uint128 price;
		uint40 mintStartDate;
		TierStatus status;
		TierType tierType;
	}

	string baseURI;
	string public baseExtension = ".json";
	uint16 public maxMintAmount = 200;
	uint16 public totalAmount = 2222;
	uint16 public currentAmount = 0;
	bool public paused = false;
	bool public revealed = true;
	string public notRevealedUri;

	/**
    * @notice current active tier
    *
    */
	uint16 public activeTierId = 0;

	/**
	* @notice all tiers
    * @dev Editing restricted to contract owner
    *
    */
	mapping(uint16 => Tier) public tiers;

 	// Mapping from owner to list of owned token IDs
	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

	// Mapping for already claimed amount
	mapping(address => uint) private _ownedAmount;

	/**
	* @dev Fired in addPriceForMint()
	*
	* @param by address that added Price of NFT
	* @param newPrice new price value
	*/
	event TierAdded(
		address by,
		uint16 tier,
		uint128 newPrice,
		uint16 amount,
		uint40 mintStartDate,
		TierStatus status,
		TierType tierType
	);

	/**
	* @dev Fired in mint(), safeMint()
	*
	* @param by address which executed the mint
	* @param to address which received the mint card
	* @param tokenId minted card id
	* @param tier tier id
	*/
	event VipCardMinted(
		address indexed by,
		address indexed to,
		uint256 tokenId,
		uint16 tier
	);

	/**
	* @dev Fired in setBaseURI()
	*
	* @param by an address which executed update
	* @param oldVal old _baseURI value
	* @param newVal new _baseURI value
	*/
	event BaseURIChanged(
		address by,
		string oldVal,
		string newVal
	);

	constructor() ERC721A("Eternity.io VIP Membership", "EVC") payable{
		
	}

	/* Opensea Operator Filter Registry */
  	// Requirement for royalties in OS
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


	function setWhitelistMintMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

	/**
	* @notice Mints card from some tier
	*
	* @param _amount of cards to be minted in range [1, maxMintAmount]
	* @param _tier tier id
	*/
	function mintCards(uint16 _amount, uint16 _tier, bytes32[] calldata merkleProof, uint16 whitelistAmount) external payable nonReentrant {
		require(!paused, "minting is paused");
		require(_amount > 0, "amount should be greater than 0");
		require(_amount <= maxMintAmount, "amount should not exceed max mint amount");
		require(_amount <= whitelistAmount, "amount should not exceed max mint amount");
		require(tiers[_tier].amount != 0, "tier is not defined");
		require(activeTierId == _tier, "tier is not active");
		require(tiers[_tier].mintStartDate <= block.timestamp, "tier minting is not started yet");
		require(tiers[_tier].totalMinted + _amount <= tiers[_tier].amount, "exceeded tier total amount");

        uint128 _cost = tiers[_tier].price * _amount;

		require(msg.value >= _cost, "not enough funds");

		// If user sent more funds than required, refund excess
		if (msg.value > _cost) {
			payable(msg.sender).sendValue(msg.value - _cost);
		}

		if (tiers[_tier].tierType == TierType.Private) {
			
			bytes32 node = keccak256(abi.encodePacked(msg.sender, whitelistAmount));
        	require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, node), 'invalid proof');

			require(_ownedAmount[msg.sender] + _amount <= whitelistAmount, "amount should not exceed max mint amount");
		}

		mint(_amount, _tier);
		
	}

	/**
	* @notice add new tier
	*
	* @param _tier the id of the tier
	* @param _price the price of the cards of the tier
	* @param _amount the amount of the cards in the tier
	* @param _mintStartDate the start date of the minting for the tier
	* @param _type the type of the tier
	* @param _status the status of the tier
	*/
	function addTierForMint(uint16 _tier, uint128 _price, uint16 _amount, uint40 _mintStartDate, TierType _type, TierStatus _status) external onlyOwner {
		require(tiers[_tier].amount == 0, "tier already defined");
		//require(currentAmount + _amount <= totalAmount, "current amount is greater than max amount");
		require(_mintStartDate > block.timestamp, "mint start date should be greater than now");
		require(_status <= TierStatus.Inactive, "Wrong tier status");
		require(_type <= TierType.Public, "Wrong tier type");

		if(activeTierId > 0) {
			require(_status == TierStatus.Inactive, "Active tier exists, please change status to inactive");
		}

		if (_tier != 1) {
			require(tiers[1].price == 0, "free tier should exist");
		} else {
			require(_price == 0, "tier with id 1 should be free tier");
		}

		tiers[_tier] = Tier({
			amount: _amount,
			totalMinted: 0,
			price: _price,
			mintStartDate: _mintStartDate,
			status: _status,
			tierType: _type
		});
		currentAmount += _amount;

		if (_status == TierStatus.Active) {
			activeTierId = _tier;
		}

		emit TierAdded(msg.sender, _tier, _price, _amount, _mintStartDate, _status, _type);
	}

	/**
	* @notice Change status of tier
	* @param _tier the id of the tier
    * @param _status the status of the tier
	*/
	function changeTierStatus(uint16 _tier, TierStatus _status) external onlyOwner {
		require(tiers[_tier].mintStartDate != 0, "tier does not exist");
		require(_status <= TierStatus.Inactive, "wrong tier status");

		if(_status == TierStatus.Active) {
			require(_tier != activeTierId, "tier is already active");

			if (activeTierId > 0) {
				uint16 remainingAmount = tiers[activeTierId].amount - tiers[activeTierId].totalMinted;

				if (remainingAmount > 0) {
					tiers[activeTierId].amount = tiers[activeTierId].totalMinted;
					tiers[_tier].amount += remainingAmount;
				}

				tiers[activeTierId].status = TierStatus.Inactive;
			}

			tiers[_tier].status = TierStatus.Active;
			activeTierId = _tier;
		} else if (_status == TierStatus.Inactive) {
			require(_tier == activeTierId, "tier is already inactive");

			tiers[activeTierId].status = TierStatus.Inactive;
			activeTierId = 0;
		}
	}

	/**
	* @notice check if user is whitelisted in tier
	* @param _tier the id of the tier
	*/
	function isWhitelisted(uint16 _tier, uint16 amount,  bytes32[] calldata merkleProof) external view returns (uint16) {
		require(tiers[_tier].mintStartDate != 0, "tier does not exist");
		bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
		if(MerkleProof.verify(merkleProof, whitelistMerkleRoot, node)){
			return amount;
		}
		return 0;
	}

	//only owner
	function reveal() external onlyOwner {
		revealed = true;
	}

	/**
	* @notice sets new max mint amount
	*
	* @param _newMaxMintAmount new max mint amount value
	*/
	function setmaxMintAmount(uint16 _newMaxMintAmount) external onlyOwner {
		maxMintAmount = _newMaxMintAmount;
	}

	/**
	* @notice sets new total amount
	*
	* @param _newTotalAmount new total amount value
	*/
	function setTotalAmount(uint16 _newTotalAmount) external onlyOwner {
		totalAmount = _newTotalAmount;
	}

	/**
	* @notice sets new not revealed uri
	*
	* @param _notRevealedURI new not revealed uri value
	*/
	function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
		notRevealedUri = _notRevealedURI;
	}

	/**
	* @notice Updates base URI used to construct ERC721Metadata.tokenURI
	*
	* @param _newBaseURI new base URI to set
	*/
	function setBaseURI(string memory _newBaseURI) external onlyOwner {
		// Fire event
		emit BaseURIChanged(msg.sender, baseURI, _newBaseURI);

		// Update base uri
		baseURI = _newBaseURI;
	}

	/**
	* @notice sets new base extension
	*
	* @param _newBaseExtension new base extension value
	*/
	function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
		baseExtension = _newBaseExtension;
	}

	/**
	* @notice pause or unpause minting
	*
	* @param _state new state value
	*/
	function pause(bool _state) external onlyOwner {
		paused = _state;
	}


	 /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
		require(index <= totalSupply(), "invalid index");
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 1;
        address currOwnershipAddr;
            for (uint256 i=1; i <= numMintedSoFar; i++) {
                currOwnershipAddr = ownerOf(i); 
                if (currOwnershipAddr != address(0) && currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
    }

	function assetsOfAccount(address _address) external view returns (uint256[] memory) {
		uint256 count = balanceOf(_address);
		uint256[] memory tokenIds = new uint256[](count);
		for (uint16 i=1; i <= count; i++) {
			tokenIds[i-1] = tokenOfOwnerByIndex(_address, i);
		}
		
		return tokenIds;
	}

	function withdraw(uint256 _amount) external onlyOwner nonReentrant {
		require(_amount <= address(this).balance, "incorrect amount");
		(bool success, ) = payable(msg.sender).call{value: _amount}("");
    	require(success, "can not withdraw");
	}

	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
		require(
			_exists(_tokenId),
			"ERC721Metadata: URI query for nonexistent token"
		);

		if (!revealed) {
			return notRevealedUri;
		}

		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0
		? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension))
		: "";
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function reserve() private view returns (uint256) {
		return address(this).balance - msg.value;
	}

	/**
	* @notice private mint function
	*
	* @param _mintAmount of cards to be minted in range [1, maxMintAmount]
	* @param _tier tier id
	*/
	function mint(uint16 _mintAmount, uint16 _tier) private {
		uint256 supply = totalSupply();
		require(supply + _mintAmount <= totalAmount, "total amount exceeded");

		if (tiers[_tier].tierType == TierType.Private) {
			_ownedAmount[msg.sender] += _mintAmount;
		}

		tiers[_tier].totalMinted += _mintAmount;
		_safeMint(msg.sender, _mintAmount);

		for (uint16 i = 1; i <= _mintAmount; i++) {
			// Emit minted event
			emit VipCardMinted(
				msg.sender,
				msg.sender,
				supply + i,
				_tier
			);	
		}
	}

	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}