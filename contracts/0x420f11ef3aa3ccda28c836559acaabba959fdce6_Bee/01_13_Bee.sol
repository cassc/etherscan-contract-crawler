// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./libraries/ERC721A.sol";
import "./libraries/SimpleAccess.sol";

contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Bee is ERC721A, SimpleAccess {
    using Strings for uint256;
    
    address private stakeAddress;
    string public baseURIString = "";
    address public openseaProxyRegistryAddress;

    /**
     * @dev The idea of boosting power is that
     * we calculate the amount of weeks since it
     * was 100% and we substract 5% power from each week.
     *
     * So we calculate each week from powerCycleStart
     * and for each one we remove 5% boosting power
     *
     * When someone refills boosting power we add the amount
     * of weeks to the start time corresponding to the amount
     * of refills they have done (1 refill = 1 week). This means
     * we add weeks to the powerCycleStart corresponding to the 
     * amount of refills.
     *
     * When we refill the bee we always refill fully. Meaning
     * If you refill right before you lose another 5% you will
     * get your original 5% back and start the counter again from 0.
     *
     * When someone unstakes we save the amount of boosting weeks
     * the bee has left. When someone stakes later we set the cycle start
     * such that the boosting weeks match again. We store the seconds difference
     * from blocktime and unstake time and when staked again we make sure
     * the difference between cycle start and blocktime is those seconds.
     *
     * This way ^^ the bee doesn't lose power when unstaked.
     */
    uint256 public powerCycleBasePeriod = 1 days * 7; /// @dev 1 week
    uint256 public powerCycleMaxPeriods = 20; /// @dev we can have 20 times 5% boost

    struct BeeSpec {
        uint88 lastInteraction; /// @dev timestamp of last interaction with flowerfam ecosystem
        uint88 powerCycleStart; /// @dev records start time of power cycle which decreases 5% every weeks
        uint80 powerCycleStored; /// @dev stores the power cycle left of the bee when unstaked --> amount of time since last restore until unstake
    }
    struct UserBeeSpec {
        uint256 beeId;
        bool isAlreadyStaked;
    }
    mapping(uint256 => BeeSpec) public beeSpecs;

    constructor(address _openseaProxyRegistryAddress, address _stakeAddress)
        ERC721A("Bee", "BEE") {
        stakeAddress = _stakeAddress;
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;
        _mint(msg.sender, 1);
    }

    function mint(
        address sender,
        uint256 amount
    ) external onlyAuthorized {
        _mint(sender, amount);
    }

    function isAlreadyStaked(uint256 tokenId) internal view returns (bool) {
        BeeSpec memory bee = beeSpecs[tokenId];
        return bee.lastInteraction > 0;
    }
    
    function getLastAction(uint256 tokenId) external view returns (uint88) {
        BeeSpec memory bee = beeSpecs[tokenId];
        return bee.lastInteraction;
    }

    function getPowerCycleStart(uint256 tokenId) external view returns (uint88) {
        BeeSpec memory bee = beeSpecs[tokenId];
        return bee.powerCycleStart;
    }

    function getNFTs(address user)
        external
        view
        returns (UserBeeSpec[] memory) {
            uint256 counter;
            uint256 balance = balanceOf(user);
            UserBeeSpec[] memory userNFTs = new UserBeeSpec[](balance);

            for (uint i = _startTokenId(); i < _startTokenId() + totalSupply(); i++) {                
                address _owner = _ownershipOf(i).addr;
                if (_owner == user) {
                    UserBeeSpec memory nft = userNFTs[counter];
                    nft.beeId = i;
                    nft.isAlreadyStaked = isAlreadyStaked(i);
                    counter++;
                }
            }

            return userNFTs;
        }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        BeeSpec memory bee = beeSpecs[tokenId];

        if (bee.lastInteraction == 0) {
            return _ownershipOf(tokenId).addr;
        } else {
            return stakeAddress;
        }
    }

    function realOwnerOf(uint256 tokenId) external view returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function startTokenId() external pure returns (uint256) {
        return _startTokenId();
    }

    function stake(
        address staker,
        uint256 tokenId
    ) external onlyAuthorized {
        require(_exists(tokenId), "stake(): Bee doesn't exist!");
        require(ownerOf(tokenId) == staker, "stake(): Staker not owner");
        require(staker != stakeAddress, "stake(): Stake address can not stake");
        
        _clearApprovals(staker, tokenId);

        BeeSpec storage bee = beeSpecs[tokenId];        
        bee.lastInteraction = uint40(block.timestamp);

        if (bee.powerCycleStart == 0) {
            bee.powerCycleStart = uint40(block.timestamp);
        } else {
            bee.powerCycleStart = uint40(block.timestamp - bee.powerCycleStored); /// @dev set bee power cycle right where it was when unstaked
        }
        emit Transfer(staker, stakeAddress, tokenId); /// @dev Emit transfer event to indicate transfer of bee to stake wallet
    }

    function unstake(address unstaker, uint256 tokenId)
        external
        onlyAuthorized
    {
        require(isAlreadyStaked(tokenId), "unStake: Bee is not staked!");
        require(
            _ownershipOf(tokenId).addr == unstaker,
            "unstake: Unstaker not real owner"
        );

        BeeSpec storage bee = beeSpecs[tokenId];
        bee.lastInteraction = 0;
        bee.powerCycleStored = uint40(block.timestamp - bee.powerCycleStart); /// @dev we save the power cycle amount we lost

        emit Transfer(stakeAddress, unstaker, tokenId); /// @dev Emit transfer event to indicate transfer of bee from stake wallet to owner
    }

    /**
     * @dev To restore the power of the bee we take in a restorePeriods amount.
     * We check if its at most the amount of periods we lost, as we cannot restore
     * more periods than were lost. Then based on the restore amount and the periods lost
     * we caculate the new target periods lost. For example if we lost 3 periods (3 weeks or 15%)
     * and we want to restore 2 periods (2 weeks or 10%) then our target lost periods becomes
     * 1 (1 week or 5%).
     *
     * Once we know this target lost periods we set the powerCycleStart such that the difference
     * with the current time, divided by the seconds per period leads to the target period amount.
     *
     * For example if the target period is 1 we set the powerCycleStart to the current time - 1 week.
     * This way when we calculate the powerReductionPeriods we will get 1 week as the result.
     */
    function restorePowerOfBee(address owner, uint256 tokenId, uint256 restorePeriods)
        external
        onlyAuthorized
    {
        require(isAlreadyStaked(tokenId), "unStake: [2] Bee is not staked!");
        require(_ownershipOf(tokenId).addr == owner, "unstake: Owner not real owner");

        uint256 currentReductionPeriods = _getPowerReductionPeriods(tokenId); 

        require(currentReductionPeriods > 0, "Cannot restore power of fully charged bee");
        require(restorePeriods <= currentReductionPeriods, "Cannot restore more power than was lost");

        /// @dev targetReductionPeriods is the reduction periods we should have after restoring the bee with restorePeriods amount
        uint256 targetReductionPeriods = currentReductionPeriods - restorePeriods;

        /// @dev newPowerCycleStart is the new start time that results in the target reduction periods
        uint256 newPowerCycleStart = block.timestamp - (targetReductionPeriods * powerCycleBasePeriod);
        
        BeeSpec storage bee = beeSpecs[tokenId];
        bee.powerCycleStart = uint40(newPowerCycleStart);
        bee.lastInteraction = uint88(block.timestamp);
    }

    /**
     * @dev returns the amount of boost reduction periods
     * the bee has accumulated. Since solidity rounds down divisions
     * we will get "0" when the difference between the start and current time
     * is less than 1 week. We will get "1" when the difference between the
     * start and current time is between 1 week and less than 2 weeks etc.
     */
    function _getPowerReductionPeriods(uint256 tokenId) internal view returns (uint256) {
        BeeSpec memory bee = beeSpecs[tokenId];

        uint256 reductionPeriods;

        if (isAlreadyStaked(tokenId)) {
            reductionPeriods = block.timestamp - bee.powerCycleStart / powerCycleBasePeriod;
        } else {
            reductionPeriods = bee.powerCycleStored / powerCycleBasePeriod;
        }

        if (reductionPeriods > powerCycleMaxPeriods) {
            return powerCycleMaxPeriods;
        }            
        else {
            return reductionPeriods;
        }
    }

    function getPowerReductionPeriods(uint256 tokenId) external view returns (uint256) {
        return _getPowerReductionPeriods(tokenId);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURIString = _newBaseURI;
    }

    function setPowerCycleBasePeriod(uint256 newBasePeriod) external onlyOwner {
        powerCycleBasePeriod = newBasePeriod;
    }

    function setPowerCycleMaxPeriods(uint256 newMaxPeriods) external onlyOwner {
        powerCycleMaxPeriods = newMaxPeriods;
    }

    function setStakeAddress(address stkaddr) external onlyOwner {
        stakeAddress = stkaddr;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        require(!isAlreadyStaked(startTokenId), "Cannot transfer staked bees");
    }

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {        
        if (openseaProxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(openseaProxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }

            if (openseaProxyRegistryAddress == operator) {
                return true;
            }
        }
        return super.isApprovedForAll(owner, operator);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURIString, tokenId.toString(), ".json"));     
    }

}