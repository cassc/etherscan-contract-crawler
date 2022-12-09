// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Standard ERC20 token, with minting and pause functionality.
 *
 */
contract EttiosToken is ERC20 {
    uint8 customDecimals = 18;
    uint TOTAL_SUPPLY_ALLOWED;
    address _owner;
    uint32 public phase = 0;
    uint public lockBlocks;
    uint public initBlock;
    uint public nextBlocksUnlock;

    constructor(string memory name, string memory symbol,
        uint256 totalSupplyAllowed, uint8 _decimals, uint _lockBlocks) ERC20(name, symbol)
    {
        require(totalSupplyAllowed > 0, "Total supply must be greater than 0");
        customDecimals = _decimals;
        //Send initially to deployer
        // _mint(msg.sender, _initMint * (10**uint256(decimals())));
        TOTAL_SUPPLY_ALLOWED = totalSupplyAllowed * 10 ** uint256(customDecimals);
        _owner = msg.sender;
        lockBlocks = _lockBlocks;
        initBlock = block.number;
        nextBlocksUnlock = initBlock + lockBlocks;
    }

    function mintByPhase(uint256 _amount) public {
        require(msg.sender == _owner, "Only owner can mint");
        require(_amount > 0, "Amount must be greater than 0");
        uint toMint = _amount * (10**uint256(customDecimals));
        require(totalSupply() + toMint <= TOTAL_SUPPLY_ALLOWED, "Total supply exceeded");
        // require(lockBlocks * phase + initBlock <= block.number, "Lock blocks not reached");
        require(nextBlocksUnlock <= block.number, "Lock blocks not reached");
        nextBlocksUnlock += lockBlocks;
        phase++;
        _mint(msg.sender, toMint);
    }

    function decimals() public view virtual override returns (uint8) {
        return customDecimals;
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function getTotalSupplyAllowed() public view returns (uint) {
        return TOTAL_SUPPLY_ALLOWED;
    }
}