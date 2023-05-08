// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IReferralHub {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NewReferralRecord(bytes32 indexed referralNodeHash);
    

    //Authorises a controller, who can issue a gift card.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    //check if a domain name is eligible for referral program
    function isReferralEligible(
        bytes32 nodeHash
    ) external view returns (bool, address);

    //add a referral count for a given referrer
    function addNewReferralRecord(bytes32 referrerNodeHash) external;

    //get a domain's referral count, referral comission and referee comission
    function getReferralDetails(bytes32 referrerNodeHash)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    //set partner comission chart
    function setPartnerComissionChart(
        string calldata name,
        string calldata tld,
        uint256 minimumReferralCount,
        uint256 referrerComission,
        uint256 refereeComission
    ) external;

    function getReferralCommisionFee(uint256 price, bytes32 nodeHash) external view returns (uint256, uint256);

    function deposit(address _referrer) external payable;

    function withdraw() external;
}