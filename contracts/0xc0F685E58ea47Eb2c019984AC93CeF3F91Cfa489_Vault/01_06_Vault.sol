//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @dev Implementation of a vault to deposit funds for yield optimizing.
 * This is the contract that receives funds and that users interface with.
 */
contract Vault is ERC20, Ownable {

    string private _name;
    address public safeFarm;

    event NameChanged(string newName, address by);
    event safeFarmUpgraded(address newSafeFarm);

    /**
     * @dev Sets the value of {token} to the token that the vault will
     * hold as underlying value. It initializes the vault's own 'moo' token.
     * This token is minted when someone does a deposit. It is burned in order
     * to withdraw the corresponding portion of the underlying assets.
     * @param safeFarm_ the address of the safeFarm.
     * @param name_ the name of the vault token.
     * @param symbol_ the symbol of the vault token.
     */
    constructor (
        address safeFarm_,
        string memory name_,
        string memory symbol_
    ) ERC20(
        name_,
        symbol_
    ) {
        require(safeFarm_ != address(0), "zero safeFarm");
        safeFarm = safeFarm_;
        _name = name_;
    }

    /**
     * @notice Strict access by safeFarm contract
     */
    modifier onlySafeFarm() {
        require(msg.sender == safeFarm, "not safeFarm");
        _;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function changeName(string memory name_) external onlyOwner {
        _name = name_;

        emit NameChanged(name_, msg.sender);
    }

    /**
     * @notice Migrating to new SafeFarm address
     * @notice Only callable by owner address.
     * @param newSafeFarm Address of new SafeFarm contract.
    */
    function upgradeSafeFarm(address newSafeFarm) external onlyOwner {
        require(newSafeFarm != address(0), "zero safeFarm");

        ISafeFarm(safeFarm).migrate(newSafeFarm);

        safeFarm = newSafeFarm;

        emit safeFarmUpgraded(newSafeFarm);
    }

    /**
     * @dev Only callable by safeFarm contract
     */
    function mint(address _recipient, uint256 _amount) public onlySafeFarm {
        _mint(_recipient, _amount);
    }

    /**
     * @dev Only callable by safeFarm contract
     */
    function burn(address _owner, uint256 _amount) public onlySafeFarm {
        _burn(_owner, _amount);
    }
}

interface ISafeFarm {
    function migrate(address newSafeFarm) external;
}