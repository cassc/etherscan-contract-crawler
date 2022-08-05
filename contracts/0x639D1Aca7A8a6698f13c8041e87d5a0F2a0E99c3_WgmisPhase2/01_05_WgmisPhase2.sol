//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IWgmisMerkleTreeWhitelist {
    function isValidMerkleProof(bytes32[] calldata _merkleProof, address _minter, uint96 _amount) external view returns (bool);
}

interface IWgmis {
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract WgmisPhase2 is Ownable {
    using Strings for uint256;

    // Controlled variables
    uint16 public prevTokenId;
    uint256 public price;
    bool public isRandomnessRequested;
    bytes32 public randomNumberRequestId;
    uint256 public vrfResult;
    uint256 public foundationMinted = 0;
    uint256 public merkleWhitelistVersion = 0;
    mapping(address => mapping(uint256 => bool)) public merkleWhitelistToWhitelistVersionToClaimed;
    mapping(address => uint256) public merkleWhitelistEarlyAccessMintCount;

    // Config variables
    uint256 public supplyLimit;
    uint256 public mintingStartTimeUnix;
    uint256 public singleOrderLimit;
    address[] public payoutAddresses;
    uint16[] public payoutAddressBasisPoints;
    address public tokenPoolHolder;
    IWgmis public wgmis;
    uint16 public earlyAccessAllowance;
    // A merkle-proof-based whitelist for initial batch of whitelisted addresses
    // All whitelisted addresses must be defined at time of WgmisMerkleTreeWhitelist deployment
    IWgmisMerkleTreeWhitelist merkleProofWhitelist;

    constructor(
        uint256 _supplyLimit,
        uint256 _mintingStartTimeUnix,
        uint256 _singleOrderLimit,
        address[] memory _payoutAddresses,
        uint16[] memory _payoutAddressBasisPoints,
        address _merkleProofWhitelist,
        address _tokenPoolHolder,
        uint16 _startTokenId,
        address _wgmis
    ) {
        supplyLimit = _supplyLimit;
        mintingStartTimeUnix = _mintingStartTimeUnix;
        singleOrderLimit = _singleOrderLimit;
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
        price = 0.01 ether;
        merkleWhitelistVersion = 0;
        tokenPoolHolder = _tokenPoolHolder;
        prevTokenId = _startTokenId;
        wgmis = IWgmis(_wgmis);
        earlyAccessAllowance = 10;
    }

    function mint(address _recipient, uint16 _quantity) external payable {
        require(isRandomnessRequested == false, "MINTING_OVER");
        require(_quantity > 0, "NO_ZERO_QUANTITY");
        require(block.timestamp >= mintingStartTimeUnix, "MINTING_PERIOD_NOT_STARTED");
        require(_quantity <= singleOrderLimit, "EXCEEDS_SINGLE_ORDER_LIMIT");
        require((prevTokenId + _quantity) <= supplyLimit, "EXCEEDS_MAX_SUPPLY");
        require((msg.value) == (price * _quantity), "INCORRECT_ETH_VALUE");

        handleSale(_recipient, _quantity);
    }

    function mintMerkleWhitelist(bytes32[] calldata _merkleProof, uint16 _quantity) external {
        require(isRandomnessRequested == false, "MINTING_OVER");
        require(block.timestamp >= (mintingStartTimeUnix - 1 hours), "EARLY_ACCESS_NOT_STARTED");
        require((prevTokenId + _quantity) <= supplyLimit, "EXCEEDS_MAX_SUPPLY");
        require(!merkleWhitelistToWhitelistVersionToClaimed[msg.sender][merkleWhitelistVersion], 'MERKLE_CLAIM_ALREADY_MADE');
        require(merkleProofWhitelist.isValidMerkleProof(_merkleProof, msg.sender, _quantity), 'INVALID_MERKLE_PROOF');

        merkleWhitelistToWhitelistVersionToClaimed[msg.sender][merkleWhitelistVersion] = true;

        handleSale(msg.sender, _quantity);
    }

    function mintMerkleWhitelistEarlyAccess(bytes32[] calldata _merkleProof, uint96 _merkleProofAmount, uint16 _mintAmount) external payable {
        require(merkleProofWhitelist.isValidMerkleProof(_merkleProof, msg.sender, _merkleProofAmount), 'INVALID_MERKLE_PROOF');
        require(isRandomnessRequested == false, "MINTING_OVER");
        require(block.timestamp >= (mintingStartTimeUnix - 1 hours), "EARLY_ACCESS_NOT_STARTED");
        require((prevTokenId + _mintAmount) <= supplyLimit, "EXCEEDS_MAX_SUPPLY");
        require((msg.value) == (price * _mintAmount), "INCORRECT_ETH_VALUE");

        merkleWhitelistEarlyAccessMintCount[msg.sender] += _mintAmount;

        require(merkleWhitelistEarlyAccessMintCount[msg.sender] <= earlyAccessAllowance, "EXCEEDS_EARLY_ACCESS_ALLOWANCE");

        handleSale(msg.sender, _mintAmount);
    }

    function handleSale(address _recipient, uint16 _quantity) internal {
      for(uint16 i = 1; i <= _quantity; i++) {
        wgmis.transferFrom(tokenPoolHolder, _recipient, prevTokenId + i);
      }
      prevTokenId += _quantity;
    }

    function totalSupply() public view returns(uint256) {
        return prevTokenId;
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

    function setPrice(
      uint256 _price
    ) public onlyOwner {
      price = _price;
    }

    function setPrevTokenId(
      uint16 _prevTokenId
    ) public onlyOwner {
      prevTokenId = _prevTokenId;
    }

    function setStartTime(
      uint256 _mintingStartTimeUnix
    ) public onlyOwner {
      mintingStartTimeUnix = _mintingStartTimeUnix;
    }

    function setSingleOrderLimit(
      uint256 _singleOrderLimit
    ) public onlyOwner {
      singleOrderLimit = _singleOrderLimit;
    }

    function updateMerkleProofWhitelist(address _merkleProofWhitelist) external onlyOwner {
        require(isRandomnessRequested == false);
        merkleProofWhitelist = IWgmisMerkleTreeWhitelist(_merkleProofWhitelist);
        merkleWhitelistVersion++;
    }

}