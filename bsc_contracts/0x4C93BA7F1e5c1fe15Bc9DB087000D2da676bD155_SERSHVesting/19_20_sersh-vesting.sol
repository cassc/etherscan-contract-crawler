// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./sersh-vesting-escrow.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import "./libraries/TokenHelper.sol";
import "./interfaces/ISERSHVesting.sol";

import "hardhat/console.sol";

contract SERSHVesting is
    ISERSHVesting,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Address for address;

    mapping(address => bool) private _isVestingEscrow;
    mapping(address => uint256) private _buyerVestingAmount;

    uint256 private _totalVested;
    mapping(DataTypes.VestingCategory => uint256) private _categoryTotalVested;

    uint private _version;
    address private _vestingToken;

    bool private _paused;

    uint256 private _minVestingAmount;
    uint256 private _maxVestingAmount;

    mapping(DataTypes.VestingCategory => address) private _subWallets;
    mapping(DataTypes.VestingCategory => DataTypes.VestingPlan)
        private _vestingPlan;

    uint256 private _tgeTimeStamp;

    mapping(string => address) private _vestingResult;

    event DeployedVesting(
        address indexed vesting,
        DataTypes.VestingCategory indexed category,
        uint256 indexed amount,
        address buyer,
        string requestHash,
        address receiver,
        address buyer2,
        address vestingToken
    );
    event UpdatedVersion(uint indexed version, uint256 indexed when);
    event UpdatedVestingToken(address indexed token, uint256 indexed when);
    event UpdatePaused(bool indexed paused, uint256 indexed when);
    event Unvested(address indexed vesting, address indexed receiver, string indexed requestHash, uint256 amount, uint256 when, uint8 finished, uint64 step);
    event UpdatedTGE(uint256 indexed when);
    

    modifier notPaused() {
        require(_paused == false, "Vesting is paused.");
        _;
    }

    function initialValue(
        uint version,
        address vestingToken
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        _version = version;
        _vestingToken = vestingToken;
        _paused = false;

        _minVestingAmount = 0;
        _maxVestingAmount = 0.1 ether; // Total supply 100000000 1e9 (decimals = 9)

        // init subwallets with default addresses. can be updated in future

        _subWallets[
            DataTypes.VestingCategory.Seed
        ] = 0x8DC4410681b6a6950aeA7B4bF59A46b117d7F714;
        _subWallets[
            DataTypes.VestingCategory.PS1
        ] = 0xe7a71D682d783Fbd3b8F41d398c76DD61D7cd913;
        _subWallets[
            DataTypes.VestingCategory.PS2
        ] = 0xa1c6b470B2CBaC4709c3ccd9F007C72C0dCBab84;
        _subWallets[
            DataTypes.VestingCategory.PR
        ] = 0x9C27990aF792BCF34315cb42C195d8003D92C746;
        _subWallets[
            DataTypes.VestingCategory.TM
        ] = 0xb30Fe6101190bFA3dAb074472d74D711359343Dc;
        _subWallets[
            DataTypes.VestingCategory.AD
        ] = 0x758339553e1dfA422E45D4f387B48eE7897A7F0f;
        _subWallets[
            DataTypes.VestingCategory.EM
        ] = 0xd471CA0783951511728632E33189BC71C367880F;
        _subWallets[
            DataTypes.VestingCategory.TR
        ] = 0x464Bbe1850Ab453aC2d08aD3896Fa9d13481262E;
        _subWallets[
            DataTypes.VestingCategory.ICO
        ] = 0xA1A3D9BFAb14e6e7c5406ead3ad3092120a94A40;

        // ? percentage 100% == 10000
        _vestingPlan[DataTypes.VestingCategory.Seed] = DataTypes.VestingPlan({
            cliffMonths: 9,
            linearMonths: 21,
            tgeRate: 0,
            cliffRate: 1500,
            vestingRate: 404
        });

        _vestingPlan[DataTypes.VestingCategory.PS1] = DataTypes.VestingPlan({
            cliffMonths: 9,
            linearMonths: 21,
            tgeRate: 100,
            cliffRate: 1500,
            vestingRate: 400
        });

        _vestingPlan[DataTypes.VestingCategory.PS2] = DataTypes.VestingPlan({
            cliffMonths: 1,
            linearMonths: 12,
            tgeRate: 700,
            cliffRate: 0,
            vestingRate: 775
        });

        _vestingPlan[DataTypes.VestingCategory.PR] = DataTypes.VestingPlan({
            cliffMonths: 6,
            linearMonths: 18,
            tgeRate: 500,
            cliffRate: 1000,
            vestingRate: 472
        });

        _vestingPlan[DataTypes.VestingCategory.TM] = DataTypes.VestingPlan({
            cliffMonths: 12,
            linearMonths: 24,
            tgeRate: 0,
            cliffRate: 1500,
            vestingRate: 354
        });
        _vestingPlan[DataTypes.VestingCategory.AD] = DataTypes.VestingPlan({
            cliffMonths: 6,
            linearMonths: 18,
            tgeRate: 0,
            cliffRate: 1500,
            vestingRate: 472
        });

        _vestingPlan[DataTypes.VestingCategory.EM] = DataTypes.VestingPlan({
            cliffMonths: 4,
            linearMonths: 24,
            tgeRate: 0,
            cliffRate: 1000,
            vestingRate: 375
        });

        _vestingPlan[DataTypes.VestingCategory.TR] = DataTypes.VestingPlan({
            cliffMonths: 12,
            linearMonths: 24,
            tgeRate: 0,
            cliffRate: 0,
            vestingRate: 416
        });

        _vestingPlan[DataTypes.VestingCategory.ICO] = DataTypes.VestingPlan({
            cliffMonths: 1,
            linearMonths: 12,
            tgeRate: 1500,
            cliffRate: 0,
            vestingRate: 708
        });
    }

    function getVersion() public view returns (uint) {
        return _version;
    }

    function setVersion(uint version) public onlyOwner {
        require(version != _version, "Already set");
        _version = version;
        emit UpdatedVersion(_version, block.timestamp);
    }

    function getVestingToken() public view returns (address) {
        return _vestingToken;
    }

    // function setVestingToken(address vestingToken) public onlyOwner {
    //     require(vestingToken != address(0), "Invalid vesting token address.");
    //     require(vestingToken != _vestingToken, "Already set.");
    //     _vestingToken = vestingToken;
    //     emit UpdatedVestingToken(_vestingToken, block.timestamp);
    // }

    function getTotalVested() public view returns (uint256) {
        return _totalVested;
    }

    function getTotalVestingAmount(
        address buyer
    ) external view returns (uint256) {
        return _buyerVestingAmount[buyer];
    }

    function isVestingContract(address vesting) external view returns (bool) {
        return _isVestingEscrow[vesting];
    }

    function getPaused() external view returns (bool) {
        return _paused;
    }

    function setPaused(bool paused) public onlyOwner {
        require(paused != _paused, "Already set");
        _paused = paused;
        emit UpdatePaused(_paused, block.timestamp);
    }

    function getMinVestingAmount() external view returns (uint256) {
        return _minVestingAmount;
    }

    function getMaxVestingAmount() external view returns (uint256) {
        return _maxVestingAmount;
    }

    function setMinVestingAmount(uint256 _min) public onlyOwner {
        require(_minVestingAmount != _min, "Already set");
        _minVestingAmount = _min;
    }

    function setMaxVestingAmount(uint256 _max) public onlyOwner {
        require(_maxVestingAmount != _max, "Already set");
        _maxVestingAmount = _max;
    }

    function getSubWallet(
        DataTypes.VestingCategory category
    ) external view returns (address) {
        return _subWallets[category];
    }

    // function setSubWallet(
    //     DataTypes.VestingCategory category,
    //     address wallet
    // ) external onlyOwner {
    //     require(_subWallets[category] != wallet, "Already set");
    //     _subWallets[category] = wallet;
    // }

    
    function getCategoryTotalVested(
        DataTypes.VestingCategory category
    ) external view returns (uint256) {
        return _categoryTotalVested[category];
    }

    function getVestingPlan(
        DataTypes.VestingCategory category
    )
        external
        view
        returns (
            uint cliff,
            uint linear,
            uint256 tgeRate,
            uint256 cliffRate,
            uint256 vestingRate
        )
    {
        return (
            _vestingPlan[category].cliffMonths,
            _vestingPlan[category].linearMonths,
            _vestingPlan[category].tgeRate,
            _vestingPlan[category].cliffRate,
            _vestingPlan[category].vestingRate
        );
    }

    function getTGETimestamp() external view returns (uint256) {
        return _tgeTimeStamp;
    }

    function setTGETimestamp(uint256 tge) external onlyOwner {
        require(_tgeTimeStamp != tge, "Already set");
        _tgeTimeStamp = tge;
        emit UpdatedTGE(_tgeTimeStamp);
    }

    function canDeployVestingContract(
        DataTypes.VestingCategory category,
        uint256 amount,
        address buyer,
        string memory requestHash,
        address receiver,
        address buyer2ForSeed
    ) public view returns (bool, string memory) {
        if (buyer == address(0)) {
            return (false, "Buyer address must be defined.");
        }

        if (receiver == address(0)) {
            return (false, "Receiver address must be defined.");
        }

        if (
            buyer2ForSeed == address(0) &&
            category == DataTypes.VestingCategory.Seed 
        ) {
            return (false, "Receiver2 must be real wallet");
        }

        if (_vestingResult[requestHash] != address(0)) {
            return (false, "Escrow was created already for this request hash");
        }

        if (amount < _minVestingAmount || amount > _maxVestingAmount) {
            return (false, "Invalid amount for vesting");
        }

        if (msg.sender.isContract() == true) {
            return (false, "Only vesting is available from admin.");
        }

        bytes memory tmpCheckString = bytes(requestHash);
        require(tmpCheckString.length > 0, "Request hash is required.");

        address subWallet = _subWallets[category];

        if (subWallet == address(0)) {
            return (false, "Invalid subwallet for vesting category");
        }

        if (IERC20(_vestingToken).balanceOf(subWallet) < amount) {
            return (false, "Insufficient balance of subwallet for vesting.");
        }

        return (true, "");
    }

    function deployVestingContract(
        DataTypes.VestingCategory category,
        uint256 amount,
        address buyer,
        string memory requestHash,
        address receiver,
        address buyer2ForSeed // Only for seed investors, beside of seed, this will be address(0)
    ) public onlyOwner notPaused nonReentrant returns (address) {
        bool possibleToDeploy;
        string memory errorMessage;

        (possibleToDeploy, errorMessage) = canDeployVestingContract(
            category,
            amount,
            buyer,
            requestHash,
            receiver,
            buyer2ForSeed
        );

        require(possibleToDeploy, errorMessage);

        console.log("deployVestingContract by onlyOwner ", amount);

        address buyer2 = address(0);

        if (category == DataTypes.VestingCategory.Seed) {
            buyer2 = buyer2ForSeed;
        }

        SERSHVestingEscrow vesting = new SERSHVestingEscrow(
            category,
            _vestingPlan[category],
            amount,
            buyer,
            requestHash,
            receiver,
            _vestingToken,
            _version,
            address(this),
            buyer2
        );

        // todo transfer amount of SERSH to vesting contract
        TokenHelper.safeTransferFrom(
            _vestingToken,
            _subWallets[category],
            address(vesting),
            amount
        );

        _buyerVestingAmount[buyer] = _buyerVestingAmount[buyer] + amount;
        _totalVested = _totalVested + amount;
        _categoryTotalVested[category] += amount;

        _isVestingEscrow[address(vesting)] = true;

        console.log(
            "Deployed vesting contract address deployVestingContract ",
            address(vesting)
        );

        _vestingResult[requestHash] = address(vesting);

        emit DeployedVesting(
            address(vesting),
            category,
            amount,
            buyer,
            requestHash,
            receiver,
            buyer2,
            // timestamp,
            _vestingToken
        );

        return address(vesting);
    }

    function unvesting(address vesting) external onlyOwner {
        // todo admin can call this to force unvesting
        require(
            _isVestingEscrow[vesting] == true,
            "Invalid vesting contract address."
        );

        bool canUnvesting;
        string memory errmsg;

        (canUnvesting, errmsg) = ISERSHVestingEscrow(vesting).canUnvesting();
        require(canUnvesting == true, errmsg);

        ISERSHVestingEscrow(vesting).unvesting();
        // emit Unvested(vesting, block.timestamp);
    }



    function isFinished(address vesting) external view returns (bool) {
        // todo admin can call this to force unvesting
        require(
            _isVestingEscrow[vesting] == true,
            "Invalid vesting contract address."
        );

        return ISERSHVestingEscrow(vesting).isFinished();
    }


    function getEscrowAddress(
        string memory requestHash
    ) public view returns (address) {
        return _vestingResult[requestHash];
    }

    function triggerUnvestedEvent(string memory requestHash, address vesting, address receiver, uint256 amount, uint256 when, uint8 finished, uint64 oldstep) external {
        require(_msgSender() == vesting, 'Only escrow contract can call');
        require( _isVestingEscrow[vesting] == true, 'Only caller must be vesting contract');

        emit Unvested(vesting, receiver, requestHash, amount, when, finished, oldstep);
    }
}