pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

contract AddXyz is ERC20BurnableUpgradeSafe, OwnableUpgradeSafe {

    address public bondedContract;
    address public unbondedContract;

    mapping(address => bool) public blackList;

    constructor(
        string memory name,
        string memory symbol,
        address _bondedContract,
        address _unbondedContract,
        uint _amountForBonded,
        uint _amountForUnBonded,
        uint _amountForSeed
    )
        public
    {
        __Ownable_init_unchained();
        __ERC20_init(name, symbol);

        bondedContract = _bondedContract;
        unbondedContract = _unbondedContract;

        _mint(
            bondedContract, _amountForBonded
        );
        _mint(
            unbondedContract, _amountForUnBonded
        );
        _mint(
            msg.sender, _amountForSeed
        );
    }

    function setBlackList(
        address[] memory addresses,
        bool[] memory blackListStates
    )
    public
    onlyOwner
    {
        require(
            addresses.length == blackListStates.length,
            "Invalid request length"
        );
        for (uint i = 0; i < addresses.length; i++) {
            blackList[addresses[i]] = blackListStates[i];
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        require(blackList[sender] == false, "ERC20: sender is in black list");
        require(blackList[recipient] == false, "ERC20: recipient is in black list");
        super._transfer(sender, recipient, amount);
    }
}