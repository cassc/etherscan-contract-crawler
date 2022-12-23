// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DelegationPod.sol";
import "./DelegatedShare.sol";
import "./interfaces/ITokenizedDelegationPod.sol";
import "./interfaces/IDelegatedShare.sol";

contract TokenizedDelegationPod is ITokenizedDelegationPod, DelegationPod {
    error NotRegisteredDelegatee();
    error AlreadyRegistered();

    uint256 public immutable maxSharePods;
    uint256 public immutable sharePodGasLimit;

    mapping(address => IDelegatedShare) public registration;

    modifier onlyRegistered {
        if (address(registration[msg.sender]) == address(0)) revert NotRegisteredDelegatee();
        _;
    }

    modifier onlyNotRegistered {
        if (address(registration[msg.sender]) != address(0)) revert AlreadyRegistered();
        _;
    }

    constructor(string memory name_, string memory symbol_, IERC20Pods token_, uint256 maxSharePods_, uint256 sharePodGasLimit_) DelegationPod(name_, symbol_, token_) {
        maxSharePods = maxSharePods_;
        sharePodGasLimit = sharePodGasLimit_;
    }

    function delegate(address delegatee) public virtual override(IDelegationPod, DelegationPod) {
        if (delegatee != address(0) && address(registration[delegatee]) == address(0)) revert NotRegisteredDelegatee();
        super.delegate(delegatee);
    }

    function register(string memory name, string memory symbol) public virtual onlyNotRegistered returns(IDelegatedShare shareToken) {
        shareToken = new DelegatedShare(name, symbol, maxSharePods, sharePodGasLimit);
        registration[msg.sender] = shareToken;
        emit RegisterDelegatee(msg.sender);
    }

    function _updateBalances(address from, address to, address fromDelegatee, address toDelegatee, uint256 amount) internal virtual override {
        super._updateBalances(from, to, fromDelegatee, toDelegatee, amount);

        if (fromDelegatee != address(0)) {
            registration[fromDelegatee].burn(from, amount);
        }
        if (toDelegatee != address(0)) {
            registration[toDelegatee].mint(to, amount);
        }
    }
}