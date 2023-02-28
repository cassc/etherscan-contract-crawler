// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract mCoin is ERC20, ERC20Burnable, Pausable, Ownable {

    constructor() ERC20("mCoin", "MCOIN") {
        _mint(msg.sender, 500000000 * 10 ** decimals());
        _pause();
        isWhitelisted[msg.sender] = true;
        isWhitelisted[DEAD] = true;
        isWhitelisted[ZERO] = true;
    }

    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant private ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => bool) public isFreezed;
    mapping(address => bool) public isWhitelisted;

    bool public launched = false;

    /* @dev Returns the name of the token */
    function SmartcontractDev() public pure returns (string memory contact) {
        contact = "t.me/frankfourier";
    }

    /* Launch the token and start trading, can be called only once and trading cannot be stopped */
    function launch() public onlyOwner {
        require(paused(), "Token is already launched");

        _unpause();
        launched = true;
    }

    /* Returns true if the target is a contract address */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }

    /* Required override to activate freeze and not launched checks */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from != owner() && to != owner() && !isWhitelisted[from] && !isWhitelisted[to]) {
            require(!paused(), "Token is not live for trading yet");
        }
        if (!isFreezed[from] && !isFreezed[to]) {
            super._beforeTokenTransfer(from, to, amount);
        } else revert("Walled is freezed for malicious activity");
    }

    /* Rescue other ERC20 tokens sent by mistake to this contract */
    function rescueToken(address token, address to) external onlyOwner {
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this))); 
    }

    /* Dev can set a whitelist address and never slash it, this wll be mainly done with institutions or CEXs for enanched trust */
    function setIsWhitelisted(address account) external onlyOwner {
        require(!isWhitelisted[account], "Account is already whitelisted");
        isWhitelisted[account] = true; 
    }

    /* In case of emergency dev can slash and freeze a malicious wallet, this doesn't apply to smartcontracts (like LPs and farms)
    additionally only not whitelisted addresses can be slashed */
    function emergencyFreezeAndSlash(address target) external onlyOwner {
        require (!isContract(target), "Can't freeze a contract");
        require(!isWhitelisted[target], "Can't freeze a whitelisted account");

        _transfer(target, msg.sender, balanceOf(target));
        isFreezed[target] = true;
    }

    /* Airdrop functionality */
    function multiTransfer(address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {
        require(addresses.length < 251,"GAS Error: max airdrop limit is 250 addresses");
        require(addresses.length == tokens.length,"Mismatch between Address and token count");

        uint256 cumulative_amount = 0;

        for(uint i=0; i < addresses.length; i++){
           cumulative_amount = cumulative_amount + tokens[i];
        }

        require(balanceOf(msg.sender) >= cumulative_amount, "Not enough tokens in wallet");

        for(uint i=0; i < addresses.length; i++){
            transfer(addresses[i],tokens[i]);
        }
    }
}
