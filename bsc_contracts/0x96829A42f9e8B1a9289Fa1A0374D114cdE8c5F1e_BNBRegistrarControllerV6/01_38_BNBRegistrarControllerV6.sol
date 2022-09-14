// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./BaseRegistrarImplementation.sol";
import "./StringUtils.sol";
import "../resolvers/Resolver.sol";
import "../registry/ReverseRegistrar.sol";
import "./IBNBRegistrarController.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../wrapper/INameWrapper.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev A registrar controller for registering and renewing names at fixed cost during staging phase
 *  Implement bot prevention mechanism through soul bound token
 */
contract BNBRegistrarControllerV6 is Ownable {
    using StringUtils for *;

    uint256 public constant MIN_REGISTRATION_DURATION = 365 days;

    bytes4 private constant INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 private constant COMMITMENT_CONTROLLER_ID =
        bytes4(
            keccak256("rentPrice(string,uint256)") ^
                keccak256("available(string)") ^
                keccak256("makeCommitment(string,address,bytes32)") ^
                keccak256("commit(bytes32)") ^
                keccak256("register(string,address,uint256,bytes32)") ^
                keccak256("renew(string,uint256)")
        );

    bytes4 private constant COMMITMENT_WITH_CONFIG_CONTROLLER_ID =
        bytes4(keccak256("registerWithConfig(string,address,uint256,bytes32,address,address)") ^ keccak256("makeCommitmentWithConfig(string,address,bytes32,address,address)"));

    BaseRegistrarImplementation base;
    IPriceOracle prices;
    ERC721 babToken;
    ERC721 galxePassport;
    uint256 public minCommitmentAge;
    uint256 public maxCommitmentAge;
    // [startTime, endTime).
    uint256 public startTime;
    uint256 public totalQuota;
    uint256 public usedQuota;
    uint256 public babtQuota;
    uint256 public galxeQuota;
    mapping(bytes32 => uint256) public commitments;
    mapping(address => uint256) public claimed;
    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint256 cost, uint256 expires);

    event NameRenewed(string name, bytes32 indexed label, uint256 cost, uint256 expires);
    event NewPriceOracle(address indexed oracle);

    modifier onlyAfterStart() {
        require(block.timestamp >= startTime, "only after staging phase starts");
        _;
    }

    modifier onlyQuotaLeft() {
        require(usedQuota < totalQuota, "no more quota");
        _;
    }

    constructor(
        BaseRegistrarImplementation _base,
        IPriceOracle _prices,
        ERC721 _babToken,
        ERC721 _galxePassport,
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge,
        uint256 _startTimestamp,
        uint256 _totalQuota
    ) public {
        require(_maxCommitmentAge > _minCommitmentAge);
        require(_totalQuota > 0);
        totalQuota = _totalQuota;
        usedQuota = 0;
        babtQuota = 3;
        galxeQuota = 2;
        startTime = _startTimestamp;
        base = _base;
        prices = _prices;
        babToken = _babToken;
        galxePassport = _galxePassport;
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function hasBABT(address addr) public view returns (bool) {
        return babToken.balanceOf(addr) > 0;
    }

    function hasGalxePassport(address addr) public view returns (bool) {
        return galxePassport.balanceOf(addr) > 0;
    }

    function individualQuotaUsed(address addr) public view returns (uint256) {
        return claimed[addr];
    }

    function individualQuotaAvailable(address addr) public view returns (uint256) {
        uint256 available = 0;
        if (!hasGalxePassport(addr)) {
            return available;
        }
        if (hasGalxePassport(addr)) {
            available += galxeQuota;
        }
        if (hasBABT(addr)) {
            available += babtQuota;
        }
        return available;
    }

    function rentPrice(string memory name, uint256 duration) public view returns (IPriceOracle.Price memory price) {
        bytes32 label = keccak256(bytes(name));
        price = prices.price(name, base.nameExpires(uint256(label)), duration);
    }

    function getCurrentUsage() public view returns (uint256) {
        return usedQuota;
    }

    function valid(string memory name) public pure returns (bool) {
        // check unicode rune count, if rune count is >=3, byte length must be >=3.
        if (name.strlen() < 3) {
            return false;
        }
        bytes memory nb = bytes(name);
        // zero width for /u200b /u200c /u200d and U+FEFF
        for (uint256 i; i < nb.length - 2; i++) {
            if (bytes1(nb[i]) == 0xe2 && bytes1(nb[i + 1]) == 0x80) {
                if (bytes1(nb[i + 2]) == 0x8b || bytes1(nb[i + 2]) == 0x8c || bytes1(nb[i + 2]) == 0x8d) {
                    return false;
                }
            } else if (bytes1(nb[i]) == 0xef) {
                if (bytes1(nb[i + 1]) == 0xbb && bytes1(nb[i + 2]) == 0xbf) return false;
            }
        }
        return true;
    }

    function available(string memory name) public view returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function makeCommitment(
        string memory name,
        address owner,
        bytes32 secret
    ) public pure returns (bytes32) {
        return makeCommitmentWithConfig(name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(
        string memory name,
        address owner,
        bytes32 secret,
        address resolver,
        address addr
    ) public pure returns (bytes32) {
        bytes32 label = keccak256(bytes(name));
        if (resolver == address(0) && addr == address(0)) {
            return keccak256(abi.encodePacked(label, owner, secret));
        }
        require(resolver != address(0));
        return keccak256(abi.encodePacked(label, owner, resolver, addr, secret));
    }

    function commit(bytes32 commitment) public onlyAfterStart onlyQuotaLeft {
        require(commitments[commitment] + maxCommitmentAge < block.timestamp);
        commitments[commitment] = block.timestamp;
    }

    function register(
        string calldata name,
        address owner,
        uint256 duration,
        bytes32 secret
    ) external payable {
        registerWithConfig(name, owner, duration, secret, address(0), address(0));
    }

    function registerWithConfig(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) public payable onlyAfterStart onlyQuotaLeft {
        //qualification check
        require(hasGalxePassport(addr), "galxe passport required");
        uint256 individualQuota = individualQuotaAvailable(addr);
        require(claimed[addr] < individualQuota, "no more quota");

        claimed[addr] = claimed[addr] + 1;
        usedQuota = usedQuota + 1;

        bytes32 commitment = makeCommitmentWithConfig(name, owner, secret, resolver, addr);
        uint256 cost = _consumeCommitment(name, duration, commitment);
        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);

        uint256 expires;
        if (resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            expires = base.register(tokenId, address(this), duration);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), label));

            // Set the resolver
            base.sid().setResolver(nodehash, resolver);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(tokenId, owner);
            base.transferFrom(address(this), owner, tokenId);
        } else {
            require(addr == address(0));
            expires = base.register(tokenId, owner, duration);
        }

        emit NameRegistered(name, label, owner, cost, expires);

        // Refund any extra payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function renew(string calldata name, uint256 duration) external payable {
        IPriceOracle.Price memory price = rentPrice(name, duration);
        uint256 cost = (price.base + price.premium);
        require(msg.value >= cost);

        bytes32 label = keccak256(bytes(name));
        uint256 expires = base.renew(uint256(label), duration);

        // Refund any extra payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit NameRenewed(name, label, cost, expires);
    }

    function setPriceOracle(IPriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }

    function setCommitmentAges(uint256 _minCommitmentAge, uint256 _maxCommitmentAge) public onlyOwner {
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID || interfaceID == COMMITMENT_CONTROLLER_ID || interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID;
    }

    function _consumeCommitment(
        string memory name,
        uint256 duration,
        bytes32 commitment
    ) internal returns (uint256) {
        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);

        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);
        require(available(name));

        delete (commitments[commitment]);

        IPriceOracle.Price memory price = rentPrice(name, duration);
        uint256 cost = (price.base + price.premium);
        require(duration >= MIN_REGISTRATION_DURATION);
        require(msg.value >= cost);

        return cost;
    }
}