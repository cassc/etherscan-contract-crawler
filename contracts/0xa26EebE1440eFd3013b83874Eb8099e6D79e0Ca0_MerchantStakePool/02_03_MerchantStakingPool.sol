// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";
import "./Mining.sol";

struct Merchant {
    //uint    id;
    address account;
    bool isMerchant;
    //uint    merchantMargin;
}

contract MerchantStakePool is StakingPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 internal constant _DOTC_ = "DOTC";

    address public dotcAddr;

    mapping(address => string) public links; //tg link
    mapping(uint256 => Merchant) public merchants; //id =>Merchant  id from 1...
    mapping(address => uint256) public merchantIds; //address =>id
    uint256 public maxMerchantID;
    uint256 public merchantCount;

    function __MerchantStakePool_init(
        address _governor,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _ecoAddr,
        address _dotcAddr
    ) public initializer {
        if (_rewardsDistribution == address(this)) {
            require(
                _rewardsToken != _stakingToken,
                "reward must diff stakingtoken"
            );
        }
        __ReentrancyGuard_init_unchained();
        __Governable_init_unchained(_governor);
        __StakingPool_init_unchained(
            _rewardsDistribution,
            _rewardsToken,
            _stakingToken,
            _ecoAddr
        );
        __MerchantStakePool_init_unchained(_dotcAddr);
    }

    function __MerchantStakePool_init_unchained(address _dotcAddr)
        internal
        governance
        initializer
    {
        dotcAddr = _dotcAddr;
    }

    function setPara(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _ecoAddr
    ) public virtual governance {
        __StakingPool_init_unchained(
            _rewardsDistribution,
            _rewardsToken,
            _stakingToken,
            _ecoAddr
        );
    }

    function punish(
        address from,
        address to,
        uint256 vol
    ) external virtual updateReward(from) updateReward(to) {
        require(msg.sender == dotcAddr, "only DOTC");
        uint256 amt = _balances[from];
        require(amt >= vol, "stake must GT punish vol");
        _balances[from] = amt.sub(vol);
        //_balances[to] = _balances[to].add(vol);
        stakingToken.safeTransfer(to, vol);
        emit Punish(from, to, vol);
    }

    event Punish(address from, address to, uint256 amt);

    function stake(uint256 amount) public virtual override {
        require(isMerchant(msg.sender), "only Merchant");
        super.stake(amount);
    }

    function withdraw(uint256 amount) public virtual override {
        require(!isMerchant(msg.sender), "Merchant can't withdraw");
        super.withdraw(amount);
    }

    function isMerchant(address account) public view returns (bool) {
        bool ret = false;
        uint256 id = merchantIds[account];
        if (id > 0) ret = merchants[id].isMerchant;
        return ret;
    }

    function addMerchant_(address[] calldata account_, string[] calldata links_)
        external
        governance
    {
        uint256 maxID = maxMerchantID;
        uint256 count = 0;
        uint256 curID;
        //Merchant memory merchant;
        for (uint256 i = 0; i < account_.length; i++) {
            if (merchantIds[account_[i]] == 0) {
                maxID++;
                curID = maxID;
                merchantIds[account_[i]] = curID;
                count++;
            } else {
                curID = merchantIds[account_[i]];
                if (!merchants[curID].isMerchant) {
                    count++;
                }
            }
            merchants[curID] = Merchant(account_[i], true);
            links[account_[i]] = links_[i];
        }
        if (maxID != maxMerchantID) maxMerchantID = maxID;
        merchantCount = merchantCount.add(count);
        emit AddMerchant(account_, links_);
    }

    event AddMerchant(address[] account, string[] links);

    function delMerchant_(address[] calldata account_) external governance {
        uint256 curID;
        uint256 count = 0;
        for (uint256 i = 0; i < account_.length; i++) {
            curID = merchantIds[account_[i]];
            if (curID > 0) {
                if (merchants[curID].isMerchant) {
                    merchants[curID].isMerchant = false;
                    count++;
                }
            }
        }
        merchantCount = merchantCount.sub(count);
        emit DelMerchant(account_);
    }

    event DelMerchant(address[] account);

    // Reserved storage space to allow for layout changes in the future.
    uint256[45] private ______gap;
}