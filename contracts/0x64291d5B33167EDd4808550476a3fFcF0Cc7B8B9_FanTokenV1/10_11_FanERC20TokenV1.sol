// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./FanTokenVariableV1.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

contract FanTokenV1 is FanTokenVariableV1, ERC2771Recipient {
    // lock the implementation contract
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Initialisation section

    function initialize(address _trustedForwarder, address _adminEOAWallet) public initializer {
        require(_trustedForwarder != address(0), "FanTokenV1: Trusted forwarder address cannot be zero");

        adminEOAWallet = _adminEOAWallet;
        _setTrustedForwarder(_trustedForwarder);
        __ERC20_init("FAN", "FAN");
        __Ownable_init();
        _mint(_msgSender(), (10 ** 8) * (10 ** decimals()));
        lockCounter = 0;
    }

    /**
     * @dev modifier to check if the caller is the eoa admin wallet or the timelock
     */
    modifier onlyAdmin() {
        require(_msgSender() == adminEOAWallet || _msgSender() == owner(), "FanTokenV1: Not authorized");
        _;
    }

    /**
     * @dev modifier to checl lock exists or is active.
     */

    modifier lockExistsOrActive(uint256 _lockId) {
        require(lockDetails[_lockId].lockDuration > block.timestamp, "FanTokenV1: lock does not exists or not active");
        _;
    }

    /**
     * @dev returns decimal for token.
     */

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    // change trustedForwarder address
    function setTruestedForwarder(address _trustedForwarder) public onlyOwner {
        require(_trustedForwarder != address(0), "FanTokenV1: Trusted forwarder address cannot be zero");
        _setTrustedForwarder(_trustedForwarder);

        emit TrustedForwarderModified(_trustedForwarder);
    }

    /**
     * @dev set the Admin EOA Wallet.
     *
     * @param _adminEOAWallet the new admin wallet
     *
     * Requirements:
     * - only owner can set the admin wallet
     *
     */
    function setAdminEOAWallet(address _adminEOAWallet) public onlyOwner {
        adminEOAWallet = _adminEOAWallet;

        emit SetAdminEOAWallet(adminEOAWallet);
    }

    /**
     * @dev creates lock.
     *
     * @param _to address.
     * @param _amount amount of token.
     * @param _duration duration for token to be locked.
     *
     * Requirements:
     * - only owner can create lock.
     *
     * Returns
     * - boolean.
     *
     * Emits a {lockCreated} event.
     */

    function lockUp(address _to, uint256 _amount, uint256 _duration) external onlyOwner {
        require(_msgSender() != _to, "FanTokenV1: Owner cannot lock tokens for itself");
        require(_to != address(this), "Cannot lockup tokens for the fan token contract itself");
        require(!isblacklistedAccount[_to], "FanTokenV1: Receiver account is blacklisted");
        require(_amount > 0, "FanTokenV1: Amount should be greater then zero");
        require(_duration > block.timestamp, "FanTokenV1: improper lock duration");

        lockCounter += 1;

        Locks memory createLock = Locks(lockCounter, _to, _amount, _duration);
        lockDetails[lockCounter] = createLock;
        userLocks[_to].push(lockCounter);

        transfer(_to, _amount);
        emit LockCreated(lockCounter, _to, _amount, _duration);
    }

    /**
     * @dev modifies the lock.
     *
     * @param _lockId lock Id.
     * @param _duration duration for token to be locked.
     *
     * Requirements:
     * - only owner can modify lock.
     *
     * Returns
     * - boolean.
     *
     * Emits a {lockModified} event.
     */

    function modifylock(uint256 _lockId, uint256 _duration) external lockExistsOrActive(_lockId) onlyOwner {
        require(!isblacklistedAccount[lockDetails[_lockId].user], "FanTokenV1: user is blacklisted");

        lockDetails[_lockId].lockDuration = _duration;
        emit LockModified(_lockId, _duration);
    }

    /**
     * @dev user can view total locked amount.
     *
     * @param _user user address
     *
     * Returns
     * - Locked Amount.
     */

    function getlockedAmount(address _user) public view returns (uint256 lockedAmount) {
        for (uint256 i = 0; i < userLocks[_user].length; i++) {
            uint256 ithLock = userLocks[_user][i];

            if (lockDetails[ithLock].lockDuration > block.timestamp) {
                lockedAmount += lockDetails[ithLock].lockAmount;
            }
        }
    }

    /**
     * @dev user address can be blacklisted.
     *
     * @param _target user address
     * @param _isBlacklisted boolean
     *
     *  Requirements:
     * - only owner can block and unblock the user.
     *
     * Returns
     * - boolean.
     */

    function blacklistAccount(address _target, bool _isBlacklisted) external onlyAdmin {
        isblacklistedAccount[_target] = _isBlacklisted;

        emit BlacklistedAccount(_target, _isBlacklisted);
    }

    /**
     * @dev minting new token.
     *
     * @param _amount amount of token.
     *
     *  Requirements:
     * - only owner can burn.
     *
     * Returns
     * - boolean.
     */

    function mintTokens(uint256 _amount) external onlyOwner {
        _mint(_msgSender(), _amount);
    }

    /**
     * @dev burning token.
     *
     * @param _amount amount of token.
     *
     *  Requirements:
     * - only owner can burn.
     *
     * Returns
     * - boolean.
     */

    function burn(uint256 _amount) external onlyOwner {
        _burn(_msgSender(), _amount);
    }

    /**
     * @dev overrides the internal transfer function where user cannot perform any
     * transfer for locked amount and blacklisted user cannot transfer tokens.
     */

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        require(from != address(0), "FanTokenV1: transfer from the zero address");
        require(to != address(0), "FanTokenV1: transfer to the zero address");
        require(!isblacklistedAccount[from], "FanTokenV1: Sender is blacklisted");
        require(!isblacklistedAccount[to], "FanTokenV1: Receiver is blacklisted");

        _beforeTokenTransfer(from, to, amount);

        // blocked all transfer for locked tokens
        uint256 lockedAmount = getlockedAmount(from);
        uint256 unlockedAmount = balanceOf(from) - lockedAmount;

        require(unlockedAmount >= amount, "FanTokenV1: amount exceeds than unlocked tokens");

        uint256 fromBalance = _balances[from];

        require(fromBalance >= amount, "FanTokenV1: transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev overrides the internal transfer function where blacklisted user cannot aprove the tokens.
     */

    function _approve(address owner, address spender, uint256 amount) internal virtual override {
        require(owner != address(0), "FanTokenV1: approve from the zero address");

        require(spender != address(0), "FanTokenV1: approve to the zero address");

        // Check if sender is not blacklisted
        require(!isblacklistedAccount[owner], "FanTokenV1: approver is blacklisted");

        require(!isblacklistedAccount[spender], "FanTokenV1: spender is blacklisted");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // This two are internal functions, they are required for eip 2771 when
    // openzepplin ownable or upgrade functionalities are used

    function _msgSender() internal view override(ContextUpgradeable, ERC2771Recipient) returns (address sender) {
        sender = ERC2771Recipient._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771Recipient) returns (bytes calldata) {
        return ERC2771Recipient._msgData();
    }
}