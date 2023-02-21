// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../oracles/PriceOracle.sol";
import "../midregistrar/BaseRegistrarImplementation.sol";
import "../midregistrar/StringUtils.sol";
import "../resolvers/Resolver.sol";

/**
 * This contract supports users to migrate their domains from other domain services
 * into our service with a premium in price
 */
interface SourceRegistry {
    function owner(bytes32 node) external view returns (address);
}

interface SourceBaseRegistrar {
    function nameExpires(uint256 tokenId) external view returns (uint256);
}

contract MIDRegistrarMigrationController is Ownable {
    using BitMaps for BitMaps.BitMap;
    using StringUtils for *;

    SourceRegistry public sourceRegistry;
    SourceBaseRegistrar public sourceBaseRegistrar;

    address public treasury;

    PriceOracle public priceOracle;

    uint256 public constant MIN_NAME_LENGTH = 2;

    uint256 public durationRoundUpUnit = 86400 * 30 * 3; // 3 months

    /**
     * @dev discount percentage
     *  e.g [50, 60, 70, 80, 90] => For names in length 1->5, the discounts: 50%, 60%, 70%, 80%, 90%
     */
    uint256[] public discountPercentages;

    /**
     * @dev key: token id
     */
    BitMaps.BitMap migrationRecords;

    /**
     * @dev only in the period of [start, end], the discount is enabled
     */
    uint256 public start;
    uint256 public end;

    BaseRegistrarImplementation public base;

    event Migrated(
        string labelname,
        address indexed account,
        uint256 indexed cost,
        uint256 expiry
    );

    event NameRegistered(
        string name, 
        bytes32 indexed label, 
        address indexed owner, 
        uint cost, 
        uint expires
    );

    constructor(
        BaseRegistrarImplementation base_,
        PriceOracle priceOracle_, 
        SourceRegistry sourceRegistry_,
        SourceBaseRegistrar sourceBaseRegistrar_,
        address treasury_,
        uint256 start_,
        uint256 end_,
        uint256[] memory discountPercentages_
    ) {
        base = base_;
        start = start_;
        end = end_;
        sourceRegistry = sourceRegistry_;
        sourceBaseRegistrar = sourceBaseRegistrar_;
        treasury = treasury_;
        priceOracle = priceOracle_;
        setDiscountPercentages(discountPercentages_);
    }

    function valid(string memory labelname) public pure returns(bool) {
        return labelname.strlen() >= MIN_NAME_LENGTH;
    }

    function available(string memory labelname) public view returns(bool) {
        bytes32 label = keccak256(bytes(labelname));
        return valid(labelname) && base.available(uint256(label));
    }

    function setDiscountPercentages(uint256[] memory discountPercentages_) public onlyOwner {
        require(discountPercentages_.length > 0, "empty discount percentages");
        discountPercentages = discountPercentages_;
    }

    function setDurationRoundUpUnit(uint256 durationRoundUpUnit_) external onlyOwner {
        require(durationRoundUpUnit_ > 0, "invalid roundup unit");
        durationRoundUpUnit = durationRoundUpUnit_;
    }

    function setPriceOracle(PriceOracle _prices) external onlyOwner {
        require(address(_prices) != address(0), "invalid address");
        priceOracle = _prices;
    }

    function setActivePeriod(uint256 start_, uint256 end_) external onlyOwner {
        require(start_ < end_ && start_ > 0, "invalid period");
        start = start_;
        end = end_;
    }

    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    /**
     * @dev rent price with discount
     */
    function rentPriceWithDuration(string memory labelname, uint256 duration)
        public
        view
        returns (uint256)
    {
        uint256 len = labelname.strlen();
        bytes32 tokenId = keccak256(bytes(labelname));
        uint256 price = priceOracle.price(labelname, base.nameExpires(uint256(tokenId)), duration);
        if(len > discountPercentages.length) {
            len = discountPercentages.length;
        }
        return price * discountPercentages[len - 1] / 100;
    }

    function rentPrice(string memory labelname) public view returns (uint256) {
        bytes32 labelHash = keccak256(bytes(labelname));
        uint256 tokenId = uint256(labelHash);
        uint256 duration = migratedDuration(tokenId);
        return rentPriceWithDuration(labelname, duration);
    }


    /**
     * @dev From Openzepplin, returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @dev returns whether the label name is migrated or not, the input is label name without .bnb suffix
     */
    function isNameOwner(address owner, bytes32 nodehash)
        public
        view
        returns (bool)
    {
        return sourceRegistry.owner(nodehash) == owner;
    }

    /**
     * @dev returns whether the label name is migrated or not, the input is label name without .bnb suffix
     */
    function isNameMigrated(bytes32 nodehash)
        public
        view
        returns (bool)
    {
        return migrationRecords.get(uint256(nodehash));
    }

    /**
     * @dev returns the full name hash, if the labelname.bnb, the input is label name without .bnb suffix
     */
    function nodeHashByLabel(string memory labelname)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(base.baseNode(), keccak256(bytes(labelname))));
    }

    /**
     * @dev calculate the duration of migrated domains, domains in grace period
     *  cannot be migrated
     */
    function migratedDuration(uint256 id) public view returns (uint256) {
        uint256 sourceExpiry = sourceBaseRegistrar.nameExpires(id);
        if (sourceExpiry < block.timestamp) {
            return 0;
        }
        // round up
        uint256 remaining = sourceExpiry - block.timestamp;
        uint256 patchedRemaining = ceilDiv(remaining, durationRoundUpUnit) * durationRoundUpUnit;
        return patchedRemaining;
    }

    /**
     * @dev migrate .bnb name to our service, owner is the recipient address
     */
    function migrateWithResolver(string memory labelname, address owner, address resolver) external payable {
        require(
            block.timestamp > start && block.timestamp < end,
            "migration not available"
        );

        bytes32 labelHash = keccak256(bytes(labelname));
        uint256 tokenId = uint256(labelHash);
        bytes32 nodehash = nodeHashByLabel(labelname);

        require(isNameOwner(owner, nodehash), "not the source name owner");
        // the following checking might be duplicated, but it's ok
        require(!isNameMigrated(nodehash), "name already migrated");
        require(available(labelname), "not available");
        
        uint duration = migratedDuration(tokenId);
        require(duration > 0, "source token might be expired"); // expired

        // the cost with discount
        uint cost = rentPriceWithDuration(labelname, duration);

        uint256 expiry;
        require(resolver != address(0), "empty resolver");

        // Set this contract as the (temporary) owner, giving it
        // permission to set up the resolver.
        expiry = base.register(tokenId, address(this), duration);

        // Set the resolver
        base.mid().setResolver(nodehash, resolver);

        // Configure the resolver
        Resolver(resolver).setAddr(nodehash, owner);

        // Now transfer full ownership to the expeceted owner
        base.reclaim(tokenId, owner);
        base.transferFrom(address(this), owner, tokenId);

        emit Migrated(labelname, owner, cost, expiry);

        // transfer the revenue to treasury
        require(msg.value >= cost, "insufficient payment");
        if (treasury != address(0)) {
            payable(treasury).transfer(cost);
        }

        // Refund any extra payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        migrationRecords.set(uint256(nodehash));

        emit NameRegistered(
            labelname, 
            labelHash, 
            owner, 
            cost, 
            expiry
        );
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}