// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openzeppelin/contracts/proxy/Clones.sol";
import "./openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IGeoCustodyWallet.sol";

contract GeoFactory is AccessControlUpgradeable {

    event ContractDeployed(address indexed _deployer, address indexed _implementation, address _contractAddress);

    IGeoCustodyWallet public walletMaster;

    function initialize(address _admin, address _walletMaster) public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);

        walletMaster = IGeoCustodyWallet(_walletMaster);
    }

    function version() public pure returns (uint32){
        //version in format aaa.bbb.ccc => aaa*1E6+bbb*1E3+ccc;
        return uint32(1000001);
    }

    // TODO: add wallets
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not the Admin");
        _;
    }

    function cloneCustody(address beneficiary, bytes32 salt) external onlyAdmin {
        address wallet = cloneDeterministic(address(walletMaster), salt);

        IGeoCustodyWallet(wallet).initialize(address(this), beneficiary);
    }

    function cloneDeterministic(address implementation, bytes32 salt) public returns(address) {
        address contractAddress = Clones.cloneDeterministic(implementation, salt);

        emit ContractDeployed(msg.sender, implementation, contractAddress);

        return contractAddress;
    }

    function generateAddress(address implementation, bytes32 salt) public view returns(address) {
        address contractAddress = Clones.predictDeterministicAddress(implementation, salt);

        return contractAddress;
    }

}