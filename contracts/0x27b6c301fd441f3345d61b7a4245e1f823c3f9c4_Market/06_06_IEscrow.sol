pragma solidity ^0.8.13;
import "src/interfaces/IERC20.sol";

interface IEscrow {
    //public variables
    function market() external view returns(address);
    function token() external view returns(IERC20);
    function beneficiary() external view returns(address);
    //public functions
    function initialize(IERC20 _token, address beneficiary) external;
    function pay(address recipient, uint amount) external;
    function balance() external view returns(uint);
    function onDeposit() external;
}

interface IClaimantEscrow is IEscrow{
    //public variables
    function beneficiary() external view returns(address);
    //public mappings
    function allowlist(address allowed) external view returns(bool);
    //public functions
    function claimTo(address to) external;
    function claim() external;
    function allowClaimOnBehalf(address allowee) external;
    function disallowClaimOnBehalf(address allowee) external;
}

interface IDelegateableEscrow is IEscrow{
    function delegate(address delegatee) external;
}