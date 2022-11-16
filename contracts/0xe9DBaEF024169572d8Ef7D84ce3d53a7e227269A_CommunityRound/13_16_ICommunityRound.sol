// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

/**************************************

    Community Phase contract

 **************************************/

interface ICommunityRound {
    
    // events
    event Reserved(address sender, uint256 amount);
    event Withdraw(address sender, uint256 amount);

    // errors
    error NonceExpired(address sender, uint256 nonce);
    error RequestExpired(address sender, bytes request);
    error ReserveDeadlineMet();
    error IncorrectSigner(address signer);
    error IncorrectSender(address sender);
    error AlreadyReserved(address sender);
    error InvalidAmount(bytes request, uint256 minAmount, uint256 maxAmount);
    error NothingToWithdraw();

    // external functions
    function isAllowed(address _owner) external view returns (bool);
    function balanceOf(address _owner) external view returns (uint256);

}