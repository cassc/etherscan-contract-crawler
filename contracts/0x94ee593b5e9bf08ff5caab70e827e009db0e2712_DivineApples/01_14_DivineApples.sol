/**
 * @title  Divine Apples Smart Contract
 * @author Diveristy - twitter.com/DiversityETH
 *
 * 8888b.  88 Yb    dP 88 88b 88 888888      db    88b 88    db    88""Yb  dP""b8 88  88 Yb  dP
 *  8I  Yb 88  Yb  dP  88 88Yb88 88__       dPYb   88Yb88   dPYb   88__dP dP   `" 88  88  YbdP
 *  8I  dY 88   YbdP   88 88 Y88 88""      dP__Yb  88 Y88  dP__Yb  88"Yb  Yb      888888   8P
 * 8888Y"  88    YP    88 88  Y8 888888   dP""""Yb 88  Y8 dP""""Yb 88  Yb  YboodP 88  88  dP
 *
 * Why is this a ERC721 contract? Because I made it in a few hours and was not thinking straight.
 * ----- yes it should of been ERC1155, but this works and im not wasting all this testing now :(
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/IDivineAnarchyToken.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DivineApples is Ownable, ERC721A, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;

	uint256 public constant MAX_ASCENSION_APPLES_SACRAFICE = 1500;
	uint256 public constant MAX_ASCENSION_APPLE_AD         = 1500;
	uint256 public constant MAX_ASCENSION_APPLES           = MAX_ASCENSION_APPLE_AD + MAX_ASCENSION_APPLES_SACRAFICE;
	uint256 public constant MAX_BAD_APPLES                 = 1500;
	uint256 public constant MAX_STATE_AIRDROP              = 500;
	uint256 public constant MAX_AIRDROP_AMOUNT             = 3000;
	uint256 public constant MAX_SUPPLY                     = MAX_ASCENSION_APPLES + MAX_BAD_APPLES;

	uint256 private _airdropState    = 0;     // 0 is ascension, 1 is bad apple
	uint256 private _airdropAmount   = 0;     // Track the amount airdropped in the current state
	uint256 private _airdropTotal    = 0;
	uint256 private _ascensionApples = 0;
	uint256 private _badApples       = 0;
	bool    private _canAirdrop      = true;
	string  private _baseExtension   = ".json";
    string  private _useBaseURI;
	address private _daContract;

	mapping(address => uint256[]) public ascendedMap;
	mapping(address => uint256[]) public burnedMap;

	constructor(address daContract, string memory initUri) ERC721A("Divine Apples", "DAA") {
		_daContract = daContract;
		_useBaseURI = initUri;
	}

	function isAscensionApple(uint256 id) public view virtual returns(bool) {
		require(id < 4500 && id >= 0, "ID is not in token range");

		// Account for 0 index
		id += 1;

		// First airdrop
		if(id <= 500) {
			return true;
		}

		// Second airdrop
		if(id > 1000 && id <= 1500) {
			return true;
		}

		// Third airdrop
		if(id > 2000 && id <= 2500) {
			return true;
		}

		// Bad apple sacrafice to create ascension apples
		if(id > 3000) {
			return true;
		}

		return false;
	}

	function airdropAscensionApples(uint256 amount, address account) external onlyOwner {
		require(amount > 0, "Cannot airdrop less than 1 apple");
		require(_ascensionApples + amount <= MAX_ASCENSION_APPLE_AD, "Ascension apple overflow");
		require(_airdropTotal + amount <= MAX_AIRDROP_AMOUNT, "No more apples can be dropped");
		require(_airdropState == 0, "Wrong airdrop state");
		require(_airdropAmount + amount <= MAX_STATE_AIRDROP, "Exceeded MAX_STATE_AIRDROP");

		_safeMint(account, amount);

		_ascensionApples += amount;
		_airdropAmount   += amount;
		_airdropTotal    += amount;

		if(_airdropAmount == MAX_STATE_AIRDROP) {
			_airdropState  = 1;
			_airdropAmount = 0;
		}
	}

	function airdropBadApples(uint256 amount, address account) external onlyOwner {
		require(amount > 0, "Cannot airdrop less than 1 apple");
		require(_badApples + amount <= MAX_BAD_APPLES, "Bad apple overflow");
		require(_airdropTotal + amount <= MAX_AIRDROP_AMOUNT, "No more apples can be dropped");
		require(_airdropState == 1, "Wrong airdrop state");
		require(_airdropAmount + amount <= MAX_STATE_AIRDROP, "Airdrop state will exceed 500");

		_safeMint(account, amount);

		_badApples     += amount;
		_airdropAmount += amount;
		_airdropTotal    += amount;

		if(_airdropAmount == MAX_STATE_AIRDROP) {
			_airdropState  = 0;
			_airdropAmount = 0;
		}
	}

	function consumeAscensionApple(uint256 daId, uint256 appleId) public nonReentrant {
		require(_airdropTotal >= 3000, "Airdropping apples still");
        require(_exists(appleId), "Nonexistent token");
		require(isAscensionApple(appleId), "Incorrect apple");
		require(IDivineAnarchyToken(_daContract).ownerOf(daId) == msg.sender, "Not the owner of given DA");
		require(ownerOf(appleId) == msg.sender, "Not the owner of given Apple");
		require(daId > 10, "Can't ascend a monarch...");

		_burn(appleId);

		ascendedMap[msg.sender].push(daId);
	}

	function consumeBadApple(uint256 daId, uint256 appleId) public nonReentrant {
		require(_airdropTotal >= 3000, "Airdropping apples still");
        require(_exists(appleId), "Nonexistent token");
		require(!isAscensionApple(appleId), "Incorrect apple");
		require(IDivineAnarchyToken(_daContract).ownerOf(daId) == msg.sender, "Not the owner of given DA");
		require(ownerOf(appleId) == msg.sender, "Not the owner of given Apple");
		require(daId > 10, "Attempting to burn a monarch!?");

		IDivineAnarchyToken(_daContract).burn(msg.sender, daId);
		_burn(appleId);
		_safeMint(msg.sender, 1);

		burnedMap[msg.sender].push(daId);
	}

    function walletOfOwner(address account) public view returns (uint256[] memory) {
		uint256 holdingAmount  = balanceOf(account);
		uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

		uint256[] memory result = new uint256[](holdingAmount);

        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];

                if (ownership.burned) {
                    continue;
                }

                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }

                if (currOwnershipAddr == account) {
					result[tokenIdsIdx] = i;
                    tokenIdsIdx++;
                }
            }
        }

		return result;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

		string memory appleType = isAscensionApple(tokenId) ? "Ascension" : "Bad";

        return bytes(_useBaseURI).length != 0 ? string(
			abi.encodePacked(
				_useBaseURI,
				appleType,
				_baseExtension
			)
		) : "";
    }

	function isAirdropFinished() public view returns(bool) {
		return _airdropTotal == MAX_AIRDROP_AMOUNT;
	}

	function getAscendedNfts(address account) public view returns(uint256[] memory) {
		return ascendedMap[account];
	}

	function getBurnedNfts(address account) public view returns(uint256[] memory) {
		return burnedMap[account];
	}

	function setCanAirdrop(bool state) external onlyOwner {
		_canAirdrop = state;
	}

	function setDaContract(address contractAddr) external onlyOwner {
		_daContract = contractAddr;
	}

    function setBaseURI(string memory uri) public onlyOwner {
        _useBaseURI = uri;
    }
}