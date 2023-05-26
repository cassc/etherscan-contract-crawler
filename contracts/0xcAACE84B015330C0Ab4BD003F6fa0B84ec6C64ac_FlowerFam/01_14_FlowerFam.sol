// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./libraries/ERC721A.sol";
import "./libraries/SimpleAccess.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract FlowerFam is ERC721A, SimpleAccess {
    using Strings for uint256;
    
    uint256 public prodigy = 0;
    uint256 public seedling = 1;
    uint256 public ancestor = 2;
    uint256 public elder = 3;
    uint256 public pioneer = 4;

    address public stakeAddress;
    string public baseURIString = "";
    address public openseaProxyRegistryAddress;

    struct FlowerSpec {
        uint40 lastInteraction; /// @dev timestamp of last interaction with flowerfam ecosystem
        uint40 upgradeCycleStart; /// @dev records start time of upgrade cycle which is 3 per year
        uint16 upgradeCount; /// @dev records amount of upgrades flower has had        
    }

    /// @dev only used in view functions
    struct UserFlowerSpec {
        uint256 flowerId;
        uint16 upgradeCount;
        bool isAlreadyStaked;
    }

    mapping(uint256 => FlowerSpec) public flowerSpecs;
    
    uint256 public upgradeCooldownTime = 1 days * 365;

    constructor(address _openseaProxyRegistryAddress, address _stakeAddress)
        ERC721A("Flower Fam", "FF")
    {
        stakeAddress = _stakeAddress;
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;
        _mint(msg.sender, 1);
    }

    function getUpgradeCountOfFlower(uint256 tokenId)
        external
        view
        returns (uint16)
    {
        FlowerSpec memory flower = flowerSpecs[tokenId];
        return flower.upgradeCount;
    }

    function getLastAction(uint256 tokenId) external view returns (uint40) {
        FlowerSpec memory flower = flowerSpecs[tokenId];
        return flower.lastInteraction;
    }

    function isAlreadyStaked(uint256 tokenId) public view returns (bool) {
        FlowerSpec memory flower = flowerSpecs[tokenId];
        return flower.lastInteraction > 0;
    }
   
    function ownerOf(uint256 tokenId) public view override returns (address) {
        FlowerSpec memory flower = flowerSpecs[tokenId];
    
        if (flower.lastInteraction == 0) {
            return _ownershipOf(tokenId).addr;
        } else {
            return stakeAddress;
        }
    }

    function realOwnerOf(uint256 tokenId) external view returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    function getNFTs(address user)
        external
        view
        returns (UserFlowerSpec[] memory)
    {
        uint256 counter;
        uint256 balance = balanceOf(user);
        UserFlowerSpec[] memory userNFTs = new UserFlowerSpec[](balance);

        for (uint256 i = _startTokenId(); i < _startTokenId() + totalSupply(); i++) {
            address _owner = _ownershipOf(i).addr;
            if (_owner == user) {
                UserFlowerSpec memory nft = userNFTs[counter];
                nft.flowerId = i;
                nft.isAlreadyStaked = isAlreadyStaked(i);
                nft.upgradeCount = flowerSpecs[i].upgradeCount;
                counter++;
            }
        }

        return userNFTs;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function startTokenId() external pure returns (uint256) {
        return _startTokenId();
    }

    function getLastMintedId() external view returns (uint256) {
        return _currentIndex - 1;
    }

    function mint(address sender, uint256 amount)
        external
        onlyAuthorized
    {
        _mint(sender, amount);
    }

    function stake(address staker, uint256 tokenId) external onlyAuthorized {
        require(_exists(tokenId), "stake(): Flower doesn't exist!");
        require(ownerOf(tokenId) == staker, "stake(): Staker not owner");
        require(staker != stakeAddress, "stake(): Stake address can not stake");

        FlowerSpec storage flower = flowerSpecs[tokenId];
        flower.lastInteraction = uint40(block.timestamp);

        _clearApprovals(staker, tokenId);
        emit Transfer(staker, stakeAddress, tokenId); /// @dev Emit transfer event to indicate transfer of flower to stake wallet
    }

    function unstake(address unstaker, uint256 tokenId)
        external
        onlyAuthorized
    {
        require(isAlreadyStaked(tokenId), "unStake: Flower is not staked!");
        require(
            _ownershipOf(tokenId).addr == unstaker,
            "unstake: Unstaker not real owner"
        );

        FlowerSpec storage flower = flowerSpecs[tokenId];
        flower.lastInteraction = 0;

        emit Transfer(stakeAddress, unstaker, tokenId); /// @dev Emit transfer event to indicate transfer of flower from stake wallet to owner
    }

    function upgrade(address upgrader, uint256 tokenId)
        external
        onlyAuthorized
    {
        require(
            _ownershipOf(tokenId).addr == upgrader,
            "upgrade(): Sender not owner of flower"
        );

        FlowerSpec storage flower = flowerSpecs[tokenId];

        /// @dev If we've upgraded 3 times we check if a year has passed since we did the first upgrade
        /// If so we reset the first upgrade timer and we start again
        if (flower.upgradeCount % 3 == 0) {
            require(
                block.timestamp - flower.upgradeCycleStart >=
                    upgradeCooldownTime,
                "Cannot upgrade more than 3 times per year"
            );
            flower.upgradeCycleStart = uint40(block.timestamp);
        }

        flower.lastInteraction = uint40(block.timestamp);
        flower.upgradeCount++;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURIString = _newBaseURI;
    }

    function setUpgradeCooldownTime(uint256 newCooldown) external onlyOwner {
        upgradeCooldownTime = newCooldown;
    }

    function setStakeAddress(address newStakeAddress) external onlyOwner {
        stakeAddress = newStakeAddress;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        require(!isAlreadyStaked(startTokenId), "Cannot transfer staked flowers");
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