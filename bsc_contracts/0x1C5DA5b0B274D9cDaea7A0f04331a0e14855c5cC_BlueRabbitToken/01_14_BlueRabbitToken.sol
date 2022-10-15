// contracts/BlueRabbitToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BlueRabbitToken is ERC20Burnable, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 private _totalMined;
    uint256 private _maxSupply = 4*10**30;

    constructor() ERC20("BlueRabbit Token", "BLRB") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(
        address _account, 
        uint256 _amount
    ) public onlyRole(MINTER_ROLE) returns (bool) {
        require(_totalMined + _amount <= _maxSupply, "maxMined");
        _mint(_account, _amount);
        _totalMined += _amount;
        return true;
    }

    function trustedBurn(
        address _account, 
        uint256 _amount
    ) public onlyRole(BURNER_ROLE) returns (bool) {
        _burn(_account, _amount);
        return true;
    }

    /**
     * @notice Function to recover BEP20
     * Caller is assumed to be governance
     * @param token Address of token to be rescued
     * @param amount Amount of tokens
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function recoverBEP20(
        IERC20 token,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, "!zero");
        token.safeTransfer(_msgSender(), amount);
    }

    /**
     * @dev totalMined.
     */
    function totalMined() public view returns (uint256) {
        return _totalMined;
    }

    /**
     * @dev maxSupply.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }


}