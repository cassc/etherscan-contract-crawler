// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// @author: olive

///////////////////////////////////////////////////////////////////////////////////////
//       __  _______  __  ____  ___           __        __        __                 //
//      /  |/  / __ )/ / / /  |/  /___ ______/ /_____  / /_____  / /___ _________    //
//     / /|_/ / __  / /_/ / /|_/ / __ `/ ___/ //_/ _ \/ __/ __ \/ / __ `/ ___/ _ \   //
//    / /  / / /_/ / __  / /  / / /_/ / /  / ,< /  __/ /_/ /_/ / / /_/ / /__/  __/   //
//   /_/  /_/_____/_/ /_/_/  /_/\__,_/_/  /_/|_|\___/\__/ .___/_/\__,_/\___/\___/    //
//                                                     /_/                           //
///////////////////////////////////////////////////////////////////////////////////////

contract MBHMarketplace is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event ItemListed(
    address indexed owner,
    address indexed nft,
    uint256 tokenId,
    uint8   payMethod,
    address payToken,
    uint256 price,
    uint256 deadline
  );
  event ItemSold(
    address indexed seller,
    address indexed buyer,
    address indexed nft,
    uint256 tokenId,
    address payToken,
    uint256 price
  );
  event ItemUpdated(
    address indexed owner,
    address indexed nft,
    uint256 tokenId,
    address payToken,
    uint256 newPrice
  );
  event ItemCanceled(
    address indexed owner,
    address indexed nft,
    uint256 tokenId
  );

  struct Listing {
    uint8   payMethod;
    address payToken;
    uint256 price;
    uint256 deadline;
  }

  address private signerAddress;

  mapping(address => mapping(uint256 => mapping(address => Listing))) public listings;

  uint16 public platformFee;
  address payable public feeReceipient;

  modifier notListed(
    address _nftAddress,
    uint256 _tokenId,
    address _owner
  ) {
    Listing memory listing = listings[_nftAddress][_tokenId][_owner];
    require(listing.price == 0, "MBHMarketplace: Already listed");
    _;
  }

  modifier isListed(
    address _nftAddress,
    uint256 _tokenId,
    address _owner
  ) {
    Listing memory listing = listings[_nftAddress][_tokenId][_owner];
    require(listing.price > 0, "MBHMarketplace: Not listed item");
    _;
  }

  modifier validListing(
    address _nftAddress,
    uint256 _tokenId,
    address _owner
    ) {
    Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

    require(IERC721(_nftAddress).ownerOf(_tokenId) == _owner, "MBHMarketplace: Not owning item");

    require(block.timestamp < listedItem.deadline, "MBHMarketplace: Item not buyable");
    _;
  }

  constructor(address _signer, address payable _feeRecipient, uint16 _platformFee) {
    signerAddress = _signer;
    platformFee = _platformFee;
    feeReceipient = _feeRecipient;
  }

  function listItem(
    address _nftAddress,
    uint256 _tokenId,
    uint8   _payMethod,
    address _payToken,
    uint256 _price,
    uint256 _deadline
  ) external notListed(_nftAddress, _tokenId, _msgSender()) {
    IERC721 nft = IERC721(_nftAddress);
    require(nft.ownerOf(_tokenId) == _msgSender(), "MBHMarketplace: Not owning item");
    require(
        nft.isApprovedForAll(_msgSender(), address(this)),
        "MBHMarketplace: Item not approved"
    );

    listings[_nftAddress][_tokenId][_msgSender()] = Listing(
      _payMethod,
      _payToken,
      _price,
      _deadline
    );
    emit ItemListed(
      _msgSender(),
      _nftAddress,
      _tokenId,
      _payMethod,
      _payToken,
      _price,
      _deadline
    );
  }

  function updateListing(
    address _nftAddress,
    uint256 _tokenId,
    uint8   _payMethod,
    address _payToken,
    uint256 _newPrice
  ) external nonReentrant isListed(_nftAddress, _tokenId, _msgSender()) {
    Listing storage listedItem = listings[_nftAddress][_tokenId][_msgSender()];

    require(IERC721(_nftAddress).ownerOf(_tokenId) == _msgSender(), "MBHMarketplace: Not owning item");
    
    listedItem.payMethod = _payMethod;
    listedItem.payToken = _payToken;
    listedItem.price = _newPrice;
    emit ItemUpdated(
      _msgSender(),
      _nftAddress,
      _tokenId,
      _payToken,
      _newPrice
    );
  }

  function cancelListing(address _nftAddress, uint256 _tokenId)
    external
    nonReentrant
    isListed(_nftAddress, _tokenId, _msgSender())
  {
    _cancelListing(_nftAddress, _tokenId, _msgSender());
  }

  function _cancelListing(
    address _nftAddress,
    uint256 _tokenId,
    address _owner
  ) private {
    require(IERC721(_nftAddress).ownerOf(_tokenId) == _owner, "MBHMarketplace: Not owning item");

    delete (listings[_nftAddress][_tokenId][_owner]);
    emit ItemCanceled(_owner, _nftAddress, _tokenId);
  }

  function buyItem(
    address _nftAddress,
    uint256 _tokenId,
    address _payToken,
    address _owner
  ) external payable
    nonReentrant
    validListing(_nftAddress, _tokenId, _owner)
  {
    Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];
    require(listedItem.payToken == _payToken, "MBHMarketplace: Invalid pay token");
    require(listedItem.price > 0, "MBHMarketplace: Not listed item");

    uint256 feeAmount = listedItem.price.mul(platformFee).div(1e3);

    if(listedItem.payMethod == 0) {
      require(msg.value >= listedItem.price, "MBHMarketplace: Value below price");
      payable(feeReceipient).transfer(feeAmount);
      payable(_owner).transfer(listedItem.price.sub(feeAmount));
    } else {
      IERC20(listedItem.payToken).safeTransferFrom(
        _msgSender(),
        feeReceipient,
        feeAmount
      );
      IERC20(listedItem.payToken).safeTransferFrom(
        _msgSender(),
        _owner,
        listedItem.price.sub(feeAmount)
      );
    }

    IERC721(_nftAddress).safeTransferFrom(_owner, _msgSender(), _tokenId);

    emit ItemSold(
      _owner,
      _msgSender(),
      _nftAddress,
      _tokenId,
      listedItem.payToken,
      listedItem.price
    );
    delete (listings[_nftAddress][_tokenId][_owner]);
  }

  function acceptOffer(
    address _nftAddress,
    uint256 _tokenId,
    address _payToken,
    uint256 _price,
    address _offerer,
    bytes memory _signature
  ) external
    nonReentrant
  {
    require(IERC721(_nftAddress).ownerOf(_tokenId) == _msgSender(), "MBHMarketplace: Not owning item");

    address signerOwner = signatureWallet(_nftAddress, _tokenId, _payToken, _price, _offerer, _msgSender(), _signature);
    require(signerOwner == signerAddress, "MBHMarketplace: Not authorized");

    uint256 feeAmount = _price.mul(platformFee).div(1e3);
    IERC20(_payToken).safeTransferFrom(_offerer, feeReceipient, feeAmount);
    IERC20(_payToken).safeTransferFrom(_offerer, _msgSender(), _price.sub(feeAmount));

    IERC721(_nftAddress).safeTransferFrom(_msgSender(), _offerer, _tokenId);

    emit ItemSold(
      _msgSender(),
      _offerer,
      _nftAddress,
      _tokenId,
      _payToken,
      _price
    );
    
    delete (listings[_nftAddress][_tokenId][_msgSender()]);
  }

  function signatureWallet(
    address _nftAddress,
    uint256 _tokenId,
    address _payToken,
    uint256 _price,
    address _offerer,
    address _owner,
    bytes memory _signature
  ) public pure returns (address){

    return ECDSA.recover(keccak256(abi.encode(_nftAddress, _tokenId, _payToken, _price, _offerer, _owner)), _signature);

  }

  function updatePlatformFee(uint16 _platformFee) external onlyOwner {
    platformFee = _platformFee;
  }

  function updateSignerAddress(address _signer) public onlyOwner {
    signerAddress = _signer;
  }
    
  function updatePlatformFeeRecipient(address payable _platformFeeRecipient) external onlyOwner
  {
    feeReceipient = _platformFeeRecipient;
  }
}