// SPDX-License-Identifier: VPL

pragma solidity ^0.8.13;
import "solady/Milady.sol";
import "solady/auth/Ownable.sol";

contract GasCityHitler is ERC20, Ownable {
    uint256 public constant SUPPLY_CAP = 1_488_420_000 * 10**18;
    uint256 public constant AIRDROP_AMOUNT = 148_869 * 10**18;

    constructor() ERC20(){
        _initializeOwner(msg.sender);
        _mint(msg.sender, SUPPLY_CAP);
        increaseAllowance(msg.sender, SUPPLY_CAP);

    }

    function sendAirdrop(address[] memory recipients) public onlyOwner{
        for(uint i = 0; i < recipients.length; i++){
            transfer(recipients[i], AIRDROP_AMOUNT);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override{
        super._beforeTokenTransfer(from, to, amount);
        require(totalSupply() <= SUPPLY_CAP, "ERC20: supply cap exceeded!");
    }

    function symbol() public override view virtual returns (string memory){
        return "GAS";
    }

    function name() public override view virtual returns (string memory){
        return "Gas City Hitler";
    }
}