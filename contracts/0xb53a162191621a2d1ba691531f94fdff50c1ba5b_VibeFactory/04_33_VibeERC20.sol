// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";

contract VibeERC20 is ERC20, Ownable, IMasterContract {

    constructor () ERC20("MASTER", "MASTER", 18) {}

    function init(bytes calldata data) public payable override {
        (string memory _name, string memory _symbol) = abi.decode(data, (string, string));
        require(bytes(name).length == 0 && bytes(_name).length != 0, "Already initialized");
        _transferOwnership(msg.sender);
        name = _name;
        symbol = _symbol;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        _burn(from, amount);
    }

}