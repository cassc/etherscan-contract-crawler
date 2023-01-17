// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CeroToken is ERC20, ERC20Burnable, Pausable, AccessControl,Ownable, ERC20Permit, ERC20Votes, ERC20FlashMint {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    address public flashLoanFeeReceiver = address(0);
    uint public flashLoanFee = 0;
    mapping(address => bool) public transferBlacklist;

    event BlackListUpdate(address indexed user, bool state);
    event LoanFeeUpdate(uint amount);
    event LoanFeeReceiverUpdate(address receiver);

    constructor() ERC20("Cero", "CERO") ERC20Permit("Cero") {
        _mint(msg.sender, 1 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
    }

    function setFlashLoanFee(uint fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
      require(fee != 0,"INPUT ZERO");
      require(fee != flashLoanFee,"SAME");

      flashLoanFee = fee;
      emit LoanFeeUpdate(fee);
    }

    function setFlashLoanReceiver(address receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
      require(receiver != address(0),"INPUT ZERO");
      require(receiver != flashLoanFeeReceiver,"SAME");

      flashLoanFeeReceiver = receiver;
      emit LoanFeeReceiverUpdate(receiver);
    }

    function transferBlackListUpdate(address user, bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        transferBlacklist[user] = value;
        emit BlackListUpdate(user,value);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        require(transferBlacklist[from] == false,"FROM ADDRESS BLACKLISTED");
        require(transferBlacklist[to] == false,"TO ADDRESS BLACKLISTED");
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _flashFee(address token, uint256 amount) internal view override returns (uint256) {
        // silence warning about unused variable without the addition of bytecode.
        token;
        amount;
        return flashLoanFee;
    }

    function _flashFeeReceiver() internal view override returns (address) {
        return flashLoanFeeReceiver;
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}