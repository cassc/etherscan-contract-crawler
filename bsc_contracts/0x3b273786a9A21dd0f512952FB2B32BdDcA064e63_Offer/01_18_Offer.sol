// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../../interfaces/IOffer.sol";
import "../../interfaces/ICurrency.sol";
import "../../shared/WhitelistUpgradeable.sol";

/**
  @dev Only use for PadiNFT721
 */
contract Offer is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IOffer,
    WhitelistUpgradeable,
    ReentrancyGuardUpgradeable
{
    enum OfferStatus {
        CREATED,
        ACCEPTED,
        CANCELED
    }

    struct Offer {
        address from;
        address contractERC20;
        uint256 price;
        OfferStatus status;
    }

    uint256 public constant FEE_PER_PRICE = 10;
    address private _currencyAddress;
    address private _treasuryAddress;
    mapping(address => mapping(uint256 => Offer[])) public tokenOffer; // contractERC721 => tokenId => offer[],

    mapping(address => mapping(uint256 => mapping(address => uint)))
        public totalOffersFromUsers;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    event CreateOffer(
        uint256 offerId,
        address from,
        address to,
        uint256 tokenId,
        uint256 price,
        address contractERC20,
        address contractERC721
    );
    event AcceptOffer(
        uint256 offerId,
        address from,
        address to,
        uint256 tokenId,
        uint256 price,
        address contractERC20,
        address contractERC721
    );
    event CancelOffer(
        uint256 offerId,
        address from,
        address to,
        uint256 tokenId,
        uint256 price,
        address contractERC20,
        address contractERC721
    );

    fallback() external payable {}
    
    /**
      @dev have to approve amount of erc20 to owner
      @notice can not use permit because some token now doesn't use permit such as USDT
     */
    function makeOffer(
        address _contractERC721,
        uint256 _tokenId,
        address _contractERC20,
        uint _price
    ) external payable override nonReentrant {
        require (_is721(_contractERC721), "Offer: not erc721 type");
        uint256 priceWithFee = (_price * (100 + FEE_PER_PRICE)) / 100;
        address _owner = IERC721Upgradeable(_contractERC721).ownerOf(_tokenId);
        require(_msgSender() != _owner, "Offer: you are owner of this nft");
        require(
            ICurrency(_currencyAddress).currencyState(_contractERC20) == true,
            "Offer: can not use this token address"
        );
        if (_contractERC20 == address(0)) {
            require(msg.value >= priceWithFee, "Offer: not enough WBNB");
        }
        _transferERC20(_contractERC20, _msgSender(), address(this), priceWithFee);

        Offer memory newOffer = Offer(
            _msgSender(),
            _contractERC20,
            _price,
            OfferStatus.CREATED
        );

        // Update offer
        tokenOffer[_contractERC721][_tokenId].push(newOffer);
        totalOffersFromUsers[_contractERC721][_tokenId][_msgSender()] += 1;

        emit CreateOffer(
            tokenOffer[_contractERC721][_tokenId].length - 1,
            _msgSender(),
            _owner,
            _tokenId,
            _price,
            _contractERC20,
            _contractERC721
        );
    }

    function acceptOffer(
        address _contractERC721,
        uint256 _tokenId,
        uint256 _offerId
    ) external override nonReentrant {
        require(
            IERC721Upgradeable(_contractERC721).getApproved(_tokenId) ==
                address(this),
            "Offer: this address is not approved"
        );
        address _owner = IERC721Upgradeable(_contractERC721).ownerOf(_tokenId);
        require(
            _msgSender() == _owner,
            "Offer: you are not owner of this tokenId"
        );
        Offer storage myOffer = tokenOffer[_contractERC721][_tokenId][_offerId];
        require(
            myOffer.status == OfferStatus.CREATED,
            "Offer: this offer is not in create state"
        );
        myOffer.status = OfferStatus.ACCEPTED;

        uint256 priceWithFee = (myOffer.price * (100 + FEE_PER_PRICE)) / 100;
        if (myOffer.contractERC20 != address(0)) {
            IERC20Upgradeable(myOffer.contractERC20).approve(address(this), priceWithFee);
        }

        _transferERC20(myOffer.contractERC20, address(this), _msgSender(), myOffer.price);
        _transferERC20(myOffer.contractERC20, address(this), _treasuryAddress, priceWithFee - myOffer.price);

        IERC721Upgradeable(_contractERC721).safeTransferFrom(
            _msgSender(),
            myOffer.from,
            _tokenId,
            "0x"
        );
        emit AcceptOffer(
            _offerId,
            _msgSender(),
            myOffer.from,
            _tokenId,
            myOffer.price,
            myOffer.contractERC20,
            _contractERC721
        );
    }

    function cancelOffer(
        address _contractERC721,
        uint256 _tokenId,
        uint256 _offerId
    ) external override nonReentrant {
        Offer storage offer = tokenOffer[_contractERC721][_tokenId][_offerId];
        require(
            offer.status == OfferStatus.CREATED,
            "Offer: this offer is not in create state"
        );
        uint offerLength = tokenOffer[_contractERC721][_tokenId].length;
        require(_offerId <= offerLength, "Offer: Invalid offer id");
        address _owner = IERC721Upgradeable(_contractERC721).ownerOf(_tokenId);
        require(
            _msgSender() == _owner || offer.from == _msgSender(),
            "Offer: you are not owner of this tokenId or this offer"
        );

        uint256 priceWithFee = (offer.price * (100 + FEE_PER_PRICE)) / 100;
        if (offer.contractERC20 != address(0)) {
            IERC20Upgradeable(offer.contractERC20).approve(address(this), priceWithFee);
        }

        _transferERC20(offer.contractERC20, address(this), offer.from, priceWithFee); // Not charge fee if close offer

        offer.status = OfferStatus.CANCELED;
        emit CancelOffer(
            _offerId,
            _msgSender(),
            offer.from,
            _tokenId,
            offer.price,
            offer.contractERC20,
            _contractERC721
        );
    }

    function setCurrencyAddress(address _address) external validateAdmin {
        _currencyAddress = _address;
    }

    function setTreasuryAddress(address _address) external validateAdmin {
        _treasuryAddress = _address;
    }

    function getTotalOffers(
        address _contractERC721,
        uint256 _tokenId
    ) public view returns (uint256) {
        return tokenOffer[_contractERC721][_tokenId].length;
    }

    function initialize(address _whitelistAddress) public initializer {
        __Ownable_init();
        __WhitelistUpgradeable_init(_whitelistAddress);
        _treasuryAddress = _msgSender();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override validateAdmin {}

    function _transferERC20(address _contractERC20, address _from, address _to, uint256 _amount) private {
        bool success;
        if (_contractERC20 == address(0)) {
            if (_to == address(this)) {
                success = true; // This mean transfer WBNB direct to contract
            }
            else {
                (success, ) = payable(_to).call{value: _amount}("");
            }
        }   
        else {
            success = IERC20Upgradeable(_contractERC20).transferFrom( _from, _to, _amount);

        }
        require(success, "Offer: Transfer ERC20 failed!");
    }

    function _is721(address _contractNFT) private view returns (bool) {
        return
            IERC165Upgradeable(_contractNFT).supportsInterface(
                type(IERC721Upgradeable).interfaceId
            );
    }
}