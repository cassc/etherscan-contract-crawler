// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccumulateBridge.sol";

contract ACMELiquidStaking is Ownable {

    using SafeERC20 for WrappedToken;

    bool internal locked;
    modifier reentrancyGuard() {
         require(!locked);
         locked = true;
         _;
         locked = false;
    }

    // WACME token
    WrappedToken public wacme;

    // stACME token
    WrappedToken public stacme;

    // Accumulate Bridge address
    AccumulateBridge public bridge;

    // Staking account on Accumulate
    string public stakingAccount;

    constructor(address _wacme, address _stacme, address _bridge, string memory _stakingAccount) {
        wacme = WrappedToken(_wacme);
        stacme = WrappedToken(_stacme);
        bridge = AccumulateBridge(_bridge);
        stakingAccount = _stakingAccount;
    }

    event Transfer_stACME_Ownership(address indexed _newOwner);
    event Renounce_stACME_Ownership();
    event Set_stakingAccount(string _stakingAccount);
    event Mint_stACME(address to, uint256 amount);
    event Deposit_WACME(address from, uint256 amount);

    function transfer_stACME_ownership(address newOwner) public onlyOwner {
        stacme.transferOwnership(newOwner);
        emit Transfer_stACME_Ownership(newOwner);
    }

    function renounce_stACME_ownership() public onlyOwner {
        stacme.renounceOwnership();
        emit Renounce_stACME_Ownership();
    }

    function set_stakingAccount(string memory newStakingAccount) public onlyOwner {
        stakingAccount = newStakingAccount;
        emit Set_stakingAccount(newStakingAccount);
    }

    function approve_bridge() public onlyOwner {
        wacme.approve(address(bridge), type(uint256).max);
    }

    function mint_stACME(address to, uint256 amount) public onlyOwner {
        stacme.mint(to, amount);
        emit Mint_stACME(to, amount);
    }

    function deposit_WACME(uint256 amount) public reentrancyGuard {
        wacme.safeTransferFrom(address(msg.sender), address(this), amount);
        bridge.burn(wacme, stakingAccount, amount);
        stacme.mint(address(msg.sender), amount);
        emit Deposit_WACME(address(msg.sender), amount);
        emit Mint_stACME(address(msg.sender), amount);
    }

}