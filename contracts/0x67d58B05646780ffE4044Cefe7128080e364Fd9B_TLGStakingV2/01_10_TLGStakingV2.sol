// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IOldStaking.sol";
import "./interfaces/IMintable.sol";

contract TLGStakingV2 is Initializable, OwnableUpgradeable, IStaking {
    struct StakerReward {
        uint256 lastUpdated;
        uint256 unclaimed;
    }

    uint256 public constant ROUNDING_PRECISION = 1000;
    uint256 public lostPerDay;

    IOldStaking public oldStaking;
    IERC721Upgradeable public tlgNfts;
    IERC721Upgradeable public comic;
    IMintable public lost;

    mapping(uint256 => address) public userStakedGlitch;
    mapping(address => uint256[]) public stakedGlitches;
    mapping(address => uint256) public override stakedComic;
    mapping(address => StakerReward) public rewards;
    mapping(address => mapping(uint256 => uint256)) public stakedGlitchIndex;

    struct NumValue {
        uint256 value;
        bool exists;
    }

    struct BoolValue {
        bool value;
        bool exists;
    }

    /**
     * A mapping that remembers how many glitches an address has staked in the old
     * contract when first interacting with this contract. After that, this contract
     * will not accept new staked glitches in the old contract.
     */
    mapping(address => NumValue) public stakedGlitchesInOldContractInitially;

    /**
     * See `stakedInOldContractInitially`. This is the same just for comics.
     */
    mapping(address => BoolValue) public stakedComicInOldContractInitially;

    event DepositedGlitches(address indexed staker, uint256[] indexed ids);
    event DepositedComic(address indexed staker, uint256 indexed id);
    event WithdrawnGlitches(address indexed staker, uint256[] indexed ids);
    event WithdrawnComic(address indexed staker, uint256 indexed id);
    event ClaimedRewards(address indexed staker, uint256 indexed amount);
    event UpdateUnclaimedRewards(
        address indexed staker,
        uint256 indexed newReward,
        uint256 indexed oldReward,
        uint256 duration
    );

    function initialize(IOldStaking _oldStaking, IERC721Upgradeable _tlgNfts, IERC721Upgradeable _comic, IMintable _lost) external initializer {
        oldStaking = _oldStaking;
        tlgNfts = _tlgNfts;
        comic = _comic;
        lost = _lost;

        lostPerDay = 1;

        __Ownable_init();
    }

    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "TLGStakingV2: balance query for the zero address");
        return stakedGlitches[owner].length;
    }

    function ownerOf(uint256 tokenId) public override view returns (address) {
        return userStakedGlitch[tokenId];
    }

    function numberOfDepositedGlitches(address staker) public override view returns (uint256 amount) {
        return stakedGlitches[staker].length;
    }

    function numberOfDepositedGlitchesCombined(address staker) public view returns (uint256 amount) {
        return numberOfDepositedGlitches(staker) +
            min(oldStaking.numberOfDepositedGlitches(staker), stakedGlitchesInOldContractInitially[staker].value);
    }

    function hasComicStakedCombined(address staker) public view returns (bool) {
        bool stakedInOld = stakedComicInOldContractInitially[staker].value;
        if (oldStaking.stakedComic(staker) == 0) {
            stakedInOld = false;
        }

        return stakedComic[staker] != 0 || stakedInOld;
    }

    function depositComic(uint256 comicId) external {
        require(comicId != 0, "TLGStakingV2: Comic 0 currently not stakeable");
        require(!hasComicStakedCombined(msg.sender), "TLGStakingV2: Already staked one comic");

        _setStakedComicInOldContractInitially(msg.sender);
        _updateUnclaimedRewards(msg.sender);

        stakedComic[msg.sender] = comicId;
        comic.transferFrom(msg.sender, address(this), comicId);

        emit DepositedComic(msg.sender, comicId);
    }

    function withdrawComic(uint256 comicId) external {
        require(stakedComic[msg.sender] == comicId, "TLGStakingV2: Comic not staked");

        _updateUnclaimedRewards(msg.sender);

        delete stakedComic[msg.sender];
        comic.transferFrom(address(this), msg.sender, comicId);

        emit WithdrawnComic(msg.sender, comicId);
    }

    function depositGlitches(uint256[] calldata glitches) external {
        _setStakedGlitchesInOldContractInitially(msg.sender);
        _updateUnclaimedRewards(msg.sender);

        for (uint256 i = 0; i < glitches.length; i++) {
            // add glitch to the list and update staking info
            stakedGlitches[msg.sender].push(glitches[i]);
            stakedGlitchIndex[msg.sender][glitches[i]] = stakedGlitches[msg.sender].length - 1;
            userStakedGlitch[glitches[i]] = msg.sender;
            tlgNfts.transferFrom(msg.sender, address(this), glitches[i]);
        }

        emit DepositedGlitches(msg.sender, glitches);
    }

    function withdrawGlitches(uint256[] calldata _glitches) external {
        require(stakedGlitches[msg.sender].length > 0, "TLGStakingV2: No glitches staked");

        _updateUnclaimedRewards(msg.sender);

        for (uint256 i = 0; i < _glitches.length; i++) {
            require(userStakedGlitch[_glitches[i]] == msg.sender, "TLGStakingV2: You do not own this glitch");
            // remove glitch from stakedGlitches
            uint256 index = stakedGlitchIndex[msg.sender][_glitches[i]];
            if (stakedGlitches[msg.sender].length - 1 == index) {
                stakedGlitches[msg.sender].pop();
            } else {
                stakedGlitches[msg.sender][index] = stakedGlitches[msg.sender][stakedGlitches[msg.sender].length - 1];
                stakedGlitchIndex[msg.sender][stakedGlitches[msg.sender][index]] = index;
                stakedGlitches[msg.sender].pop();
            }
            // remove the staking info and the index
            delete stakedGlitchIndex[msg.sender][_glitches[i]];
            delete userStakedGlitch[_glitches[i]];

            tlgNfts.transferFrom(address(this), msg.sender, _glitches[i]);
        }

        emit WithdrawnGlitches(msg.sender, _glitches);
    }

    function claimRewards() external {
        require(rewards[msg.sender].lastUpdated != 0, "TLGStakingV2: Rewards have never been updated");
        _updateUnclaimedRewards(msg.sender);
        lost.mint(msg.sender, rewards[msg.sender].unclaimed);
        emit ClaimedRewards(msg.sender, rewards[msg.sender].unclaimed);
        rewards[msg.sender].unclaimed = 0;
    }

    function currentMultiplier(address staker) public view returns (uint256 amount) {
        uint256 numOfStakedGlitches = numberOfDepositedGlitchesCombined(staker);

        if (numOfStakedGlitches == 1) {
            return 1 * ROUNDING_PRECISION;
        }

        uint256 multi = (numOfStakedGlitches * ROUNDING_PRECISION) / 10 + ROUNDING_PRECISION;
        if (multi > 2 * ROUNDING_PRECISION) {
            multi = 2 * ROUNDING_PRECISION;
        }
        return multi;
    }

    function _setStakedGlitchesInOldContractInitially(address staker) internal {
        if (!stakedGlitchesInOldContractInitially[staker].exists) {
            stakedGlitchesInOldContractInitially[staker] = NumValue({
                value: oldStaking.numberOfDepositedGlitches(staker),
                exists: true
            });
        }
    }

    function _setStakedComicInOldContractInitially(address staker) internal {
        if (!stakedComicInOldContractInitially[staker].exists) {
            stakedComicInOldContractInitially[staker] = BoolValue({
                value: oldStaking.stakedComic(staker) != 0,
                exists: true
            });
        }
    }

    function _updateUnclaimedRewards(address staker) internal {
        uint256 newReward = _calculateNewRewards(staker);
        emit UpdateUnclaimedRewards(
            staker,
            newReward,
            rewards[staker].unclaimed,
            block.timestamp - rewards[staker].lastUpdated
        );
        rewards[staker].lastUpdated = block.timestamp;
        rewards[staker].unclaimed += newReward;
    }

    function _calculateNewRewards(address staker) internal view returns (uint256) {
        if (rewards[staker].lastUpdated == 0) {
            return 0;
        }
        uint256 numGlitches = numberOfDepositedGlitchesCombined(staker);
        uint256 newReward;
        uint256 diff = block.timestamp - rewards[staker].lastUpdated;
        uint256 daysDiff = diff / 1 days;
        uint256 dailyReward = daysDiff * lostPerDay * numGlitches;

        uint256 multi = currentMultiplier(staker);
        dailyReward = dailyReward * multi;
        newReward = (dailyReward * 1e18) / ROUNDING_PRECISION;

        if (hasComicStakedCombined(staker)) {
            newReward = (newReward * 12) / 10;
        }

        return newReward;
    }

    function calculateRewards(address staker) external view returns (uint256) {
        uint256 newReward = _calculateNewRewards(staker);
        return newReward + rewards[staker].unclaimed;
    }

    function addRewards(address[] memory stakers, uint256[] memory amounts, bool sub) external onlyOwner {
        require(stakers.length == amounts.length, "TLGStakingV2: Not same length!");
        for (uint256 i = 0; i < stakers.length; i++) {
            _setStakedGlitchesInOldContractInitially(stakers[i]);
            _setStakedComicInOldContractInitially(stakers[i]);
            if (sub) {
                rewards[stakers[i]].unclaimed -= amounts[i];
            } else {
                rewards[stakers[i]].unclaimed += amounts[i];
            }
            rewards[stakers[i]].lastUpdated = block.timestamp;
        }
    }

    function setInitialDataFromOldContract(address[] memory stakers) external onlyOwner {
        for (uint256 i = 0; i < stakers.length; i++) {
            _setStakedGlitchesInOldContractInitially(stakers[i]);
            _setStakedComicInOldContractInitially(stakers[i]);
        }
    }

    /**
     * Just for utility
     */
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a >= b ? b : a;
    }
}