// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "solmate/utils/SignedWadMath.sol";
import "./systems/ISpatialSystem.sol";
import "./utils/EntityUtils.sol";
import "./whitelist/NFTWhitelistManager.sol";
import "./whitelist/AccountWhitelistManager.sol";
import "./IERC20Resource.sol";
import "./IMetadata.sol";
import "./IMiaocraft.sol";
import "./constants.sol";

struct ShipInfoExtended {
    uint256 id;
    address owner;
    uint256 balance;
    ShipInfo shipInfo;
    LocationInfo locationInfo;
}

contract Miaocraft is IMiaocraft, ERC721, Initializable, Ownable, Multicall {
    using Address for address;

    uint256 public immutable BUILD_COST;
    uint256 public immutable SINGLE_SPINS_DECAY_PER_SEC;

    bool public commissionWlOpen;
    bool public commissionPublicOpen;

    uint256 public scrapReward;
    uint256 public scrapRadius;
    uint256 public transferBurnRate;

    IERC20Resource public butter;
    ISpatialSystem public spatialSystem;
    IMetadata public metadata;
    address public sbh;

    NFTWhitelistManager public nftWlManager;
    AccountWhitelistManager public accountWlManager;

    mapping(uint256 => ShipInfo) private _shipInfos;
    mapping(address => bool) private _commissioned;

    uint256 public nextId;

    constructor(uint256 buildCost_, uint256 unitDecayInterval)
        ERC721("Miaocraft", "MC")
    {
        BUILD_COST = buildCost_;
        SINGLE_SPINS_DECAY_PER_SEC = SPINS_PRECISION / unitDecayInterval;
    }

    function initialize(
        address butter_,
        address spatialSystem_,
        address metadata_,
        address sbh_,
        uint256 scrapReward_,
        uint256 scrapRadius_,
        uint256 transferBurnRate_,
        address nftWlManager_,
        address accountWlManager_
    ) public initializer {
        butter = IERC20Resource(butter_);
        spatialSystem = ISpatialSystem(spatialSystem_);
        metadata = IMetadata(metadata_);
        sbh = sbh_;
        scrapReward = scrapReward_;
        scrapRadius = scrapRadius_;
        transferBurnRate = transferBurnRate_;

        nftWlManager = NFTWhitelistManager(nftWlManager_);
        accountWlManager = AccountWhitelistManager(accountWlManager_);

        _transferOwnership(msg.sender);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return metadata.getMetadata(tokenId);
    }

    function spinsOf(uint256 id) public view override returns (uint256) {
        return _shipInfos[id].spins;
    }

    function spinsDecayOf(uint256 id) public view returns (uint256) {
        uint256 spins = _shipInfos[id].spins;
        return
            Math.min(
                spins,
                (spinsDecayPerSec(spins) *
                    (block.timestamp - _shipInfos[id].lastServiceTime) +
                    _shipInfos[id].spinsBurned)
            );
    }

    function spinsDecayPerSec(uint256 spins) public view returns (uint256) {
        return (SINGLE_SPINS_DECAY_PER_SEC * spins) / SPINS_PRECISION;
    }

    function buildCost(uint256 spins) public view returns (uint256) {
        return (BUILD_COST * spins) / SPINS_PRECISION;
    }

    function serviceCostOf(uint256 id) public view returns (uint256) {
        return (BUILD_COST * spinsDecayOf(id)) / SPINS_PRECISION;
    }

    function isApprovedOrOwner(address spender, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function getShipInfo(uint256 id)
        public
        view
        override
        returns (ShipInfo memory)
    {
        return _shipInfos[id];
    }

    function toEntity(uint256 id) public view returns (uint256) {
        return tokenToEntity(address(this), id);
    }

    function commissionNftWl(
        address token,
        uint256[] calldata ids,
        string[] calldata names
    ) public {
        require(commissionWlOpen, "Not open yet");
        require(nextId < GENESIS_SUPPLY, "No more");
        require(ids.length == names.length, "Length mismatch");

        nftWlManager.claim(_msgSender(), token, ids);

        for (uint256 i = 0; i < ids.length; i++) {
            _buildShip(_msgSender(), SPINS_PRECISION, names[i]);
        }
    }

    function commissionWl(string calldata name, bytes32[] calldata proof)
        public
    {
        require(commissionWlOpen, "Not open yet");
        require(nextId < GENESIS_SUPPLY, "No more");

        accountWlManager.claim(_msgSender(), proof);

        _buildShip(_msgSender(), SPINS_PRECISION, name);
    }

    function commissionPublic(string calldata name) public {
        require(commissionPublicOpen, "Not open yet");
        require(nextId < GENESIS_SUPPLY, "No more");

        address sender = _msgSender();

        require(!_commissioned[sender], "Already commissioned");

        _commissioned[sender] = true;

        _buildShip(sender, SPINS_PRECISION, name);
    }

    function buildAndLoad(
        uint256 spins,
        string calldata name,
        uint256 amount
    ) public virtual {
        require(spins >= SPINS_PRECISION, "Less than 1 spin");

        address sender = _msgSender();

        butter.burnFrom(sender, buildCost(spins));

        uint256 id = _buildShip(sender, spins, name);

        butter.transferFrom(accountToEntity(sender), toEntity(id), amount);
    }

    function build(uint256 spins, string calldata name) public virtual {
        require(spins >= SPINS_PRECISION, "Less than 1 spin");

        address sender = _msgSender();

        butter.burnFrom(sender, buildCost(spins));

        _buildShip(sender, spins, name);
    }

    function loadAndUpgrade(
        uint256 id,
        uint256 amount,
        uint256 spins
    ) public virtual onlyApprovedOrOwner(id) {
        require(spins >= SPINS_PRECISION, "Less than 1 spin");

        uint256 shipEntityId = toEntity(id);
        butter.transferFrom(
            accountToEntity(_msgSender()),
            shipEntityId,
            amount
        );

        _service(id);
        _shipInfos[id].spins += uint96(spins);

        butter.burnFrom(shipEntityId, buildCost(spins));

        emit Upgrade(ownerOf(id), id, spins);
    }

    function upgrade(uint256 id, uint256 spins)
        public
        virtual
        override
        onlyApprovedOrOwner(id)
    {
        _service(id);
        _shipInfos[id].spins += uint96(spins);

        butter.burnFrom(toEntity(id), buildCost(spins));

        emit Upgrade(ownerOf(id), id, spins);
    }

    function merge(uint256 id1, uint256 id2)
        public
        virtual
        override
        onlyApprovedOrOwner(id1)
        onlyApprovedOrOwner(id2)
    {
        uint256 entityId1 = toEntity(id1);
        uint256 entityId2 = toEntity(id2);

        require(spatialSystem.collocated(entityId1, entityId2));

        _service(id1);
        _service(id2);

        _shipInfos[id1].spins += _shipInfos[id2].spins;
        delete _shipInfos[id2];

        butter.transferFrom(entityId2, entityId1, butter.balanceOf(entityId2));
        _burn(id2);

        emit Merge(ownerOf(id1), id1, id2, _shipInfos[id1].spins);
    }

    function scrap(uint256 scavengerId, uint256 targetId)
        public
        virtual
        override
        onlyApprovedOrOwner(scavengerId)
    {
        uint256 scavengerEntityId = toEntity(scavengerId);
        uint256 targetEntityId = toEntity(targetId);

        require(spinsOf(targetId) == spinsDecayOf(targetId), "Not scrappable");
        require(
            spatialSystem.collocated(
                scavengerEntityId,
                targetEntityId,
                scrapRadius
            ),
            "Too far away"
        );

        delete _shipInfos[targetId];

        butter.burnFrom(targetEntityId, butter.balanceOf(targetEntityId));
        _burn(targetId);

        butter.mint(scavengerEntityId, scrapReward);

        emit Scrap(ownerOf(scavengerId), scavengerId, targetId);
    }

    function service(uint256 id)
        public
        virtual
        override
        onlyApprovedOrOwner(id)
    {
        _service(id);
    }

    function rename(uint256 id, string calldata name) public virtual override {
        require(_msgSender() == ownerOf(id), "Unauthorized");
        _shipInfos[id].name = name;
        emit Rename(ownerOf(id), id, name);
    }

    function _service(uint256 id) internal {
        uint256 cost = serviceCostOf(id);
        uint256 entityId = toEntity(id);
        uint256 butterBalance = butter.balanceOf(entityId);

        _shipInfos[id].lastServiceTime = uint40(block.timestamp);

        if (cost > butterBalance) {
            // burn all existing balance and decay spins with excess cost
            butter.burnFrom(entityId, butterBalance);
            _shipInfos[id].spins -= uint96(
                ((cost - butterBalance) * SPINS_PRECISION) / BUILD_COST
            );
            _shipInfos[id].spinsBurned = 0;
        } else {
            // has enough balance to pay for service
            butter.burnFrom(entityId, cost);
        }

        emit Service(ownerOf(id), id, _shipInfos[id].spins, cost);
    }

    function _buildShip(
        address account,
        uint256 spins,
        string calldata name
    ) internal returns (uint256 id) {
        id = nextId++;
        _shipInfos[id] = ShipInfo({
            spins: uint96(spins),
            spinsBurned: 0,
            lastServiceTime: uint40(block.timestamp),
            name: name
        });

        _mint(account, id);

        emit Build(account, id, spins, name);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id,
        uint256 batchSize
    ) internal virtual override {
        if (from != address(0) && to != address(0)) {
            for (uint256 currId = id; currId < id + batchSize; currId++) {
                uint256 remainingSpins = spinsOf(currId) - spinsDecayOf(currId);
                if (remainingSpins > 0) {
                    uint256 spinsBurn = (remainingSpins * transferBurnRate) /
                        1e18;
                    _shipInfos[currId].spinsBurned += uint96(spinsBurn);
                    butter.mint(
                        sbh,
                        (2 * (spinsBurn * BUILD_COST)) / SPINS_PRECISION
                    );
                }
            }
        }

        super._beforeTokenTransfer(from, to, id, batchSize);
    }

    modifier onlyApprovedOrOwner(uint256 id) {
        require(_isApprovedOrOwner(_msgSender(), id), "Only approved or owner");
        _;
    }

    function paginateShips(uint256 offset, uint256 limit)
        public
        view
        returns (ShipInfoExtended[] memory shipInfos)
    {
        uint256 total = nextId;
        if (offset >= total) {
            return shipInfos;
        }

        uint256 end = offset + limit;
        if (end > total) {
            end = total;
        }

        shipInfos = new ShipInfoExtended[](end - offset);

        for (uint256 id = offset; id < end; id++) {
            shipInfos[id] = ShipInfoExtended({
                id: id,
                owner: ownerOf(id),
                balance: butter.balanceOf(toEntity(id)),
                shipInfo: _shipInfos[id],
                locationInfo: spatialSystem.getLocationInfo(toEntity(id))
            });
        }
    }

    /*
    OWNER FUNCTIONS
    */

    function setCommissionWlOpen(bool open) public onlyOwner {
        commissionWlOpen = open;
    }

    function setCommissionPublicOpen(bool open) public onlyOwner {
        commissionPublicOpen = open;
    }

    function setTransferBurnRate(uint256 rate) public onlyOwner {
        require(rate <= 0.1e18, "Rate must be <= 0.1e18");
        transferBurnRate = rate;
    }

    function setScrapRadius(uint256 radius) public onlyOwner {
        scrapRadius = radius;
    }

    function setScrapReward(uint256 reward) public onlyOwner {
        require(reward <= BUILD_COST, "Reward must be <= build cost");
        scrapReward = reward;
    }

    function setButter(IERC20Resource butter_) public onlyOwner {
        butter = butter_;
    }

    function setSpatialSystem(ISpatialSystem spatialSystem_) public onlyOwner {
        spatialSystem = spatialSystem_;
    }

    function setSbh(address sbh_) public onlyOwner {
        sbh = sbh_;
    }

    function setMetadata(IMetadata metadata_) public onlyOwner {
        metadata = metadata_;
    }
}