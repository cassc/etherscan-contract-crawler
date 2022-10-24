// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakedCLRToken is IERC20 {
    /// @notice Mints SCLR tokens in exchange for LP's provided tokens to CLR instance
    /// @param _recipient (address) LP's address to send the SCLR tokens to
    /// @param _amount (uint256) SCLR tokens amount to be minted
    /// @return  (bool) indicates a successful operation
    function mint(address _recipient, uint256 _amount) external returns (bool);

    /// @notice Burns SCLR tokens as indicated
    /// @param _sender (address) LP's address account to burn SCLR tokens from
    /// @param _amount (uint256) SCLR token amount to be burned
    /// @return  (bool) indicates a successful operation
    function burnFrom(address _sender, uint256 _amount) external returns (bool);

    /// @notice Initializes SCLR token
    /// @param _name (string) SCLR token's name
    /// @param _symbol (string) SCLR token's symbol
    /// @param _clrPool (address) Address of the CLR pool the token belongs to
    /// @param _transferable (bool) Indicates if token is transferable
    function initialize(
        string memory _name,
        string memory _symbol,
        address _clrPool,
        bool _transferable
    ) external;
}