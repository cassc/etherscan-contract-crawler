// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../utils/ERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ILOOMI {
  function spendLoomi(address user, uint256 amount) external;
  function getUserBalance(address user) external view returns (uint256);
}

interface ISTAKING {
  function registerDeposit(address owner, address contractAddress, uint256 tokenId) external;
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ReptileArmoury is Context, ERC721Enumerable, VRFConsumerBase, Ownable, ReentrancyGuard  {
    using SafeMath for uint256;
    using Strings for uint256;

    // currentSupply
    uint256 private currentSupply;

    // Provenance hash
    string public PROVENANCE_HASH;

    // Base URI
    string private _armsBaseURI;

    // Starting Index
    uint256 public startingIndex;

    // Max number of NFTs
    uint256 public constant MAX_SUPPLY = 20000;
    uint256 public constant BASE_RATE_TOKENS = 3;
    uint256 public _basePrice;
    uint256 public _incrementRate;

    bool public saleIsActive;
    bool public metadataFinalised;
    bool public startingIndexSet;

    // Royalty info
    address public royaltyAddress;
    uint256 public ROYALTY_SIZE = 750;
    uint256 public ROYALTY_DENOMINATOR = 10000;
    mapping(uint256 => address) private _royaltyReceivers;

    // Loomi contract
    ILOOMI public LOOMI;
    ISTAKING public STAKING;

    // Stores the number of minted tokens by user
    mapping(address => uint256) public _mintedByAddress;

    bytes32 internal keyHash;
    uint256 internal fee;

    event TokensMinted(
      address indexed mintedBy,
      uint256 indexed tokensNumber
    );

    event startingIndexFinalized(
      uint256 indexed startingIndex
    );

    event baseUriUpdated(
      string oldBaseUri,
      string newBaseUri
    );

    constructor(address _royaltyAddress, address _loomi, address _staking, string memory _baseURI)
    ERC721("Reptile Armoury", "ARMS")
    VRFConsumerBase(
      0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
      0x514910771AF9Ca656af840dff83E8264EcF986CA // LINK Token
    )
    {
      royaltyAddress = _royaltyAddress;

      LOOMI = ILOOMI(_loomi);
      STAKING = ISTAKING(_staking);

      keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
      fee = 2 * 10 ** 18;

      _armsBaseURI = _baseURI;
    }

    function armsPurchase(uint256 tokensToMint, bool autoStake) public nonReentrant {
      if (_msgSender() != owner()) require(saleIsActive, "The mint has not started yet");

      require(tokensToMint > 0, "Min mint is 1 token");
      require(tokensToMint <= 50, "You can mint max 50 tokens per transaction");
      require(totalSupply().add(tokensToMint) <= MAX_SUPPLY, "Mint more tokens than allowed");

      if (_msgSender() != owner()) {
        uint256 batchPrice = getTokenPrice(_msgSender(), tokensToMint);

        LOOMI.spendLoomi(_msgSender(), batchPrice);
        _mintedByAddress[_msgSender()] += tokensToMint;
      }

      address to = autoStake ? address(STAKING) : _msgSender();

      for(uint256 i = 0; i < tokensToMint; i++) {
        uint256 tokenId = totalSupply();
        _safeMint(to, tokenId);
        if (autoStake) STAKING.registerDeposit(_msgSender(), address(this), tokenId);
      }

      emit TokensMinted(_msgSender(), tokensToMint);
    }

    function getTokenPrice(address user, uint256 amount) public view returns (uint256) {
      uint256 minted = _mintedByAddress[user];
      if (minted.add(amount) <= BASE_RATE_TOKENS) return amount.mul(_basePrice);

      uint256 totalPrice;
      for (uint256 i; i < amount; i++) {
        minted = minted.add(1);
        if(minted <= BASE_RATE_TOKENS) {
          totalPrice = totalPrice.add(_basePrice);
          continue;
        }
        totalPrice += _basePrice.add((minted.sub(BASE_RATE_TOKENS).mul(_incrementRate)));
      }
      return totalPrice;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      uint256 amount = _salePrice.mul(ROYALTY_SIZE).div(ROYALTY_DENOMINATOR);
      address royaltyReceiver = _royaltyReceivers[_tokenId] != address(0) ? _royaltyReceivers[_tokenId] : royaltyAddress;
      return (royaltyReceiver, amount);
    }

    function addRoyaltyReceiverForTokenId(address receiver, uint256 tokenId) public onlyOwner {
      _royaltyReceivers[tokenId] = receiver;
    }

    function updateSaleStatus(bool status) public onlyOwner {
      saleIsActive = status;
    }

    function updateBasePrice(uint256 _newPrice) public onlyOwner {
      require(!saleIsActive, "Pause sale before price update");
      _basePrice = _newPrice;
    }

    function updateIncrementRate(uint256 _newRate) public onlyOwner {
      require(!saleIsActive, "Pause sale before price update");
      _incrementRate = _newRate;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
      require(bytes(PROVENANCE_HASH).length == 0, "Provenance hash has already been set");
      PROVENANCE_HASH = provenanceHash;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
      require(!metadataFinalised, "Metadata already finalised");

      string memory currentURI = _armsBaseURI;
      _armsBaseURI = newBaseURI;
      emit baseUriUpdated(currentURI, newBaseURI);
    }

    function finalizeStartingIndex() public onlyOwner returns (bytes32 requestId) {
      require(!startingIndexSet, 'startingIndex already set');

      require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
      return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        startingIndex = (randomness % MAX_SUPPLY);
        startingIndexSet = true;
        emit startingIndexFinalized(startingIndex);
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      return string(abi.encodePacked(_armsBaseURI, tokenId.toString()));
    }

    function finalizeMetadata() public onlyOwner {
      require(!metadataFinalised, "Metadata already finalised");
      metadataFinalised = true;
    }

    function withdraw() external onlyOwner {
      uint256 balance = address(this).balance;
      payable(owner()).transfer(balance);
    }
}