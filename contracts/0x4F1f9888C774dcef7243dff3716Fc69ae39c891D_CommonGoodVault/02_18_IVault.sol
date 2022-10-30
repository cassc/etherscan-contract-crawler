// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/access/Ownable.sol";
import "../project/PledgeEvent.sol";

interface IVault {

    function transferPToksToTeamWallet(uint sum_, uint platformCutPromils_, address platformAddr_) external returns(uint,uint);

    function transferPaymentTokensToPledger( address pledgerAddr_, uint sum_) external returns(uint);

    function increaseBalance( uint numPaymentTokens_) external;

    function vaultBalance() external view returns(uint);

    function totalAllPledgerDeposits() external view returns(uint);

    function changeOwnership( address project_) external;
    function getOwner() external view returns (address);

    function initialize( address owner_) external;
}