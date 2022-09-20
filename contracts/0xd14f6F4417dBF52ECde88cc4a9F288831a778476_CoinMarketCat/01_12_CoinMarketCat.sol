// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface ERC20Burnable is IERC20 {
  function burn(address account, uint256 amount) external;
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract CoinMarketCat is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;


  address public proxyRegistryAddress;
  address public treasury;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => uint256) public mintedAmount;
  mapping(uint256 => string) private catNames;
  mapping(string => bool) private nameReserved;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  uint256 public phase = 0; // 0: sale not started, 1: company reserve, 2: whitelist, 3: recess, 4: public sale, 5: finished
  uint256 public cost;
  uint256 public renameCost;
  uint256 public maxSupply;
  uint256 public phaseSupply;
  uint256 public maxMintAmountPerWallet;
  uint256 public treasuryRatio;
  
  bool public revealed = false;

  ERC20Burnable public Tears;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerWallet,
    string memory _hiddenMetadataUri,
    address _proxyRegistryAddress
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    phaseSupply = 10000;
    setMaxMintAmountPerWallet(_maxMintAmountPerWallet);
    setHiddenMetadataUri(_hiddenMetadataUri);
    proxyRegistryAddress = _proxyRegistryAddress;
    renameCost = 1000000000000000000;
    treasuryRatio = 150;
    treasury = 0xF432c6cc746A17434BA5BB55894dBAf9FF4CD18a;
  }

  function decimals() public view virtual returns (uint8) {
    return 0;
  }

  modifier mintCompliance(address _receiver, uint256 _mintAmount) {
    require(_mintAmount > 0 && mintedAmount[_receiver] + _mintAmount <= maxMintAmountPerWallet, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(totalSupply() + _mintAmount <= phaseSupply, "Phase supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  function reserveForCompany(uint256 _mintAmount) public onlyOwner {
    _safeMint(_msgSender(), _mintAmount);
  }

  function _singleMint(address _receiver) internal {
    require(mintedAmount[_receiver] < maxMintAmountPerWallet, "Minting limit exceeded!");
    _safeMint(_receiver, 1);
    mintedAmount[_receiver] += 1;
    if (totalSupply() == maxSupply) {
      phase = 5;
    } else if (totalSupply() == phaseSupply) {
      phase = 3;
    }
  }

  function _multipleMint(address _receiver, uint256 _mintAmount) internal {
    for (uint i = 0; i < _mintAmount; i++) {
      _safeMint(_receiver, 1);
    }
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_msgSender(), _mintAmount) mintPriceCompliance(_mintAmount) {
    require(phase == 2, "Whitelist minting is not enabled.");
    require(!whitelistClaimed[_msgSender()], "Current address has already claimed whitelist minting.");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[_msgSender()] = true;
    _singleMint(_msgSender());
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_msgSender(), _mintAmount) mintPriceCompliance(_mintAmount) {
    require(phase == 4, "Public minting is not enabled.");
    for (uint i = 0; i < _mintAmount; i++) {
      _singleMint(_msgSender());
    }
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_msgSender(), _mintAmount) onlyOwner {
    _multipleMint(_receiver, _mintAmount);
  }

  function changeName(uint256 tokenId, string memory newName) public virtual {
    require(Tears.balanceOf(_msgSender()) >= renameCost, "Insufficient $Tears!");
    Tears.burn(_msgSender(), renameCost);
		address owner = ownerOf(tokenId);

		require(_msgSender() == owner, "ERC721: caller is not the owner");
		require(validateName(newName) == true, "Not a valid new name");
		require(sha256(bytes(newName)) != sha256(bytes(catNames[tokenId])), "New name is same as the current one");
		require(isNameReserved(newName) == false, "Name already reserved");

		// If already named, dereserve old name
		if (bytes(catNames[tokenId]).length > 0) {
			toggleReserveName(catNames[tokenId], false);
		}
		toggleReserveName(newName, true);
		catNames[tokenId] = newName;
	}

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownershipOf(currentTokenId);

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function catName(uint256 index) public view returns (string memory) {
		return catNames[index];
	}

  function transferFrom(address from, address to, uint256 tokenId) public virtual override {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
    super.safeTransferFrom(from, to, tokenId, _data);
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPhase(uint _phase) public onlyOwner {
    phase = _phase;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setTears(address _tears) public onlyOwner {
    Tears = ERC20Burnable(_tears);
  }

  function setRenameCost(uint256 _renameCost) public onlyOwner {
    renameCost = _renameCost;
  }

  function setTreasury(address _treasury) public onlyOwner {
    treasury = _treasury;
  }

  function setTreasuryRatio(uint256 _treasuryRatio) public onlyOwner {
    treasuryRatio = _treasuryRatio;
  }

  function setPhaseSupply(uint256 _phaseSupply) public onlyOwner {
    phaseSupply = _phaseSupply;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function isNameReserved(string memory nameString) public view returns (bool) {
		return nameReserved[toLower(nameString)];
	}

  function toggleReserveName(string memory str, bool isReserve) internal {
		nameReserved[toLower(str)] = isReserve;
	}

  function validateName(string memory str) public pure returns (bool){
		bytes memory b = bytes(str);
		if(b.length < 1) return false;
		if(b.length > 25) return false; // Cannot be longer than 25 characters
		if(b[0] == 0x20) return false; // Leading space
		if (b[b.length - 1] == 0x20) return false; // Trailing space

		bytes1 lastChar = b[0];

		for(uint i; i<b.length; i++){
			bytes1 char = b[i];

			if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

			if(
				!(char >= 0x30 && char <= 0x39) && //9-0
				!(char >= 0x41 && char <= 0x5A) && //A-Z
				!(char >= 0x61 && char <= 0x7A) && //a-z
				!(char == 0x20) //space
			)
				return false;

			lastChar = char;
		}

		return true;
	}

  function toLower(string memory str) public pure returns (string memory){
		bytes memory bStr = bytes(str);
		bytes memory bLower = new bytes(bStr.length);
		for (uint i = 0; i < bStr.length; i++) {
			// Uppercase character
			if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
				bLower[i] = bytes1(uint8(bStr[i]) + 32);
			} else {
				bLower[i] = bStr[i];
			}
		}
		return string(bLower);
	}

    /**
    * Override isApprovedForAll to whitelist user"s OpenSea proxy accounts to enable gas-less listings.
    */
  function isApprovedForAll(address owner, address operator)
      override
      public
      view
      returns (bool)
  {
      // Whitelist OpenSea proxy contract for easy trading.
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(owner)) == operator) {
          return true;
      }

      return super.isApprovedForAll(owner, operator);
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool treasuryCall, ) = payable(treasury).call{value: address(this).balance * treasuryRatio / 1000}("");
    require(treasuryCall, "Treasury withdraw failed");
    (bool ownerCall, ) = payable(owner()).call{value: address(this).balance}("");
    require(ownerCall, "Owner withdraw failed");
    
  }
}