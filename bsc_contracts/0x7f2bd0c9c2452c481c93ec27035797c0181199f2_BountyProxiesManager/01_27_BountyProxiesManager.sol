//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import "./SaloonWallet.sol";
import "./BountyProxyFactory.sol";
import "./IBountyProxyFactory.sol";
import "./BountyPool.sol";

import "./lib/OwnableUpgradeable.sol";
import "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract BountyProxiesManager is OwnableUpgradeable, UUPSUpgradeable {
    /// PUBLIC STORAGE ///

    event DeployNewBounty(
        address indexed sender,
        address indexed _projectWallet,
        BountyPool newProxyAddress
    );

    event BountyKilled(string indexed projectName);

    event PremiumBilled(
        string indexed projectName,
        address indexed projectWallet
    );

    event SaloonFundsWithdrawal(address indexed token, uint256 indexed amount);

    event BountyPaid(
        uint256 indexed time,
        address indexed hunter,
        uint256 indexed amount,
        address token
    );

    event BountyPoolImplementationUpdated(address indexed newImplementation);

    event tokenWhitelistUpdated(
        address indexed token,
        bool indexed whitelisted
    );

    event PoolCapChanged(string indexed projectName, uint256 indexed poolCap);

    event APYChanged(string indexed projectName, uint256 indexed apy);

    event WithdrawalorUnstakeScheduled(
        string indexed projectName,
        uint256 indexed amount
    );

    event BountyBalanceChanged(
        string indexed projectName,
        uint256 indexed oldAmount,
        uint256 indexed newAmount
    );

    event StakedAmountChanged(
        string indexed projectName,
        uint256 indexed previousStaked,
        uint256 indexed newStaked
    );

    event SaloonPremiumCollected(uint256 indexed totalCollected);

    BountyProxyFactory public factory;
    UpgradeableBeacon public beacon;
    address public bountyImplementation;
    SaloonWallet public saloonWallet;

    struct Bounties {
        BountyPool proxyAddress;
        address projectWallet;
        address token;
        uint256 decimals;
        string projectName;
        bool dead;
    }

    Bounties[] public bountiesList;
    // Project name => project auth address => proxy address
    mapping(string => Bounties) public bountyDetails;
    // Token address => approved or not
    mapping(address => bool) public tokenWhitelist;

    function notDead(bool _isDead) internal pure returns (bool) {
        // if notDead is false return bounty is live(true)
        return _isDead == false ? true : false;
    }

    function initialize(
        BountyProxyFactory _factory,
        UpgradeableBeacon _beacon,
        address _bountyImplementation
    ) public initializer {
        factory = _factory;
        beacon = _beacon;
        bountyImplementation = _bountyImplementation;
        __Ownable_init();
    }

    function _authorizeUpgrade(address _newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}

    //////// UPDATE SALOON WALLET FOR HUNTER PAYOUTS //////
    function updateSaloonWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0), "Address cant be zero");
        saloonWallet = SaloonWallet(_newWallet);
    }

    //////// WITHDRAW FROM SALOON WALLET //////
    function withdrawSaloon(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        require(_to != address(0), "Address Zero");
        uint256 decimals = ERC20(_token).decimals();
        saloonWallet.withdrawSaloonFunds(_token, _to, _amount, decimals);

        emit SaloonFundsWithdrawal(_token, _amount);
        return true;
    }

    ///// DEPLOY NEW BOUNTY //////
    function deployNewBounty(
        bytes memory _data,
        string memory _projectName,
        address _token,
        address _projectWallet
    ) external onlyOwner returns (BountyPool, bool) {
        // revert if project name already has bounty
        require(
            bountyDetails[_projectName].proxyAddress == BountyPool(address(0)),
            "Project already has bounty"
        );

        require(tokenWhitelist[_token] == true, "Token not approved");

        Bounties memory newBounty;
        newBounty.projectName = _projectName;
        newBounty.projectWallet = _projectWallet;
        newBounty.token = _token;
        newBounty.decimals = ERC20(_token).decimals();
        require(newBounty.decimals != 0, "Invalid Token Decimals");

        // call factory to deploy bounty
        BountyPool newProxyAddress = factory.deployBounty(
            address(beacon),
            _data
        );
        newProxyAddress.initializeImplementation(
            address(this),
            newBounty.decimals
        );

        newBounty.proxyAddress = newProxyAddress;

        // Push new bounty to storage array
        bountiesList.push(newBounty);

        // Create new mapping so we can look up bounty details by their name
        bountyDetails[_projectName] = newBounty;

        // bountyImplementation.updateProxyWhitelist(newProxyAddress, true);
        emit DeployNewBounty(msg.sender, _projectWallet, newProxyAddress);

        return (newProxyAddress, true);
    }

    ///// KILL BOUNTY ////
    function killBounty(string memory _projectName)
        external
        onlyOwner
        returns (bool)
    {
        // attempt to withdraw all money?
        // call (currently non-existent) pause function?
        // look up address by name
        bountyDetails[_projectName].dead = true;

        emit BountyKilled(_projectName);
        return true;
    }

    ///// PUBLIC PAY PREMIUM FOR ONE BOUNTY //
    function billPremiumForOnePool(string memory _projectName)
        external
        returns (bool)
    {
        // check if active
        require(
            notDead(bountyDetails[_projectName].dead) == true,
            "Bounty is Dead"
        );

        // bill
        if (
            bountyDetails[_projectName].proxyAddress.billPremium(
                bountyDetails[_projectName].token,
                bountyDetails[_projectName].projectWallet
            ) == true
        ) {
            emit PremiumBilled(
                _projectName,
                bountyDetails[_projectName].projectWallet
            );
        } else {
            uint256 apy = viewDesiredAPY(_projectName);
            uint256 poolCap = viewPoolCap(_projectName);
            emit PoolCapChanged(_projectName, poolCap);
            emit APYChanged(_projectName, apy);
        }
        return true;
    }

    ///// PUBLIC PAY PREMIUM FOR ALL BOUNTIES //
    function billPremiumForAll() external returns (bool) {
        // cache bounty bounties listt
        Bounties[] memory bountiesArray = bountiesList;
        uint256 length = bountiesArray.length;
        // iterate through all bounty proxies
        for (uint256 i; i < length; ++i) {
            // collect the premium fees from bounty
            if (notDead(bountiesArray[i].dead) == false) {
                continue; // killed bounties are supposed to be skipped.
            }
            if (
                bountiesArray[i].proxyAddress.billPremium(
                    bountiesArray[i].token,
                    bountiesArray[i].projectWallet
                ) == true
            ) {
                emit PremiumBilled(
                    bountiesArray[i].projectName,
                    bountiesArray[i].projectWallet
                );
            } else {
                uint256 apy = viewDesiredAPY(bountiesArray[i].projectName);
                uint256 poolCap = viewPoolCap(bountiesArray[i].projectName);
                emit PoolCapChanged(bountiesArray[i].projectName, poolCap);
                emit APYChanged(bountiesArray[i].projectName, apy);
            }
        }
        return true;
    }

    /// ADMIN WITHDRAWAL FROM POOL  TO PAY BOUNTY ///
    function payBounty(
        string memory _projectName,
        address _hunter,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        require(
            notDead(bountyDetails[_projectName].dead) == true,
            "Bounty is Dead"
        );
        require(_hunter != address(0), "Hunter address(0)");

        uint256 decimals = bountyDetails[_projectName].decimals;
        uint256 amount = _amount * (10**decimals);

        bountyDetails[_projectName].proxyAddress.payBounty(
            bountyDetails[_projectName].token,
            address(saloonWallet),
            _hunter,
            amount
        );

        saloonWallet.bountyPaid(
            bountyDetails[_projectName].token,
            bountyDetails[_projectName].decimals,
            _hunter,
            _amount
        );

        emit BountyPaid(
            block.timestamp,
            _hunter,
            _amount,
            bountyDetails[_projectName].token
        );
        return true;
    }

    /// ADMIN CLAIM PREMIUM FEES for ALL BOUNTIES///
    function withdrawSaloonPremiumFees() external onlyOwner returns (bool) {
        // cache bounty bounties listt
        Bounties[] memory bountiesArray = bountiesList;
        uint256 length = bountiesArray.length;
        uint256 collected;
        // iterate through all bounty proxies
        for (uint256 i; i < length; ++i) {
            if (notDead(bountiesArray[i].dead) == false) {
                continue; // killed bounties are supposed to be skipped.
            }
            // collect the premium fees from bounty
            uint256 totalCollected = bountiesArray[i]
                .proxyAddress
                .collectSaloonPremiumFees(
                    bountiesArray[i].token,
                    address(saloonWallet)
                );

            saloonWallet.premiumFeesCollected(
                bountiesArray[i].token,
                totalCollected
            );
            collected += totalCollected;
        }
        emit SaloonPremiumCollected(collected);
        return true;
    }

    /// ADMIN update BountyPool IMPLEMENTATION ADDRESS of UPGRADEABLEBEACON /// done
    function updateBountyPoolImplementation(address _newImplementation)
        external
        onlyOwner
        returns (bool)
    {
        require(_newImplementation != address(0), "Address zero");
        beacon.upgradeTo(_newImplementation);
        emit BountyPoolImplementationUpdated(_newImplementation);
        return true;
    }

    /// ADMIN UPDATE APPROVED TOKENS /// done
    function updateTokenWhitelist(address _token, bool _whitelisted)
        external
        onlyOwner
        returns (bool)
    {
        tokenWhitelist[_token] = _whitelisted;

        emit tokenWhitelistUpdated(_token, _whitelisted);
        return true;
    }

    //////// PROJECTS FUNCTION TO CHANGE APY and CAP by NAME/////
    // note: timelock present in bounty implementation
    function setBountyCapAndAPY(
        string memory _projectName,
        uint256 _poolCap,
        uint256 _desiredAPY
    ) external returns (bool) {
        // look for project address
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        // require msg.sender == projectWallet
        require(msg.sender == bounty.projectWallet, "Not project owner");

        // Set right amount of decimals
        uint256 poolCap = _poolCap * (10**bounty.decimals);
        uint256 desiredAPY = _desiredAPY * (10**bounty.decimals);

        bounty.proxyAddress.setPoolCap(poolCap);

        // set APY
        bounty.proxyAddress.setDesiredAPY(
            bounty.token,
            bounty.projectWallet,
            desiredAPY
        );

        emit PoolCapChanged(_projectName, poolCap);
        emit APYChanged(_projectName, desiredAPY);
        return true;
    }

    function schedulePoolCapChange(
        string memory _projectName,
        uint256 _newPoolCap
    ) external returns (bool) {
        Bounties memory bounty = bountyDetails[_projectName];
        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");
        // require msg.sender == projectWallet
        require(msg.sender == bounty.projectWallet, "Not project owner");
        uint256 poolCap = _newPoolCap * (10**bounty.decimals);
        bounty.proxyAddress.schedulePoolCapChange(poolCap);

        return true;
    }

    function setPoolCap(string memory _projectName, uint256 _newPoolCap)
        external
        returns (bool)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");
        // require msg.sender == projectWallet
        require(msg.sender == bounty.projectWallet, "Not project owner");
        uint256 poolCap = _newPoolCap * (10**bounty.decimals);
        bounty.proxyAddress.setPoolCap(poolCap);

        emit PoolCapChanged(_projectName, poolCap);
        return true;
    }

    function scheduleAPYChange(string memory _projectName, uint256 _newAPY)
        external
        returns (bool)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");
        // require msg.sender == projectWallet
        require(msg.sender == bounty.projectWallet, "Not project owner");
        uint256 poolCap = _newAPY * (10**bounty.decimals);
        bounty.proxyAddress.scheduleAPYChange(poolCap);

        return true;
    }

    function setAPY(string memory _projectName, uint256 _newAPY)
        external
        returns (bool)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");
        // require msg.sender == projectWallet
        require(msg.sender == bounty.projectWallet, "Not project owner");
        uint256 apy = _newAPY * (10**bounty.decimals);

        // set APY
        bounty.proxyAddress.setDesiredAPY(
            bounty.token,
            bounty.projectWallet,
            apy
        );

        emit APYChanged(_projectName, apy);
        return true;
    }

    /////// PROJECTS FUNCTION TO DEPOSIT INTO POOL by NAME///////
    function projectDeposit(string memory _projectName, uint256 _amount)
        external
        returns (bool)
    {
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        // check if msg.sender is allowed
        require(msg.sender == bounty.projectWallet, "Not project owner");

        uint256 oldBalance = bounty.proxyAddress.viewBountyBalance();

        // handle decimals
        uint256 amount = _amount * (10**bounty.decimals);

        // do deposit
        bounty.proxyAddress.bountyDeposit(
            bounty.token,
            bounty.projectWallet,
            amount
        );

        uint256 newBalance = oldBalance + amount;

        emit BountyBalanceChanged(_projectName, oldBalance, newBalance);

        return true;
    }

    /////// PROJECT FUNCTION TO SCHEDULE WITHDRAW FROM POOL  by PROJECT NAME///// done
    function scheduleProjectDepositWithdrawal(
        string memory _projectName,
        uint256 _amount
    ) external returns (bool) {
        // cache bounty
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        // check if caller is project
        require(msg.sender == bounty.projectWallet, "Not project owner");

        // handle decimals
        uint256 amount = _amount * (10**bounty.decimals);

        // schedule withdrawal
        bounty.proxyAddress.scheduleprojectDepositWithdrawal(amount);

        emit WithdrawalorUnstakeScheduled(_projectName, amount);
        return true;
    }

    /////// PROJECT FUNCTION TO WITHDRAW FROM POOL  by PROJECT NAME///// done
    function projectDepositWithdrawal(
        string memory _projectName,
        uint256 _amount
    ) external returns (bool) {
        // cache bounty
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        // check if caller is project
        require(msg.sender == bounty.projectWallet, "Not project owner");

        uint256 oldBalance = bounty.proxyAddress.viewBountyBalance();

        // handle decimals
        uint256 amount = _amount * (10**bounty.decimals);

        // schedule withdrawal
        bounty.proxyAddress.projectDepositWithdrawal(
            bounty.token,
            bounty.projectWallet,
            amount
        );

        uint256 newBalance = oldBalance + amount;

        emit BountyBalanceChanged(_projectName, oldBalance, newBalance);
        return true;
    }

    ////// STAKER FUNCTION TO STAKE INTO POOL by PROJECT NAME////// done
    function stake(string memory _projectName, uint256 _amount)
        external
        returns (bool)
    {
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        uint256 oldBalance = bounty.proxyAddress.viewBountyBalance();
        uint256 previousStaked = bounty.proxyAddress.viewStakersDeposit();

        // handle decimals
        uint256 amount = _amount * (10**bounty.decimals);

        bounty.proxyAddress.stake(bounty.token, msg.sender, amount);

        uint256 newBalance = oldBalance + amount;
        uint256 newStaked = previousStaked + amount;

        emit StakedAmountChanged(_projectName, previousStaked, newStaked);
        emit BountyBalanceChanged(_projectName, newBalance, oldBalance);
        return true;
    }

    ////// STAKER FUNCTION TO SCHEDULE UNSTAKE FROM POOL /////// done
    function scheduleUnstake(string memory _projectName, uint256 _amount)
        external
        returns (bool)
    {
        Bounties memory bounty = bountyDetails[_projectName];

        // handle decimals
        uint256 amount = _amount * (10**bounty.decimals);

        if (bounty.proxyAddress.scheduleUnstake(msg.sender, amount)) {
            emit WithdrawalorUnstakeScheduled(_projectName, amount);
            return true;
        } else {
            return false;
        }
    }

    ////// STAKER FUNCTION TO UNSTAKE FROM POOL /////// done
    function unstake(string memory _projectName, uint256 _amount)
        external
        returns (bool)
    {
        Bounties memory bounty = bountyDetails[_projectName];

        uint256 oldBalance = bounty.proxyAddress.viewBountyBalance();
        uint256 previousStaked = bounty.proxyAddress.viewStakersDeposit();

        // handle decimals
        uint256 amount = _amount * (10**bounty.decimals);

        if (bounty.proxyAddress.unstake(bounty.token, msg.sender, amount)) {
            uint256 newBalance = oldBalance + amount;
            uint256 newStaked = previousStaked - amount;

            emit StakedAmountChanged(_projectName, previousStaked, newStaked);
            emit BountyBalanceChanged(_projectName, oldBalance, newBalance);
            return true;
        } else {
            return false;
        }
    }

    ///// STAKER FUNCTION TO CLAIM PREMIUM by PROJECT NAME////// done
    function claimPremium(string memory _projectName)
        external
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        (uint256 premiumClaimed, ) = bounty.proxyAddress.claimPremium(
            bounty.token,
            msg.sender,
            bounty.projectWallet
        );

        return premiumClaimed;
    }

    // ??????????/  STAKER FUNCTION TO STAKE INTO GLOBAL POOL??????????? ////// - maybe on future version

    ///////////////////////// VIEW FUNCTIONS //////////////////////

    // Function to view all bounties name string // done
    function viewAllBountiesByName() external view returns (Bounties[] memory) {
        return bountiesList;
    }

    function viewBountyInfo(string memory _projectName)
        external
        view
        returns (
            uint256 payout,
            uint256 apy,
            uint256 staked,
            uint256 poolCap
        )
    {
        payout = viewHackerPayout(_projectName);
        staked = viewstakersDeposit(_projectName);
        apy = viewDesiredAPY(_projectName);
        poolCap = viewPoolCap(_projectName);
    }

    function viewBountyBalance(string memory _projectName)
        public
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        return bounty.proxyAddress.viewBountyBalance();
    }

    function viewPoolCap(string memory _projectName)
        public
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        return bounty.proxyAddress.viewPoolCap();
    }

    // Function to view Total Balance of Pool By Project Name // done
    function viewHackerPayout(string memory _projectName)
        public
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        return bounty.proxyAddress.viewHackerPayout();
    }

    // Function to view Project Deposit to Pool by Project Name // done
    function viewProjectDeposit(string memory _projectName)
        external
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        return bounty.proxyAddress.viewProjecDeposit();
    }

    // Function to view Total Staker Balance of Pool By Project Name // done
    function viewstakersDeposit(string memory _projectName)
        public
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        return bounty.proxyAddress.viewStakersDeposit();
    }

    function viewDesiredAPY(string memory _projectName)
        public
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        return bounty.proxyAddress.viewDesiredAPY();
    }

    // Function to view individual Staker Balance in Pool by Project Name // done
    function viewUserStakingBalance(string memory _projectName, address _staker)
        external
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        (uint256 stakingBalance, ) = bounty.proxyAddress.viewUserStakingBalance(
            _staker
        );
        return stakingBalance;
    }

    // Function to view individual staker's timelock, if any
    function viewUserTimelock(string memory _projectName, address _staker)
        external
        view
        returns (
            uint256 timelock,
            uint256 amount,
            bool executed
        )
    {
        Bounties memory bounty = bountyDetails[_projectName];
        (timelock, amount, executed) = bounty.proxyAddress.viewUserTimelock(
            _staker
        );
    }

    // Function to find bounty proxy and wallet address by Name // done
    function getBountyAddressByName(string memory _projectName)
        external
        view
        returns (address)
    {
        return address(bountyDetails[_projectName].proxyAddress);
    }

    function viewBountyOwner(string memory _projectName)
        external
        view
        returns (address)
    {
        return address(bountyDetails[_projectName].projectWallet);
    }

    //  SALOON WALLET VIEW FUNCTIONS
    function viewSaloonBalance() external view returns (uint256) {
        return saloonWallet.viewSaloonBalance();
    }

    function viewTotalEarnedSaloon() external view returns (uint256) {
        return saloonWallet.viewTotalEarnedSaloon();
    }

    function viewTotalHackerPayouts() external view returns (uint256) {
        return saloonWallet.viewTotalHackerPayouts();
    }

    function viewHunterTotalTokenPayouts(address _token, address _hunter)
        external
        view
        returns (uint256)
    {
        return saloonWallet.viewHunterTotalTokenPayouts(_token, _hunter);
    }

    function viewTotalSaloonCommission() external view returns (uint256) {
        return saloonWallet.viewTotalSaloonCommission();
    }

    ///////////////////////    VIEW FUNCTIONS END  ////////////////////////
}