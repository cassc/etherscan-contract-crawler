// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "./interfaces/IBabyBirdez.sol";
import "./interfaces/ISeedToken.sol";
import "hardhat/console.sol";

contract Breeder is Ownable {
    event SeedClaimed(
        address indexed user,
        uint256 indexed tokenId,
        uint256 amount
    );

    ISeedToken public immutable seed;
    IERC721Enumerable public immutable genesis;
    IBabyBirdez public immutable baby;

    uint256 public immutable breedStart;

    // Operation costs
    uint256 public constant BREEDING_COST = 600 * (10**18);
    uint256 public constant NAME_COST = 300 * (10**18);
    uint256 public constant BIO_COST = 100 * (10**18);

    // Seed drip per token, per day
    uint256 public constant SEED_PER_DAY = 10 * (10**18);

    // Max seed drip from this contract
    uint256 public constant SEED_AMOUNT = 48_654_500 * (10**18);

    // Max totalSupply of mintable Baby
    uint256 public maxBreedableBaby = 5000;

    // Total Seed claimed from this contract
    uint256 public totalSeedClaimed;

    // Genesis TokenId -> Seed Claimed
    mapping(uint256 => uint256) public seedClaimed;

    // Genesis TokenID -> Custom Bio
    mapping(uint256 => string) public bio;
    // Genesis TokenID -> Custom Name
    mapping(uint256 => string) public name;

    modifier onlyGenesisOwner(uint256 _tokenId) {
        address _tokenOwner = genesis.ownerOf(_tokenId);
        require(msg.sender == _tokenOwner, "not-genesis-owner");
        _;
    }

    constructor(
        ISeedToken _seed,
        IERC721Enumerable _genesis,
        IBabyBirdez _baby
    ) {
        require(address(_seed) != address(0), "invalid-token");
        require(address(_genesis) != address(0), "invalid-genesis");
        require(address(_baby) != address(0), "invalid-baby");

        seed = _seed;
        genesis = _genesis;
        baby = _baby;

        breedStart = block.timestamp - 30 days;
    }

    function pendingRewards(uint256 _tokenId) public view returns (uint256) {
        uint256 _seedPerSec = SEED_PER_DAY / 1 days;
        uint256 _elapsed = block.timestamp - breedStart;
        uint256 _pending = (_seedPerSec * _elapsed) - seedClaimed[_tokenId];
        if (_pending + totalSeedClaimed > SEED_AMOUNT) {
            _pending = SEED_AMOUNT - totalSeedClaimed;
        }
        return _pending;
    }

    function allPendingRewards(address _user) external view returns (uint256) {
        uint256[] memory _ids = _getGenesisIds(_user);
        uint256 _allPendingRewards;
        for (uint256 i = 0; i < _ids.length; i++) {
            _allPendingRewards += pendingRewards(_ids[i]);
        }
        if (_allPendingRewards + totalSeedClaimed > SEED_AMOUNT) {
            _allPendingRewards = SEED_AMOUNT - totalSeedClaimed;
        }
        return _allPendingRewards;
    }

    function claim(uint256 _tokenId) external onlyGenesisOwner(_tokenId) {
        _claim(_tokenId);
    }

    function setBio(uint256 _tokenId, string memory _text)
        external
        onlyGenesisOwner(_tokenId)
    {
        require(
            seed.balanceOf(msg.sender) >= BIO_COST,
            "insufficent-seed-tokens"
        );

        _burn(msg.sender, BIO_COST);
        bio[_tokenId] = _text;
    }

    function setName(uint256 _tokenId, string memory _text)
        external
        onlyGenesisOwner(_tokenId)
    {
        require(
            seed.balanceOf(msg.sender) >= NAME_COST,
            "insufficent-seed-tokens"
        );
        _burn(msg.sender, NAME_COST);
        name[_tokenId] = _text;
    }

    function claimAll() external {
        uint256[] memory _ids = _getGenesisIds(msg.sender);
        for (uint256 i = 0; i < _ids.length; i++) {
            _claim(_ids[i]);
        }
    }

    function setMaxBreedable(uint256 _newLimit) external onlyOwner {
        maxBreedableBaby = _newLimit;
    }

    function breed(uint256 _numberOfTokens) external {
        require(_getGenesisCount(msg.sender) >= 2, "not-enough-genesis");

        uint256 _maxLeft = maxBreedableBaby - baby.totalSupply();
        if (_numberOfTokens > _maxLeft) _numberOfTokens = _maxLeft;
        if (_numberOfTokens > 0) {
            uint256 _cost = _numberOfTokens * BREEDING_COST;
            require(
                seed.balanceOf(msg.sender) >= _cost,
                "insufficent-seed-tokens"
            );
            _burn(msg.sender, _cost);
            baby.mintTo(msg.sender, _numberOfTokens);
        }
    }

    function _mint(address _to, uint256 _amount) internal {
        seed.mint(_to, _amount);
    }

    function _burn(address _to, uint256 _amount) internal {
        seed.burn(_to, _amount);
    }

    function _claim(uint256 _tokenId) internal {
        uint256 _pending = pendingRewards(_tokenId);
        if (_pending != 0) {
            totalSeedClaimed += _pending;
            seedClaimed[_tokenId] += _pending;
            emit SeedClaimed(msg.sender, _tokenId, _pending);
            _mint(msg.sender, _pending);
        }
    }

    function _getGenesisCount(address _owner)
        internal
        view
        returns (uint256 _count)
    {
        _count = genesis.balanceOf(_owner);
    }

    function _getGenesisIds(address _owner)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 _count = _getGenesisCount(_owner);
        uint256[] memory _ids = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++)
            _ids[i] = genesis.tokenOfOwnerByIndex(_owner, i);

        return _ids;
    }
}