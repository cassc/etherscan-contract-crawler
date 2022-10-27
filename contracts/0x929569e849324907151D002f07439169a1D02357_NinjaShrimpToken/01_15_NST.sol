// SPDX-License-Identifier: MIT

// Developers: www.agentscovetech.com

pragma solidity ^0.8.11;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBreedCert.sol";
import "./Breedable.sol";
import "./Usable.sol";

contract NinjaShrimpToken is ERC20, Ownable, IBreedCert, Breedable, Usable {
  using ECDSA for bytes32;

  uint256[5] public tokenRates;
  mapping (uint256 => uint256) public rarities;
	mapping(address => mapping (uint256 => uint256)) public rewards;
	mapping(address => mapping (uint256 => uint256)) public lastUpdate;

	address public signingKey = address(0);
	bytes32 public DOMAIN_SEPARATOR;

	uint256 constant public INITIAL_ISSUANCE = 75 ether;

	bytes32 public constant SIGNUP_FOR_REWARDS_TYPEHASH = keccak256("Rewards(address wallet,uint256 tokenId,uint256 rarityId)");

  uint256 public MAX_SUPPLY = 2000000000 ether;
  uint256 public TOTAL_MINTED = 0 ether;

  struct SignForm {
    uint256 tokenID;
    uint256 rarityID;
    address signer;
    address userWallet;
    address contractAddress;
    uint256 chainId;
  }

	constructor(address _ninjaShrimps, address _newOwner, address _signingKey) ERC20("NST", "NST") {
		signingKey = _signingKey;
		DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("RegisterForRewards")),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
      )
		);
    tokenRates[1] = 20 ether;
    tokenRates[2] = 40 ether;
    tokenRates[3] = 70 ether;
    tokenRates[4] = 120 ether;
		nftContract = IBreedable(_ninjaShrimps);
		_transferOwnership(_newOwner);
    _mint(_newOwner, 75000000 ether);
    TOTAL_MINTED += 75000000 ether;
	}

  function setTokenRates(
    uint256[5] calldata _newRates
  ) public onlyOwner {
    for(uint256 i = 1; i<_newRates.length; i++) {
      if(_newRates[i] >= 1 ether) {
        tokenRates[i] = _newRates[i];
      }
    }
  }

  function setTokenRate(
    uint256 _index, uint256 _newRate
  ) public onlyOwner {
    require(_index != 0, "Index can't start at zero");
    require(_index < tokenRates.length, "Index is too high");
    require(_newRate >= 1 ether, "Rate is too low");
    tokenRates[_index] = _newRate;
  }

  function getTokenRates(uint256 tokenId) public view returns(uint256) {
    return tokenRates[rarities[tokenId]];
  }
  
  function setSigningAddress(address newSigningKey) public onlyOwner {
    signingKey = newSigningKey;
  }

  modifier isAllowed() {
    require (address(breedManager) != address(0), "Breed Manager Not Set");
    require(
      _msgSender() == address(nftContract) || 
      _msgSender() == address(breedManager), 
      "Caller not authorized"
    );
    _;
  }

	function updateReward(address _from, address _to, uint256 _tokenId) external isAllowed {
    _updateRewards(_from, _to, _tokenId);
	}

  function _updateRewards(address _from, address _to, uint256 _tokenId) internal {
    uint256 tokenRate = getTokenRates(_tokenId);
    uint256 time = block.timestamp;
    uint256 timerFrom = lastUpdate[_from][_tokenId];
    uint256 generation = getTokenGeneration(_tokenId);

    if (timerFrom > 0) {
      rewards[_from][_tokenId] += tokenRate * generation * (time - timerFrom) / 86400;
      _mintRewards(_from, _tokenId);
    }

    lastUpdate[_from][_tokenId] = time;

    if (_to != address(0)) { 
      lastUpdate[_to][_tokenId] = time; 
    }
  }

  event RewardClaimed(address indexed user, uint256 reward);

  function claimRewards(uint256 _nftId) external {
    require(address(nftContract) != address(0), 'NFT contract not set');
    require(nftContract.ownerOf(_nftId) == _msgSender(), 'You are not the nft owner');
    _updateRewards(_msgSender(), address(0), _nftId);
    _mintRewards(_msgSender(), _nftId);
	}

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a <= b ? a : b;
  }

	function _mintRewards(address _from, uint256 _tokenId) internal {
		uint256 reward = rewards[_from][_tokenId];
		if (reward > 0) {
      require(MAX_SUPPLY > TOTAL_MINTED, "Exceeds max supply");
			rewards[_from][_tokenId] = 0;
      uint256 amounToMint = min(MAX_SUPPLY - TOTAL_MINTED, reward);
      _mint(_from, amounToMint);
      TOTAL_MINTED += amounToMint;
      emit RewardClaimed(_from, amounToMint);
		}
	}

	function burn(address _from, uint256 _amount) external isAllowed {
		_burn(_from, _amount);
	}

  function getTokenGeneration(uint256 _nft) internal view returns (uint256) {
    uint256 generation = breedManager.getTokenCert(_nft).generation;
    return generation > 1? generation : 1;
  }

	function getTotalClaimable(address _from, uint256 _tokenId) external view returns(uint256) {
    uint256 tokenRate = getTokenRates(_tokenId);
		uint256 time = block.timestamp;
    uint256 generation = getTokenGeneration(_tokenId);
    if (nftContract.ownerOf(_tokenId) == _from) {
		  uint256 pending = tokenRate * generation * (time - lastUpdate[_from][_tokenId]) / 86400;
		  return rewards[_from][_tokenId] + pending;
    }
    return rewards[_from][_tokenId];
	}

  modifier withValidSignature(bytes calldata signature, uint256 _tokenId, uint256 _rarity) {
    require(signingKey != address(0), "rewards not enabled");

    bytes32 digest = keccak256(
        abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(
              abi.encode(
                SIGNUP_FOR_REWARDS_TYPEHASH, 
                _msgSender(),
                _tokenId,
                _rarity
              )
            )
        )
    );

    address recoveredAddress = digest.recover(signature);
    require(recoveredAddress == signingKey, "Invalid Signature");
    _;
  }

  function registerForRewards(bytes calldata signature, uint256 _tokenId, uint256 _rarity) public withValidSignature(signature, _tokenId, _rarity) {
    require(_rarity < tokenRates.length, "Invalid rarity");
    require(rarities[_tokenId] == 0, 'Token cannot be registered for rewards more than once');
    require(nftContract.ownerOf(_tokenId) == _msgSender(), 'You are not the nft owner');
    rarities[_tokenId] = _rarity;
    rewards[_msgSender()][_tokenId] = rewards[_msgSender()][_tokenId] + INITIAL_ISSUANCE;
		lastUpdate[_msgSender()][_tokenId] = block.timestamp;
  }

  function adminRarityRegistration(uint256 _tokenId, uint256 _rarity, address _tokenOwner) public onlyOwner {
    require(_rarity < tokenRates.length, "Invalid rarity");
    rarities[_tokenId] = _rarity;
    rewards[_tokenOwner][_tokenId] = rewards[_tokenOwner][_tokenId] + INITIAL_ISSUANCE;
    lastUpdate[_tokenOwner][_tokenId] = block.timestamp;
  }

  function bulkAdminRarityRegistration(uint256[] calldata _tokenIds, uint256[] calldata  _rarities, address[] calldata _tokenOwners) public onlyOwner {
    require(_tokenIds.length == _rarities.length, "Arrays must much length");
    require(_rarities.length == _tokenOwners.length, "Arrays must much length");
    for(uint256 i = 0; i < _tokenIds.length; i++) {
      require(_rarities[i] < tokenRates.length, "Invalid rarity");
      rarities[_tokenIds[i]] = _rarities[i];
      rewards[_tokenOwners[i]][_tokenIds[i]] = rewards[_tokenOwners[i]][_tokenIds[i]] + INITIAL_ISSUANCE;
      lastUpdate[_tokenOwners[i]][_tokenIds[i]] = block.timestamp;
    }
  }

  function changeMaxSupply(uint256 _newMaxSupply) public onlyOwner {
    require(_newMaxSupply > TOTAL_MINTED, "The new max supply must be greater than the total tokens minted");
    MAX_SUPPLY = _newMaxSupply;
  }
  
}