// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./Proposal.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CitrusV2 is Initializable, Proposal {
    
    /**
     * Initialization of the Contract 
     */

    function init(
        address[] memory _owners, 
        uint[] memory _sharePercentage
    ) external initializer 
    {
        symbol = "CTS2";
        name = "Citrus 2.0";
        decimals = 18;
        totalSupply = 500000000 * 1 ether;
        
        for(uint256 i=0; i < _owners.length; i++)
        {
            address owner = _owners[i];
            require(
                owner != address(0), 
                "PROMPT 2009: Invalid address. Please enter a valid address!"
            );
            require(
                !isOwner[owner], 
                "PROMPT 2010: Owner is not unique. Please enter a unique owner!"
            );
            isOwner[owner] = true;
            balances[owner] = (totalSupply * _sharePercentage[i])/100 ;
            lockTime[owner] = block.timestamp + 1826 days;
            noOfOwners++;
        }
        lockTimeForOwners = block.timestamp + 1826 days;
    }

    /**
     * Burning a tokens if user want to burn it. if Owner want to burn token , they have to pass through proposals
     */

    function burn(uint _amount)
        external 
        onlyUsers
    {
        _burn(msg.sender, _amount);
    }   

    function setSwapAddress(address swapContractAddress) 
        external 
        onlyOwners
    {
        require(
            swapContractAddress != address(0), 
            "PROMPT 2009: Invalid address. Please enter a valid address!"
        );

        swapAddress = swapContractAddress;
    }
}