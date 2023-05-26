// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./libraries/ERC721A.sol";
import "./libraries/SimpleAccess.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract FlowerFamGarden is ERC721A, SimpleAccess {
    using Strings for uint256;

    address public stakeAddress;
    string public baseURIString;
    address public openseaProxyRegistryAddress;

    struct FlowerGardenSpec {
        uint16 upgradeCount;
        uint256 upgradeBooster;
        uint40 lastInteraction; /// @dev timestamp of last interaction with flowerfam ecosystem
    }

    /// @dev only used in view functions
    struct UserFlowerGardenSpec {
        uint256 flowerGardenId;
        bool isAlreadyStaked;
    }

    mapping(uint256 => FlowerGardenSpec) public flowerGardenSpecs;
    uint256 public maxUpgradeCount;

    constructor(address _openseaProxyRegistryAddress, address _stakeAddress)
        ERC721A("Flower Fam - Oasis Gardens", "FFOG")
    {
        stakeAddress = _stakeAddress;
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress; 
        maxUpgradeCount = 4;
        baseURIString = "https://storage.googleapis.com/flowerfam/metadata/garden-unrevealed/";   
    }

    function startTokenId() external pure returns (uint256) {
        return _startTokenId();
    }

    function getLastMintedId() external view returns (uint256) {
        return _currentIndex - 1;
    }

    function getBooster(uint256 tokenId) external view returns (uint256) {
        return flowerGardenSpecs[tokenId].upgradeBooster;
    }
    
    function getUpgradeCount(uint256 tokenId) external view returns (uint256) {
        return flowerGardenSpecs[tokenId].upgradeCount;
    }

    function isAlreadyStaked(uint256 tokenId) public view returns (bool) {
        FlowerGardenSpec memory flowerGarden = flowerGardenSpecs[tokenId];
        return flowerGarden.lastInteraction > 0;
    }

    function getLastAction(uint256 tokenId) external view returns (uint256) {
        FlowerGardenSpec memory flowerGarden = flowerGardenSpecs[tokenId];
        return flowerGarden.lastInteraction;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        FlowerGardenSpec memory flowerGarden = flowerGardenSpecs[tokenId];

        if (flowerGarden.lastInteraction == 0) {
            return _ownershipOf(tokenId).addr;
        } else {
            return stakeAddress;
        }
    }

    function realOwnerOf(uint256 tokenId) external view returns (address) {
        return _ownershipOf(tokenId).addr; 
    }

    function canGardenUpgrade(uint256 tokenId) public view returns (bool) {
        return flowerGardenSpecs[tokenId].upgradeCount < maxUpgradeCount;
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function getNFTs(address user)
        external
        view
        returns (UserFlowerGardenSpec[] memory)
    {
        uint256 counter;
        uint256 balance = balanceOf(user);
        UserFlowerGardenSpec[] memory userNFTs = new UserFlowerGardenSpec[](
            balance
        );

        for (
            uint256 i = _startTokenId();
            i < _startTokenId() + totalSupply();
            i++
        ) {
            address _owner = _ownershipOf(i).addr;
            if (_owner == user) {
                UserFlowerGardenSpec memory nft = userNFTs[counter];
                nft.flowerGardenId = i;
                nft.isAlreadyStaked = isAlreadyStaked(i);
                counter++;
            }
        }

        return userNFTs;
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (openseaProxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(
                openseaProxyRegistryAddress
            );
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }

            if (openseaProxyRegistryAddress == operator) {
                return true;
            }
        }
        return super.isApprovedForAll(owner, operator);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseURIString, tokenId.toString(), ".json")
            );
    }

    function mint(address sender, uint256 amount) external onlyAuthorized {
        _mint(sender, amount);
    }

    function stake(address staker, uint256 tokenId) external onlyAuthorized {
        require(_exists(tokenId), "stake(): FlowerGarden doesn't exist!");
        require(ownerOf(tokenId) == staker, "stake(): Staker not owner");
        require(staker != stakeAddress, "stake(): Stake address can not stake");

        FlowerGardenSpec storage flowerGarden = flowerGardenSpecs[tokenId];
        flowerGarden.lastInteraction = uint40(block.timestamp);

        _clearApprovals(staker, tokenId);
        emit Transfer(staker, stakeAddress, tokenId); /// @dev Emit transfer event to indicate transfer of flower to stake wallet
    }

    function unstake(address unstaker, uint256 tokenId)
        external
        onlyAuthorized
    {
        require(
            isAlreadyStaked(tokenId),
            "unStake: FlowerGarden is not staked!"
        );
        require(
            _ownershipOf(tokenId).addr == unstaker,
            "unstake: Unstaker not real owner"
        );

        FlowerGardenSpec storage flowerGarden = flowerGardenSpecs[tokenId];
        flowerGarden.lastInteraction = 0;

        emit Transfer(stakeAddress, unstaker, tokenId); /// @dev Emit transfer event to indicate transfer of flower from stake wallet to owner
    }

    function upgrade(address upgrader, uint256 tokenId, uint256 booster)
        external
        onlyAuthorized
    {
        require(
            _ownershipOf(tokenId).addr == upgrader,
            "upgrade(): Sender not owner of garden"
        );

        FlowerGardenSpec storage flowerGarden = flowerGardenSpecs[tokenId];

        require(canGardenUpgrade(tokenId), "Cannot upgrade more than 4 times");

        flowerGarden.upgradeCount++;
        flowerGarden.upgradeBooster += booster;
    }

    function setStakeAddress(address stkaddr) external onlyOwner {
        stakeAddress = stkaddr;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURIString = _newBaseURI;
    }

    function setMaxUpgradeCount(uint256 maxCount) external onlyOwner {
        maxUpgradeCount = maxCount;
    }
    
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        require(
            !isAlreadyStaked(startTokenId),
            "Cannot transfer staked flowerGardens"
        );
    }
}