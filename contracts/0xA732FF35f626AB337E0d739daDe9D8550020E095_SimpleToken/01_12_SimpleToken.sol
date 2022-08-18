//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../utils/MerkleProof.sol";
import "../utils/Airdroppable.sol";

//import "hardhat/console.sol";

/**
 * @title Simple Token
 * @author Javier Gonzalez
 * @dev Implementation of a Simple Token.
 */
contract SimpleToken is ERC20, AccessControl, Airdroppable {
    uint256 public immutable initialSupply;

    /**
     * @notice Launches contract, mints tokens for a vault and for an airdrop
     * @param _freeSupply The number of tokens to issue to the contract deployer
     * @param _airdropSupply The number of tokens to reserve for the airdrop
     * @param vault The address to send the free supply to
     * @param name The ERC20 token name
     * @param symbol The ERC20 token symbol
     * @param admins A list of addresses that are able to call admin functions
     */
    constructor(
        uint256 _freeSupply,
        uint256 _airdropSupply,
        address vault,
        string memory name,
        string memory symbol,
        address[] memory admins
    ) ERC20(name, symbol) {
        _mint(vault, _freeSupply);
        _mint(address(this), _airdropSupply);
        initialSupply = _freeSupply + _airdropSupply;
        for (uint256 i = 0; i < admins.length; i++) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
    }

    function getInitialSupply() external view returns (uint256) {
        return initialSupply;
    }

    function newAirdrop(bytes32 _merkleRoot, uint256 _timeLimit)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256 airdropId)
    {
        return _newAirdrop(_merkleRoot, _timeLimit);
    }

    function completeAirdrop() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _completeAirdrop();
    }

    function sweepTokens(address _destination)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _sweepTokens(_destination, balanceOf(address(this)));
    }

    function _sweep(address to, uint256 amount) internal virtual override {
        _transfer(address(this), to, amount);
    }
}