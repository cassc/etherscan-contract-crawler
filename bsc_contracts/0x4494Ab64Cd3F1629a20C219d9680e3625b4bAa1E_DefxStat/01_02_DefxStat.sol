// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./DefxInterfaces.sol";

// DeFX User Statistics contract
contract DefxStat is IDefxStat {
    address public factory;

    constructor() {
        factory = msg.sender;
    }

    modifier onlyPair() {
        require(IDefxFactory(factory).isPair(msg.sender), "DefxFactory: !PAIR");
        _;
    }

    mapping(address => UserProfile) public userProfile;
    mapping(address => mapping(address => bool)) /* from */ /* to */
        public feedbackAllowed;

    function getUserProfile(address account) public view returns (UserProfile memory) {
        return userProfile[account];
    }

    function setFeedbackAllowed(address a, address b) external onlyPair {
        feedbackAllowed[a][b] = true;
        feedbackAllowed[b][a] = true;
    }

    function _setFirstDeal(address account) internal {
        if (userProfile[account].firstDealBlock == 0) {
            userProfile[account].firstDealBlock = block.number;
        }
    }

    function _incrementCompletedDeal(address account) internal {
        userProfile[account].completedDeals++;
        _setFirstDeal(account);
    }

    function _incrementFailedDeal(address account) internal {
        userProfile[account].failedDeals++;
    }

    function incrementCompletedDeal(address a, address b) external onlyPair {
        _incrementCompletedDeal(a);
        _incrementCompletedDeal(b);
    }

    function incrementFailedDeal(address a, address b) external onlyPair {
        _incrementFailedDeal(a);
        _incrementFailedDeal(b);
    }

    function _submitFeedback(
        address from,
        address to,
        bool isPositive,
        string calldata desc
    ) internal {
        userProfile[to].feedbacks.push(Feedback({isPositive: isPositive, desc: desc, from: from, blockNumber: block.number}));
        feedbackAllowed[from][to] = false;
    }

    function submitFeedback(
        address to,
        bool isPositive,
        string calldata desc
    ) external {
        require(feedbackAllowed[msg.sender][to], "DefxFactory: NOT_ALLOWED");
        _submitFeedback(msg.sender, to, isPositive, desc);
    }

    function submitFeedbackFrom(
        address from,
        address to,
        bool isPositive,
        string calldata desc
    ) external onlyPair {
        _submitFeedback(from, to, isPositive, desc);
    }

    function setName(string calldata name) external {
        userProfile[msg.sender].name = name;
    }

    function setSocialAccounts(string calldata data) external {
        userProfile[msg.sender].socialAccounts = data;
    }

    function setUserProfile(string calldata name, string calldata socialAccounts) external {
        userProfile[msg.sender].name = name;
        userProfile[msg.sender].socialAccounts = socialAccounts;
    }
}