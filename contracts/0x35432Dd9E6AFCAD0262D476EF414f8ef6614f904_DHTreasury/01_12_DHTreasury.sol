// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

// TODO: registration for each monthly distribution. so need to support "epochs" of distribution - 72h for registration once a month or smth
contract DHTreasury is Initializable, OwnableUpgradeable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Token -> amount
    mapping(address => uint256) public totalRewards;
    // Token -> amount
    mapping(address => uint256) public paidRewards;
    // Account -> (Token -> amount)
    mapping(address => mapping(address => uint256)) public paidUserRewards;
    EnumerableSet.AddressSet private _tokens;

    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    event RewardSet(address indexed token, uint256 amount);
    event RewardPaid(address indexed user, address indexed token, uint256 amount);

    struct Rewards {
        address[] tokens;
        uint256[] amounts;
        uint256[] paid;
        uint256[] remaining;
    }

    struct UserReward {
        address[] tokens;
        uint256[] paid;
    }
    
    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
        AccessControlUpgradeable.__AccessControl_init();
    
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }
    
    function getTokens() external view returns (address[] memory) {
        return _tokens.values();
    }

    function getUserRewards(address user) external view returns (UserReward memory) {
        UserReward memory v;
        v.tokens = new address[](_tokens.length());
        v.paid = new uint256[](_tokens.length());
        for (uint256 i = 0; i < _tokens.length(); i++) {
            address token = _tokens.at(i);
            v.tokens[i] = token;
            v.paid[i] = paidUserRewards[user][token];
        }

        return v;
    }

    function getRewards() external view returns (Rewards memory) {
        Rewards memory v;
        v.tokens = new address[](_tokens.length());
        v.amounts = new uint256[](_tokens.length());
        v.paid = new uint256[](_tokens.length());
        v.remaining = new uint256[](_tokens.length());
        for (uint256 i = 0; i < _tokens.length(); i++) {
            address token = _tokens.at(i);
            v.tokens[i] = token;
            v.amounts[i] = totalRewards[token];
            v.paid[i] = paidRewards[token];
            v.remaining[i] = v.amounts[i] - v.paid[i];
        }
        return v;
    }

    function setRewards(address token, uint256 amount) external onlyRole(MANAGER_ROLE) {
        require(amount >= paidRewards[token], 'DHTreasury: setting amount less than already paid out');
        totalRewards[token] = amount;
        _tokens.add(token);
        if (totalRewards[token] == 0) {
            _tokens.remove(token);
        }

        emit RewardSet(token, amount);
    }

    function transferReward(
        address token,
        uint256 amount,
        address to
    ) external onlyRole(MANAGER_ROLE) {
        IERC20 tokenContract = IERC20(token);
        require(amount <= totalRewards[token] - paidRewards[token], 'DHTreasury: sending more than remaining');
        require(tokenContract.balanceOf(address(this)) >= amount, 'DHTreasury: not enough balance');

        paidRewards[token] += amount;
        paidUserRewards[to][token] += amount;
        tokenContract.transfer(to, amount);

        emit RewardPaid(to, token, amount);
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }

        for (uint256 i = 0; i <= _tokens.length(); i++) {
            address token = _tokens.at(i);
            IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
        }
    }

    function withdrawToken(address token, uint256 amount) external onlyOwner {
        require(amount > 0, 'Withdrawable: amount should be greater than zero');
        IERC20(token).transfer(owner(), amount);
    }
}