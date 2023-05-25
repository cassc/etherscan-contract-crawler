// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./TransferHelper.sol";
import "./INFTWEscrow.sol";
import "./INFTWRental.sol";
import "./INFTWRouter.sol";
import "./INFTW_ERC721.sol";


contract NFTWEscrow is Context, ERC165, INFTWEscrow, ERC20Permit, ERC20Votes, Ownable, ReentrancyGuard {
    using SafeCast for uint;
    using ECDSA for bytes32;

    address immutable WRLD_ERC20_ADDR;
    INFTW_ERC721 immutable NFTW_ERC721;
    INFTWRental private NFTWRental;
    INFTWRouter private NFTWRouter;
    WorldInfo[10001] private worldInfo; // NFTW tokenId is in N [1,10000]
    RewardsPeriod public rewardsPeriod;
    RewardsPerWeight public rewardsPerWeight;     
    mapping (address => UserRewards) public rewards;
    mapping (address => bool) private isPredicate; // Polygon bridge predicate
    mapping (address => uint) public userBridged;
    uint private bridged;
    
    address private signer;

    // ======== Admin functions ========

    constructor(address wrld, address nftw) ERC20("Vote-escrowed NFTWorld", "veNFTW") ERC20Permit("Vote-escrowed NFTWorld") {
        require(wrld != address(0), "E0"); // E0: addr err
        require(nftw != address(0), "E0");
        WRLD_ERC20_ADDR = wrld;
        NFTW_ERC721 = INFTW_ERC721(nftw);
    }

    // Set a rewards schedule
    // rate is in wei per second for all users
    // This must be called AFTER some worlds are staked (or ensure at least 1 world is staked before the start timestamp)
    function setRewards(uint32 start, uint32 end, uint96 rate) external virtual onlyOwner {
        require(start <= end, "E1"); // E1: Incorrect input
        // some safeguard, value TBD. (2b over 5 years is 12.68 per sec) 
        require(rate > 0.03 ether && rate < 30 ether, "E2"); // E2: Rate incorrect
        require(WRLD_ERC20_ADDR != address(0), "E3"); // E3: Rewards token not set
        require(block.timestamp.toUint32() < rewardsPeriod.start || block.timestamp.toUint32() > rewardsPeriod.end, "E4"); // E4: Rewards already set

        rewardsPeriod.start = start;
        rewardsPeriod.end = end;

        rewardsPerWeight.lastUpdated = start;
        rewardsPerWeight.rate = rate;

        emit RewardsSet(start, end, rate);
    }

    function setWeight(uint[] calldata tokenIds, uint[] calldata weights) external onlyOwner {
        require(tokenIds.length == weights.length, "E6");
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            require(worldInfo[tokenId].weight == 0, "E8");
            worldInfo[tokenId].weight = weights[i].toUint16();
        }
    }

    // signing key does not require high security and can be put on an API server and rotated periodically, as signatures are issued dynamically
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setRentalContract(INFTWRental _contract) external onlyOwner {
        require(_contract.supportsInterface(type(INFTWRental).interfaceId),"E0");
        NFTWRental = _contract;
    }

    function setRouterContract(INFTWRouter _contract) external onlyOwner {
        NFTWRouter = _contract;
    }

    function setPredicate(address _contract, bool _allow) external onlyOwner {
        require(_contract != address(0), "E0"); // E0: addr err
        isPredicate[_contract] = _allow;
    }


    // ======== Public functions ========

    // Stake worlds for a first time. You may optionally stake to a different wallet. Ownership will be transferred to the stakeTo address.
    // Initial weights passed as input parameters, which are secured by a dev signature. weight = 40003 - 3 * rank
    // When you stake you can set rental conditions for all of them.
    // Initialized and uninitialized stake can be mixed into one tx using this method.
    // If you set rentalPerDay to 0 and rentableUntil to some time in the future, then anyone can rent for free 
    //    until the rentableUntil timestamp with no way of backing out
    function initialStake(uint[] calldata tokenIds, uint[] calldata weights, address stakeTo, 
        uint16 _deposit, uint16 _rentalPerDay, uint16 _minRentDays, uint32 _rentableUntil, uint32 _maxTimestamp, bytes calldata _signature) 
        external virtual override nonReentrant
    {
        require(uint(_deposit) <= uint(_rentalPerDay) * (uint(_minRentDays) + 1), "ER"); // ER: Rental rate incorrect
        // security measure against input length attack
        require(tokenIds.length == weights.length, "E6"); // E6: Input length mismatch
        require(block.timestamp <= _maxTimestamp, "EX"); // EX: Signature expired
        // verifying signature here is much cheaper than verifying merkle root
        require(_verifySignerSignature(keccak256(
            abi.encode(tokenIds, weights, _msgSender(), _maxTimestamp, address(this))), _signature), "E7"); // E7: Invalid signature
        // ensure stakeTo is EOA or ERC721Receiver to avoid token lockup
        _ensureEOAorERC721Receiver(stakeTo);
        require(stakeTo != address(this), "ES"); // ES: Stake to escrow

        uint totalWeights = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            { // scope to avoid stack too deep errors
                uint tokenId = tokenIds[i];
                uint _weight = worldInfo[tokenId].weight;
                require(_weight == 0 || _weight == weights[i], "E8"); // E8: Initialized weight cannot be changed
                require(NFTW_ERC721.ownerOf(tokenId) == _msgSender(), "E9"); // E9: Not your world
                NFTW_ERC721.safeTransferFrom(_msgSender(), address(this), tokenId);  
            
                emit WorldStaked(tokenId, stakeTo);
            }
            worldInfo[tokenIds[i]] = WorldInfo(weights[i].toUint16(), stakeTo, _deposit, _rentalPerDay, _minRentDays, _rentableUntil);
            totalWeights += weights[i];
        }
        // update rewards
        _updateRewardsPerWeight(totalWeights.toUint32(), true);
        _updateUserRewards(stakeTo, totalWeights.toUint32(), true);
        // mint veNFTW
        _mint(stakeTo, tokenIds.length * 1e18);
    }

    // subsequent staking does not require dev signature
    function stake(uint[] calldata tokenIds, address stakeTo, 
        uint16 _deposit, uint16 _rentalPerDay, uint16 _minRentDays, uint32 _rentableUntil) 
        external virtual override nonReentrant
    {
        require(uint(_deposit) <= uint(_rentalPerDay) * (uint(_minRentDays) + 1), "ER"); // ER: Rental rate incorrect
        // ensure stakeTo is EOA or ERC721Receiver to avoid token lockup
        _ensureEOAorERC721Receiver(stakeTo);
        require(stakeTo != address(this), "ES"); // ES: Stake to escrow

        uint totalWeights = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            uint16 _weight = worldInfo[tokenId].weight;
            require(_weight != 0, "EA"); // EA: Weight not initialized
            require(NFTW_ERC721.ownerOf(tokenId) == _msgSender(), "E9"); // E9: Not your world
            NFTW_ERC721.safeTransferFrom(_msgSender(), address(this), tokenId);
            totalWeights += _weight;
            worldInfo[tokenId] = WorldInfo(_weight, stakeTo, _deposit, _rentalPerDay, _minRentDays, _rentableUntil);

            emit WorldStaked(tokenId, stakeTo);
        }
        // update rewards
        _updateRewardsPerWeight(totalWeights.toUint32(), true);
        _updateUserRewards(stakeTo, totalWeights.toUint32(), true);
        // mint veNFTW
        _mint(stakeTo, tokenIds.length * 1e18);
    }

    // Update rental conditions as long as therer's no ongoing rent.
    // setting rentableUntil to 0 makes the world unrentable.
    function updateRent(uint[] calldata tokenIds, 
        uint16 _deposit, uint16 _rentalPerDay, uint16 _minRentDays, uint32 _rentableUntil) 
        external virtual override
    {
        require(uint(_deposit) <= uint(_rentalPerDay) * (uint(_minRentDays) + 1), "ER"); // ER: Rental rate incorrect
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            WorldInfo storage worldInfo_ = worldInfo[tokenId];
            require(worldInfo_.weight != 0, "EA"); // EA: Weight not initialized
            require(NFTW_ERC721.ownerOf(tokenId) == address(this) && worldInfo_.owner == _msgSender(), "E9"); // E9: Not your world
            require(!NFTWRental.isRentActive(tokenId), "EB"); // EB: Ongoing rent
            worldInfo_.deposit = _deposit;
            worldInfo_.rentalPerDay = _rentalPerDay;
            worldInfo_.minRentDays = _minRentDays;
            worldInfo_.rentableUntil = _rentableUntil;
        }
    }

    // Extend rental period of ongoing rent
    function extendRentalPeriod(uint tokenId, uint32 _rentableUntil) external virtual override {
        WorldInfo storage worldInfo_ = worldInfo[tokenId];
        require(worldInfo_.weight != 0, "EA"); // EA: Weight not initialized
        require(NFTW_ERC721.ownerOf(tokenId) == address(this) && worldInfo_.owner == _msgSender(), "E9"); // E9: Not your world
        worldInfo_.rentableUntil = _rentableUntil;
    }

    function unstake(uint[] calldata tokenIds, address unstakeTo) external virtual override nonReentrant {
        // ensure unstakeTo is EOA or ERC721Receiver to avoid token lockup
        _ensureEOAorERC721Receiver(unstakeTo);
        require(unstakeTo != address(this), "ES"); // ES: Unstake to escrow
        require(balanceOf(_msgSender()) - userBridged[_msgSender()] >= tokenIds.length * 1e18, "EP"); // EP: veNFTW bridged to polygon

        uint totalWeights = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            require(worldInfo[tokenId].owner == _msgSender(), "E9"); // E9: Not your world
            require(!NFTWRental.isRentActive(tokenId), "EB"); // EB: Ongoing rent
            NFTW_ERC721.safeTransferFrom(address(this), unstakeTo, tokenId);
            uint16 _weight = worldInfo[tokenId].weight;
            totalWeights += _weight;
            worldInfo[tokenId] = WorldInfo(_weight,address(0),0,0,0,0);

            emit WorldUnstaked(tokenId, _msgSender()); // World `id` unstaked from `address`
        }
        // update rewards
        _updateRewardsPerWeight(totalWeights.toUint32(), false);
        _updateUserRewards(_msgSender(), totalWeights.toUint32(), false);
        // burn veNFTW
        _burn(_msgSender(), tokenIds.length * 1e18);
    }

    function setRoutingDataIPFSHash(uint tokenId, string calldata _ipfsHash) external {
        require((worldInfo[tokenId].owner == _msgSender() && !NFTWRental.isRentActive(tokenId)) 
                || (worldInfo[tokenId].owner != address(0) && NFTWRental.getTenant(tokenId) == _msgSender()),
                "EH"); // EH: Not your world or not rented
        NFTWRouter.setRoutingDataIPFSHash(tokenId, _ipfsHash);
    }

    function removeRoutingDataIPFSHash(uint tokenId) external {
        require((worldInfo[tokenId].owner == _msgSender() && !NFTWRental.isRentActive(tokenId)) 
                || (worldInfo[tokenId].owner != address(0) && NFTWRental.getTenant(tokenId) == _msgSender()),
                "EH"); // EH: Not your world or not rented
        NFTWRouter.removeRoutingDataIPFSHash(tokenId);
    }

    function updateMetadata(uint tokenId, string calldata _tokenMetadataIPFSHash) external virtual {
        require((worldInfo[tokenId].owner == _msgSender() && !NFTWRental.isRentActive(tokenId)) 
                || (worldInfo[tokenId].owner != address(0) && NFTWRental.getTenant(tokenId) == _msgSender()),
                "EH"); // EH: Not your world or not rented
        NFTW_ERC721.updateMetadataIPFSHash(tokenId, _tokenMetadataIPFSHash);
    }

    // Claim all rewards from caller into a given address
    function claim(address to) external virtual override nonReentrant {
        _updateRewardsPerWeight(0, false);
        uint rewardAmount = _updateUserRewards(_msgSender(), 0, false);
        rewards[_msgSender()].accumulated = 0;
        TransferHelper.safeTransfer(WRLD_ERC20_ADDR, to, rewardAmount);
        emit RewardClaimed(to, rewardAmount);
    }

    // ======== View only functions ========

    function getWorldInfo(uint tokenId) external view override returns(WorldInfo memory) {
        return worldInfo[tokenId];
    }

    function checkUserRewards(address user) external virtual view override returns(uint) {
        RewardsPerWeight memory rewardsPerWeight_ = rewardsPerWeight;
        UserRewards memory userRewards_ = rewards[user];

        // Find out the unaccounted time
        uint32 end = min(block.timestamp.toUint32(), rewardsPeriod.end);
        uint256 unaccountedTime = end - rewardsPerWeight_.lastUpdated; // Cast to uint256 to avoid overflows later on
        if (unaccountedTime != 0) {

            // Calculate and update the new value of the accumulator. unaccountedTime casts it into uint256, which is desired.
            // If the first mint happens mid-program, we don't update the accumulator, no one gets the rewards for that period.
            if (rewardsPerWeight_.totalWeight != 0) {
                rewardsPerWeight_.accumulated = (rewardsPerWeight_.accumulated + unaccountedTime * rewardsPerWeight_.rate / rewardsPerWeight_.totalWeight).toUint96();
            }
        }
        // Calculate and update the new value user reserves. userRewards_.stakedWeight casts it into uint256, which is desired.
        return userRewards_.accumulated + userRewards_.stakedWeight * (rewardsPerWeight_.accumulated - userRewards_.checkpoint);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(INFTWEscrow).interfaceId || super.supportsInterface(interfaceId);
    }

    // ======== internal functions ========

    function _verifySignerSignature(bytes32 hash, bytes calldata signature) internal view returns(bool) {
        return hash.toEthSignedMessageHash().recover(signature) == signer;
    }

    function min(uint32 x, uint32 y) internal pure returns (uint32 z) {
        z = (x < y) ? x : y;
    }


    // Updates the rewards per weight accumulator.
    // Needs to be called on each staking/unstaking event.
    function _updateRewardsPerWeight(uint32 weight, bool increase) internal virtual {
        RewardsPerWeight memory rewardsPerWeight_ = rewardsPerWeight;
        RewardsPeriod memory rewardsPeriod_ = rewardsPeriod;

        // We skip the update if the program hasn't started
        if (block.timestamp.toUint32() >= rewardsPeriod_.start) {

            // Find out the unaccounted time
            uint32 end = min(block.timestamp.toUint32(), rewardsPeriod_.end);
            uint256 unaccountedTime = end - rewardsPerWeight_.lastUpdated; // Cast to uint256 to avoid overflows later on
            if (unaccountedTime != 0) {

                // Calculate and update the new value of the accumulator.
                // If the first mint happens mid-program, we don't update the accumulator, no one gets the rewards for that period.
                if (rewardsPerWeight_.totalWeight != 0) {
                    rewardsPerWeight_.accumulated = (rewardsPerWeight_.accumulated + unaccountedTime * rewardsPerWeight_.rate / rewardsPerWeight_.totalWeight).toUint96();
                }
                rewardsPerWeight_.lastUpdated = end;
            }
        }
        if (increase) {
            rewardsPerWeight_.totalWeight += weight;
        }
        else {
            rewardsPerWeight_.totalWeight -= weight;
        }
        rewardsPerWeight = rewardsPerWeight_;
        emit RewardsPerWeightUpdated(rewardsPerWeight_.accumulated);
    }

    // Accumulate rewards for an user.
    // Needs to be called on each staking/unstaking event.
    function _updateUserRewards(address user, uint32 weight, bool increase) internal virtual returns (uint96) {
        UserRewards memory userRewards_ = rewards[user];
        RewardsPerWeight memory rewardsPerWeight_ = rewardsPerWeight;
        
        // Calculate and update the new value user reserves.
        userRewards_.accumulated = userRewards_.accumulated + userRewards_.stakedWeight * (rewardsPerWeight_.accumulated - userRewards_.checkpoint);
        userRewards_.checkpoint = rewardsPerWeight_.accumulated;    
        
        if (weight != 0) {
            if (increase) {
                userRewards_.stakedWeight += weight;
            }
            else {
                userRewards_.stakedWeight -= weight;
            }
            emit WeightUpdated(user, increase, weight, block.timestamp);
        }
        rewards[user] = userRewards_;
        emit UserRewardsUpdated(user, userRewards_.accumulated, userRewards_.checkpoint);

        return userRewards_.accumulated;
    }

    function _ensureEOAorERC721Receiver(address to) internal virtual {
        uint32 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            try IERC721Receiver(to).onERC721Received(address(this), address(this), 0, "") returns (bytes4 retval) {
                require(retval == IERC721Receiver.onERC721Received.selector, "ET"); // ET: neither EOA nor ERC721Receiver
            } catch (bytes memory) {
                revert("ET"); // ET: neither EOA nor ERC721Receiver
            }
        }
    }


    // ======== function overrides ========

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override
    {
        require(from == address(0) || to == address(0) || isPredicate[from] || isPredicate[to], "ERC20: Non-transferrable");
        // bridge back from polygon
        if (isPredicate[from]) {
            bridged -= amount;
            userBridged[to] -= amount;
            super._burn(to, amount);
        }
        // bridge to polygon
        if (isPredicate[to]) {
            bridged += amount;
            userBridged[from] += amount;
            super._mint(from, amount);
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function totalSupply() public view override(ERC20, IERC20) returns (uint256 supply) {
        supply = super.totalSupply() - bridged;
    }

    // Prevent sending ERC721 tokens directly to this contract
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view override returns (bytes4) {
        from; tokenId; data; // supress solidity warnings
        if (operator == address(this)) {
            return this.onERC721Received.selector;
        }
        else {
            return 0x00000000;
        }
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

}