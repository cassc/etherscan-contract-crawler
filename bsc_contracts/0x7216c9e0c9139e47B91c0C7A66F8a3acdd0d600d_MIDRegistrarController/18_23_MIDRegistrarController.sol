// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../oracles/PriceOracle.sol";
import "./BaseRegistrarImplementation.sol";
import "./StringUtils.sol";
import "../resolvers/Resolver.sol";
import "./IMIDRegistrarController.sol";
import "../business/IWishlist.sol";

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract MIDRegistrarController is Ownable, IMIDRegistrarController {
    using StringUtils for *;

    uint constant public MIN_REGISTRATION_DURATION = 28 days;

    uint constant public MIN_NAME_LENGTH = 2;

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));

    BaseRegistrarImplementation base;
    PriceOracle public prices;
    uint public minCommitmentAge;
    uint public maxCommitmentAge;

    mapping(bytes32 => uint) public commitments;

    address public treasury;

    // wishlist contract
    IWishlist public wishlist;

    // reservation period, out of which we    
    uint256 public reservationPhraseStart;
    uint256 public reservationPhraseEnd;

    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
    event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
    event NewPriceOracle(address indexed oracle);

    constructor(
        address wishlist_,
        uint256 reservationPhraseStart_,
        uint256 reservationPhraseEnd_,
        BaseRegistrarImplementation base_, 
        PriceOracle prices_, 
        uint minCommitmentAge_, 
        uint maxCommitmentAge_
    ) {
        require(maxCommitmentAge_ > minCommitmentAge_, "invalid commitment age");
        setWishlist(wishlist_);
        setReservationPhraseTime(reservationPhraseStart_, reservationPhraseEnd_);
        base = base_;
        prices = prices_;
        minCommitmentAge = minCommitmentAge_;
        maxCommitmentAge = maxCommitmentAge_;
    }

    function setWishlist(address wishlist_) public onlyOwner {
        wishlist = IWishlist(wishlist_);
    }

    function setReservationPhraseTime(uint256 reservationPhraseStart_, uint256 reservationPhraseEnd_) public onlyOwner {
        reservationPhraseStart = reservationPhraseStart_;
        reservationPhraseEnd = reservationPhraseEnd_;
    }
    
    function isReservationAlive() public view returns (bool) {
        return block.timestamp > reservationPhraseStart && block.timestamp < reservationPhraseEnd;
    }

    function setTreasury(address treasury_) external onlyOwner {
        require(treasury_ != address(0), "treasury can't be zero address");
        treasury = treasury_;
    }

    function rentPrice(string memory name, uint duration) view public override returns(uint) {
        bytes32 hash = keccak256(bytes(name));
        return prices.price(name, base.nameExpires(uint256(hash)), duration);
    }

    function valid(string memory name) public pure returns(bool) {
        return name.strlen() >= MIN_NAME_LENGTH;
    }

    function available(string memory name) public view override returns(bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function makeCommitment(string memory name, address owner, bytes32 secret) pure public override returns(bytes32) {
        return makeCommitmentWithConfig(name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure public override returns(bytes32) {
        bytes32 label = keccak256(bytes(name));
        if (resolver == address(0) && addr == address(0)) {
            return keccak256(abi.encodePacked(label, owner, secret));
        }
        require(resolver != address(0), "resolver can't be empty");
        return keccak256(abi.encodePacked(label, owner, resolver, addr, secret));
    }

    function commit(bytes32 commitment) public override {
        require(commitments[commitment] + maxCommitmentAge < block.timestamp, "commitment not outdated yet");
        commitments[commitment] = block.timestamp;
    }

    function register(string calldata name, address owner, uint duration, bytes32 secret) external payable override {
      registerWithConfig(name, owner, duration, secret, address(0), address(0));
    }

    function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) public payable virtual override {
        // if reservation is alive, you can only register the name you've wished
        if (isReservationAlive()) {
            require(wishlist.wishCounts(keccak256(bytes(name))) == 1, "wish count must be 1");
            require(wishlist.userHasWish(owner, name), "not owner's wish");
        }
        
        bytes32 commitment = makeCommitmentWithConfig(name, owner, secret, resolver, addr);
        uint cost = _consumeCommitment(name, duration, commitment);

        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);

        uint expires;
        if(resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            expires = base.register(tokenId, address(this), duration);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), label));

            // Set the resolver
            base.mid().setResolver(nodehash, resolver);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(tokenId, owner);
            base.transferFrom(address(this), owner, tokenId);
        } else {
            require(addr == address(0), "addr can't be empty");
            expires = base.register(tokenId, owner, duration);
        }

        emit NameRegistered(name, label, owner, cost, expires);

        // transfer the revenue to treasury
        if (treasury != address(0)) {
            payable(treasury).transfer(cost);
        }

        // Refund any extra payment
        if(msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function renew(string calldata name, uint duration) external payable override {
        uint cost = rentPrice(name, duration);
        require(msg.value >= cost, "renew underpaid");

        bytes32 label = keccak256(bytes(name));
        uint expires = base.renew(uint256(label), duration);

        // transfer the revenue to treasury
        if (treasury != address(0)) {
            payable(treasury).transfer(cost);
        }

        if(msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
            
        }

        emit NameRenewed(name, label, cost, expires);
    }

    function setPriceOracle(PriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }

    function setCommitmentAges(uint minCommitmentAge_, uint maxCommitmentAge_) public onlyOwner {
        minCommitmentAge = minCommitmentAge_;
        maxCommitmentAge = maxCommitmentAge_;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);        
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
               interfaceID == type(IMIDRegistrarController).interfaceId;
    }

    function _consumeCommitment(string memory name, uint duration, bytes32 commitment) internal returns (uint256) {
        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp, "too early");

        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp, "too late");
        require(available(name), "name not available");

        delete(commitments[commitment]);

        uint cost = rentPrice(name, duration);
        require(duration >= MIN_REGISTRATION_DURATION, "duration must over 28 days");
        require(msg.value >= cost, "registry underpaid");

        return cost;
    }
}