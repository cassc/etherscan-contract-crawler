// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/INodeRewardVault.sol";
import "./interfaces/IValidatorNft.sol";

/**
 * @title NodeRewardVault for managing rewards
 */
contract NodeRewardVault is INodeRewardVault, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IValidatorNft private _nftContract;

    RewardMetadata[] public cumArr;
    uint256 public unclaimedRewards;
    uint256 public daoRewards;
    uint256 public lastPublicSettle;
    uint256 public publicSettleLimit;

    uint256 private _comission;
    uint256 private _tax;
    address private _dao;
    address private _authority;
    address private _aggregatorProxyAddress;

    event ComissionChanged(uint256 _before, uint256 _after);
    event TaxChanged(uint256 _before, uint256 _after);
    event DaoChanged(address _before, address _after);
    event AuthorityChanged(address _before, address _after);
    event AggregatorChanged(address _before, address _after);
    event PublicSettleLimitChanged(uint256 _before, uint256 _after);
    event RewardClaimed(address _owner, uint256 _amount);
    event Transferred(address _to, uint256 _amount);
    event Settle(uint256 _blockNumber, uint256 _settleRewards);

    modifier onlyAggregator() {
        require(_aggregatorProxyAddress == msg.sender, "Not allowed to touch funds");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    function initialize(address nftContract_) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _nftContract = IValidatorNft(nftContract_);
        _aggregatorProxyAddress = address(0x1);
        _dao = address(0xee09C9a517ecE6Bedd2EbC766938e39367F37753);
        _authority = address(0x2C21721627aad3F43606836FEC22142c5e1edEe2);
        _comission = 1000;
        _tax = 0;

        RewardMetadata memory r = RewardMetadata({
            value: 0,
            height: 0
        });

        cumArr.push(r);
        unclaimedRewards = 0;
        lastPublicSettle = 0;
        publicSettleLimit = 216000;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice Computes the reward a nft has
     * @param tokenId - tokenId of the validator nft
     */
    function _rewards(uint256 tokenId) private view returns (uint256) {
        uint256 gasHeight = _nftContract.gasHeightOf(tokenId);
        uint256 low = 0;
        uint256 high = cumArr.length;

        while (low < high) {
            uint256 mid = (low + high) >> 1;

            if (cumArr[mid].height > gasHeight) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will use it.
        return cumArr[cumArr.length - 1].value - cumArr[low - 1].value;
    }

    /**
     * @notice Settles outstanding rewards
     * @dev Current active validator nft will equally recieve all rewards earned in this era
     */
    function _settle() private {
        uint256 outstandingRewards = address(this).balance - unclaimedRewards - daoRewards;
        if (outstandingRewards == 0 || cumArr[cumArr.length - 1].height == block.number) {
            return;
        }

        uint256 daoReward = (outstandingRewards * _comission) / 10000;
        daoRewards += daoReward;
        outstandingRewards -= daoReward;
        unclaimedRewards += outstandingRewards;

        uint256 averageRewards = outstandingRewards / _nftContract.totalSupply();
        uint256 currentValue = cumArr[cumArr.length - 1].value + averageRewards;
        RewardMetadata memory r = RewardMetadata({
            value: currentValue,
            height: block.number
        });
        cumArr.push(r);

        emit Settle(block.number, averageRewards);
    }

    /**
     * @notice Returns the address of the validator nft
     */
    function nftContract() external view override returns (address) {
        return address(_nftContract);
    }

    /**
     * @notice Computes the reward a nft has
     * @param tokenId - tokenId of the validator nft
     */
    function rewards(uint256 tokenId) external view override returns (uint256) {
        return _rewards(tokenId);
    }

    /**
     * @notice Gets the last recorded height which rewards was last dispersed + 1
     */
    function rewardsHeight() external view override returns (uint256) {
        return cumArr[cumArr.length - 1].height + 1;
    }

    /**
     * @notice Returns an array of recent `RewardMetadata`
     * @param amt - The amount of `RewardMetdata` to return, ordered according to the most recent
     */
    function rewardsAndHeights(uint256 amt) external view override returns (RewardMetadata[] memory) {
        if (amt >= cumArr.length) {
            return cumArr;
        }

        RewardMetadata[] memory r = new RewardMetadata[](amt);

        for (uint256 i = 0; i < amt; i++) {
            r[i] = cumArr[cumArr.length - 1 - i];
        }

        return r;
    }

    /**
     * @notice Returns the amount of comission on validator rewards
     */
    function comission() external view override returns (uint256) {
        return _comission;
    }

    /**
     * @notice Returns the amount of tax on nft trades
     */
    function tax() external view override returns (uint256) {
        return _tax;
    }

    /**
     * @notice Returns the dao's multisig address
     */
    function dao() external view override returns (address) {
        return _dao;
    }

    /**
     * @notice Returns the authority's (in-charge of signing) public address
     */
    function authority() external view override returns (address) {
        return _authority;
    }

    /**
     * @notice Returns the address of the Aggregator
     */
    function aggregator() external view override returns (address) {
        return _aggregatorProxyAddress;
    }

    /**
     * @notice Settles outstanding rewards
     * @dev Current active validator nft will equally recieve 
     *      all rewards earned in this era
     */
    function settle() external override onlyAggregator {
        _settle();
    }

    /**
     * @notice Settles outstanding rewards in the event there is no change in amount of validators
     * @dev Current active validator nft will equally recieve 
     *      all rewards earned in this era
     */
    function publicSettle() external override {
        // prevent spam attack
        if (lastPublicSettle + publicSettleLimit > block.number) {
            return;
        }

        _settle();
        lastPublicSettle = block.number;
    }

    //slither-disable-next-line arbitrary-send
    function transfer(uint256 amount, address to) private {
        require(to != address(0), "Recipient address provided invalid");
        payable(to).transfer(amount);
        emit Transferred(to, amount);
    }

    /**
     * @notice Claims the rewards belonging to a validator nft and transfer it to the owner
     * @param tokenId - tokenId of the validator nft
     */
    function claimRewards(uint256 tokenId) external override nonReentrant onlyAggregator {
        address owner = _nftContract.ownerOf(tokenId);
        uint256 nftRewards = _rewards(tokenId);

        unclaimedRewards -= nftRewards;
        transfer(nftRewards, owner);

        emit RewardClaimed(owner, nftRewards);
    }

    /**
     * @notice Claims the rewards belonging to the dao
     */
    function claimDao() external nonReentrant {
        transfer(daoRewards, _dao);
        daoRewards = 0;
    }

    /**
     * @notice Sets the comission. Comission is currently used to fund hardware costs
     */
    function setComission(uint256 comission_) external onlyOwner {
        require(comission_ < 10000, "Comission cannot be 100%");
        emit ComissionChanged(_comission, comission_);
        _comission = comission_;
    }

    /**
     * @notice Sets the tax for nft trading
     */
    function setTax(uint256 tax_) external onlyOwner {
        require(tax_ < 10000, "Tax cannot be 100%");
        emit TaxChanged(_tax, tax_);
        _tax = tax_;
    }

    /**
     * @notice Sets the dao address. dao funds the hardware for running the validator
     */
    function setDao(address dao_) external onlyOwner {
        require(dao_ != address(0), "DAO address provided invalid");
        emit DaoChanged(_dao, dao_);
        _dao = dao_;
    }

    /**
     * @notice Sets the authority address. Authority is in charge of signing & authorizing the launch of validator nodes
     */
    function setAuthority(address authority_) external onlyOwner {
        require(authority_ != address(0), "Authority address provided invalid");
        emit AuthorityChanged(_authority, authority_);
        _authority = authority_;
    }

    /**
     * @notice Sets the aggregator address
     */
    function setAggregator(address aggregatorProxyAddress_) external onlyOwner {
        require(aggregatorProxyAddress_ != address(0), "Aggregator address provided invalid");
        emit AggregatorChanged(_aggregatorProxyAddress, aggregatorProxyAddress_);
        _aggregatorProxyAddress = aggregatorProxyAddress_;
    }

    /**
     * @notice Sets the `PublicSettleLimit`. Determines how frequently this contract can be spammed
     */
    function setPublicSettleLimit(uint256 publicSettleLimit_) external onlyOwner {
        emit PublicSettleLimitChanged(publicSettleLimit, publicSettleLimit_);
        publicSettleLimit = publicSettleLimit_;
    }

    receive() external payable{}
}