// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract ErnykaStaking is Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    event addressDeclaring(address);
    event amount (uint256);
    event amountOfStakeMap(uint256);
    event log(bool);
    event sub(uint256);
    event stakeMapLenght(uint);
    event error(string);
    using SafeERC20Upgradeable for IERC20Upgradeable;
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    IERC20Upgradeable UsdtToken;
    IERC20Upgradeable WavesToken;
    mapping(address => stakingInfo) internal stakeMap;
    address[] private stakeHolders;
    uint remainingTime;

    function initialize(address wavesAddress, address usdtAddress, address owner_) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
        WavesToken = IERC20Upgradeable(wavesAddress);
        UsdtToken = IERC20Upgradeable(usdtAddress);
        remainingTime = 1 hours;
    }
    using SafeMathUpgradeable for uint256;
    struct stakingInfo {
        uint256 amount;
        uint256 releaseDate;
    }

    function stake(uint256 _amount)
    external
    {
        require(stakeMap[msg.sender].amount == 0, "you can't stake twice.");
        require(UsdtToken.transferFrom(msg.sender, address(this), _amount), "transferring allowance");

        stakingInfo memory userStakingInfo;

        userStakingInfo = stakingInfo(_amount, block.timestamp + remainingTime);

        stakeMap[msg.sender] = userStakingInfo;
        stakeHolders.push(msg.sender);
    }

    function release()
    external
    onlyRole(KEEPER_ROLE)
    {
        uint128 counter;
        for (counter = 0; counter < stakeHolders.length; counter++) {
            if (stakeMap[stakeHolders[counter]].releaseDate < block.timestamp && stakeMap[stakeHolders[counter]].amount > 0) {
                WavesToken.transfer(stakeHolders[counter], stakeMap[stakeHolders[counter]].amount);
                UsdtToken.transfer(stakeHolders[counter], stakeMap[stakeHolders[counter]].amount);
                delete stakeMap[stakeHolders[counter]];
                delete stakeHolders[counter];
            }
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) virtual {}

}