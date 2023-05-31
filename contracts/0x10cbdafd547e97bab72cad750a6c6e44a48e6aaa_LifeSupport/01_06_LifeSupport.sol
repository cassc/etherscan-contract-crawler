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

// TODO VAX THIS CONTRACT

contract LifeSupport is Ownable {
    ICovidGambit public covid;
    uint256 public maxComaDuration = 7 days;

    event WokeUp(address indexed patient, address indexed newIdentity, uint256 balance);

    function wakeUp(address patient, address newIdentity) public {
        require(isInComa(patient), "Can't wake up without being asleep");
        require(block.timestamp > covid.quarantineEndTime(patient), "Still in quarantine");
        require(covid.balanceOf(patient) > 0, "Already woke up");
        require(covid.balanceOf(newIdentity) == 0, "New identity already taken");
        require(covid.patientStatus(newIdentity) == 0, "New identity is not healthy");
        require(msg.sender == patient || msg.sender == owner(), "Can't impersonate another patient");
        require(
            lifeSupportEndTime(patient) > block.timestamp || maxComaDuration == 0,
            "Life support ended due to unpaid medical bills"
        );

        uint256 balance = covid.balanceOf(patient);
        covid.startPlandemic(false); // Pause plandemic for split second
        covid.transferFrom(patient, newIdentity, balance); // Can now transfer freely to new account
        covid.startPlandemic(true); // Plandemic continues
        emit WokeUp(patient, newIdentity, balance);
    }

    // Patient is in a coma if they got infected inside a quarantine chamber.
    // Covid Gambit contract sees them as dead but actually they are in comatose state
    function isInComa(address patient) public view returns (bool isIndeed) {
        return covid.firstInfectedTime(patient) <= covid.quarantineEndTime(patient) && covid.firstInfectedTime(patient) != 0;
    }

    function lifeSupportEndTime(address patient) public view returns (uint256 timestamp) {
        return covid.quarantineEndTime(patient) + maxComaDuration;
    }

    function transferCovidOwnership(address to) public onlyOwner {
        covid.transferOwnership(to);
    }

    function setCovidAddress(address covidAddress) public onlyOwner {
        covid = ICovidGambit(covidAddress);
    }

    function setMaxComaDuration(uint256 _maxComaDuration) public onlyOwner {
        maxComaDuration = _maxComaDuration;
    }
}