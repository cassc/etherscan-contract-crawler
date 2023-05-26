// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
interface IKeep3r {
    event Keep3rSet(address _keep3r);
    event Keep3rRequirementsSet(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA);
    
    function keep3r() external view returns (address _keep3r);

    function setKeep3r(address _keep3r) external;
    function setKeep3rRequirements(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA) external;
}