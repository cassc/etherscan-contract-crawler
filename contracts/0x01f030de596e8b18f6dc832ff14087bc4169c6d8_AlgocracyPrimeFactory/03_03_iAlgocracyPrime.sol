// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface iAlgocracyPrime {
    /// AlgocracyDAO::
    function VRFConsumer() external view returns (address);
    
    function Deployer() external view returns (address);
    function NFTFactory() external view returns (address);
    function PrimeFactory() external view returns (address);

    function PassNFT() external view returns (address);
    function CollectionNFT() external view returns (address);
    function RandomNFT() external view returns (address);

    function PassProvider() external view returns (address);
    function CollectionProvider() external view returns (address);

    function chain() external view returns (uint256);

    /// AlgocracyPass::
    function LOCK() external view returns (bool);
    function ACCESS_LEVEL_CORE() external view returns (uint256);
    function ACCESS_LEVEL_VETOER() external view returns (uint256);
    function ACCESS_LEVEL_OPERATOR() external view returns (uint256);
    function ACCESS_LEVEL_BASE() external view returns (uint256);
    function getAccessLevel(uint256) external view returns (uint256);
    function mintPassFromCollection(address, uint256) external;
    function mintPassFromEvent(address) external;
    function mintPassFromCore(address) external;
    
    /// AlgocracyCollection::
    struct Meta{string name; string cover; string description; uint256 maxSupply; uint256 blockNumber;}
    struct Mint{bool isActive;bool isRandom;bool isAllowListed;uint256 maxQuantity;uint256 price;}
    struct Module{address NFT; address Prime; address Provider;}
    function getCollectionRegistryLength() external view returns (uint256);
    function getCollectionData(uint256) external view returns (Meta memory);
    function getCollectionState(uint256) external view returns (Mint memory);
    function getCollectionContract(uint256) external view returns (Module memory);
    function setCollectionStateAllowListInternal(uint256, bool) external;
    function setCollectionStateRandomInternal(uint256, bool) external;
    function mintCollectionNFT(
        address, address, address, address,
        string memory, string memory, string memory,
        uint256
    ) external;

    /// AlgocracyRandom
    struct Random {uint256 id;uint256 provableRandom;}
    function FIXED_TIC() external view returns (uint16);
    function FIXED_GAS() external view returns (uint32);
    function FIXED_QTY() external view returns (uint32);
    function getRandomRegistry(uint256) external view returns (Random memory);
    function mintRandom(uint256, uint256) external;

    /// AlgocracyFactory::
    function deployAlgocracyNFT(address, uint256) external returns (address);
    function deployAlgocracyPrime(uint256) external returns (address);

    /// AlgocracyERC721::
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function maxSupply() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function exist(uint256) external view returns (bool);
    function balanceOf(address) external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
    function ownedBy(address) external view returns (uint256);
    function mintSequentialNFT(address, uint256) external;
    function mintRandomNFT(address, uint256[] memory) external;

    /// AlgocracyProvider::
    function generateMetadata(uint256 id) external view returns (string memory);

    /// AlgocracyUtils::Regex
    function matches(string memory) external pure returns (bool);

    /// AlgocracyVRF::
    function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);
    function requestRandomWords(bytes32, uint64, uint16, uint32, uint32 ) external returns (uint256);
    function createSubscription() external returns (uint64);
    function getSubscription(uint64) external view returns (uint96, uint64, address, address[] memory);
    function requestSubscriptionOwnerTransfer(uint64, address) external;
    function acceptSubscriptionOwnerTransfer(uint64) external;
    function addConsumer(uint64, address) external;
    function removeConsumer(uint64, address) external;
    function cancelSubscription(uint64, address) external;
    function pendingRequestExists(uint64) external view returns (bool);
}