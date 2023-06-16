//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PrivateSaleETH is AccessControlUpgradeable, PausableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    uint private soldAmountToken;

    // 18 months or 24 months
    uint public unlockDuration;

    address public tokenAddress;

    struct Info {
        uint code;
        address user;
        uint totalTokenAmount;
        uint claimedTokenAmount;
        uint boughtAt;
    }

    address[] private investorsMap;
    mapping(address => Info) investorDetails;

    uint private startCountdown;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

        soldAmountToken = 0;

        unlockDuration = 18;

        startCountdown = 0;
    }

    /*
        Admin's function BEGIN
    */
    function getAllInvestors()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(Info [] memory)
    {
        Info[] memory investors = new Info [](investorsMap.length);

        for(uint i = 0; i<investorsMap.length; i++) {
            investors[i] = _getUserInfo(investorsMap[i]);
        }
        
        return investors;
    }

    function setTokenCurrency(address _currency)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "PrivateSale: Caller is not an admin"
        );
        tokenAddress = _currency;
    }

    /*
       @dev admin can add information of private sale investors
    */
    function adminAddInvestors(address[] calldata _investors, uint256[] calldata _amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for(uint i = 0; i<_investors.length; i++) {
            soldAmountToken = soldAmountToken + _amounts[i];

            address user = _investors[i];
            uint code = investorsMap.length;
            investorsMap.push(user);

            investorDetails[user].code = code;
            investorDetails[user].user = user;
            investorDetails[user].totalTokenAmount = _amounts[i];
            investorDetails[user].claimedTokenAmount = 0;
            investorDetails[user].boughtAt = block.timestamp;
        }
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address _currencyAddress)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "PrivateSale: Caller is not an admin"
        );
        // withdraw native currency
        if (_currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(_currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        Admin can set unlock duration (in month)
    */
    function setUnlockDuration(uint _unlockDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        unlockDuration = _unlockDuration;
    }

    /*
        Admin can change the time to start countdown
    */
    function setCountDownTime(uint _startCountdown)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        startCountdown = _startCountdown;
    }

    /*
        Admin can check amount of token sold
    */
    function getAmountToken()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return soldAmountToken;
    }

    /*
        Admin can retrieve information of a user
    */
    function _getUserInfo(address _user)
        internal
        view
        returns(Info memory)
    {
        Info memory rs;

        rs.code = investorDetails[_user].code;
        rs.user = investorDetails[_user].user;
        rs.totalTokenAmount = investorDetails[_user].totalTokenAmount;
        rs.claimedTokenAmount = investorDetails[_user].claimedTokenAmount;
        rs.boughtAt = investorDetails[_user].boughtAt;

        return rs;
    }

    /*
        User can retrieve his information
    */
    function getInfo()
        external
        view
        returns(Info memory)
    {
        return _getUserInfo(msg.sender);
    }

    function getClaimable()
        public
        view
        returns(uint)
    {
        address user = msg.sender;
        uint timeLock = startCountdown + 7 days;
        if (block.timestamp <= timeLock) {
            return 0;
        }
        uint daysDiff = (block.timestamp - timeLock) / 1 days;

        uint unlockDays = 30 * unlockDuration;

        uint unlockedToken = (investorDetails[user].totalTokenAmount < investorDetails[user].totalTokenAmount * daysDiff / unlockDays) ?
                              investorDetails[user].totalTokenAmount : investorDetails[user].totalTokenAmount * daysDiff / unlockDays;
        uint claimableToken = unlockedToken - investorDetails[user].claimedTokenAmount;

        return claimableToken;
    }

    function userClaim()
        external
    {
        address user = msg.sender;
        uint claimableToken = getClaimable();
        investorDetails[user].claimedTokenAmount += claimableToken;
        IERC20(tokenAddress).transfer(msg.sender, claimableToken);
    }
}