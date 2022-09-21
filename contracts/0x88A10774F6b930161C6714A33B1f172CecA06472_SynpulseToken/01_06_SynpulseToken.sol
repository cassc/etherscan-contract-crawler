// SDPX-Licence-Identifier: MIT
// This contract was designed and deployed by : Janis Heibel, Roy Hove and Adil Anees on behalf of Synpulse.
// This contract replaces 0x96b7b58a063e8d0b18f29ec0e7fc5e7742a1fc39

pragma solidity ^0.8.0;

import "ERC20.sol";
import "Pausable.sol";

contract SynpulseToken is ERC20, Pausable {
    address[] public owner;
    address public vaultContract = 0x7eff474f44D384Ee5D48a89cD5A473AC6Fe24CE2; // Synpulse Vault address;
    address admin = 0xAfC3973ca0a79F94c476689c9e9e39cbF83131f4; // Administrator address;

    constructor(uint256 initialSupply)
        ERC20("vSynpulse Token of 2021", "vSYN21")
    {
        _mint(vaultContract, initialSupply);
        owner.push(vaultContract); // Wallet allowed to pause and unpause the contract
        owner.push(admin); // Wallet allowed to pause and unpause the contract
        
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    // This function checks if something is in an array and returns "true" if yes, else "not"
    function isInArray(
        address address_to_check,
        address[] memory array_WeWant_ToCheck
    ) private pure returns (bool) {
        for (uint256 x = 0; x < array_WeWant_ToCheck.length; x++) {
            if (array_WeWant_ToCheck[x] == address_to_check) {
                return true;
            }
        }
        return false;
    }

    modifier onlyOwner() {
        require(
            isInArray(_msgSender(), owner),
            "Only the owner can perform this action!"
        );
        _;
    }

    modifier onlyMaster() {
        require(
            _msgSender() == vaultContract,
            "Only the vault contract can perform this action!"
        );
        _;
    }

    function administrator() public view returns (address) {
        return owner[1];
    }

    function setAdministrator(address administrator_to_set)
        public
        onlyMaster
        whenNotPaused
        returns (bool)
    {
        owner[1] = administrator_to_set;
        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        if (!(_msgSender() == vaultContract)) {
            require(
                (to == vaultContract),
                "Nice try buddy, but you got caught. You cannot send unvested funds!"
            );
        }
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {

        if (!(from == vaultContract)) {
            require(
                (to == vaultContract),
                "This was even better buddy, but we got you again. You cannot send unvested funds!"
            );
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
        }
    }

    // Airdrop aka batch transfers should only be available by the master contract. The amount must be the same for each recipient.
    function sendTokensToMultipleAddresses(
        address[] memory listOfAddresses_ToSend_To,
        uint256[] calldata amountToSend
    ) public whenNotPaused onlyOwner {
        require(listOfAddresses_ToSend_To.length == amountToSend.length, "array lengths must be matching");
        for (uint256 z = 0; z < listOfAddresses_ToSend_To.length; z++) {
            _transfer(vaultContract,listOfAddresses_ToSend_To[z], amountToSend[z]);
        }
    } 

    // This function pauses the contract and preserves the current state of the holdings. It is to be called once the token will be vested.
    function vestAllTokens() public whenNotPaused onlyOwner {
        _pause();
    }

    function reactivateContract() public whenPaused onlyOwner {
        _unpause();
    }
}