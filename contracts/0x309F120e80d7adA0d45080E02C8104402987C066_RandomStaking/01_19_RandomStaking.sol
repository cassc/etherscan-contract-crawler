// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./RandomToken.sol";

abstract contract ContractErc721 {
    function ownerOf(uint256 nftId) public virtual returns (address);

    function getApproved(uint256 nftId) public virtual returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 nftId
    ) public virtual;

    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId
    ) public virtual;

    function setApprovalForAll(address operator, bool approved) public virtual;

    function isApprovedForAll(address owner, address operator)
        public
        virtual
        returns (bool);

    function totalSupply() public virtual returns (uint256);
}

contract RandomStaking is Ownable, IERC721Receiver {
    enum LockupPeriod {
        regular,
        sevenDays,
        thirtyDays
    }

    uint256 public totalStaked;
    bool paused = true;
        
    struct Stake {
        uint24 nftId;
        uint48 timestamp;
        address collection;
        address owner;
        LockupPeriod lockupPeriod;
        uint48 staketime;
    }

    event randomStaked(address owner, uint256 nftId, uint256 value);
    event nftRemoved(address owner, uint256 nftId, uint256 value);
    event retreiveTokens(address owner, uint256 amount);

    // reference to the Block NFT contract
    RandomToken token;
    ContractErc721 nftContract;

    // maps nftId to stake
    mapping(uint256 => mapping(address => Stake)) public randomsStaked;
    mapping(address => bool) public stakeAllowedCollections;

    constructor(address[] memory _collections, RandomToken _token) {
        token = _token;
        for (uint i = 0; i < _collections.length; i++) {
            stakeAllowedCollections[_collections[i]] = true;
        }
    }

    function stake(
        uint256[] calldata nftIds,
        address collection,
        uint8 period
    ) external {
        require(!paused, "Contract is paused");
        require(stakeAllowedCollections[collection] == true, "Collection not allowed");
        uint256 nftId;
        totalStaked += nftIds.length;
        nftContract = ContractErc721(collection);
        for (uint i = 0; i < nftIds.length; i++) {
            nftId = nftIds[i];
            require(
                nftContract.ownerOf(nftId) == msg.sender,
                "You do not own this NFT"
            );
            bool isApproved = nftContract.isApprovedForAll(
                msg.sender,
                address(this)
            );
            require(
                isApproved,
                "You must approve this contract to transfer your NFT"
            );
            randomsStaked[nftId][collection] = Stake(
                uint24(nftId),
                uint48(block.timestamp),
                collection,
                msg.sender,
                LockupPeriod(period),
                uint48(block.timestamp)
            );
            nftContract.transferFrom(msg.sender, address(this), nftId);
            emit randomStaked(msg.sender, nftId, 1);
        }
    }

    function addCollections(address[] calldata collections) external onlyOwner {
        require(collections.length > 0, "No collections provided");
        require(msg.sender == owner(), "Only the owner can add collections");        
        for (uint i = 0; i < collections.length; i++) {
            stakeAllowedCollections[collections[i]] = true;
        }
    }

    function removeCollections(address[] calldata collections)
        external
        onlyOwner
    {
        require(collections.length > 0, "No collections provided");
        require(msg.sender == owner(), "Only the owner can remove collections");
        for (uint i = 0; i < collections.length; i++) {
            stakeAllowedCollections[collections[i]] = false;
        }
    }

    function claim(uint256[] calldata nftIds, address collection) external {
        require(!paused, "Contract is paused");
        require(stakeAllowedCollections[collection] == true, "Collection not allowed");

        _claim(msg.sender, nftIds, collection, false);
    }

    function claimForAddress(
        address account,
        address collection,
        uint256[] calldata nftIds
    ) external onlyOwner {
        _claim(account, nftIds, collection, false);
    }

    function unstake(uint256[] calldata nftIds, address collection) external {
        _claim(msg.sender, nftIds, collection, true);
    }

    function _claim(
        address account,
        uint256[] calldata nftIds,
        address collection,
        bool isUnstaking
    ) internal {
        uint256 nftId;
        uint256 earned = 0;
        Stake memory staked;
        for (uint i = 0; i < nftIds.length; i++) {
            nftId = nftIds[i];
            staked = randomsStaked[nftId][collection];
            require(staked.owner == account, "not an nft staker, or not the original owner");
        }
        earned = _calculateEarningReturns(nftIds, collection, block.timestamp);
        for (uint i = 0; i < nftIds.length; i++) {
            nftId = nftIds[i];
            staked = randomsStaked[nftId][collection];            
            if (isUnstaking) {
                if (staked.lockupPeriod == LockupPeriod.sevenDays) {
                    require(
                        block.timestamp >= staked.staketime + 7 days,
                        "nft is still locked"
                    );
                    delete randomsStaked[nftId][collection];
                    emit nftRemoved(account, nftId, block.timestamp);
                    nftContract.transferFrom(address(this), account, nftId);
                } else if (staked.lockupPeriod == LockupPeriod.thirtyDays) {
                    require(
                        block.timestamp >= staked.staketime + 30 days,
                        "nft is still locked"
                    );
                    delete randomsStaked[nftId][collection];
                    emit nftRemoved(account, nftId, block.timestamp);
                    nftContract.transferFrom(address(this), account, nftId);
                } else {
                    delete randomsStaked[nftId][collection];
                    emit nftRemoved(account, nftId, block.timestamp);
                    nftContract.transferFrom(address(this), account, nftId);
                }
            } else {
                randomsStaked[nftId][collection].timestamp = uint48(block.timestamp);
            }
        }
    }


    //the date is the current epoch unix timestamp in seconds
    function earningInfo(
        uint256[] calldata nftIds,
        address collection,
        uint date
    ) public view returns (uint256[2] memory) {
        uint256 firstStakedAt = 0;
        uint256 earnRatePerDay = 0;
        uint256 earned = _calculateEarningReturns(nftIds, collection, date);
        uint256 nftId;
        for (uint i = 0; i < nftIds.length; i++) {
            nftId = nftIds[i];
            Stake memory staked = randomsStaked[nftId][collection];
            uint256 stakedAt = staked.timestamp;
            if (staked.lockupPeriod == LockupPeriod.sevenDays) {
                earnRatePerDay += 125;
                firstStakedAt = stakedAt;
            } else if (staked.lockupPeriod == LockupPeriod.thirtyDays) {
                earnRatePerDay += 200;
                firstStakedAt = stakedAt;
            } else {
                earnRatePerDay += 100;
                firstStakedAt = stakedAt;
            }
        }
        return [earned, earnRatePerDay / 10];
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function _calculateEarningReturns(
        uint256[] calldata nftIds,
        address collection,
        uint date
    ) internal view returns (uint256) {        
        uint256 earned = 0;
        uint256 nftId;
        for (uint i = 0; i < nftIds.length; i++) {
            nftId = nftIds[i];
            Stake memory staked = randomsStaked[nftId][collection];
            uint256 stakedAt = staked.timestamp;
            if (staked.lockupPeriod == LockupPeriod.sevenDays) {
                earned += (((date - stakedAt) / 1 days) * 125) / 10;
            } else if (staked.lockupPeriod == LockupPeriod.thirtyDays) {
                earned += ((date - stakedAt) / 1 days) * 20;
            } else {
                earned += ((date - stakedAt) / 1 days) * 10;
            }
        }
        return earned;
    }

    // should never be used inside of transaction because of gas fee
    function balanceOf(address account, address collection)
        public
        returns (uint256)
    {
        uint256 balance = 0;
        nftContract = ContractErc721(collection);
        uint256 supply = nftContract.totalSupply();
        for (uint i = 1; i <= supply; i++) {
            if (randomsStaked[i][collection].owner == account) {
                balance += 1;
            }
        }
        return balance;
    }

    // should never be used inside of transaction because of gas fee
    function tokensOfOwner(address account, address collection)
        public
        returns (uint256[] memory ownerTokens)
    {
        nftContract = ContractErc721(collection);
        uint256 supply = nftContract.totalSupply();
        uint256[] memory tmp = new uint256[](supply);
        uint256 index = 0;
        for (uint nftId = 1; nftId <= supply; nftId++) {
            if (randomsStaked[nftId][collection].owner == account) {
                tmp[index] = randomsStaked[nftId][collection].nftId;
                index += 1;
            }
        }
        uint256[] memory tokens = new uint256[](index);
        for (uint i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }
        return tokens;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send to staking like that");
        return IERC721Receiver.onERC721Received.selector;
    }
}