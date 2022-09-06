// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ClaimToken.sol";
import "./interfaces/IClaimToken.sol";

error ZeroAddressImplementation();

contract ClaimTokenFactory is Ownable {
    address public claimTokenImplementation;
    event ClaimTokenContractCreated(address contractAddress);
    event TokenClaimed(address beneficiary, uint256 amount);
    event ClaimTokenImplementationUpgraded(address implementation);
    mapping(address => bool) public claimTokenContracts;

    constructor(
        address _initialclaimTokenImplementation
    ) {
        if (_initialclaimTokenImplementation == address(0))
            revert ZeroAddressImplementation();

        claimTokenImplementation = _initialclaimTokenImplementation;
    }

    function upgradeClaimImplementation(address _upgradedImplementation)
        external
        onlyOwner
    {
        if (_upgradedImplementation == address(0))
            revert ZeroAddressImplementation();
        claimTokenImplementation = _upgradedImplementation;
        emit ClaimTokenImplementationUpgraded(_upgradedImplementation);
    }
    
    function createNewClaimTokenContract(
        address _tokenContract,
        bytes32 _merkleRoot
    ) external onlyOwner returns (address claimTokenContractAddress) {
        // all input checks are performed by the contribution collector itself
        IClaimToken _claimToken = IClaimToken(
            ClonesUpgradeable.cloneDeterministic(
                claimTokenImplementation,
                keccak256(abi.encodePacked(_tokenContract, _merkleRoot ))
            )
        );
        _claimToken.initialize(_tokenContract, _merkleRoot);
        _claimToken.transferOwnership(msg.sender);
        claimTokenContracts[address(_claimToken)] = true;
        emit ClaimTokenContractCreated(address(_claimToken));
        return address(_claimToken);
    }

}