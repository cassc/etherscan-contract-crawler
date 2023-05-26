/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: FeeRecipientCommission.sol

pragma solidity >=0.8.0 <0.9.0;

contract FeeRecipientCommission {
    struct PayoutAmount {
        uint256 MainAmount;
        uint256 CommissionAmount;
    }

    address adminAddress;
    address mainAddress;
    address commissionAddress;

    address proposedNewAdminAddress;
    address proposedNewMainAddress;
    address proposedNewCommissionAddress;

    uint256 commissionPercent;
    uint256 constant one_hundred = 100;

    event Distribute(address mainAddress, address commissionAddress, uint256 _mainAmount, uint256 _commissionAmount, uint256 commissionPercent);
    event ETHReceived(address _from, uint256 _amount);
    event ETHRecovered(address _to, uint256 _amount);
    event ERC20Recovered(address _to, address _tokenAddress, uint256 _amount);
    
    constructor(address _main, address _commission, uint256 _percent) {
        adminAddress = msg.sender;
        mainAddress = _main;
        commissionAddress = _commission;
        commissionPercent = _percent;
    }

    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    modifier isValidAddress(address _address) {
        require(_address != address(0), "Invalid address.");
        _;
    }

    modifier isAdmin(address _address) {
        require(adminAddress == _address, "Is not admin.");
        _;
    }

    modifier isAdminOrMainAddress(address _address) {
        require(mainAddress == _address || adminAddress == _address, "Is not admin or main address.");
        _;
    }

    modifier isAdminOrCommissionAddress(address _address) {
        require(commissionAddress == _address || adminAddress == _address, "Is not admin or commission address.");
        _;
    }

    modifier isProposedNewAdminAddress(address _address) {
        require(proposedNewAdminAddress == _address, "Is not the proposed new admin address.");
        _;
    }

    modifier isProposedNewMainAddress(address _address) {
        require(proposedNewMainAddress == _address, "Is not the proposed new main address.");
        _;
    }

    modifier isProposedNewCommissionAddress(address _address) {
        require(proposedNewCommissionAddress == _address, "Is not the proposed new commission address.");
        _;
    }

    modifier isAdminMainOrCommissionAddress(address _address) {
        require(adminAddress == _address || mainAddress == _address || commissionAddress == _address, "Is not a user of this contract.");
        _;
    }

    function updateAdmin(address _address) isAdmin(msg.sender) public {
        // ossify
        if (_address == address(0)) {
            adminAddress = _address;
            return;
        }

        proposedNewAdminAddress = _address;
    }

    function updateAdminAddress(address _address) isAdmin(msg.sender) public {
        proposedNewAdminAddress = _address;
    }

    function updateMainAddress(address _address) isAdminOrMainAddress(msg.sender) isValidAddress(_address) public {
        proposedNewMainAddress = _address;
    }

    function updateCommissionAddress(address _address) isAdminOrCommissionAddress(msg.sender) isValidAddress(_address) public {
        proposedNewCommissionAddress = _address;
    }

    function updateCommissionPercentage(uint256 _newCommissionPercentage) isAdmin(msg.sender) public {
        commissionPercent = _newCommissionPercentage;
    }

    function confirmAdminAddress() isProposedNewAdminAddress(msg.sender) public {
        adminAddress = proposedNewAdminAddress;
    }

    function confirmMainAddress() isProposedNewMainAddress(msg.sender) public {
        mainAddress = proposedNewMainAddress;
    }

    function confirmCommissionAddress() isProposedNewCommissionAddress(msg.sender) public {
        commissionAddress = proposedNewCommissionAddress;
    }

    function getAdminAddress() public view returns (address)  {
        return adminAddress;
    }

    function getCommissionAddress() public view returns (address)  {
        return commissionAddress;
    }

    function getMainAddress() public view returns (address)  {
        return mainAddress;
    }

    function getCommissionPercentage() public view returns (uint256) {
        return commissionPercent;
    }

    function getProposedNewAdminAddress() public view returns (address)  {
        return proposedNewAdminAddress;
    }

    function getProposedNewCommissionAddress() public view returns (address)  {
        return proposedNewCommissionAddress;
    }

    function getProposedNewMainAddress() public view returns (address)  {
        return proposedNewMainAddress;
    }

    function distribute() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to transfer.");

        uint256 commissionAmount = balance * commissionPercent / one_hundred;
        (bool commissionSuccess, ) = commissionAddress.call{value: commissionAmount}("");
        require(commissionSuccess, "Failed to transfer commission.");

        uint256 mainAmount = balance - commissionAmount;
        (bool mainSuccess, ) = mainAddress.call{value: mainAmount}("");
        require(mainSuccess, "Failed to transfer main balance.");

        emit Distribute(mainAddress, commissionAddress, mainAmount, commissionAmount, commissionPercent);
    }

    function recoverERC20(address _tokenAddress) isAdmin(msg.sender) public {
        IERC20 token = IERC20(_tokenAddress);

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "This token has no balance.");

        bool success = token.transfer(adminAddress, balance);
        require(success, "Token transfer failed.");

        emit ERC20Recovered(adminAddress, _tokenAddress, balance);
    }

    function recoverETH() isAdmin(msg.sender) public {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to transfer.");

        (bool success,) = adminAddress.call{value: balance}("");
        require(success, "ETH transfer failed.");

        emit ETHRecovered(adminAddress, balance);
    }
}