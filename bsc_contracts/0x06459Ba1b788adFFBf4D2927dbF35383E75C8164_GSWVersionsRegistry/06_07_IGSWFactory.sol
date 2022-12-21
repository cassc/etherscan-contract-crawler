// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IGSWFactory {
    /// @notice GSW logic contract address that new GSWProxy deployments point to
    /// @return contract address
    function gswImpl() external view returns (address);

    /// @notice         Computes the deterministic address for owner based on Create2
    /// @param owner_   GSW owner
    /// @return         computed address for the contract (GSWProxy)
    function computeAddress(address owner_) external view returns (address);

    /// @notice         Deploys if necessary or gets the address for a GSWProxy for a certain owner
    /// @param owner_   GSW owner
    /// @return         deployed address for the contract (GSWProxy)
    function deploy(address owner_) external returns (address);

    /// @notice             registry can update the current GSW implementation contract
    ///                     set as default for new GSW proxy deployments logic contract
    /// @param gswImpl_     the new gswImpl address
    function setGSWImpl(address gswImpl_) external;
}