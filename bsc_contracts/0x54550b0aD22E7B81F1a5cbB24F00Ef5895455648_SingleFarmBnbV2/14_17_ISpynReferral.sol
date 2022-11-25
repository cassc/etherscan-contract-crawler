pragma solidity ^0.8.0;

interface ISpynReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(
        address _referrer,
        address _referee,
        uint256 _commission,
        address _token,
        uint256 _type,
        uint256 _level
    ) external;

    function recordReferralCommissionMissing(
        address _referrer,
        address _referee,
        uint256 _commission,
        address _token,
        uint256 _type,
        uint256 _level
    ) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);

    /**
     * @dev Get the referrer addresses that referred the user by level.
     */
    function getReferrersByLevel(
        address _user,
        uint256 count
    ) external view returns (
        address[] memory referrersByLevel
    );
}