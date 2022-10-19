// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract EntangleSynth is ERC20, AccessControl {

    struct TokenAmount {
        uint256 amount;
        address token;
    }

    uint256 public chainId;
    address public synthChef;
    uint256 public pid;

    uint256 public price;

    IERC20 public opToken;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(uint256 _chainId, address _synthChef, uint256 _pid, IERC20 _opToken) ERC20("ETHSynth", "SYNTH") {
        opToken = _opToken;
        chainId = _chainId;
        synthChef = _synthChef;
        pid = _pid;
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function convertSynthAmountToOpAmount(uint256 synthAmount) public view returns (uint256 opAmount) {
        opAmount = synthAmount * price / (10 ** decimals());
    }

    function convertOpAmountToSynthAmount(uint256 opAmount) public view returns (uint256 synthAmount) {
        synthAmount = opAmount * (10 ** decimals()) / price;
    }

    /** @dev Creates `_amount` SynthTokens and assigns them to `_to`, increasing
     * the total supply.
     *
     * Requirements:
     *
     * - `_to` cannot be the zero address.
     */
    function mint(address _to, uint256 _amount) external onlyRole(ADMIN_ROLE) {
        _mint(_to, _amount);
    }

    /**
     * @dev Destroys `_amount` tokens from `_from`, reducing the
     * total supply.
     *
     * Requirements:
     *
     * - `_from` cannot be the zero address.
     * - `_from` must have at least `amount` tokens.
     */
    function burn(address _from, uint256 _amount) external onlyRole(ADMIN_ROLE) {
        _burn(_from, _amount);
    }

    function setPrice(uint256 _price) external onlyRole(ADMIN_ROLE) {
        price = _price;
    }
}