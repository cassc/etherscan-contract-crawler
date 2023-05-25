pragma solidity =0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ReferralRegistry is Ownable {
    event ReferralAnchorCreated(address indexed user, address indexed referee);
    event ReferralAnchorUpdated(address indexed user, address indexed referee);
    event AnchorManagerUpdated(address account, bool isManager);

    // stores addresses which are allowed to create new anchors
    mapping(address => bool) public isAnchorManager;

    // stores the address that referred a given user
    mapping(address => address) public referralAnchor;

    /// @dev create a new referral anchor on the registry
    /// @param _user address of the user
    /// @param _referee address wich referred the user
    function createReferralAnchor(address _user, address _referee) external onlyAnchorManager {
        require(referralAnchor[_user] == address(0), "ReferralRegistry: ANCHOR_EXISTS");
        referralAnchor[_user] = _referee;
        emit ReferralAnchorCreated(_user, _referee);
    }

    /// @dev allows admin to overwrite anchor
    /// @param _user address of the user
    /// @param _referee address wich referred the user
    function updateReferralAnchor(address _user, address _referee) external onlyOwner {
        referralAnchor[_user] = _referee;
        emit ReferralAnchorUpdated(_user, _referee);
    }

    /// @dev allows admin to grant/remove anchor priviliges
    /// @param _anchorManager address of the anchor manager
    /// @param _isManager add or remove privileges
    function updateAnchorManager(address _anchorManager, bool _isManager) external onlyOwner {
        isAnchorManager[_anchorManager] = _isManager;
        emit AnchorManagerUpdated(_anchorManager, _isManager);
    }

    function getUserReferee(address _user) external view returns (address) {
        return referralAnchor[_user];
    }

    function hasUserReferee(address _user) external view returns (bool) {
        return referralAnchor[_user] != address(0);
    }

    modifier onlyAnchorManager() {
        require(isAnchorManager[msg.sender], "ReferralRegistry: FORBIDDEN");
        _;
    }
}