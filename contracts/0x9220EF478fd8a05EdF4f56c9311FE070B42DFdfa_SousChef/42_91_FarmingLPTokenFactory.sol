// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFarmingLPTokenFactory.sol";
import "./FarmingLPToken.sol";

contract FarmingLPTokenFactory is Ownable, IFarmingLPTokenFactory {
    address public immutable override router;
    address public immutable override masterChef;
    address internal immutable _implementation;

    address public override yieldVault;
    address public override migrator;
    mapping(uint256 => address) public override getFarmingLPToken;

    constructor(
        address _router,
        address _masterChef,
        address _yieldVault
    ) {
        router = _router;
        masterChef = _masterChef;
        yieldVault = _yieldVault;
        FarmingLPToken token = new FarmingLPToken();
        token.initialize(address(0), address(0), 0);
        _implementation = address(token);
    }

    function predictFarmingLPTokenAddress(uint256 pid) external view override returns (address token) {
        token = Clones.predictDeterministicAddress(_implementation, bytes32(pid));
    }

    function updateYieldVault(address vault) external override onlyOwner {
        if (vault == address(0)) revert InvalidAddress();
        yieldVault = vault;

        emit UpdateVault(vault);
    }

    function updateMigrator(address _migrator) external override onlyOwner {
        if (_migrator != address(0)) revert MigratorSet();
        migrator = _migrator;

        emit UpdateMigrator(_migrator);
    }

    function createFarmingLPToken(uint256 pid) external override returns (address token) {
        if (getFarmingLPToken[pid] != address(0)) revert TokenCreated();

        token = Clones.cloneDeterministic(_implementation, bytes32(pid));
        FarmingLPToken(token).initialize(router, masterChef, pid);

        getFarmingLPToken[pid] = token;

        emit CreateFarmingLPToken(pid, token);
    }
}