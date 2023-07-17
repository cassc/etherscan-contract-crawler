/*
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⣰⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⡀⠀⢀⠒⠑⣴⣦⣾⣧⣤⢀⡤⠀⠀⠀⡀⠀⠀⠀
 * ⠀⠀⠀⠀⢀⠀⢀⡘⠉⠁⣰⣾⣿⣿⣿⣿⣿⣿⣷⢀⡤⠊⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⢱⠊⡄⠒⠾⣿⣿⣿⣿⣿⣿⠿⠛⢹⣿⣯⣤⠤⠄⠀⠀
 * ⠀⠀⠀⠒⢦⠂⠀⣇⠀⠸⠟⢈⣿⣿⡁⠺⠗⠀⣸⣿⣿⣃⠀⠀⠀⠀
 * ⠀⠀⠀⠀⢘⢀⣼⠻⢷⣶⣶⣿⣿⣿⣿⣶⣶⣾⠟⣻⣿⡯⠁⠀⠀⠀
 * ⠀⠀⠀⠉⠱⢾⣿⡀⠀⠈⠉⠙⠛⠛⠛⠉⠉⠀⢀⣿⣿⠿⠛⠒⠀⠀
 * ⠀⠀⠀⠀⠔⢛⣿⣷⡈⠒⠀⠀⠀⠔⠁⠊⠒⢈⣾⣿⡏⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠜⠛⠿⣿⣶⣤⣀⣀⣀⣀⣤⣶⣿⠿⣿⠉⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⡸⠛⢉⡿⠻⠟⣿⢿⡟⣏⠁⠀⠘⠄⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⡜⠀⠀⠀⠁⠀⠃⠘⡀⠀⠀⠀
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "interfaces/ICovidGambit.sol";

contract EmergencyExit is Ownable {
    ICovidGambit public covid = ICovidGambit(0xCDa63c270E4c9948429ef2224A0883df00f7802d);

    event ExitedQuarantine(address indexed patient, address indexed newIdentity, uint256 balance);

    function exitQuarantine(address patient, address newIdentity) public {
        require(block.timestamp <= covid.quarantineEndTime(patient), "Not in quarantine");
        require(covid.balanceOf(patient) > 0, "Already exited");
        require(covid.balanceOf(newIdentity) == 0, "New identity already taken");
        require(covid.patientStatus(newIdentity) == 0, "New identity is not healthy");
        require(msg.sender == patient || msg.sender == owner(), "Can't impersonate another patient");

        uint256 balance = covid.balanceOf(patient);
        covid.startPlandemic(false); // Pause plandemic for split second
        covid.transferFrom(patient, newIdentity, balance); // Can now transfer freely to new account
        covid.startPlandemic(true); // Plandemic continues
        emit ExitedQuarantine(patient, newIdentity, balance);
    }

    function transferCovidOwnership(address to) public onlyOwner {
        covid.transferOwnership(to);
    }
}