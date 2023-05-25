pragma solidity >=0.5.0;

interface IReferralRegistry {
    function getUserReferee(address _user) external view returns (address);

    function hasUserReferee(address _user) external view returns (bool);

    function createReferralAnchor(address _user, address _referee) external;
}