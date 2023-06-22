// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { ReentrancyGuard } from "./external/openzeppelin/ReentrancyGuard.sol";

import { StableMath } from "./libraries/StableMath.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { Ownable } from "./abstract/Ownable.sol";
import { Lockable } from "./abstract/Lockable.sol";

/**
 * @title   SynapseVesting
 * @notice  Synapse Network Vesting contract
 * @dev     Vesting is constantly releasing tokens every block every second
 */
contract SynapseVesting is Ownable, Lockable, ReentrancyGuard {
    using StableMath for uint256;

    /// @notice address of Synapse Network token
    address public snpToken;
    /// @notice total tokens vested in contract
    /// @dev tokens from not initialized sale contracts are not included
    uint256 public totalVested;
    /// @notice total tokens already claimed form vesting
    uint256 public totalClaimed;
    /// @notice staking contract address
    /// @dev set by Owner, for claimAndStake
    address public stakingAddress;

    struct Vest {
        uint256 dateStart; // start of claiming, can claim startTokens
        uint256 dateEnd; // after it all tokens can be claimed
        uint256 totalTokens; // total tokens to claim
        uint256 startTokens; // tokens to claim on start
        uint256 claimedTokens; // tokens already claimed
    }
    /// @notice storage of vestings
    Vest[] internal vestings;
    /// @notice map of vestings for user
    mapping(address => uint256[]) internal user2vesting;

    struct SaleContract {
        address[] contractAddresses; // list of cross sale contracts from sale round
        uint256 tokensPerCent; // amount of tokens per cent for sale round
        uint256 maxAmount; // max amount in USD cents for sale round
        uint256 percentOnStart; // percent of tokens to claim on start
        uint256 startDate; // start of claiming, can claim start tokens
        uint256 endDate; // after it all tokens can be claimed
    }
    /// @notice list of sale contract that will be checked
    SaleContract[] internal saleContracts;

    /// @notice map of users that initialized vestings from sale contracts
    mapping(address => bool) public vestingAdded;
    /// @notice map of users that were refunded after sales
    mapping(address => bool) public refunded;

    /// @dev events
    event Claimed(address indexed user, uint256 amount);
    event Vested(address indexed user, uint256 totalAmount, uint256 endDate);

    /**
     * @dev Contract initiator
     * @param _token address of SNP token
     */
    function init(address _token) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        require(snpToken == address(0), "Init already done");
        snpToken = _token;
    }

    /**
     * @dev Add multiple vesting to contract by arrays of data
     * @param _users[] addresses of holders
     * @param _startTokens[] tokens that can be withdrawn at startDate
     * @param _totalTokens[] total tokens in vesting
     * @param _startDate date from when tokens can be claimed
     * @param _endDate date after which all tokens can be claimed
     */
    function massAddHolders(
        address[] calldata _users,
        uint256[] calldata _startTokens,
        uint256[] calldata _totalTokens,
        uint256 _startDate,
        uint256 _endDate
    ) external onlyOwner whenNotLocked {
        uint256 len = _users.length; //cheaper to use one variable
        require((len == _startTokens.length) && (len == _totalTokens.length), "data size mismatch");
        require(_startDate < _endDate, "startDate cannot exceed endDate");
        uint256 i;
        for (i; i < len; i++) {
            _addHolder(_users[i], _startTokens[i], _totalTokens[i], _startDate, _endDate);
        }
    }

    /**
     * @dev Add new vesting to contract
     * @param _user address of a holder
     * @param _startTokens how many tokens are claimable at start date
     * @param _totalTokens total number of tokens in added vesting
     * @param _startDate date from when tokens can be claimed
     * @param _endDate date after which all tokens can be claimed
     */
    function _addHolder(
        address _user,
        uint256 _startTokens,
        uint256 _totalTokens,
        uint256 _startDate,
        uint256 _endDate
    ) internal {
        require(_user != address(0), "user address cannot be 0");
        Vest memory v;
        v.startTokens = _startTokens;
        v.totalTokens = _totalTokens;
        v.dateStart = _startDate;
        v.dateEnd = _endDate;

        totalVested += _totalTokens;
        vestings.push(v);
        user2vesting[_user].push(vestings.length); // we are skipping index "0" for reasons
        emit Vested(_user, _totalTokens, _endDate);
    }

    /**
     * @dev Claim tokens from msg.sender vestings
     */
    function claim() external {
        _claim(msg.sender, msg.sender);
    }

    /**
     * @dev Claim tokens from msg.sender vestings to external address
     * @param _target transfer address for claimed tokens
     */
    function claimTo(address _target) external {
        _claim(msg.sender, _target);
    }

    /**
     * @dev Claim and stake claimed tokens directly in staking contract
     *      Ask staking contract if user is not in withdrawing state
     */
    function claimAndStake() external {
        require(stakingAddress != address(0), "Staking contract not configured");
        require(IStaking(stakingAddress).canStakeTokens(msg.sender), "Unable to stake");
        uint256 amt = _claim(msg.sender, stakingAddress);
        IStaking(stakingAddress).onClaimAndStake(msg.sender, amt);
    }

    /**
     * @dev internal claim function
     * @param _user address of holder
     * @param _target where tokens should be send
     * @return amt number of tokens claimed
     */
    function _claim(address _user, address _target) internal nonReentrant returns (uint256 amt) {
        require(_target != address(0), "Claim, then burn");
        if (!vestingAdded[_user] && !refunded[_user]) {
            _addVesting(_user);
        }
        uint256 len = user2vesting[_user].length;
        require(len > 0, "No vestings for user");
        uint256 cl;
        uint256 i;
        for (i; i < len; i++) {
            Vest storage v = vestings[user2vesting[_user][i] - 1];
            cl = _claimable(v);
            v.claimedTokens += cl;
            amt += cl;
        }
        if (amt > 0) {
            totalClaimed += amt;
            _transfer(_target, amt);
            emit Claimed(_user, amt);
        } else revert("Nothing to claim");
    }

    /**
     * @dev Internal function to send out claimed tokens
     * @param _user address that we send tokens
     * @param _amt amount of tokens
     */
    function _transfer(address _user, uint256 _amt) internal {
        require(IERC20(snpToken).transfer(_user, _amt), "Token transfer failed");
    }

    /**
     * @dev Count how many tokens can be claimed from vesting to date
     * @param _vesting Vesting object
     * @return canWithdraw number of tokens
     */
    function _claimable(Vest memory _vesting) internal view returns (uint256 canWithdraw) {
        uint256 currentTime = block.timestamp;
        if (_vesting.dateStart > currentTime) return 0;
        // we are somewhere in the middle
        if (currentTime < _vesting.dateEnd) {
            // how much time passed (as fraction * 10^18)
            // timeRatio = (time passed * 1e18) / duration
            uint256 timeRatio = (currentTime - _vesting.dateStart).divPrecisely(_vesting.dateEnd - _vesting.dateStart);
            // how much tokens we can get in total to date
            canWithdraw = (_vesting.totalTokens - _vesting.startTokens).mulTruncate(timeRatio) + _vesting.startTokens;
        }
        // time has passed, we can take all tokens
        else {
            canWithdraw = _vesting.totalTokens;
        }
        // but maybe we take something earlier?
        canWithdraw -= _vesting.claimedTokens;
    }

    /**
     * @dev Read number of claimable tokens by user and vesting no
     * @param _user address of holder
     * @param _id his vesting number (starts from 0)
     * @return amount number of tokens
     */
    function getClaimable(address _user, uint256 _id) external view returns (uint256 amount) {
        amount = _claimable(vestings[user2vesting[_user][_id] - 1]);
    }

    /**
     * @dev Read total amount of tokens that user can claim to date from all vestings
     *      Function also includes tokens to claim from sale contracts that were not
     *      yet initiated for user.
     * @param _user address of holder
     * @return amount number of tokens
     */
    function getAllClaimable(address _user) public view returns (uint256 amount) {
        uint256 len = user2vesting[_user].length;
        uint256 i;
        for (i; i < len; i++) {
            amount += _claimable(vestings[user2vesting[_user][i] - 1]);
        }

        if (!vestingAdded[_user]) {
            amount += _claimableFromSaleContracts(_user);
        }
    }

    /**
     * @dev Extract all the vestings for the user
     *      Also extract not initialized vestings from
     *      sale contracts.
     * @param _user address of holder
     * @return v array of Vest objects
     */
    function getVestings(address _user) external view returns (Vest[] memory) {
        // array of pending vestings
        Vest[] memory pV;

        if (!vestingAdded[_user]) {
            pV = _vestingsFromSaleContracts(_user);
        }
        uint256 pLen = pV.length;
        uint256 len = user2vesting[_user].length;
        Vest[] memory v = new Vest[](len + pLen);

        // copy normal vestings
        uint256 i;
        for (i; i < len; i++) {
            v[i] = vestings[user2vesting[_user][i] - 1];
        }

        // copy not initialized vestings
        if (!vestingAdded[_user]) {
            uint256 j;
            for (j; j < pLen; j++) {
                v[i + j] = pV[j];
            }
        }

        return v;
    }

    /**
     * @dev Read total number of vestings registered
     * @return number of registered vestings on contract
     */
    function getVestingsCount() external view returns (uint256) {
        return vestings.length;
    }

    /**
     * @dev Read single registered vesting entry
     * @param _id index of vesting in storage
     * @return Vest object
     */
    function getVestingByIndex(uint256 _id) external view returns (Vest memory) {
        return vestings[_id];
    }

    /**
     * @dev Read registered vesting list by range from-to
     * @param _start first index
     * @param _end last index
     * @return array of Vest objects
     */
    function getVestingsByRange(uint256 _start, uint256 _end) external view returns (Vest[] memory) {
        uint256 cnt = _end - _start + 1;
        uint256 len = vestings.length;
        require(_end < len, "range error");
        Vest[] memory v = new Vest[](cnt);
        uint256 i;
        for (i; i < cnt; i++) {
            v[i] = vestings[_start + i];
        }
        return v;
    }

    /**
     * @dev Extract all sale contracts
     * @return array of SaleContract objects
     */
    function getSaleContracts() external view returns (SaleContract[] memory) {
        return saleContracts;
    }

    /**
     * @dev Read total number of sale contracts
     * @return number of SaleContracts
     */
    function getSaleContractsCount() external view returns (uint256) {
        return saleContracts.length;
    }

    /**
     * @dev Read single sale contract entry
     * @param _id index of sale contract in storage
     * @return SaleContract object
     */
    function getSaleContractByIndex(uint256 _id) external view returns (SaleContract memory) {
        return saleContracts[_id];
    }

    /**
     * @dev Register sale contract
     * @param _contractAddresses  addresses of sale contracts
     * @param _tokensPerCent      sale price
     * @param _maxAmount          the maximum amount in USD cents for which user could buy
     * @param _percentOnStart     percentage of vested coins that can be claimed on start date
     * @param _startDate          date when initial vesting can be released
     * @param _endDate            final date of vesting, where all tokens can be claimed
     */
    function addSaleContract(
        address[] memory _contractAddresses,
        uint256 _tokensPerCent,
        uint256 _maxAmount,
        uint256 _percentOnStart,
        uint256 _startDate,
        uint256 _endDate
    ) external onlyOwner whenNotLocked {
        require(_contractAddresses.length > 0, "data is missing");
        require(_startDate < _endDate, "startDate cannot exceed endDate");
        SaleContract memory s;
        s.contractAddresses = _contractAddresses;
        s.tokensPerCent = _tokensPerCent;
        s.maxAmount = _maxAmount;
        s.startDate = _startDate;
        s.percentOnStart = _percentOnStart;
        s.endDate = _endDate;
        saleContracts.push(s);
    }

    /**
     * @dev Initialize vestings from sale contracts for msg.sender
     */
    function addMyVesting() external {
        _addVesting(msg.sender);
    }

    /**
     * @dev Initialize vestings from sale contracts for target user
     * @param _user address of user that will be initialized
     */
    function addVesting(address _user) external {
        require(_user != address(0), "User address cannot be 0");
        _addVesting(_user);
    }

    /**
     * @dev Function iterate sale contracts and initialize corresponding
     *      vesting for user.
     * @param _user address that will be initialized
     */
    function _addVesting(address _user) internal {
        require(!refunded[_user], "User refunded");
        require(!vestingAdded[_user], "Already done");
        uint256 len = saleContracts.length;
        uint256 i;
        for (i; i < len; i++) {
            SaleContract memory s = saleContracts[i];
            uint256 sLen = s.contractAddresses.length;
            uint256 j;
            uint256 amt;
            for (j; j < sLen; j++) {
                amt += ISaleContract(s.contractAddresses[j]).balanceOf(_user);
            }
            // amt is in cents, so $100 = 10000
            if (amt > 0) {
                if (amt > s.maxAmount) {
                    amt = s.maxAmount;
                }
                // create Vest object
                Vest memory v = _vestFromSaleContractAndAmount(s, amt);
                // update contract data
                totalVested += v.totalTokens;
                vestings.push(v);
                user2vesting[_user].push(vestings.length);
                emit Vested(_user, v.totalTokens, v.dateEnd);
            }
        }
        vestingAdded[_user] = true;
    }

    /**
     * @dev Function iterate sale contracts and count claimable amounts for given user.
     *      Used to calculate claimable amounts from not initialized vestings.
     * @param _user address of user to count claimable
     * @return claimable amount of tokens
     */
    function _claimableFromSaleContracts(address _user) internal view returns (uint256 claimable) {
        if (refunded[_user]) return 0;
        uint256 len = saleContracts.length;
        if (len == 0) return 0;
        uint256 i;
        for (i; i < len; i++) {
            SaleContract memory s = saleContracts[i];
            uint256 sLen = s.contractAddresses.length;
            uint256 j;
            uint256 amt;
            for (j; j < sLen; j++) {
                amt += ISaleContract(s.contractAddresses[j]).balanceOf(_user);
            }
            // amt is in cents, so $100 = 10000
            if (amt > 0) {
                if (amt > s.maxAmount) {
                    amt = s.maxAmount;
                }
                claimable += _claimable(_vestFromSaleContractAndAmount(s, amt));
            }
        }
    }

    /**
     * @dev Function iterate sale contracts and extract not initialized user vestings.
     *      Used to return all stored and not initialized vestings.
     * @param _user address of user to extract vestings
     * @return v vesting array
     */
    function _vestingsFromSaleContracts(address _user) internal view returns (Vest[] memory) {
        uint256 len = saleContracts.length;
        if (refunded[_user] || len == 0) return new Vest[](0);

        Vest[] memory v = new Vest[](_numberOfVestingsFromSaleContracts(_user));
        uint256 i;
        uint256 idx;
        for (i; i < len; i++) {
            SaleContract memory s = saleContracts[i];
            uint256 sLen = s.contractAddresses.length;
            uint256 j;
            uint256 amt;
            for (j; j < sLen; j++) {
                amt += ISaleContract(s.contractAddresses[j]).balanceOf(_user);
            }
            // amt is in cents, so $100 = 10000
            if (amt > 0) {
                if (amt > s.maxAmount) {
                    amt = s.maxAmount;
                }
                v[idx] = _vestFromSaleContractAndAmount(s, amt);
                idx++;
            }
        }
        return v;
    }

    /**
     * @dev Function iterate sale contracts and return number of not initialized vestings for user.
     * @param _user address of user to extract vestings
     * @return number of not not initialized user vestings
     */
    function _numberOfVestingsFromSaleContracts(address _user) internal view returns (uint256 number) {
        uint256 len = saleContracts.length;
        uint256 i;
        for (i; i < len; i++) {
            SaleContract memory s = saleContracts[i];
            uint256 sLen = s.contractAddresses.length;
            uint256 j;
            uint256 amt;
            for (j; j < sLen; j++) {
                amt += ISaleContract(s.contractAddresses[j]).balanceOf(_user);
            }
            // amt is in cents, so $100 = 10000
            if (amt > 0) {
                number++;
            }
        }
    }

    /**
     * @dev Return vesting created from given sale and usd cent amount.
     * @param _sale address of user to extract vestings
     * @param _amount address of user to extract vestings
     * @return v vesting from given parameters
     */
    function _vestFromSaleContractAndAmount(SaleContract memory _sale, uint256 _amount) internal pure returns (Vest memory v) {
        v.dateStart = _sale.startDate;
        v.dateEnd = _sale.endDate;
        uint256 total = _amount * _sale.tokensPerCent;
        v.totalTokens = total;
        v.startTokens = (total * _sale.percentOnStart) / 100;
    }

    /**
     * @dev Set staking contract address for Claim and Stake.
     *      Only contract owner can set.
     * @param _staking address
     */
    function setStakingAddress(address _staking) external onlyOwner {
        stakingAddress = _staking;
    }

    /**
     * @dev Mark user as refunded
     * @param _user address of user
     * @param _refunded true=refunded
     */
    function setRefunded(address _user, bool _refunded) external onlyOwner whenNotLocked {
        require(_user != address(0), "user address cannot be 0");
        refunded[_user] = _refunded;
    }

    /**
     * @dev Mark multiple refunded users
     * @param _users[] addresses of refunded users
     */
    function massSetRefunded(address[] calldata _users) external onlyOwner whenNotLocked {
        uint256 i;
        for (i; i < _users.length; i++) {
            require(_users[i] != address(0), "user address cannot be 0");
            refunded[_users[i]] = true;
        }
    }

    /**
     * @dev Recover ETH from contract to owner address.
     */
    function recoverETH() external {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Recover given ERC20 token from contract to owner address.
     *      Can't recover SNP tokens.
     * @param _token address of ERC20 token to recover
     */
    function recoverErc20(address _token) external {
        require(_token != snpToken, "Not permitted");
        uint256 amt = IERC20(_token).balanceOf(address(this));
        require(amt > 0, "Nothing to recover");
        IBadErc20(_token).transfer(owner, amt);
    }
}

/**
 * @title IStaking
 * @dev Interface for claim and stake
 */
interface IStaking {
    function canStakeTokens(address _account) external view returns (bool);

    function onClaimAndStake(address _from, uint256 _amount) external;
}

/**
 * @title ISaleContract
 * @dev Interface for sale contract
 */
interface ISaleContract {
    function balanceOf(address _account) external view returns (uint256);
}

/**
 * @title IBadErc20
 * @dev Interface for emergency recover any ERC20-tokens,
 *      even non-erc20-compliant like USDT not returning boolean
 */
interface IBadErc20 {
    function transfer(address _recipient, uint256 _amount) external;
}