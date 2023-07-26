// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./CloneFactory.sol";
import "./AlphaProVault.sol";

/**
 * @title   Alpha Pro Vault Factory
 * @notice  A factory contract for creating new vaults
 */
contract AlphaProVaultFactory is CloneFactory {
    event NewVault(address vault);
    event UpdateProtocolFee(uint24 protocolFee);

    event UpdateGovernance(address governance);

    address public immutable template;
    address[] public vaults;
    mapping(address => bool) public isVault;

    address public governance;
    address public pendingGovernance;
    uint24 public protocolFee;

    /**
     * @param _template A deployed AlphaProVault contract
     * @param _governance Charm Finance governance address
     * @param _protocolFee Fee multiplied by 1e6. Hard capped at 20%.
     */
    constructor(address _template, address _governance, uint24 _protocolFee) {
        template = _template;
        governance = _governance;
        protocolFee = _protocolFee;
        require(_protocolFee <= 20e4, "protocolFee must be <= 200000");
    }

    /**
     * @notice Create a new Alpha Pro Vault
     * @param params InitizalizeParams Underlying Uniswap V3 pool address
     */
    function createVault(VaultParams calldata params) external returns (address vaultAddress) {
        vaultAddress = createClone(template);
        AlphaProVault(vaultAddress).initialize(params, address(this));
        vaults.push(vaultAddress);
        isVault[vaultAddress] = true;
        emit NewVault(vaultAddress);
    }

    function numVaults() external view returns (uint256) {
        return vaults.length;
    }

    /**
     * @notice Change the protocol fee charged on pool fees earned from
     * Uniswap, expressed as multiple of 1e-6. Fee is hard capped at 20%.
     */
    function setProtocolFee(uint24 _protocolFee) external onlyGovernance {
        require(_protocolFee <= 20e4, "protocolFee must be <= 200000");
        protocolFee = _protocolFee;
        emit UpdateProtocolFee(_protocolFee);
    }

    /**
     * @notice Governance address is not updated until the new governance
     * address has called `acceptGovernance()` to accept this responsibility.
     */
    function setGovernance(address _governance) external onlyGovernance {
        pendingGovernance = _governance;
    }

    /**
     * @notice `setGovernance()` should be called by the existing fee recipient
     * address prior to calling this function.
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "pendingGovernance");
        governance = msg.sender;
        emit UpdateGovernance(msg.sender);
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "governance");
        _;
    }
}