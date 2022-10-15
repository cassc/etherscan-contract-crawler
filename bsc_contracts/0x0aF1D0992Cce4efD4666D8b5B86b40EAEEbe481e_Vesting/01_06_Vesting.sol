/*************************************************************************************
 * 
 * Autor & Owner: BotPlanet
 *
 * 446576656c6f7065723a20416e746f6e20506f6c656e79616b61 *****************************/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IVesting.sol";

contract Vesting is IVesting {

    // Attributies

    ERC20 private _tokenBOT;
    address private _owner;
    address private _contractAddress;
    bool private _isPaused;
    uint256 _minTimeBetweenReleases;

    BeneficiaryData[] private _beneficiarys;
    mapping(address => BeneficiaryData) private _addressToBeneficiary;
    mapping(address => bool) private _benefeciaryExists;

    // Constants

    address constant BOT_V2_ADDRESS = 0x0026908A7eFA57eccbbbE4Ba68C48eb670311d01;
    uint256 constant FIRST_DATE_TO_RELEASE = 1666915200; // Fri Oct 28 2022 00:00:00 GMT+0000

    // Constructor

    constructor() {
        _isPaused = false;
        _tokenBOT = ERC20(BOT_V2_ADDRESS);
        _contractAddress = address(this);
        _minTimeBetweenReleases = 30 days;
        _owner = address(msg.sender);
        emit OwnerChanged(address(0), _owner);
    }

    // Modifiers

    modifier onlyOwner() {
        require(_owner == msg.sender, "Vesting: caller is not the owner");
        _;
    }

    modifier notPaused() {
        require(!_isPaused, "Vesting: Contract state is paused!");
        _;
    }

    // Methods: General

    function GetTokensBalance() external override view notPaused returns(uint256) {
        return _vestedAmount();
    }

    function GetBNBBalance() external override view notPaused returns(uint256) {
        return _contractAddress.balance;
    }

    function Pause() external override onlyOwner {
        _isPaused = true;
        emit StateChanged(_isPaused);
    }

    function Unpause() external override onlyOwner {
        _isPaused = false;
        emit StateChanged(_isPaused);
    }

    function IsPaused() external view returns(bool) {
        return _isPaused;
    }

    // Methods: Owner

    function OwnerSet(address newOwner) external onlyOwner {
        // Check data        
        require(newOwner != address(0), "Vesting: Address of owner need to be different 0");
        // Work
        _owner = newOwner;
        // Event
        emit OwnerChanged(msg.sender, newOwner);
    }

    function OwnerGet() external view notPaused returns(address) {
        return _owner;
    }

    // Methods: Beneficiary

    function _vestedAmount() internal view returns(uint256 balance) {
        return _tokenBOT.balanceOf(_contractAddress);
    }

    function _beneficiaryAdd(address account_, uint256 periodAmount_) internal {
        _beneficiaryFastAdd(account_, periodAmount_, FIRST_DATE_TO_RELEASE - _minTimeRelease(), FIRST_DATE_TO_RELEASE);
    }

    function _beneficiaryFastAdd(
        address account_, 
        uint256 periodAmount_, 
        uint256 lastTransferTimestamp, 
        uint256 nextTransferTimestamp) internal {
        // Work
        BeneficiaryData memory data = BeneficiaryData({
            account: account_,
            periodAmount: periodAmount_,
            lastTransferTimestamp: lastTransferTimestamp,
            nextTransferTimestamp: nextTransferTimestamp
        });
        _beneficiarys.push(data);
        _addressToBeneficiary[account_] = data;
        _benefeciaryExists[account_] = true;
    }

    function BeneficiaryAdd(address account_, uint256 periodAmount_) external override onlyOwner {
        // Check data
        require(account_ != address(0), "Vesting: account address need to be different 0");
        require(periodAmount_ > 0, "Vesting: amount need to be greater 0");
        // Work
        _beneficiaryAdd(account_, periodAmount_);
        // Event
        emit BeneficiaryAdded(account_, periodAmount_);
    }

    function BeneficiaryAddExtended(address account_, uint256 periodAmount_, uint256 nextTransferTimestamp) external override onlyOwner {
        // Check data
        require(account_ != address(0), "Vesting: account address need to be different 0");
        require(periodAmount_ > 0, "Vesting: amount need to be greater 0");
        // Work
        _beneficiaryFastAdd(account_, periodAmount_, nextTransferTimestamp - _minTimeRelease(), nextTransferTimestamp);
        // Event
        emit BeneficiaryAdded(account_, periodAmount_);
    }

    function BeneficiaryUpdate(address account_, uint256 periodAmount_, uint256 nextTransferTimestamp) external override onlyOwner {
        // Check data
        require(account_ != address(0), "Vesting: account address need to be different 0");
        require(periodAmount_ > 0, "Vesting: amount need to be greater 0");
        require(_benefeciaryExists[account_] == true, "Vesting: don't exist any beneficiary with this account address");
        // Work
        BeneficiaryData storage data = _addressToBeneficiary[account_];
        data.periodAmount = periodAmount_;
        data.lastTransferTimestamp = nextTransferTimestamp - _minTimeRelease();
        data.nextTransferTimestamp = nextTransferTimestamp;
        // Event
        emit BeneficiaryUpdated(account_, periodAmount_);
    }

    function _removeFromArray(uint256 index_) internal {
        _beneficiarys[index_] = _beneficiarys[_beneficiarys.length - 1];
        _beneficiarys.pop();
    }

    function _getIndexFromArray(address account_) internal view returns(bool exist, uint256 index) {
        index = 0;
        exist = false;
        for(uint256 i = 0; i < _beneficiarys.length; i++) {
            if(_beneficiarys[i].account == account_) {
                exist = true;
                index = i;
                break;
            }
        }
        return (exist, index);
    }

    function BeneficiaryRemove(address account_) external override onlyOwner {
        // Check data
        require(account_ != address(0), "Vesting: account address need to be different 0");
        require(_benefeciaryExists[account_] == true, "Vesting: don't exist any beneficiary with this account address");
        // Work
        (bool exist, uint256 index) = _getIndexFromArray(account_);
        if(exist) {
            _removeFromArray(index);
            delete _addressToBeneficiary[account_];
            _benefeciaryExists[account_] = false;
            // Event
            emit BeneficiaryRemoved(account_);
        }
    }

    function BeneficiaryRestartTransfers(address account_) external override onlyOwner {
        // Check data
        require(account_ != address(0), "Vesting: account address need to be different 0");
        require(_benefeciaryExists[account_] == true, "Vesting: don't exist any beneficiary with this account address");
        // Work
        BeneficiaryData storage data = _addressToBeneficiary[account_];
        data.lastTransferTimestamp = block.timestamp;
        data.nextTransferTimestamp = block.timestamp + _minTimeRelease();
        // Event
        emit BeneficiaryRestartedTransfers(account_);
    }

    function BeneficiaryGetInfo(address account_) external override view notPaused returns(BeneficiaryData memory) {
        // Check data
        require(account_ != address(0), "Vesting: account address is zero!");
        require(_benefeciaryExists[account_] == true, "Vesting: beneficiary with this address not exist!");
        // Return data
        return _addressToBeneficiary[account_];
    }

    // Methods: Distribution

    function _minTimeRelease() internal view returns(uint256 time) {
        return _minTimeBetweenReleases;
    }

    function _checkTimeRelease(uint256 nextTransfer_) internal view returns(bool isAllowedRelease){
        isAllowedRelease = nextTransfer_ > 0 && block.timestamp >= nextTransfer_;
        return isAllowedRelease;
    }

    function _checkAmount(uint256 amount) internal view returns(bool isAmountOk) {
        isAmountOk = amount > 0 && _vestedAmount() >= amount;
        return isAmountOk;
    }

    function _releaseOneBeneficiary(address account_) internal returns(bool isReleased, uint256 amount, string memory error) {
        isReleased = false;
        amount = 0;
        error = "";
        // Check if address of beneficiary exist
        bool exist = _benefeciaryExists[account_];
        if(exist) {
            // Check last time execution/release
            BeneficiaryData storage data = _addressToBeneficiary[account_];
            bool isAllowedRelease = _checkTimeRelease(data.nextTransferTimestamp);
            if(isAllowedRelease) {
                // Check amount
                bool isAmountOk = _checkAmount(data.periodAmount);
                if (isAmountOk) {
                    // Transfer tokens to beneficiary
                    _tokenBOT.transfer(data.account, data.periodAmount);
                    // Increase time for next claim
                    do {
                        data.nextTransferTimestamp = data.nextTransferTimestamp + _minTimeRelease();
                    } while(data.nextTransferTimestamp <= block.timestamp);
                    data.lastTransferTimestamp = data.nextTransferTimestamp - _minTimeRelease();
                    isReleased = true;
                    amount = data.periodAmount;
                } else {
                    error = "Vesting: Amount is not allowed";
                }
            } else {
                error = "Vesting: Is not time to release tokens";
            }
        } else {
            error = "Vesting: Beneficiary not exist";
        }
        return (isReleased, amount, error);
    }

    function ReleaseTokens() external override notPaused {
        // Check data
        require(!_isPaused, "Vesting: Contract state is paused!");
        require(_beneficiarys.length > 0, "Vesting: we don't have any beneficiary!");
        require(_vestedAmount() > 0, "Vesting: vesting amount is zero!");
        // Work
        uint256 releasedTokens = 0;
        for(uint256 i = 0; i < _beneficiarys.length; i++) {
            // Transfer tokens
            (bool isReleased, uint256 amount,) = _releaseOneBeneficiary(_beneficiarys[i].account);
            if(isReleased) {
                releasedTokens += amount;
            }
        }
        // Check result
        require(releasedTokens > 0, "Vesting: nobody now receive tokens!");
        // Event
        emit ReleasedTokens(releasedTokens);
    }
}