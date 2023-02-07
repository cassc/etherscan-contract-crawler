// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

abstract contract IVaccine {
    function getMaxVaccinationProgress() public pure virtual returns(uint8);
    
    function isFullyVaccinated(uint256 porkId) public view virtual returns(bool);
    
    function vaccinationProgress(uint256 porkId) public view virtual returns(uint8);
}