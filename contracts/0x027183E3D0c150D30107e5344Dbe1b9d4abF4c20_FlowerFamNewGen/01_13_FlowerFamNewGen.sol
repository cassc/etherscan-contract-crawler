// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./libraries/ERC721A.sol";
import "./libraries/SimpleAccess.sol";

contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract FlowerFamNewGen is ERC721A, SimpleAccess {
    using Strings for uint256;
    
    address private stakeAddress;
    string public baseURIString = "";
    address public openseaProxyRegistryAddress;

    struct NewGenFlowerSpec {
        uint256 lastInteraction; /// @dev timestamp of last interaction with flowerfam ecosystem
    }

    /// @dev Used in view functions only
    struct UserFlowerSpec {
        uint256 flowerId;
        bool isAlreadyStaked;
    }

    mapping(uint256 => NewGenFlowerSpec) public newGenFlowerSpecs;

    constructor(address _openseaProxyRegistryAddress, address _stakeAddress)
        ERC721A("Flower Fam New Generation", "FFNG")
    {
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

    function isAlreadyStaked(uint256 tokenId) public view returns (bool) {
        NewGenFlowerSpec memory flower = newGenFlowerSpecs[tokenId];
        return flower.lastInteraction > 0;
    }

    function getLastAction(uint256 tokenId) external view returns (uint256) {
        NewGenFlowerSpec memory flower = newGenFlowerSpecs[tokenId];
        return flower.lastInteraction;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {        
        NewGenFlowerSpec memory flower = newGenFlowerSpecs[tokenId];

        if (flower.lastInteraction == 0) {
            return _ownershipOf(tokenId).addr;
        } else {
            return stakeAddress;
        }
    }

    function realOwnerOf(uint256 tokenId) external view returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 7000;
    }

    function startTokenId() external pure returns (uint256) {
        return _startTokenId();
    }

    function getNFTs(address user)
        external
        view
        returns (UserFlowerSpec[] memory) {
            uint256 counter;
            uint256 balance = balanceOf(user);
            UserFlowerSpec[] memory userNFTs = new UserFlowerSpec[](balance);

            for (uint i = _startTokenId(); i < _startTokenId() + totalSupply(); i++) {                
                address _owner = _ownershipOf(i).addr;
                if (_owner == user) {
                    UserFlowerSpec memory nft = userNFTs[counter];
                    nft.flowerId = i;
                    nft.isAlreadyStaked = isAlreadyStaked(i);
                    counter++;
                }
            }

            return userNFTs;
        }

    function stake(address staker, uint256 tokenId) external onlyAuthorized {
        require(_exists(tokenId), "stake(): Flower doesn't exist!");
        require(ownerOf(tokenId) == staker, "stake(): Staker not owner");
        require(staker != stakeAddress, "stake(): Stake address can not stake");

        NewGenFlowerSpec storage flower = newGenFlowerSpecs[tokenId];
        flower.lastInteraction = uint40(block.timestamp);

        _clearApprovals(staker, tokenId);
        emit Transfer(staker, stakeAddress, tokenId); /// @dev Emit transfer event to indicate transfer of flower to stake wallet
    }

    function unstake(address unstaker, uint256 tokenId)
        external
        onlyAuthorized
    {
        require(isAlreadyStaked(tokenId), "unStake: [2] Flower is not staked!");
        require(
            _ownershipOf(tokenId).addr == unstaker,
            "unstake: Unstaker not real owner"
        );

        NewGenFlowerSpec storage flower = newGenFlowerSpecs[tokenId];
        flower.lastInteraction = 0;

        emit Transfer(stakeAddress, unstaker, tokenId); /// @dev Emit transfer event to indicate transfer of flower from stake wallet to owner
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

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURIString = _newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURIString, tokenId.toString(), ".json"));     
    }
}