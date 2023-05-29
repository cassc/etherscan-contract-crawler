// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {IERC20} from "src/interfaces/external/IERC20.sol";
import {ISpotStorage} from "src/spot/interfaces/ISpotStorage.sol";
import {ISpot} from "src/spot/interfaces/ISpot.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ISwap} from "src/spot/uni/interfaces/ISwap.sol";
import {ITrade} from "src/spot/uni/interfaces/ITrade.sol";

/*//////////////////////////////////////////////////////////////
                        CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

error ZeroAddress();
error ZeroAmount();
error NoAccess(address desired, address given);
error StillFundraising(uint256 desired, uint256 given);
error FundraisingComplete();
error BelowMin(uint96 min, uint96 given);
error AboveMax(uint96 max, uint96 given);
error FundExists(address fund);
error NoBaseToken(address token);
error AlreadyOpened();
error CantOpen();
error CantClose();
error AlreadyClaimed();
error NotFinalised();
error NotValidPlugin();

/// @title Spot
/// @author 7811
/// @notice Contract for the investors to deposit and for managers to open and close positions
contract Spot is ISpot, Pausable {
    // owner/deployer of the contract
    address public owner;
    // max fundraising period which can be used by the manager to raise funds (defaults - 1 week)
    uint40 public maxFundraisingPeriod;
    // address used by the backend bot to close/cancel the stfs
    address public admin;
    // address used to collect the protocol fees
    address public treasury;
    // percentage of fees from the profits of the stf to the manager (default - 15e18 (15%))
    uint96 public managerFee;
    // percentage of fees from the profits of the stf to the protocol (default - 5e18 (5%))
    uint96 public protocolFee;
    // min investment amount per investor per stf
    mapping(address => uint96) public minInvestmentAmount;
    // manager's address to indicate if the manager is managing a fund currently
    // manager can only manage one stf per address
    mapping(address => bool) public isManagingFund;
    // mapping to get the details of the stf
    mapping(bytes32 => StfSpotInfo) public stfInfo;
    // mapping to get the manager's current stf
    mapping(address => bytes32) public managerCurrentStf;
    // amount an investor deposits into a particular stf
    mapping(address => mapping(bytes32 => uint96)) public userAmount;
    // amount an investor claims from a particular stf
    mapping(address => mapping(bytes32 => uint96)) public claimAmount;
    // amount an investor claims form an stf if partial amount was used to open a spot position
    mapping(address => mapping(bytes32 => uint96)) public claimPartialAmount;
    // is the base token for opening a spot position eligible
    mapping(address => bool) public isBaseToken;
    // is the deposit token for opening a spot position eligible
    mapping(address => bool) public isDepositToken;
    // capacity of each token which can be fundraised per stf
    mapping(address => mapping(address => uint96)) public tokenCapacity;
    // contracts will can call functions in this contract, `transferToken(), openSpot(), closeSpot)`
    mapping(address => bool) public isPlugin;
    // map the trade contract to the baseToken
    mapping(address => address) public tradeMapping;

    /*//////////////////////////////////////////////////////////////
                            INITIALIZE
    //////////////////////////////////////////////////////////////*/

    constructor(address _admin, address _treasury) {
        owner = msg.sender;
        admin = _admin;
        treasury = _treasury;
        maxFundraisingPeriod = 1 weeks;
        managerFee = 15e18;
        protocolFee = 5e18;

        emit InitializeSpot({
            _maxFundraisingPeriod: 1 weeks,
            _mFee: managerFee,
            _pFee: protocolFee,
            _owner: msg.sender,
            _admin: _admin,
            _treasury: _treasury
        });
    }

    /// @notice initializes the base token for creating an stf
    /// @dev can only be called by the owner
    /// @param _baseToken address of the token which can be used as the base/asset when creating an stf
    /// @param _isBaseToken bool to change if the baseToken is eligible or not
    function changeBaseToken(address _baseToken, bool _isBaseToken) external onlyOwner {
        if (_baseToken == address(0)) revert ZeroAddress();
        isBaseToken[_baseToken] = _isBaseToken;
        emit BaseTokenUpdate(_baseToken, _isBaseToken);
    }

    /// @notice initializes the deposit token for creating an stf
    /// @dev can only be called by the owner
    /// @param _depositToken address of the token which can be used as the deposit when creating an stf
    /// @param _isDepositToken bool to change if the depositToken is eligible or not
    function changeDepositToken(address _depositToken, bool _isDepositToken) external onlyOwner {
        if (_depositToken == address(0)) revert ZeroAddress();
        isDepositToken[_depositToken] = _isDepositToken;
        emit DepositTokenUpdate(_depositToken, _isDepositToken);
    }

    /// @notice adds the total capacity of the deposit token for fundraising per stf
    /// @dev can only be called by the owner
    /// @param baseToken address of the base token
    /// @param depositToken address of the deposit token
    /// @param capacity the total amount of tokens which can be used while fundraising
    function addTokenCapacity(address baseToken, address depositToken, uint96 capacity) external onlyOwner {
        if (baseToken == address(0)) revert ZeroAddress();
        if (depositToken == address(0)) revert ZeroAddress();
        if (capacity < 1) revert ZeroAmount();
        tokenCapacity[baseToken][depositToken] = capacity;
        emit TokenCapacityUpdate(baseToken, depositToken, capacity);
    }

    /// @notice set the min investment of deposit an investor can invest per stf
    /// @dev can only be called by the `owner`
    /// @param _token address of the deposit token
    /// @param _amount min investment of deposit an investor can invest per stf
    function addMinInvestmentAmount(address _token, uint96 _amount) external override onlyOwner {
        if (_amount < 1) revert ZeroAmount();
        minInvestmentAmount[_token] = _amount;
        emit MinInvestmentAmountChanged(_token, _amount);
    }

    /// @notice Updates the plugin addresses
    /// @dev can only be called by the `owner`
    /// @param _plugin address of the plugin which can be used to called `transferToken()`, `openSpot()`, `closeSpot()`
    /// @param _isPlugin bool to determine if the address is a plugin
    function addPlugin(address _plugin, bool _isPlugin) external onlyOwner {
        if (_plugin == address(0)) revert ZeroAddress();
        isPlugin[_plugin] = _isPlugin;
        emit PluginUpdate(_plugin, _isPlugin);
    }

    /// @notice Updates the link of baseToken to the Trade contract of protocols
    /// @dev can only be called by the `owner`
    /// @param _baseToken address of the baseToken
    /// @param _stfxTrade address of the Trade contract of different protocols (uni, sushi, tj)
    function addTradeMapping(address _baseToken, address _stfxTrade) external onlyOwner {
        if (_baseToken == address(0)) revert ZeroAddress();
        tradeMapping[_baseToken] = _stfxTrade;
        emit TradeMappingUpdate(_baseToken, _stfxTrade);
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice modifier for the setters to be called only by the manager
    modifier onlyOwner() {
        if (msg.sender != owner) revert NoAccess(owner, msg.sender);
        _;
    }

    /// @notice modifier for cancel vaults to be called only by the admin
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NoAccess(admin, msg.sender);
        _;
    }

    /// @notice modifier to check if the msg.sender is a plugin
    modifier onlyPlugin() {
        if (!isPlugin[msg.sender]) revert NotValidPlugin();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice get the stf details by giving the salt as input
    /// @param _salt the stf salt
    /// @return StfSpotInfo the stf info struct
    function getStfInfo(bytes32 _salt) public view returns (StfSpotInfo memory) {
        return stfInfo[_salt];
    }

    /// @notice get the manager address by giving the salt as input
    /// @param _salt the stf salt
    /// @return manager address
    function getManagerFromSalt(bytes32 _salt) public view returns (address) {
        StfSpotInfo memory _stf = stfInfo[_salt];
        return _stf.manager;
    }

    /// @notice get the stf details by giving the manager address as input
    /// @param _manager address of the manager
    /// @return StfSpotInfo the stf info struct
    function getManagerCurrentStfInfo(address _manager) public view returns (StfSpotInfo memory) {
        bytes32 salt = managerCurrentStf[_manager];
        return stfInfo[salt];
    }

    /// @notice get the stf salt by giving the manager address as input
    /// @param _manager address of the manager
    /// @return salt of the stf
    function getManagerCurrentSalt(address _manager) public view returns (bytes32) {
        bytes32 salt = managerCurrentStf[_manager];
        return salt;
    }

    /// @notice get the pnl of the stf after deducting the fees
    /// @param _salt salt of the stf
    /// @return pnlAfterFees the pnl after the fees has been deducted
    function getPnlAfterFees(bytes32 _salt) external view returns (int96 pnlAfterFees) {
        StfSpotInfo memory _stf = stfInfo[_salt];
        pnlAfterFees = int96(_stf.remainingAfterFees) - int96(_stf.totalRaised);
    }

    /// @notice view function to get the status of the stf
    function getStatusOfStf(bytes32 _salt) public view returns (StfStatus) {
        StfSpotInfo memory _stf = stfInfo[_salt];
        return _stf.status;
    }

    function hasFundraisingPeriodEnded(bytes32 _salt) public view returns (bool) {
        StfSpotInfo memory _stf = stfInfo[_salt];
        if (block.timestamp > _stf.endTime) return true;
        else return false;
    }

    function getIsBaseToken(address _token) external view returns (bool) {
        return isBaseToken[_token];
    }

    function getIsDepositToken(address _token) external view returns (bool) {
        return isDepositToken[_token];
    }

    /// @notice get the capacity of the baseToken per stf
    function getTokenCapacity(address _baseToken, address _depositToken) public view returns (uint96) {
        return tokenCapacity[_baseToken][_depositToken];
    }

    /// @notice get if the manager is managing an stv
    function getIsManagingFund(address _manager) public view returns (bool) {
        return isManagingFund[_manager];
    }

    /// @notice get the deposit amount of the investor per stf
    function getUserAmount(address _investor, bytes32 _salt) external view returns (uint96) {
        return userAmount[_investor][_salt];
    }

    /// @notice get the claim amount of the investor per stf
    function getClaimAmount(address _investor, bytes32 _salt) external view returns (uint96) {
        return claimAmount[_investor][_salt];
    }

    /// @notice get the partial claim amount of the investor per stf
    function getClaimPartialAmount(address _investor, bytes32 _salt) external view returns (uint96) {
        return claimPartialAmount[_investor][_salt];
    }

    /// @notice get the trade contract for the given baseToken
    function getTradeMapping(address _baseToken) external view returns (address) {
        return tradeMapping[_baseToken];
    }

    /// @notice view function to see if the stf has been `DISTRIBUTED`, ie, position is closed
    function isDistributed(bytes32 _salt) external view returns (bool) {
        StfStatus _status = getStatusOfStf(_salt);
        if (_status == StfStatus.DISTRIBUTED) return true;
    }

    /// @notice view function to see if the stf has been `OPENED`, ie, spot position was opened
    function isOpened(bytes32 _salt) external view returns (bool) {
        StfStatus _status = getStatusOfStf(_salt);
        if (_status == StfStatus.OPENED) return true;
    }

    /// @notice view function to see if the stf has been `CANCELLED_WITH_ZERO_RAISE`, ie, the stf has been cancelled with nothing raised
    function isCancelledWithZeroRaised(bytes32 _salt) external view returns (bool) {
        StfStatus _status = getStatusOfStf(_salt);
        if (_status == StfStatus.CANCELLED_WITH_ZERO_RAISE) return true;
    }

    /// @notice view function to see if the stf has been `CANCELLED_WITH_NO_FILL`, ie, the stf has been cancelled without any position
    function isCancelledWithNoFill(bytes32 _salt) external view returns (bool) {
        StfStatus _status = getStatusOfStf(_salt);
        if (_status == StfStatus.CANCELLED_WITH_NO_FILL) return true;
    }

    /// @notice view function to see if the stf has been `CANCELLED_BY_MANAGER`, ie, the stf has been cancelled by the manager
    function isCancelledByManager(bytes32 _salt) external view returns (bool) {
        StfStatus _status = getStatusOfStf(_salt);
        if (_status == StfStatus.CANCELLED_BY_MANAGER) return true;
    }

    /// @notice view function to see if the stf has been `NOT_OPENED`, ie, no open orders has been created
    function isNotOpened(bytes32 _salt) external view returns (bool) {
        StfStatus _status = getStatusOfStf(_salt);
        if (_status == StfStatus.NOT_OPENED) return true;
    }

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Create a new Single Trade Fund (STF)
    /// @dev returns the address of the proxy contract with Stfx.sol implementation
    /// @param _stf the fund details, check `ISpotStorage.Stf`
    /// @return salt of the stf
    function createNewStf(StfSpot calldata _stf) external override whenNotPaused returns (bytes32 salt) {
        if (isManagingFund[msg.sender]) revert FundExists(msg.sender);
        if (_stf.fundraisingPeriod < 15 minutes) revert BelowMin(15 minutes, _stf.fundraisingPeriod);
        if (_stf.fundraisingPeriod > maxFundraisingPeriod) {
            revert AboveMax(maxFundraisingPeriod, _stf.fundraisingPeriod);
        }
        if (!isBaseToken[_stf.baseToken] || !isDepositToken[_stf.depositToken]) {
            revert NoBaseToken(_stf.baseToken);
        }

        salt = keccak256(
            abi.encodePacked(
                msg.sender,
                _stf.baseToken,
                _stf.depositToken,
                _stf.fundraisingPeriod,
                block.timestamp,
                block.number,
                block.chainid
            )
        );

        managerCurrentStf[msg.sender] = salt;
        isManagingFund[msg.sender] = true;
        stfInfo[salt].manager = msg.sender;
        stfInfo[salt].baseToken = _stf.baseToken;
        stfInfo[salt].depositToken = _stf.depositToken;
        stfInfo[salt].endTime = uint40(block.timestamp) + _stf.fundraisingPeriod;
        stfInfo[salt].fundDeadline = 72 hours;

        emit NewFundCreated(
            _stf.baseToken,
            _stf.depositToken,
            _stf.fundraisingPeriod,
            msg.sender,
            salt,
            block.chainid,
            tokenCapacity[_stf.baseToken][_stf.depositToken]
        );
    }

    /// @notice deposit a particular amount into an stf for the manager to open a position
    /// @dev `fundraisingPeriod` has to end and the `totalRaised` should not be more than `maxInvestmentPerStf`
    /// @dev amount has to be more than `minInvestmentAmount`
    /// @dev approve has to be called before this method for the investor to transfer usdc to this contract
    /// @param salt the stf salt
    /// @param amount amount the investor wants to deposit
    function depositIntoFund(bytes32 salt, uint96 amount) external whenNotPaused {
        StfSpotInfo memory _stf = getStfInfo(salt);
        uint8 tokenDecimals = IERC20(_stf.depositToken).decimals();
        uint256 balance = IERC20(_stf.depositToken).balanceOf(msg.sender);
        uint96 depositAmount = uint96(amount / (10 ** (18 - tokenDecimals)));

        if (amount < minInvestmentAmount[_stf.depositToken]) {
            revert BelowMin(minInvestmentAmount[_stf.depositToken], amount);
        }
        if (_stf.manager == address(0)) revert ZeroAddress();
        if (uint96(balance) < depositAmount) revert BelowMin(uint96(balance), depositAmount);
        if (uint40(block.timestamp) > _stf.endTime) revert FundraisingComplete();
        if (_stf.status != StfStatus.NOT_OPENED) revert AlreadyOpened();
        if (_stf.totalRaised + amount > tokenCapacity[_stf.baseToken][_stf.depositToken]) {
            revert AboveMax(tokenCapacity[_stf.baseToken][_stf.depositToken], _stf.totalRaised + amount);
        }

        stfInfo[salt].totalRaised += amount;
        userAmount[msg.sender][salt] += amount;

        IERC20(_stf.depositToken).transferFrom(msg.sender, address(this), depositAmount);
        emit DepositIntoFund(msg.sender, amount, salt);
    }

    /// @notice allows the manager to close the fundraising and open a position later
    /// @dev changes the `_stf.endTime` to the current `block.timestamp`
    /// @dev closes fundraising for the current stf managed by the `msg.sender`(manager)
    function closeFundraising() external override whenNotPaused {
        StfSpotInfo memory _stf = getManagerCurrentStfInfo(msg.sender);
        bytes32 salt = managerCurrentStf[msg.sender];

        if (_stf.manager != msg.sender) revert NoAccess(_stf.manager, msg.sender);
        if (_stf.status != StfStatus.NOT_OPENED) revert AlreadyOpened();
        if (_stf.totalRaised < 1) revert ZeroAmount();
        if (block.timestamp >= _stf.endTime) revert CantClose();

        stfInfo[salt].endTime = uint40(block.timestamp);

        emit FundraisingClosed(salt);
    }

    /// @notice transfers an amount of token to the `msg.sender`
    /// @dev can only be called by an approved plugin
    /// @param token address of the token to be transferred
    /// @param amount total amount of tokens to be transferred
    function transferToken(address token, uint256 amount) external override onlyPlugin whenNotPaused {
        IERC20(token).transfer(msg.sender, amount);
    }

    /// @notice Called by the `Trade` contract to change the state after opening a spot position
    /// @dev can only be called by an approved plugin
    /// @param amount the totalAmount which is being used from the stf's `totalRaised`
    /// @param received the total amount of baseToken received after opening a spot position (in baseToken's decimal units)
    /// @param salt the hash of the stf when it was created
    function openSpot(uint96 amount, uint96 received, bytes32 salt) external override onlyPlugin whenNotPaused {
        stfInfo[salt].status = StfStatus.OPENED;
        stfInfo[salt].totalAmountUsed = amount;
        stfInfo[salt].totalReceived = received;
    }

    /// @notice Called by the `Trade` contract to change the state after closing a spot position and distributing the pnl
    /// @dev can only be called by an approved plugin
    /// @param remaining the amount of tokens remaining after closing the spot position (in 1e18 units)
    /// @param salt the hash of the stf when it was created
    function closeSpot(uint96 remaining, bytes32 salt) external override onlyPlugin whenNotPaused {
        stfInfo[salt].status = StfStatus.DISTRIBUTED;
        stfInfo[salt].remainingAfterFees = remaining;
        isManagingFund[stfInfo[salt].manager] = false;
    }

    /// @notice get the `claimableAmount` of the investor from a particular stf
    /// @dev if theres no spot position opened, it'll return the deposited amount
    /// @dev after the spot position is closed, it'll calculate the `claimableAmount` depending on the weightage of the investor
    /// @param _salt the stf salt
    /// @param _investor address of the investor
    /// @return amount which can be claimed by the investor from a particular stf
    function claimableAmount(bytes32 _salt, address _investor) public view override returns (uint256 amount) {
        StfSpotInfo memory _stf = getStfInfo(_salt);

        if ((claimAmount[_investor][_salt] > 0)) {
            // if the investor has already claimed
            amount = 0;
        } else if (_stf.status == StfStatus.OPENED) {
            if (_stf.totalRaised == _stf.totalAmountUsed || claimPartialAmount[_investor][_salt] > 0) {
                // if a spot position is opened and if either the investor has claimed partial amount or if totalRaised is equal to the totalAmountUsed
                amount = 0;
            } else {
                // if a spot position is opened and if the investor can claim the partial amount which was not used by the manager
                uint256 _n =
                    uint256(_stf.totalRaised - _stf.totalAmountUsed) * uint256(userAmount[_investor][_salt]) * 1e18;
                uint256 _d = uint256(_stf.totalRaised) * 1e18;
                amount = _n / _d;
            }
        } else if (_stf.status == StfStatus.DISTRIBUTED) {
            // if the spot position for the stf has been closed and distributed
            uint256 _n = uint256(_stf.remainingAfterFees) * uint256(userAmount[_investor][_salt]) * 1e18;
            uint256 _d = uint256(_stf.totalRaised) * 1e18;
            amount = _n / _d;
        } else {
            // if the stf is either cancelled manually or automatically or if the stf has not been opened
            // valid for NOT_OPENED, CANCELLED_BY_MANAGER, CANCELLED_WITH_ZERO_RAISE, CANCELLED_WITH_NO_FILL
            amount = userAmount[_investor][_salt];
        }
    }

    /// @notice transfers the deposit to the investor depending on the investor's weightage to the totalRaised by the stf
    /// @dev will revert if the investor did not invest in the stf during the fundraisingPeriod
    /// @param _salt the stf salt
    function claim(bytes32 _salt) external override whenNotPaused {
        StfSpotInfo memory _stf = getStfInfo(_salt);
        uint256 amount;

        if (_stf.status == StfStatus.NOT_OPENED) revert NotFinalised();
        if (_stf.status == StfStatus.OPENED) {
            if (_stf.totalAmountUsed == _stf.totalRaised) revert NotFinalised();
            amount = claimableAmount(_salt, msg.sender);
            if (amount < 1) revert ZeroAmount();
            claimPartialAmount[msg.sender][_salt] = uint96(amount);
        } else {
            amount = claimableAmount(_salt, msg.sender);
            if (amount < 1) revert ZeroAmount();
            claimAmount[msg.sender][_salt] = uint96(amount);
        }

        uint8 tokenDecimals = IERC20(_stf.depositToken).decimals();
        uint256 c = amount / (10 ** (18 - tokenDecimals));

        IERC20(_stf.depositToken).transfer(msg.sender, c);
        emit Claimed(msg.sender, amount, _salt);
    }

    /// @notice will change the status of the stf to `CANCELLED` and `isManagingFund(manager)` to false
    /// @dev can be called by the `admin` if there was nothing raised during `fundraisingPeriod`
    /// @dev or if the manager did not open a spot position within the `fundDeadline`
    /// @dev and it can be called by the manager if they want to cancel an stf
    /// @param salt the stf salt
    function cancelVault(bytes32 salt) external override whenNotPaused {
        StfSpotInfo memory _stf = getStfInfo(salt);

        if (_stf.status != StfStatus.NOT_OPENED) revert AlreadyOpened();

        if (msg.sender == admin) {
            if (_stf.totalRaised == 0) {
                if (uint40(block.timestamp) <= _stf.endTime) revert BelowMin(_stf.endTime, uint40(block.timestamp));
                stfInfo[salt].status = StfStatus.CANCELLED_WITH_ZERO_RAISE;
            } else {
                if (uint40(block.timestamp) <= _stf.endTime + _stf.fundDeadline) {
                    revert BelowMin(_stf.endTime + _stf.fundDeadline, uint40(block.timestamp));
                }
                stfInfo[salt].status = StfStatus.CANCELLED_WITH_NO_FILL;
            }
        } else if (msg.sender == _stf.manager) {
            if (_stf.totalRaised == 0) {
                stfInfo[salt].status = StfStatus.CANCELLED_WITH_ZERO_RAISE;
            } else {
                if (uint40(block.timestamp) > _stf.endTime + _stf.fundDeadline) revert CantClose();
                stfInfo[salt].status = StfStatus.CANCELLED_BY_MANAGER;
            }
        } else {
            revert NoAccess(_stf.manager, msg.sender);
        }

        stfInfo[salt].fundDeadline = 0;
        stfInfo[salt].endTime = 0;
        isManagingFund[_stf.manager] = false;

        emit CancelVault(salt);
    }

    function withdraw(address token, uint96 amount) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) revert AboveMax(uint96(balance), amount);
        IERC20(token).transfer(treasury, amount);
        emit Withdraw(token, amount, treasury);
    }

    /*//////////////////////////////////////////////////////////////
                            SETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice set the max fundraising period a manager can use when creating an stf
    /// @dev can only be called by the `owner`
    /// @param _maxFundraisingPeriod max fundraising period a manager can use when creating an stf
    function setMaxFundraisingPeriod(uint40 _maxFundraisingPeriod) external onlyOwner whenNotPaused {
        if (_maxFundraisingPeriod < 15 minutes) revert BelowMin(15 minutes, _maxFundraisingPeriod);
        maxFundraisingPeriod = _maxFundraisingPeriod;
        emit MaxFundraisingPeriodChanged(_maxFundraisingPeriod);
    }

    /// @notice set the manager fee percent to calculate the manager fees on profits depending on the governance
    /// @dev can only be called by the `owner`
    /// @param newManagerFee the percent which is used to calculate the manager fees on profits
    function setManagerFee(uint96 newManagerFee) external override onlyOwner whenNotPaused {
        managerFee = newManagerFee;
        emit ManagerFeeChanged(newManagerFee);
    }

    /// @notice set the protocol fee percent to calculate the protocol fees on profits depending on the governance
    /// @dev can only be called by the `owner`
    /// @param newProtocolFee the percent which is used to calculate the protocol fees on profits
    function setProtocolFee(uint96 newProtocolFee) external override onlyOwner whenNotPaused {
        protocolFee = newProtocolFee;
        emit ProtocolFeeChanged(newProtocolFee);
    }

    /// @notice set the new owner of the StfxVault contract
    /// @dev can only be called by the current `owner`
    /// @param newOwner the new owner of the StfxVault contract
    function setOwner(address newOwner) external override onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }

    /// @notice set the `fundDeadline` for a particular stf to cancel the vault early if needed
    /// @dev can only be called by the `owner` or the `manager` of the stf
    /// @param salt the stf salt
    /// @param newFundDeadline new fundDeadline
    function setFundDeadline(bytes32 salt, uint40 newFundDeadline) external override whenNotPaused {
        StfSpotInfo memory _stf = getStfInfo(salt);
        if (msg.sender != _stf.manager && msg.sender != owner) revert NoAccess(_stf.manager, msg.sender);
        if (newFundDeadline > 72 hours) revert AboveMax(uint96(72 hours), uint96(newFundDeadline));
        stfInfo[salt].fundDeadline = newFundDeadline;
        emit FundDeadlineChanged(salt, newFundDeadline);
    }

    /// @notice set the admin address
    /// @dev can only be called by the `owner`
    /// @param _admin the admin address
    function setAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) revert ZeroAddress();
        admin = _admin;
        emit AdminChanged(_admin);
    }

    /// @notice set the treasury address
    /// @dev can only be called by the `owner`
    /// @param _treasury the treasury address
    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ZeroAddress();
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    /// @notice Set the `isManagingFund` state to true or false depending on the emergency
    /// @dev Can only be called by the owner
    /// @param _manager address of the manager
    /// @param _isManaging true if already managing an stf and false if not managing an stf
    function setIsManagingFund(address _manager, bool _isManaging) external override onlyOwner whenNotPaused {
        isManagingFund[_manager] = _isManaging;
        emit ManagingFundUpdate(_manager, _isManaging);
    }

    /*//////////////////////////////////////////////////////////////
                          PAUSE/UNPAUSE
    //////////////////////////////////////////////////////////////*/

    /// @notice Pause contract
    /// @dev can only be called by the `owner` when the contract is not paused
    function pause() public onlyAdmin whenNotPaused {
        _pause();
    }

    /// @notice Unpause contract
    /// @dev can only be called by the `owner` when the contract is paused
    function unpause() public onlyAdmin whenPaused {
        _unpause();
    }
}