// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../token/oft/OFT.sol";

/// @notice Use this contract only on the BASE CHAIN. It locks tokens on source, on outgoing send(), and unlocks tokens when receiving from other chains.
contract Sifu is Ownable, OFT {
    // account => isMinter : minters
    mapping(address => bool) public minters;

    // account => isBurner : burners
    mapping(address => bool) public burners;

    // events
    event SetMinter(address indexed account, bool isMinter);
    event SetBurner(address indexed account, bool isBurner);

    /**
     * @notice constructor
     * @param _layerZeroEndpoint address of layerzero endpoint
     * @param _name token name
     * @param _symbol token symbol
     */
    constructor(
        address _layerZeroEndpoint,
        string memory _name,
        string memory _symbol
    ) OFT(_name, _symbol, _layerZeroEndpoint) {}

    /**
     * @notice Mint tokens by minter
     * @param _account address that send minted token
     * @param _amount mint token amount
     */
    function mint(address _account, uint256 _amount) external {
        require(minters[msg.sender], "Invalid minter");
        _mint(_account, _amount);
    }

    /**
     * @notice Burn tokens by burner
     * @param _account address that burns token
     * @param _amount burn token amount
     */
    function burn(address _account, uint256 _amount) external {
        require(burners[msg.sender], "Invalid burner");
        _burn(_account, _amount);
    }

    ///////////////////////
    /// Owner Functions ///
    ///////////////////////

    /**
     * @notice Set minter role
     * @param _minter address for adding or removing minter role
     * @param _isMinter boolean value for defining minter role
     */
    function addMinter(address _minter, bool _isMinter) external onlyOwner {
        minters[_minter] = _isMinter;
        emit SetMinter(_minter, _isMinter);
    }

    /**
     * @notice Set burner role
     * @param _burner address for adding or removing burner role
     * @param _isBurner boolean value for defining burner role
     */
    function addBurner(address _burner, bool _isBurner) external onlyOwner {
        burners[_burner] = _isBurner;
        emit SetBurner(_burner, _isBurner);
    }
}