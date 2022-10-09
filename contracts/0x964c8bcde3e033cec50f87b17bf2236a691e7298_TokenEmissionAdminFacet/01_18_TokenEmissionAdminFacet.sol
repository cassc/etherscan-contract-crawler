// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base} from "../base/Base.sol";
import {LibMint} from "../libraries/LibMint.sol";

import {ITokenEmissionAdminFacet} from "../interfaces/ITokenEmissionAdminFacet.sol";

contract TokenEmissionAdminFacet is Base, ITokenEmissionAdminFacet {

    function setClaimingMerkleRoot(bytes32 root_) external {
        LibMint.mintStorage().claimingMerkleRoot = root_;
    }

    function initMint(
        uint256 price,
        uint256 supply,
        uint256 maxMintsPerTx,
        uint256 maxMintsPerAddress,
        bytes32 privateSaleMerkleRoot,
        bytes32 claimingMerkleRoot,
        address conditionContract,
        uint256 conditionAmount
    ) external {
        LibMint.init(price, supply, maxMintsPerTx, maxMintsPerAddress, privateSaleMerkleRoot, claimingMerkleRoot, conditionContract, conditionAmount);
    }

    function setBalanceCondition(address _contract, uint256 _amount) external {
        if(_contract == address(0)) revert InvalidContractAddress();
        if(_amount == 0) revert InvalidBalanceConditionAmount();
        if(_contract.code.length == 0) revert AddressIsEoA();

        LibMint.mintStorage().conditionContract = _contract;
        LibMint.mintStorage().conditionAmount = _amount;
    }

    function setClaiming(bool active_) external {
        active_ ? LibMint.activateClaiming() : LibMint.deactivateClaiming();
    }

    function setPublicSale(bool active_) external {
        active_ ? LibMint.startPublicSale() : LibMint.stopPublicSale();
    }

    function setPrivateSale(bool active_) external {
        active_ ? LibMint.startPrivateSale() : LibMint.stopPrivateSale();
    }

    function setPrivateSaleMerkleRoot(bytes32 root_) external {
        LibMint.mintStorage().privateSaleMerkleRoot = root_;
    }

    function getClaimingMerkleRoot() external view returns (bytes32) {
        return LibMint.mintStorage().claimingMerkleRoot;
    }

    function getPrivateSaleMerkleRoot() external view returns (bytes32) {
        return LibMint.mintStorage().privateSaleMerkleRoot;
    }
}