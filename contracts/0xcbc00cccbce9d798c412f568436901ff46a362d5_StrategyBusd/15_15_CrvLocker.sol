pragma solidity 0.5.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Ownable.sol";
import "../interfaces/IVotingEscrow.sol";

/**
* @title CrvLocker
* @dev Inherit this contract to gain functionalities to interact with curve's voting_escrow
*/
contract CrvLocker is Ownable {

    constructor(address owner) public Ownable(owner) {}

    address constant public voting_escrow = address(0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2);
    IERC20 constant public crv = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);

    /**
     * @dev Lock CRV to enhance CRV rewards
     * @param amount amount of CRV to lock
     * @param unlockTime unix timestamp to unlock
     */
    function lock_crv(uint256 amount, uint256 unlockTime) external onlyOwner {
        crv.approve(voting_escrow, 0);
        crv.approve(voting_escrow, amount);
        IVotingEscrow(voting_escrow).create_lock(amount, unlockTime);
    }

    /**
     * @dev Withdraw locked CRV after the unlock time
     */
    function withdraw_crv() external onlyOwner {
        IVotingEscrow(voting_escrow).withdraw();
    }

    /**
     * @dev Increase CRV locking amount
     * @param amount amount of CRV to increase
     */
    function increase_crv_amount(uint256 amount) external onlyOwner {
        crv.approve(voting_escrow, 0);
        crv.approve(voting_escrow, amount);
        IVotingEscrow(voting_escrow).increase_amount(amount);
    }

    /**
     * @dev Increase CRV locking time
     * @param unlockTime new CRV locking time
     */
    function increase_crv_unlock_time(uint256 unlockTime) external onlyOwner {
        IVotingEscrow(voting_escrow).increase_unlock_time(unlockTime);
    }
}