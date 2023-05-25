// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RadarToken is ERC20 {
    /**
     * @dev constructor
     * @param _erc20Name token name
     * @param _erc20Symbol token symbol
     * @param _mintAddresses array of address to hold initial tokens
     * @param _mintAmounts array of initial token amounts to be minted to mint addresses
     */
    constructor(
        string memory _erc20Name,
        string memory _erc20Symbol,
        address[] memory _mintAddresses,
        uint256[] memory _mintAmounts
    ) ERC20(_erc20Name, _erc20Symbol) {
        require(_mintAddresses.length == _mintAmounts.length, "RadarToken: must have same number of mint addresses and amounts");

        for (uint i; i < _mintAddresses.length; i++) {
            require(_mintAddresses[i] != address(0), "RadarToken: cannot have a non-address as reserve.");
            ERC20._mint(_mintAddresses[i], _mintAmounts[i]);
        }
    }

    /**
     * @dev anyone can burn tokens in their own address
     * @param _amount token amount to burn
     */
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}