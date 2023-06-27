pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ReferralManager is Ownable {
    mapping(address => address) private _referrers;
    mapping(address => bool) private _validReferrers;
    mapping(string => address) private _linksToAddresses; 
    address private _referralManagerManager;

    address[] private _users; 

    event ReferrerAdded(address referrer, string link);

    // Get referrer for customer
    function getReferrer(address account) public view returns (address) {
        return _referrers[account];
    }

    // Check if a referrer address is valid
    function isValidReferrer(address referrer) public view returns (bool) {
        return _validReferrers[referrer];
    }

    // Map customer to referrer
    function setReferrer(address account, address referrer) public {
        require(msg.sender == _referralManagerManager, "Caller is not the ReferralManagerManager");
        require(_referrers[account] == address(0), "Referrer already set");
        require(_validReferrers[referrer], "Not a valid referrer");
        _referrers[account] = referrer;
        _users.push(account); // add user to the list of users
    }

    // Add referrer
    function addValidReferrer(address referrer, string memory link) public onlyOwner {
        _validReferrers[referrer] = true;
        _linksToAddresses[link] = referrer; 

        emit ReferrerAdded(referrer, link);
    }

    // Remove referrer 
    function removeValidReferrer(address referrer) public onlyOwner {
        _validReferrers[referrer] = false;
    }

    // Set the ReferralManagerManager
    function setReferralManagerManager(address newManager) public onlyOwner {
        _referralManagerManager = newManager;
    }

    // Check if a referral link is valid
    function isValidLink(string memory link) public view returns (bool) {
        address referrerAddress = _linksToAddresses[link];
        return isValidReferrer(referrerAddress);
    }
    
    // Get the address associated with a referral code
    function getReferrerAddress(string memory link) public view returns (address) {
        return _linksToAddresses[link];
    }

    // Get all users
    function getUsers() public view returns (address[] memory) {
        return _users;
    }

    // Get all referrers
    function getReferrers() public view returns (address[] memory) {
        address[] memory referrers = new address[](_users.length);
        for (uint i = 0; i < _users.length; i++) {
            referrers[i] = _referrers[_users[i]];
        }
        return referrers;
    }
}