// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/IDefiiFactory.sol";
import "./interfaces/IDefii.sol";

contract DefiiFactory is IDefiiFactory {
    address immutable _executor;
    address public immutable defiiImplementation;
    address[] public wallets;

    event DefiiCreated(address owner, address defii);

    constructor(address defiiImplementation_, address executor_) {
        defiiImplementation = defiiImplementation_;
        _executor = executor_;
    }

    function executor() external view returns (address) {
        return _executor;
    }

    function getDefiiFor(address wallet) public view returns (address defii) {
        defii = Clones.predictDeterministicAddress(
            defiiImplementation,
            keccak256(abi.encodePacked(wallet)),
            address(this)
        );
    }

    function getAllWallets() external view returns (address[] memory) {
        return wallets;
    }

    function getAllDefiis() public view returns (address[] memory) {
        address[] memory defiis = new address[](wallets.length);
        for (uint256 i = 0; i < defiis.length; i++) {
            defiis[i] = getDefiiFor(wallets[i]);
        }
        return defiis;
    }

    function getAllAllocations() external view returns (bool[] memory) {
        bool[] memory allocations = new bool[](wallets.length);
        for (uint256 i = 0; i < allocations.length; i++) {
            allocations[i] = IDefii(getDefiiFor(wallets[i])).hasAllocation();
        }
        return allocations;
    }

    function getAllInfos() external view returns (Info[] memory) {
        Info[] memory infos = new Info[](wallets.length);
        for (uint256 i = 0; i < infos.length; i++) {
            infos[i] = Info({
                wallet: wallets[i],
                defii: getDefiiFor(wallets[i]),
                hasAllocation: IDefii(getDefiiFor(wallets[i])).hasAllocation(),
                incentiveVault: IDefii(getDefiiFor(wallets[i])).incentiveVault()
            });
        }
        return infos;
    }

    function createDefii() external {
        createDefiiFor(msg.sender, msg.sender);
    }

    function createDefiiFor(address owner, address incentiveVault) public {
        address defii = Clones.cloneDeterministic(
            defiiImplementation,
            keccak256(abi.encodePacked(owner))
        );
        IDefii(defii).init(owner, address(this), incentiveVault);

        wallets.push(owner);
        emit DefiiCreated(owner, defii);
    }
}