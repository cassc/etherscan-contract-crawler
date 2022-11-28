// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;
import "./interfaces/Interfaces.sol";

/// @title Option Vault Factory
/// @author dannydoritoeth
/// @notice The central contract for deploying and managing option collateral vaults.
contract Referrals is AccessControl {

    // properties
    address public optionsContract;
    address public referralFeeRecipient;
    uint public referFee = 50;  //.5%
    uint public referralPeriod = 52 weeks;  //1 year
    mapping(address => address) public referredBy;
    mapping(address => uint256) public referredDate;
    mapping(address => uint256) public referrerId;
    address[] public referrers;
    mapping(address => bool) public blacklisted;

    // constants

    // events

    /// @notice An address is added/removed from the blacklist
    /// @param account the address making the change
    /// @param value The address
    /// @param isBlacklisted Is blacklisted?
    event Blacklisted(address indexed account, address indexed value, bool isBlacklisted);

    /// @notice Change the address that receives the referral fee when there is no referrer
    /// @param account the address making the change
    /// @param value the address
    event ReferralFeeRecipient(address indexed account, address indexed value);

    /// @notice An address is added as a referrer
    /// @param account the address making the change
    /// @param position what position the address it added to
    event AddReferrer(address indexed account, address indexed value, uint position);

    /// @notice Referral period has been updated
    /// @param account the address making the change
    /// @param referralPeriod the new period
    event SetReferralPeriod(address indexed account, uint referralPeriod);

    // functions

    /// @notice Constructor for the contract
    /// @param _referralFeeRecipient the address that receives the referral fee when there is no referrer
    constructor(address _referralFeeRecipient) {
        require(_referralFeeRecipient!=address(0), "Referrals: referralFeeRecipient can't be null");
        referralFeeRecipient = _referralFeeRecipient;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        addReferrer(_msgSender());
    }

    function initialize(address _optionsContract) external {
        require(optionsContract==address(0), "Referrals: optionsContract must be 0 address");
        optionsContract = _optionsContract;
    }


    /// @notice Implements the function to return the refer fee
    /// @param inParams the parameters passed to the premium function in a struct
    function getReferFee(IStructs.InputParams memory inParams) external view returns (uint256) {
        return referFee*inParams.optionSize/1e4;
    }


    /// @notice Captures a referal and creates a referer record for the holder address.
    /// If there is none passed in then check if there is valid one on record and use that
    /// If there is no valid one on record then capture a new referral record
    /// Store in an array so there can be a number that links the referrer's address for nice urls
    /// @param holder The address purchasing the option
    /// @param referredByIn Who the proposed referrer is
    /// @return referredByOut Who the actual referrer is
    function captureReferral(address holder, address referredByIn) external returns (address referredByOut) {
        require(optionsContract == _msgSender(), "Referrals: must be called from options contract");

        if(blacklisted[referredByIn]){
            //clear the referrer if its blacklisted
            if (referredBy[holder] == referredByIn){
                referredBy[holder] = address(0);
                referredDate[holder] = block.timestamp;
            }
            referredByIn = referralFeeRecipient;
        }

        if((referredBy[holder]!=address(0)) && (referredDate[holder] + referralPeriod>=block.timestamp)){
            //valid referred by on record, so use that
            referredByOut = referredBy[holder];
        }
        else{
            //on record referred by either expired or null so use the protocol recipient
            if(referredByIn == address(0) || referredByIn == holder){
                referredByOut = referralFeeRecipient;
            }
            else{
                //use the referred by passed in
                referredByOut = referredByIn;
            }

            // its null or expired so
            referredBy[holder] = referredByOut;
            referredDate[holder] = block.timestamp;
            addReferrer(referredByOut);
        }
        require(referredByOut!=address(0), "Referrals: referredByOut can't be null");
    }

    /// @notice Add a referrer to the array. Referers can use this integer when referring rather than their full address
    /// @param value the address to add to the array
    function addReferrer(address value) public {
        if(referrerId[value]==0){
            // id for a friendly url
            uint rId = referrers.length;
            referrerId[value] = rId;
            referrers.push(value);
            emit AddReferrer(_msgSender(), value, rId);
        }
    }

    /// @notice A modifer that checks if the caller holds the DEFAULT_ADMIN_ROLE role on the referrals contract
    modifier IsDefaultAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Referrals: must have admin role");
        _;
    }

    /// @notice Change the address that receives the referral fee when there is no referrer
    /// @param value The address
    function setReferralFeeRecipient(address value) external IsDefaultAdmin  {
        require(value!=address(0), "Referrals: referralFeeRecipient can't be null");
        referralFeeRecipient = value;
        emit ReferralFeeRecipient(_msgSender(), value);
    }

    /// @notice An address is added/removed from the blacklist
    /// @param value The address
    /// @param isBlacklisted Is blacklisted
    function setBlacklisted(address value, bool isBlacklisted) public IsDefaultAdmin  {
        blacklisted[value] = isBlacklisted;
        emit Blacklisted(_msgSender(),value,isBlacklisted);
    }

    /// @notice Bulk address' are added/removed from the blacklist
    /// @param addresses the array of addresses
    /// @param isBlacklisted whether they should be blacklisted or not
    function setBlacklistedAll(address[] calldata addresses, bool isBlacklisted) external IsDefaultAdmin  {
        uint arrayLength = addresses.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            blacklisted[addresses[i]] = isBlacklisted;
            emit Blacklisted(_msgSender(),addresses[i],isBlacklisted);
        }
    }

    /// @notice Update the referral period
    /// @param _referralPeriod the new period
    function setReferralPeriod(uint _referralPeriod) public IsDefaultAdmin  {
        require(_referralPeriod>=12 weeks, "Referrals: Can't be less that 3 months");
        referralPeriod = _referralPeriod;
        emit SetReferralPeriod(_msgSender(),_referralPeriod);
    }
}