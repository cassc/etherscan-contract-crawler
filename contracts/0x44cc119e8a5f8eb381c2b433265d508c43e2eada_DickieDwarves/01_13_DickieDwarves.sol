// SPDX-License-Identifier: MIT


// ██████╗░██╗░█████╗░██╗░░██╗██╗███████╗  ██████╗░░██╗░░░░░░░██╗░█████╗░██████╗░██╗░░░██╗███████╗░██████╗
// ██╔══██╗██║██╔══██╗██║░██╔╝██║██╔════╝  ██╔══██╗░██║░░██╗░░██║██╔══██╗██╔══██╗██║░░░██║██╔════╝██╔════╝
// ██║░░██║██║██║░░╚═╝█████═╝░██║█████╗░░  ██║░░██║░╚██╗████╗██╔╝███████║██████╔╝╚██╗░██╔╝█████╗░░╚█████╗░
// ██║░░██║██║██║░░██╗██╔═██╗░██║██╔══╝░░  ██║░░██║░░████╔═████║░██╔══██║██╔══██╗░╚████╔╝░██╔══╝░░░╚═══██╗
// ██████╔╝██║╚█████╔╝██║░╚██╗██║███████╗  ██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░██║░░╚██╔╝░░███████╗██████╔╝
// ╚═════╝░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝╚══════╝  ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═════╝░

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract DickieDwarves is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost= 0.0069 ether;
  uint256 public maxSupply = 4444;
  uint256 public maxMintAmountPerTx = 5;
  uint256 public constant MAX_FREE = 2;
  uint256 public MAX_PER_WALLET = 10;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  mapping(address => uint) private _walletMintedCount;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 count) {
    require(count > 0 && count <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + count <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 count) {
    require(msg.value >= cost * count, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 count, bytes32[] calldata _merkleProof) public payable mintCompliance(count) mintPriceCompliance(count) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), count);
  }

  function mint(uint256 count) external payable  {
    require(!paused, 'The contract is paused!');
		require(count <= maxMintAmountPerTx,'Exceeds NFT per transaction limit');
		require(totalSupply() + count <= maxSupply,'Exceeds max supply');
    require(
            _numberMinted(msg.sender) + count <= MAX_PER_WALLET,
            "Too many for address"
        );

        uint payForCount = count;
        uint mintedSoFar = _walletMintedCount[msg.sender];
        if(mintedSoFar < MAX_FREE) {
            uint remainingFreeMints = MAX_FREE - mintedSoFar;
            if(count > remainingFreeMints) {
                payForCount = count - remainingFreeMints;
            }
            else {
                payForCount = 0;
            }
        }

		require(
			msg.value >= payForCount * cost,
			'Ether value sent is not sufficient'
		);

		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
    // require(isContract(msg.sender) == false, "Cannot mint from a contract");
    // require(!paused, 'The contract is paused!');

    // _safeMint(_msgSender(), count);
  }
  

  function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
  
  function mintForAddress(uint256 count, address _receiver) public mintCompliance(count) onlyOwner {
    _safeMint(_receiver, count);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function mintedCount(address owner) external view returns (uint) {
        return _walletMintedCount[owner];
    }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}