/**
 *Submitted for verification at Etherscan.io on 2023-02-09
*/

pragma solidity ^0.8.13;

// Caution. We assume all failed transfers cause reverts and ignore the returned bool.
interface IERC20 {
    function transfer(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function delegate(address delegatee) external;
    function delegates(address delegator) external view returns (address delegatee);
}

/**
@title Gov Token Escrow
@notice Collateral is stored in unique escrow contracts for every user and every market.
 This specific escrow is meant as an example of how an escrow can be implemented that allows depositors to delegate votes with their collateral, unlike pooled deposit protocols.
@dev Caution: This is a proxy implementation. Follow proxy pattern best practices
*/
contract GovTokenEscrow {
    address public market;
    IERC20 public token;
    address public beneficiary;

    /**
    @notice Initialize escrow with a token
    @dev Must be called right after proxy is created.
    @param _token The IERC20 token representing the governance token
    @param _beneficiary The beneficiary who may delegate token voting power
    */
    function initialize(IERC20 _token, address _beneficiary) public {
        require(market == address(0), "ALREADY INITIALIZED");
        market = msg.sender;
        token = _token;
        beneficiary = _beneficiary;
        _token.delegate(_token.delegates(_beneficiary));
    }

    /**
    @notice Transfers the associated ERC20 token to a recipient.
    @param recipient The address to receive payment from the escrow
    @param amount The amount of ERC20 token to be transferred.
    */
    function pay(address recipient, uint amount) public {
        require(msg.sender == market, "ONLY MARKET");
        token.transfer(recipient, amount);
    }

    /**
    @notice Get the token balance of the escrow
    @return Uint representing the INV token balance of the escrow including the additional INV accrued from xINV
    */
    function balance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    /**
    @notice Function called by market on deposit. Function is empty for this escrow.
    @dev This function should remain callable by anyone to handle direct inbound transfers.
    */
    function onDeposit() public {

    }

    /**
    @notice Delegates voting power of the underlying xINV.
    @param delegatee The address to be delegated voting power
    */
    function delegate(address delegatee) public {
        require(msg.sender == beneficiary);
        token.delegate(delegatee);
    }
}