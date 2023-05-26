// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ens-contracts/wrapper/NameWrapper.sol";
import "ens-contracts/ethregistrar/IBaseRegistrar.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./structs/EnsOffer.sol";
import "./structs/EnsListing.sol";
import "./structs/Signature.sol";
import "./structs/EIP712Domain.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EnsVision-Namewrapper-functions.sol";

/**
 *
 * @title EnsVision Subdomain Storefront
 * @author hodl.esf.eth
 * @dev This contract allows users sell and mint subdomains. Uses
 * EIP712 for signatures and ENS for ownership.
 * @notice Developed by EnsVision.
 */
contract EnsSubdomainStorefront is
    NamewrapperFunctions,
    Ownable,
    ReentrancyGuard
{
    IERC20 public immutable WETH;

    /**
     * @return marketCommissionPercentage is the percentage of the sale price that is taken by the market.
     * If 100 is set then 10% taken, 1000 is 1% taken.
     */
    uint256 public marketCommissionPercentage;

    /**
     * @return domainNonce is used so that the owner of a domain can bulk cancel all of their listings
     */
    mapping(bytes32 => uint256) public domainNonce;

    /**
     * @return bidderNonce bidderNonce is used to cancel all offers if bytes32 = 0,
     * or for specific subdomain if bytes32 != 0
     */
    mapping(address => mapping(bytes32 => uint256)) public bidderNonce;

    /**
     * @return sellerNonce sellerNonce is used to cancel all listing if bytes32 = 0,
     * or for specific subdomain if bytes32 != 0
     */
    mapping(address => mapping(bytes32 => uint256)) public sellerNonce;

    /**
     * @return DOMAIN_SEPARATOR is used for eip712
     */
    bytes32 public immutable DOMAIN_SEPARATOR;

    // used for seperator for eip712
    bytes32 private constant EnsOffer_TYPEHASH =
        keccak256(
            "EnsOffer(uint256 nonce,uint256 bidderNonce,uint256 priceInWei,bytes32 domain,address bidder,uint64 expires,address resolver,uint32 fuses,string label)"
        );

    bytes32 private constant EnsListing_TYPEHASH =
        keccak256(
            "EnsListing(uint256 priceInWei,uint256 nonce,uint256 domainNonce,uint256 sellerNonce,bytes32 domain,address seller,uint64 expires,uint32 fuses,string label)"
        );

    bytes32 private constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    event AcceptSubdomainOffer(
        bytes32 indexed _ens,
        address _buyer,
        address _seller,
        uint256 _value,
        string _label
    );
    event PurchaseSubdomainFromListing(
        bytes32 indexed _ens,
        address _buyer,
        address _seller,
        uint256 _value,
        string _label
    );
    event OwnerMintSubdomain(
        bytes32 indexed _ens,
        address _receiver,
        address _owner,
        string _label
    );

    event CancelSubdomainOffer(
        bytes32 indexed _subdomainHash,
        address indexed _bidder,
        uint256 _newNonce
    );
    event CancelGlobalSubdomainOffers(address indexed _bidder, uint256 _nonce);
    event CancelSubdomainListing(
        bytes32 indexed _subdomainHash,
        address indexed _seller,
        uint256 _newNonce
    );
    event CancelAllSubdomainListingsFromDomain(
        bytes32 indexed _domainHash,
        address indexed _seller,
        uint256 _newNonce
    );
    event CancelGlobalSubdomainListings(
        address indexed _seller,
        uint256 _nonce
    );

    constructor(
        NameWrapper _wrapper,
        ENS _ens,
        IERC20 _weth,
        uint256 _percent
    ) NamewrapperFunctions(_wrapper, _ens) {
        WETH = _weth;
        updateMarketCommissionPercentage(_percent);

        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: "EnsVision",
                version: "1",
                chainId: block.chainid,
                verifyingContract: address(this)
            })
        );
    }

    /**
     * @notice Update the market commission percentage
     * @dev Only the owner can update the market commission percentage
     * the percentage is divided by 1000. 1% is 10, 10% is 100
     * @notice Percentage is divided by 1000. 1% is 10, 10% is 100
     * @param _marketCommissionPercentage The new market commission percentage
     */
    function updateMarketCommissionPercentage(
        uint256 _marketCommissionPercentage
    ) public onlyOwner {
        // 1% is 10, 10% is 100
        require(_marketCommissionPercentage <= 100, "sale percent too high");
        marketCommissionPercentage = _marketCommissionPercentage;
    }

    /**
     * @notice Withdraw ETH from the contract
     * @dev Only the owner can withdraw ETH from the contract
     */
    function withdrawEth() public onlyOwner {
        payable(msg.sender).call{value: address(this).balance}("");
    }

    /**
     * @notice Withdraw ERC20 tokens from the contract
     * @dev Only the owner can withdraw ERC20 tokens from the contract. Can be
     * used for any ERC20 token.
     * @param _token The address of the ERC20 token
     */
    function withdrawTokens(address _token) public onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /**
     * @notice Owner mint function for subdomains
     * @dev Owner of domain can mint subdomains using EnsOffer structs. They don't
     * need to be signed as we're checking that the owner is submitting the tx
     * @param _offers We use offer objects for this. Expiry doesn't matter.
     */
    function ownerMintSubdomains(EnsOffer[] calldata _offers) external payable {
        for (uint256 i = 0; i < _offers.length; ) {
            // private function lower down in the contract.
            // owner of domain is checked inside this function
            ownerMintSubdomains(_offers[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Accept multiple subdomain offers
     * @dev Owner of domain can accept multiple subdomain offers from buyers
     * @param _offers The offers to be accepted
     * @param _signatures The signed offers from the buyers. v, r, s
     */
    function acceptMultipleSubdomainOffer(
        EnsOffer[] calldata _offers,
        Signature[] calldata _signatures
    ) external payable {
        uint256 price;
        uint256 fee;
        address tokenOwner;

        for (uint256 i; i < _offers.length; ) {
            bytes32 domainHash = _offers[i].domain;
            bytes32 subdomainHash = keccak256(
                abi.encodePacked(
                    domainHash,
                    keccak256(abi.encodePacked(_offers[i].label))
                )
            );

            price += _offers[i].priceInWei;
            tokenOwner = nameWrapper.ownerOf(uint256(domainHash));

            // if it is the last offer or the next offer is from a different bidder
            if (
                i == _offers.length - 1 ||
                _offers[i].bidder != _offers[i + 1].bidder
            ) {
                // only pay out if the price is greater than 0
                if (price > 0) {
                    uint256 currentFee = (price * marketCommissionPercentage) /
                        1000;
                    fee += currentFee;

                    WETH.transferFrom(
                        _offers[i].bidder,
                        tokenOwner,
                        price - currentFee
                    );

                    if (fee > 0) {
                        // store the marketplace fee in the contract
                        WETH.transferFrom(
                            _offers[i].bidder,
                            address(this),
                            fee
                        );
                        fee = 0;
                    }

                    // if we payout then reset the price
                    price = 0;
                }
            }

            _verifyOffer(
                _offers[i],
                tokenOwner,
                subdomainHash,
                _signatures[i].v,
                _signatures[i].r,
                _signatures[i].s
            );
            mintSubdomainFromOffer(_offers[i], domainHash, tokenOwner);

            // prevent replay attacks which could happen if
            // subdomain expires
            unchecked {
                ++bidderNonce[_offers[i].bidder][subdomainHash];
                ++i;
            }
        }
    }

    function mintSubdomainFromOffer(
        EnsOffer calldata _offer,
        bytes32 _domainHash,
        address _tokenOwner
    ) private {
        nameWrapper.setSubnodeRecord( // mint the subdomain
            _offer.domain, // wrapper node
            _offer.label, // label
            _offer.bidder, // owner
            _offer.resolver, // resolver
            0, // TTL
            _offer.fuses, // number of fuses
            type(uint64).max // expiry time
        );

        emit AcceptSubdomainOffer(
            _domainHash,
            _offer.bidder,
            _tokenOwner,
            _offer.priceInWei,
            _offer.label
        );
    }

    /**
     * @notice Purchase multiple subdomains from listings
     * @dev Owner of domain can list subdomains for sale using EnsListing structs.
     * They don't need to be signed as we're checking that the owner is submitting
     * the tx
     * @param _listings The listings to be created. Expiry doesn't matter.
     * @param _signatures The signed listings from the sellers. v, r, s
     */
    function purchaseMultipleSubdomainFromListing(
        EnsListing[] calldata _listings,
        Signature[] calldata _signatures,
        address _resolver
    ) external payable nonReentrant {
        uint256 price;
        uint256 totalPrice;
        address tokenOwner;

        for (uint256 i; i < _listings.length; ) {
            bytes32 domainHash = _listings[i].domain;
            bytes32 subdomainHash = keccak256(
                abi.encodePacked(
                    domainHash,
                    keccak256(abi.encodePacked(_listings[i].label))
                )
            );

            price += _listings[i].priceInWei;
            totalPrice += _listings[i].priceInWei;
            tokenOwner = nameWrapper.ownerOf(uint256(domainHash));

            _verifyListing(
                _listings[i],
                tokenOwner,
                domainHash,
                subdomainHash,
                _signatures[i].v,
                _signatures[i].r,
                _signatures[i].s
            );

            // if it is the last offer or this owner is different to previous
            if (
                i == _listings.length - 1 ||
                _listings[i].seller != _listings[i + 1].seller
            ) {
                // only pay out if the price is greater than 0
                if (price > 0) {
                    uint256 currentFee = (price * marketCommissionPercentage) /
                        1000;

                    payable(tokenOwner).transfer(price - currentFee);

                    // if we payout then reset the price
                    price = 0;
                }
            }

            mintSubdomainFromListing(
                _listings[i],
                domainHash,
                tokenOwner,
                _resolver
            );

            // prevent replay attacks which could happen if
            // subdomain expires
            unchecked {
                ++sellerNonce[_listings[i].seller][subdomainHash];
                ++i;
            }
        }

        require(msg.value == totalPrice, "incorrect funds");
    }

    function mintSubdomainFromListing(
        EnsListing calldata _listing,
        bytes32 _domainHash,
        address _tokenOwner,
        address _resolver
    ) private {
        nameWrapper.setSubnodeRecord( // mint the subdomain
            _domainHash, // wrapper node
            _listing.label, // label
            msg.sender, // owner
            _resolver, // resolver
            0, // TTL
            _listing.fuses, // number of fuses
            type(uint64).max // expiry time
        );

        emit PurchaseSubdomainFromListing(
            _domainHash,
            msg.sender,
            _tokenOwner,
            _listing.priceInWei,
            _listing.label
        );
    }

    function _verifyOffer(
        EnsOffer calldata _offerObject,
        address tokenOwner,
        bytes32 subdomainHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        require(msg.sender == tokenOwner, "not owner of domain");

        require(
            nameWrapper.ownerOf(uint256(subdomainHash)) == address(0),
            "Subdomain already exists"
        );

        // check that the bidder hasn't cancelled their bid
        require(
            bidderNonce[_offerObject.bidder][subdomainHash] ==
                _offerObject.nonce,
            "bid cancelled"
        );

        // check that the bidder hasn't cancelled all of their bids
        require(
            bidderNonce[_offerObject.bidder][bytes32(0)] ==
                _offerObject.bidderNonce,
            "global bid revoked"
        );

        require(block.timestamp < _offerObject.expires, "bid expired");

        require(
            ecrecover(getTypedEnsOfferDataHash(_offerObject), v, r, s) ==
                _offerObject.bidder,
            "Invalid signature"
        );
    }

    /**
     * @notice Accept a single subdomain offer
     * @dev Owner of token can accept a bid for subdomain. More gas efficient than
     * using the multiple offer function
     * @param _offerObject The offer object
     * @param v The v value of the signature
     * @param r The r value of the signature
     * @param s The s value of the signature
     */
    function acceptSubdomainOffer(
        EnsOffer calldata _offerObject,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        bytes32 domainHash = _offerObject.domain;
        bytes32 subdomainHash = keccak256(
            abi.encodePacked(
                domainHash,
                keccak256(abi.encodePacked(_offerObject.label))
            )
        );
        address tokenOwner = nameWrapper.ownerOf(uint256(domainHash));

        _verifyOffer(_offerObject, tokenOwner, subdomainHash, v, r, s);

        // prevent replay attacks which could happen if
        // subdomain expires
        unchecked {
            ++bidderNonce[_offerObject.bidder][subdomainHash];
        }

        nameWrapper.setSubnodeRecord( // mint the subdomain
            domainHash, // wrapper node
            _offerObject.label, // label
            _offerObject.bidder, // owner
            _offerObject.resolver, // resolver
            0, // TTL
            _offerObject.fuses, // number of fuses
            type(uint64).max // expiry time
        );

        if (_offerObject.priceInWei > 0) {
            uint256 fee = (_offerObject.priceInWei *
                marketCommissionPercentage) / 1000;

            WETH.transferFrom(
                _offerObject.bidder,
                tokenOwner,
                _offerObject.priceInWei - fee
            );

            // store the marketplace fee in the contract
            WETH.transferFrom(_offerObject.bidder, address(this), fee);
        }

        emit AcceptSubdomainOffer(
            domainHash,
            _offerObject.bidder,
            tokenOwner,
            _offerObject.priceInWei,
            _offerObject.label
        );
    }

    function _verifyListing(
        EnsListing calldata _listingObject,
        address tokenOwner,
        bytes32 domainHash,
        bytes32 subdomainHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        require(
            domainNonce[domainHash] == _listingObject.domainNonce,
            "domain offer revoked"
        );
        require(
            tokenOwner == _listingObject.seller,
            "owner of domain not correct"
        );

        require(
            sellerNonce[tokenOwner][subdomainHash] == _listingObject.nonce,
            "subdomain offer revoked"
        );

        require(
            sellerNonce[tokenOwner][bytes32(0)] == _listingObject.sellerNonce,
            "global offer revoked"
        );

        require(block.timestamp < _listingObject.expires, "listing expired");

        require(
            nameWrapper.ownerOf(uint256(subdomainHash)) == address(0),
            "Subdomain already exists"
        );

        require(
            ecrecover(getTypedEnsListingDataHash(_listingObject), v, r, s) ==
                tokenOwner,
            "Invalid signature"
        );
    }

    /**
     * @notice Buy single subdomain from listing
     * @dev Buyer can buy single subdomain using listing object
     * that has been signed by the owner of the ens domain
     * @param _listingObject The listing to be purchased
     * @param _resolver The buyer always chooses the resolver
     * @param v The v value of the signature
     * @param r The r value of the signature
     * @param s The s value of the signature
     */
    function purchaseSubdomainFromListing(
        EnsListing calldata _listingObject,
        address _resolver,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable nonReentrant {
        bytes32 domainHash = _listingObject.domain;
        bytes32 subdomainHash = keccak256(
            abi.encodePacked(
                domainHash,
                keccak256(abi.encodePacked(_listingObject.label))
            )
        );
        address tokenOwner = nameWrapper.ownerOf(uint256(domainHash));

        require(msg.value == _listingObject.priceInWei, "not enough ether");

        _verifyListing(
            _listingObject,
            tokenOwner,
            domainHash,
            subdomainHash,
            v,
            r,
            s
        );

        // prevent replay attacks which could happen if seller
        // repurchases the subdomain or something like that.
        unchecked {
            ++sellerNonce[tokenOwner][subdomainHash];
        }

        nameWrapper.setSubnodeRecord( // mint the subdomain
            domainHash, // wrapper node
            _listingObject.label, // label
            msg.sender, // owner
            _resolver, // resolver
            0, // TTL
            _listingObject.fuses, // number of fuses
            type(uint64).max // expiry time
        );

        if (msg.value > 0) {
            uint256 fee = (msg.value * marketCommissionPercentage) / 1000;
            payable(tokenOwner).transfer(msg.value - fee);
        }

        emit PurchaseSubdomainFromListing(
            domainHash,
            msg.sender,
            tokenOwner,
            _listingObject.priceInWei,
            _listingObject.label
        );
    }

    /**
     * @notice Cancel a single subdomain offer
     * @dev Bidder for a domain can cancel a single offer by incrementing the
     * their subdomain nonce
     * @param _subdomainHash The hash of the subdomain to cancel
     */
    function cancelSingleSubdomainOffer(bytes32 _subdomainHash) public {
        unchecked {
            ++bidderNonce[msg.sender][_subdomainHash];
        }
        emit CancelSubdomainOffer(
            _subdomainHash,
            msg.sender,
            bidderNonce[msg.sender][_subdomainHash]
        );
    }

    /**
     * @notice Cancel all sudomain offers
     * @dev Bidder can cancel all offers they have out on
     * all domains by incrementing their bidder nonce
     */
    function cancelAllOffers() public {
        unchecked {
            ++bidderNonce[msg.sender][bytes32(0)];
        }
        emit CancelGlobalSubdomainOffers(
            msg.sender,
            bidderNonce[msg.sender][bytes32(0)]
        );
    }

    /**
     * @notice Cancel single subdomain listing
     * @dev Owner can cancel a single subdomain listing by incrementing their
     * seller subdomain nonce
     * @param _subdomainHash The hash of the domain to cancel offers for
     */
    function cancelSingleSubdomainListing(bytes32 _subdomainHash) public {
        unchecked {
            ++sellerNonce[msg.sender][_subdomainHash];
        }
        emit CancelSubdomainListing(
            _subdomainHash,
            msg.sender,
            sellerNonce[msg.sender][_subdomainHash]
        );
    }

    function cancelAllSubdomainListings() public {
        unchecked {
            ++sellerNonce[msg.sender][bytes32(0)];
        }
        emit CancelGlobalSubdomainListings(
            msg.sender,
            sellerNonce[msg.sender][bytes32(0)]
        );
    }

    /**
     * @notice Cancel all subdomain listings for a domain
     * @dev Owner can cancel all subdomain listings for an ENS domain by incrementing
     * the domain nonce
     * @param _domainHash The hash of the parent domain to cancel offers for
     *
     */
    function cancelAllSubdomainListingsForDomain(bytes32 _domainHash) public {
        address owner = nameWrapper.ownerOf(uint256(_domainHash));
        require(owner == msg.sender, "caller is not the owner");
        unchecked {
            ++domainNonce[_domainHash];
        }
        emit CancelAllSubdomainListingsFromDomain(
            _domainHash,
            owner,
            domainNonce[_domainHash]
        );
    }

    function ownerMintSubdomains(EnsOffer calldata _offer) private {
        bytes32 domainHash = _offer.domain;
        bytes32 subdomainHash = keccak256(
            abi.encodePacked(
                domainHash,
                keccak256(abi.encodePacked(_offer.label))
            )
        );

        require(
            msg.sender == nameWrapper.ownerOf(uint256(domainHash)),
            "not owner of domain"
        );

        require(
            nameWrapper.ownerOf(uint256(subdomainHash)) == address(0),
            "Subdomain already exists"
        );

        nameWrapper.setSubnodeRecord( // mint the subdomain
            domainHash, // wrapper node
            _offer.label, // label
            _offer.bidder, // owner
            _offer.resolver, // resolver
            0, // TTL
            _offer.fuses, // number of fuses
            type(uint64).max // expiry time
        );

        emit OwnerMintSubdomain(
            domainHash,
            _offer.bidder,
            msg.sender,
            _offer.label
        );
    }

    function hash(
        EIP712Domain memory eip712Domain
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function getDomainHash(
        string calldata _label
    ) private pure returns (bytes32 namewrapperHash) {
        namewrapperHash = keccak256(
            abi.encodePacked(
                namewrapperHash,
                keccak256(abi.encodePacked("eth"))
            )
        );

        namewrapperHash = keccak256(
            abi.encodePacked(
                namewrapperHash,
                keccak256(abi.encodePacked(_label))
            )
        );
    }

    /**
     * @notice Get Typed ENS Listing Data Hash
     * @dev Helper method for getting an eip712 hash of a listing object. Listing objects
     * are used by domain sellers to list subdomains for sale
     * @param _listingObject The listing object to hash
     * @return The bytes32 hash of the listing object, including the domain separator
     */
    function getTypedEnsListingDataHash(
        EnsListing calldata _listingObject
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            EnsListing_TYPEHASH,
                            _listingObject.priceInWei,
                            _listingObject.nonce,
                            _listingObject.domainNonce,
                            _listingObject.sellerNonce,
                            _listingObject.domain,
                            _listingObject.seller,
                            _listingObject.expires,
                            _listingObject.fuses,
                            keccak256(bytes(_listingObject.label))
                        )
                    )
                )
            );
    }

    /**
     * @notice Get Typed ENS Offer Data Hash
     * @dev Helper method for getting an eip712 hash of an offer object. Offer objects
     * are used by domain buyers to make offers on subdomains
     * @param _offerObject The offer object to hash
     * @return The bytes32 hash of the offer object, including the domain separator
     */
    function getTypedEnsOfferDataHash(
        EnsOffer calldata _offerObject
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            EnsOffer_TYPEHASH,
                            _offerObject.nonce,
                            _offerObject.bidderNonce,
                            _offerObject.priceInWei,
                            _offerObject.domain,
                            _offerObject.bidder,
                            _offerObject.expires,
                            _offerObject.resolver,
                            _offerObject.fuses,
                            keccak256(bytes(_offerObject.label))
                        )
                    )
                )
            );
    }

    /**
    
        view helper functions

     */

    function isValidOffer(
        EnsOffer calldata _bidObject,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        bytes32 domainHash = _bidObject.domain;
        bytes32 subdomainHash = keccak256(
            abi.encodePacked(
                domainHash,
                keccak256(abi.encodePacked(_bidObject.label))
            )
        );
        address tokenOwner = nameWrapper.ownerOf(uint256(domainHash));

        bool result = WETH.balanceOf(_bidObject.bidder) >=
            _bidObject.priceInWei &&
            WETH.allowance(_bidObject.bidder, address(this)) >=
            _bidObject.priceInWei &&
            bidderNonce[_bidObject.bidder][subdomainHash] == _bidObject.nonce &&
            bidderNonce[_bidObject.bidder][bytes32(0)] ==
            _bidObject.bidderNonce &&
            block.timestamp < _bidObject.expires &&
            nameWrapper.ownerOf(uint256(subdomainHash)) == address(0) &&
            ecrecover(getTypedEnsOfferDataHash(_bidObject), v, r, s) ==
            _bidObject.bidder &&
            nameWrapper.isApprovedForAll(tokenOwner, address(this));

        return result;
    }

    function isValidListing(
        EnsListing calldata _offerObject,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        bytes32 domainHash = _offerObject.domain;
        bytes32 subdomainHash = keccak256(
            abi.encodePacked(
                domainHash,
                keccak256(abi.encodePacked(_offerObject.label))
            )
        );
        address tokenOwner = nameWrapper.ownerOf(uint256(domainHash));

        bool result = domainNonce[domainHash] == _offerObject.domainNonce &&
            tokenOwner == _offerObject.seller &&
            sellerNonce[tokenOwner][subdomainHash] == _offerObject.nonce &&
            sellerNonce[tokenOwner][bytes32(0)] == _offerObject.domainNonce &&
            block.timestamp < _offerObject.expires &&
            ecrecover(getTypedEnsListingDataHash(_offerObject), v, r, s) ==
            tokenOwner &&
            nameWrapper.isApprovedForAll(tokenOwner, address(this));

        return result;
    }

    /**
     * @notice Is Valid Offers
     * @dev Helper method for checking if an array of offers are valid.
     * this method uses the same logic as minting
     * @param _bidObjects The array of offer objects to check
     * @param _signatures The array of signatures to check. Signed by the bidders
     * @return isValid An array of booleans, where each index corresponds to the index of the offer object
     */
    function isValidOfferArray(
        EnsOffer[] calldata _bidObjects,
        Signature[] calldata _signatures
    ) public view returns (bool[] memory isValid) {
        isValid = new bool[](_bidObjects.length);
        for (uint256 i; i < _bidObjects.length; i++) {
            isValid[i] = isValidOffer(
                _bidObjects[i],
                _signatures[i].v,
                _signatures[i].r,
                _signatures[i].s
            );
        }

        return isValid;
    }

    /**
     * @notice Is Valid Listings
     * @dev Helper method for checking if an array of listings are valid.
     * this method uses the same logic as minting. Just omits the msg.value check
     * @param _listingObjects The array of listing objects to check.
     * @param _signatures The array of signatures to check. Signed by the domain sellers
     * @return isValid An array of booleans, where each index corresponds to the index of the listing object
     */
    function isValidListingArray(
        EnsListing[] calldata _listingObjects,
        Signature[] calldata _signatures
    ) public view returns (bool[] memory isValid) {
        isValid = new bool[](_listingObjects.length);
        for (uint256 i; i < _listingObjects.length; i++) {
            isValid[i] = isValidListing(
                _listingObjects[i],
                _signatures[i].v,
                _signatures[i].r,
                _signatures[i].s
            );
        }

        return isValid;
    }

    /**
     * @notice Get Offer Array
     * @dev Helper method for getting an array of offers. This will populate all the
     * nonce and other fields in the objects. Price / fuses / resolver all set to zero
     * @param _bidder The bidder to get offers for
     * @param _domains The array of domains to get offers for. Domain and label must be in the same index
     * @param _labels The array of labels to get offers for. Domain and label must be in the same index
     * @return _offers An array of offers with correct nonces
     */
    function getOfferArray(
        address _bidder,
        bytes32[] calldata _domains,
        string[] calldata _labels
    ) public view returns (EnsOffer[] memory _offers) {
        require(_domains.length == _labels.length, "length mismatch");

        _offers = new EnsOffer[](_domains.length);

        for (uint256 i; i < _domains.length; ) {
            string memory label = _labels[i];

            bytes32 domainHash = _domains[i];
            bytes32 subdomainHash = keccak256(
                abi.encodePacked(domainHash, keccak256(abi.encodePacked(label)))
            );

            address seller = nameWrapper.ownerOf(uint256(domainHash));

            if (seller != address(0)) {
                _offers[i] = EnsOffer({
                    bidder: _bidder,
                    priceInWei: 0,
                    expires: uint64(block.timestamp + 1 days),
                    label: label,
                    domain: domainHash,
                    resolver: address(0),
                    fuses: 0,
                    nonce: bidderNonce[_bidder][subdomainHash],
                    bidderNonce: bidderNonce[_bidder][bytes32(0)]
                });
            }
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Get Listing Array
     * @dev Helper method for getting an array of listings. This will populate all the
     * nonce and other fields in the objects. Price is set to 10 eth rather than zero
     * so you don't accidently offer up free domains. fuses set to zero
     * @param _domains The array of domains to get listings for. Domain and labels must be in the same order
     * @param _labels The array of labels to get listings for. Domain and labels must be in the same order
     * @return _listings An array of listings with correct nonces
     */
    function getListingArray(
        bytes32[] calldata _domains,
        string[] calldata _labels
    ) public view returns (EnsListing[] memory _listings) {
        require(_domains.length == _labels.length, "length mismatch");

        _listings = new EnsListing[](_domains.length);

        for (uint256 i; i < _domains.length; ) {
            string memory label = _labels[i];

            bytes32 domainHash = _domains[i];
            bytes32 subdomainHash = keccak256(
                abi.encodePacked(domainHash, keccak256(abi.encodePacked(label)))
            );

            address seller = nameWrapper.ownerOf(uint256(domainHash));

            require(seller != address(0), "domain not owned");

            uint256 priceInWei = 10 ether;
            uint256 nonce = sellerNonce[seller][subdomainHash];
            uint256 dNonce = domainNonce[domainHash];
            uint256 sNonce = sellerNonce[seller][bytes32(0)];
            uint64 expires;
            uint32 fuses;

            _listings[i] = EnsListing(
                priceInWei,
                nonce,
                dNonce,
                sNonce,
                domainHash,
                seller,
                expires,
                fuses,
                label
            );

            unchecked {
                ++i;
            }
        }
        return _listings;
    }

    function getSubdomainName(
        string calldata _domain,
        string calldata _label
    ) private pure returns (string memory) {
        return string(abi.encodePacked(_label, ".", _domain));
    }
}