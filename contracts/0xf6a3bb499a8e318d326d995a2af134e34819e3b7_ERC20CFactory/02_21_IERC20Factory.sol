// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Factory {

    /// @dev Create a ERC20Factory
    /// @param name name
    /// @param symbol symbol
    /// @param initialSupply initialSupply
    /// @param owner  owner address
    /// @return contract address
    function create(
        string calldata name,
        string calldata symbol,
        uint256 initialSupply,
        address owner
    ) external returns (address) ;

    /// @dev Last generated contract information
    function lastestCreated() external view returns (address contractAddress, string memory name, string memory symbol);

    /// @dev Contract information stored in the index
    function getContracts(uint256 _index) external view returns (address contractAddress, string memory name, string memory symbol);


}