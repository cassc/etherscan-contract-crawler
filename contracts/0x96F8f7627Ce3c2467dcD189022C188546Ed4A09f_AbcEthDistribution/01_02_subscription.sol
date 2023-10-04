// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

import "./abc.sol";

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
contract AbcEthDistribution is Ownable, Pausable {
    AlphaBotCalls public tokenContract;
    uint256 public minTraderTokenAmount = 400000000000000000000; // 400 ABC
    uint8 public traderReward = 70;
    uint8 public communityReward = 20;
    uint8 public groupOwnerReward = 0;
    uint256 private rewardsForCommunity = 0;
    uint256 private rewardsForDevelopers = 0;
    address public communityWallet = 0x7Eb5eE0ECCAbAC6629a5bD2C24F672103e1E0216;
    address public developersWallet = 0x664e2531f5c1AeCA86b7C65935431AbB06F29f71;

    constructor(address payable _tokenContract) {
        tokenContract = AlphaBotCalls(_tokenContract);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getSubscription(address _traderAddress, address _groupOwnersAddress, uint40 _trnId) external payable whenNotPaused {
        require(msg.value > 0, "Sent ETH must be greater than 0");
        require(_traderAddress != address(0), "Trader address cannot be 0");
        uint256 totalAmount = msg.value;

        rewardsForCommunity += (totalAmount * communityReward) / 100;

        if (minTraderTokenAmount <= tokenContract.balanceOf(_traderAddress)) {
            if (groupOwnerReward > 0 && minTraderTokenAmount <= tokenContract.balanceOf(_groupOwnersAddress)) {
                rewardsForDevelopers += (totalAmount * (100 - communityReward - traderReward - groupOwnerReward)) / 100;
                require(payable(_groupOwnersAddress).send((totalAmount * groupOwnerReward) / 100), "Transfer to owner group failed");
            } else {
                rewardsForDevelopers += (totalAmount * (100 - communityReward - traderReward)) / 100;
            }

            require(payable(_traderAddress).send((totalAmount * traderReward) / 100), "Transfer to trader failed");
        } else {
            rewardsForDevelopers += (totalAmount * (100 - communityReward)) / 100;
        }
    }

    // Function to set the min trader's an amount of tokens
    function setMinTraderTokenCount(uint256 _newAmount) external onlyOwner {
        minTraderTokenAmount = _newAmount;
    }

    // Function to set the trader reward percentage
    function setTraderReward(uint8 _newTraderReward) external onlyOwner {
        require(_newTraderReward + communityReward + groupOwnerReward <= 100, "The sum of percentages can't be more than 100");
        traderReward = _newTraderReward;
    }

    // Function to set the community reward percentage
    function setCommunityReward(uint8 _newCommunityReward) external onlyOwner {
        require(_newCommunityReward + traderReward + groupOwnerReward <= 100, "The sum of percentages can't be more than 100");
        communityReward = _newCommunityReward;
    }

    // Function to set the group owner reward percentage
    function setTopGroupOwnerReward(uint8 _newTopGroupOwnerReward) external onlyOwner {
        require(_newTopGroupOwnerReward + traderReward + communityReward <= 100, "The sum of percentages can't be more than 100");
        groupOwnerReward = _newTopGroupOwnerReward;
    }

    // Function to set the community wallet address
    function setCommunityWallet(address _newWallet) external onlyOwner {
        communityWallet = _newWallet;
    }

    // Function to set the developers wallet address
    function setDevelopersWallet(address _newWallet) external onlyOwner {
        developersWallet = _newWallet;
    }

    function withdrawCommunity(uint256 _amount) public onlyOwner {
        require(_amount > 0, "The amount must be greater than 0");
        require((rewardsForCommunity >= _amount), "It's impossible to dump this much");
        require(payable(communityWallet).send(_amount));
        rewardsForCommunity -= _amount;

    }

    function withdrawDevelopers(uint256 _amount) public onlyOwner {
        require(_amount > 0, "The amount must be greater than 0");
        require((rewardsForDevelopers >= _amount), "It's impossible to dump this much");
        require(payable(developersWallet).send(_amount));
        rewardsForDevelopers -= _amount;
    }

    function getRewardsForCommunity() public view returns (uint256) {
        return rewardsForCommunity;
    }

    function getRewardsForDevelopers() public view returns (uint256) {
        return rewardsForDevelopers;
    }
}