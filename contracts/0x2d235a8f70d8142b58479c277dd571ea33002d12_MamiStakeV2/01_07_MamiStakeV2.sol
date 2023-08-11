pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface RewardsToken {
    function mint(address, uint256) external;
}

contract MamiStakeV2 is Ownable, ReentrancyGuard {
    Pool[] public pools;

    mapping(uint256 => uint256[]) public poolStakeTokenIds;

    mapping(uint256 => uint256) public poolStakeAmount;

    mapping(uint256 => mapping(uint256 => PoolStake)) public poolStakes;

    uint256 public start;

    struct PoolStake {
        bool staked;
        uint256 last;
        uint256 remainRewardsAmount;
    }

    struct Pool {
        address needNftAddress;
        address needTokenAddress;
        uint256 needTokenAmount;
        uint256 rate;
        address rewardsTokenAddress;
        uint256[] sharePoolIds;
    }

    constructor() {
        start = block.number;
        uint256[] memory sharePoolIds0 = new uint256[](1);
        sharePoolIds0[0] = 1;
        uint256[] memory sharePoolIds1 = new uint256[](1);
        sharePoolIds1[0] = 0;
        //mainnet
        address lmc = 0x8983CF891867942d06AD6CEb9B9002de860E202d;
        address ssr = 0xbc77f3A44f19113845B2870ce9E72f612D77DC17;
        addPool(ssr, lmc, 23000 ether, 0 ether, lmc, sharePoolIds0);
        addPool(ssr, address(0), 0, 0 ether, lmc, sharePoolIds1);

        //test
        // address lmc = 0x42A282eCea54dF092d32D1937e9B83C769DDF1c6;
        // address ssr = 0x7023ba9cFA134E5c781a9278Fc7486467B221D5E;
        // addPool(ssr, lmc, 23000 ether, 6 ether, lmc, sharePoolIds0);
        // addPool(ssr, address(0), 0, 3.3 ether, lmc, sharePoolIds1);
    }

    function checkStaked(
        uint256 _poolId,
        uint256[] calldata _tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory stakeds = new bool[](_tokenIds.length);
        Pool storage pool = pools[_poolId];
        uint256[] memory sharePoolIds = pool.sharePoolIds;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            PoolStake storage poolStake = poolStakes[_poolId][_tokenIds[i]];
            if (poolStake.staked) {
                stakeds[i] = true;
                continue;
            }

            for (uint256 y = 0; y < pool.sharePoolIds.length; y++) {
                if (poolStakes[sharePoolIds[y]][_tokenIds[i]].staked) {
                    stakeds[i] = true;
                    break;
                }
            }
        }
        return stakeds;
    }

    function stake(
        uint256 _poolId,
        uint256[] calldata _tokenIds,
        uint256[] calldata _syncTokenIds
    ) external {
        _sync(_poolId, _syncTokenIds);
        Pool storage pool = pools[_poolId];
        uint256[] memory sharePoolIds = pool.sharePoolIds;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _msgSender() ==
                    IERC721(pool.needNftAddress).ownerOf(_tokenIds[i]),
                "You dont owner this nft"
            );
            PoolStake storage poolStake = poolStakes[_poolId][_tokenIds[i]];
            require(!poolStake.staked, "The nft already staked");

            for (uint256 y = 0; y < pool.sharePoolIds.length; y++) {
                require(
                    !poolStakes[sharePoolIds[y]][_tokenIds[i]].staked,
                    "The nft already staked"
                );
            }

            poolStake.staked = true;
            poolStake.last = block.number;
            poolStakeTokenIds[_poolId].push(_tokenIds[i]);
        }
        poolStakeAmount[_poolId] += _tokenIds.length;
        if (pool.needTokenAddress != address(0)) {
            IERC20(pool.needTokenAddress).transferFrom(
                _msgSender(),
                address(this),
                pool.needTokenAmount * _tokenIds.length
            );
        }
    }

    function unStake(
        uint256 _poolId,
        uint256[] calldata _tokenIds,
        uint256[] calldata _syncTokenIds
    ) external {
        claim(_poolId, _syncTokenIds, _syncTokenIds);
        Pool storage pool = pools[_poolId];

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _msgSender() ==
                    IERC721(pool.needNftAddress).ownerOf(_tokenIds[i]),
                "You dont owner this nft"
            );
            PoolStake storage poolStake = poolStakes[_poolId][_tokenIds[i]];
            require(poolStake.staked, "The nft must staked");

            poolStake.staked = false;
        }
        poolStakeAmount[_poolId] -= _tokenIds.length;
        if (pool.needTokenAddress != address(0)) {
            IERC20(pool.needTokenAddress).transfer(
                _msgSender(),
                pool.needTokenAmount * _tokenIds.length
            );
        }
    }

    function claim(
        uint256 _poolId,
        uint256[] calldata _tokenIds,
        uint256[] calldata _syncTokenIds
    ) public {
        _sync(_poolId, _syncTokenIds);
        Pool storage pool = pools[_poolId];
        uint256 rewardsAmount = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _msgSender() ==
                    IERC721(pool.needNftAddress).ownerOf(_tokenIds[i]),
                "You dont owner this nft"
            );
            PoolStake storage poolStake = poolStakes[_poolId][_tokenIds[i]];
            require(poolStake.staked, "The nft must staked");
            rewardsAmount += poolStake.remainRewardsAmount;
            poolStake.remainRewardsAmount = 0;
        }
        RewardsToken(pool.rewardsTokenAddress).mint(
            _msgSender(),
            rewardsAmount
        );
    }

    function getRewardsAmount(
        uint256 _poolId,
        uint256[] calldata _tokenIds
    ) public view returns (uint256) {
        uint256 rewardsAmount = 0;
        Pool storage pool = pools[_poolId];
        uint256 totalRewardsAmount = (block.number - start) * pool.rate;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            PoolStake storage poolStake = poolStakes[_poolId][_tokenIds[i]];
            if (poolStake.staked) {
                rewardsAmount +=
                    poolStake.remainRewardsAmount +
                    (totalRewardsAmount * (block.number - poolStake.last)) /
                    (block.number - start) /
                    poolStakeAmount[_poolId];
            }
        }
        return rewardsAmount;
    }

    function _sync(
        uint256 _poolId,
        uint256[] memory _syncTokenIds
    ) private nonReentrant {
        Pool storage pool = pools[_poolId];
        uint256 totalRewardsAmount = (block.number - start) * pool.rate;
        for (uint256 i = 0; i < _syncTokenIds.length; i++) {
            uint256 tokenId = _syncTokenIds[i];
            PoolStake storage poolStake = poolStakes[_poolId][tokenId];
            if (block.number == poolStake.last) {
                continue;
            }
            if (poolStake.staked) {
                poolStake.remainRewardsAmount +=
                    (totalRewardsAmount * (block.number - poolStake.last)) /
                    (block.number - start) /
                    poolStakeAmount[_poolId];
                poolStake.last = block.number;
            }
        }
    }

    function addPool(
        address _needNftAddress,
        address _needTokenAddress,
        uint256 _needTokenAmount,
        uint256 _rate,
        address _rewardsTokenAddress,
        uint256[] memory _sharePoolIds
    ) public onlyOwner {
        pools.push(
            Pool(
                _needNftAddress,
                _needTokenAddress,
                _needTokenAmount,
                _rate,
                _rewardsTokenAddress,
                _sharePoolIds
            )
        );
    }

    function editPool(
        uint256 _poolId,
        uint256 _rate,
        address _rewardsTokenAddress,
        uint256[] memory _sharePoolIds
    ) external onlyOwner {
        _sync(_poolId, poolStakeTokenIds[_poolId]);
        Pool storage pool = pools[_poolId];
        pool.rate = _rate;
        pool.rewardsTokenAddress = _rewardsTokenAddress;
        pool.sharePoolIds = _sharePoolIds;
    }
}