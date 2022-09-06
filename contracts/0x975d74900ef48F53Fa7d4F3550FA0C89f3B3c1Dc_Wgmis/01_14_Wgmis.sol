//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IRandomNumberConsumer.sol";
import "./interfaces/IERC2981.sol";

interface IWgmisMerkleTreeWhitelist {
    function isValidMerkleProof(bytes32[] calldata _merkleProof, address _minter, uint96 _amount) external view returns (bool);
}

contract Wgmis is ERC721, Ownable {
    using Strings for uint256;

    // Controlled variables
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public price;
    bool public isRandomnessRequested;
    bytes32 public randomNumberRequestId;
    uint256 public vrfResult;
    uint256 public foundationMinted;
    mapping(address => bool) public merkleWhitelistClaimed;
    mapping(address => uint256) public merkleWhitelistEarlyAccessMintCount;

    // Static
    uint16 public earlyAccessAllowance = 10;
    uint96 public foundationAllowance = 150;

    // Config variables
    string public preRevealURI;
    string public baseURI;
    uint256 public supplyLimit;
    uint256 public mintingStartTimeUnix;
    uint256 public singleOrderLimit;
    address public vrfProvider;
    address[] public payoutAddresses;
    uint16[] public payoutAddressBasisPoints;
    address public royaltyReceiver;
    uint16 public royaltyBasisPoints;
    // A merkle-proof-based whitelist for initial batch of whitelisted addresses
    // All whitelisted addresses must be defined at time of WgmisMerkleTreeWhitelist deployment
    IWgmisMerkleTreeWhitelist merkleProofWhitelist;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _preRevealURI,
        string memory _baseURI,
        uint256 _supplyLimit,
        uint256 _mintingStartTimeUnix,
        uint256 _singleOrderLimit,
        address _vrfProvider,
        address[] memory _payoutAddresses,
        uint16[] memory _payoutAddressBasisPoints,
        address _merkleProofWhitelist
    ) ERC721(_tokenName, _tokenSymbol) {
        preRevealURI = _preRevealURI;
        baseURI = _baseURI;
        supplyLimit = _supplyLimit;
        mintingStartTimeUnix = _mintingStartTimeUnix;
        singleOrderLimit = _singleOrderLimit;
        vrfProvider = _vrfProvider;
        uint256 totalBasisPoints;
        for(uint256 i = 0; i < _payoutAddresses.length; i++) {
            require((_payoutAddressBasisPoints[i] > 0) && (_payoutAddressBasisPoints[i] <= 10000)); // "BP_NOT_BETWEEN_0_AND_10000"
            totalBasisPoints += _payoutAddressBasisPoints[i];
        }
        require(totalBasisPoints == 10000); // "BP_MUST_ADD_TO_10000"
        payoutAddresses = _payoutAddresses;
        payoutAddressBasisPoints = _payoutAddressBasisPoints;
        merkleProofWhitelist = IWgmisMerkleTreeWhitelist(_merkleProofWhitelist);
        foundationMinted = 0;
        price = 0.069 ether;
    }

    // We signify support for ERC2981, ERC721 & ERC721Metadata
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mint(address _recipient, uint96 _quantity) external payable {
        require(isRandomnessRequested == false, "MINTING_OVER");
        require(_quantity > 0, "NO_ZERO_QUANTITY");
        require(block.timestamp >= mintingStartTimeUnix, "MINTING_PERIOD_NOT_STARTED");
        require(_quantity <= singleOrderLimit, "EXCEEDS_SINGLE_ORDER_LIMIT");
        require((_tokenIds.current() + _quantity) <= supplyLimit, "EXCEEDS_MAX_SUPPLY");
        require((msg.value) == (price * _quantity), "INCORRECT_ETH_VALUE");

        _handleMint(_recipient, _quantity);
    }

    function mintFoundation(address _recipient, uint96 _quantity) external onlyOwner {
        require(isRandomnessRequested == false); // "MINTING_OVER"
        require(_quantity > 0, "NO_ZERO_QUANTITY");
        require((foundationMinted + _quantity) <= foundationAllowance, "FOUNDATION_MINT_EXCEEDS_ALLOWANCE");
        require((_tokenIds.current() + _quantity) <= supplyLimit, "EXCEEDS_MAX_SUPPLY");
        foundationMinted += _quantity;
        _handleMint(_recipient, _quantity);
    }

    function mintMerkleWhitelist(bytes32[] calldata _merkleProof, uint96 _quantity) external {
        require(isRandomnessRequested == false, "MINTING_OVER");
        require(block.timestamp >= (mintingStartTimeUnix - 24 hours), "EARLY_ACCESS_NOT_STARTED");
        require((_tokenIds.current() + _quantity) <= supplyLimit, "EXCEEDS_MAX_SUPPLY");
        require(!merkleWhitelistClaimed[msg.sender], 'MERKLE_CLAIM_ALREADY_MADE');
        require(merkleProofWhitelist.isValidMerkleProof(_merkleProof, msg.sender, _quantity), 'INVALID_MERKLE_PROOF');

        merkleWhitelistClaimed[msg.sender] = true;

        _handleMint(msg.sender, _quantity);
    }

    function mintMerkleWhitelistEarlyAccess(bytes32[] calldata _merkleProof, uint96 _merkleProofAmount, uint96 _mintAmount) external payable {
        require(merkleProofWhitelist.isValidMerkleProof(_merkleProof, msg.sender, _merkleProofAmount), 'INVALID_MERKLE_PROOF');
        require(isRandomnessRequested == false, "MINTING_OVER");
        require(block.timestamp >= (mintingStartTimeUnix - 24 hours), "EARLY_ACCESS_NOT_STARTED");
        require((_tokenIds.current() + _mintAmount) <= supplyLimit, "EXCEEDS_MAX_SUPPLY");
        require((msg.value) == (price * _mintAmount), "INCORRECT_ETH_VALUE");

        merkleWhitelistEarlyAccessMintCount[msg.sender] += _mintAmount;

        require(merkleWhitelistEarlyAccessMintCount[msg.sender] <= earlyAccessAllowance, "EXCEEDS_EARLY_ACCESS_ALLOWANCE");

        _handleMint(msg.sender, _mintAmount);
    }

    function _handleMint(address _recipient, uint96 _quantity) internal {
        for(uint96 i = 0; i < _quantity; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(_recipient, newTokenId);
        }
    }

    function initiateRandomDistribution() external {
        require(_tokenIds.current() == supplyLimit, "MINTING_ONGOING");
        require(isRandomnessRequested == false, "RANDOMNESS_REQ_NOT_INITIATED");
        IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(vrfProvider);
        randomNumberRequestId = randomNumberConsumer.getRandomNumber();
        isRandomnessRequested = true;
    }

    function forceInitiateRandomDistribution() external onlyOwner {
        // Forces ending of minting period by skipping check for all tokens being minted
        uint256 supply = _tokenIds.current();
        require(supply > 0);
        require(isRandomnessRequested == false);
        IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(vrfProvider);
        randomNumberRequestId = randomNumberConsumer.getRandomNumber();
        isRandomnessRequested = true;
    }

    function commitRandomDistribution() external {
        require(isRandomnessRequested == true, "RANDOMNESS_REQ_NOT_INITIATED");
        IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(vrfProvider);
        uint256 result = randomNumberConsumer.readFulfilledRandomness(randomNumberRequestId);
        require(result > 0, "RANDOMNESS_NOT_FULFILLED");
        vrfResult = result;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NONEXISTENT_TOKEN");

        if (vrfResult == 0) {
            return preRevealURI;
        }

        string memory tokenURI_ = metadataOf(tokenId);
        
        return string(abi.encodePacked(baseURI, tokenURI_, ".json"));
    }

    function metadataOf(uint256 _tokenId) public view returns (string memory) {
        require((_tokenId > 0) && (_tokenId <= totalSupply()), "INVALID_TOKEN_ID");

        uint256 seed_ = vrfResult;
        if (seed_ == 0) {
            return "";
        }

        uint256[] memory randomIds = new uint256[](supplyLimit);
        for (uint256 i = 0; i < supplyLimit; i++) {
            randomIds[i] = 8888 - i;
        }

        for (uint256 i = 0; i < supplyLimit - 1; i++) {
            uint256 j = i + (uint256(keccak256(abi.encode(seed_, i))) % (supplyLimit - i));
            (randomIds[i], randomIds[j]) = (randomIds[j], randomIds[i]);
        }

        return randomIds[_tokenId - 1].toString();
    }

    function totalSupply() public view returns(uint256) {
        return _tokenIds.current();
    }

    // Fee distribution logic below

    modifier onlyFeeRecipientOrOwner() {
        bool isFeeRecipient = false;
        for(uint256 i = 0; i < payoutAddresses.length; i++) {
            if(payoutAddresses[i] == msg.sender) {
                isFeeRecipient = true;
            }
        }
        require((isFeeRecipient == true) || (owner() == _msgSender()));
        _;
    }

    function getPercentageOf(
        uint256 _amount,
        uint16 _basisPoints
    ) internal pure returns (uint256 value) {
        value = (_amount * _basisPoints) / 10000;
    }

    function distributeFees() public onlyFeeRecipientOrOwner {
        uint256 feeCutsTotal;
        uint256 balance = address(this).balance;
        for(uint256 i = 0; i < payoutAddresses.length; i++) {
            uint256 feeCut;
            if(i < (payoutAddresses.length - 1)) {
                feeCut = getPercentageOf(balance, payoutAddressBasisPoints[i]);
            } else {
                feeCut = (balance - feeCutsTotal);
            }
            feeCutsTotal += feeCut;
            (bool feeCutDeliverySuccess, ) = payoutAddresses[i].call{value: feeCut}("");
            require(feeCutDeliverySuccess, "FEE_CUT_NO_DELIVERY");
        }
    }
    
    function updateFeePayoutScheme(
      address[] memory _payoutAddresses,
      uint16[] memory _payoutAddressBasisPoints
    ) public onlyOwner {
        payoutAddresses = _payoutAddresses;
        payoutAddressBasisPoints = _payoutAddressBasisPoints;
    }

    function updateMerkleProofWhitelist(address _merkleProofWhitelist) external onlyOwner {
        require(isRandomnessRequested == false);
        merkleProofWhitelist = IWgmisMerkleTreeWhitelist(_merkleProofWhitelist);
    }

    // ERC2981 logic

    function updateRoyaltyInfo(address _royaltyReceiver, uint16 _royaltyBasisPoints) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    // Takes a _tokenId and _price (in wei) and returns the royalty receiver's address and how much of a royalty the royalty receiver is owed
    function royaltyInfo(uint256 _tokenId, uint256 _price) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = royaltyReceiver;
        royaltyAmount = getPercentageOf(_price, royaltyBasisPoints);
    }

}