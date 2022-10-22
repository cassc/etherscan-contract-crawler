// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*                                                                                
 *                                     ~~                                       
 *                                    .BG                                       
 *                                    J&&J                                      
 *                                   ~&&&&^                                     
 *                                   G&&&&P                                     
 *                                  J&&&&&&?                                    
 *                                 ^BB&&&&BB:                                   
 *                         :Y~     J?Y&&&&J??     ~Y.                           
 *                        7#&~     7:?&&&&7:!     ~&#!                          
 *                       Y&&B.       7&#&&!       .B&&J                         
 *                     .P&&&P        7&&&&!        P&&&5.                       
 *                     P&&#&5        ?&&&&7        5&#&&5                       
 *                    Y#YB#&Y        J&&&&?        5&&GY#J                      
 *                   ~P7^J&#P        Y&&&&J        P&&J^?P~                     
 *                   ^7: ~##G        G&###P       .B&&~ :!^                     
 *                       ^###^      ^######^      ~&&&^                         
 *                       ^&&&Y      5######Y      5&&#:                         
 *                       ^&&&#^    7########7    ~&&&#:                         
 *                       !&###B7^~Y########&&Y~^?#####~                         
 *                       Y&##############&&&&&&#&#####J                         
 *                      .G############&&&&&&##########G                         
 *                      ?###########&&&&&#############&7                        
 *                     .Y5PGGBB##&&&&&###########BBGGP5J.                       
 *                      .:^~!7?J5PB##########BP5J?7!~^:.                        
 *                             .:^7YG######GY7~:.                               
 *                                 .~YB##BY~.                                   
 *                                   .7BB?.                                     
 *                                     ??                                       
 *                                     ..                                       
 */                                                                              

contract HolyNephalemSecondary is Ownable, ReentrancyGuard  {

    /* Construction */

    constructor() {
        constructDistribution();
    }

    /* Fallbacks */

    receive() payable external {}
    fallback() payable external {}

    /* Owner */

    /// @notice Prevents ownership renouncement
    function renounceOwnership() public override onlyOwner {}

    /* Funds */

    uint16 private shareDenominator = 10000;
    uint16[] private shares;
    address[] private payees;

    /// @notice Assigns payees and their associated shares
    /// @dev Uses the addPayee function to assign the share distribution
    function constructDistribution() private {
        addPayee(0x8f5C577c85D7Ff99ecA58457cadcaaB7B2433C85, 7000);
        addPayee(0xb71BF456529a0392C48EFAE846Cf6d30C705561D, 1500);
        addPayee(0x86212f0fe1944f37208e0A71c81c772440B89eF6, 1500);
    }

    /// @notice Adds a payee to the distribution list
    /// @dev Ensures that both payee and share length match and also that there is no over assignment of shares.
    function addPayee(address payee, uint16 share) public onlyOwner {
        require(payees.length == shares.length, "Payee and shares must be the same length.");
        require(totalShares() + share <= shareDenominator, "Cannot overassign share distribution.");
        payees.push(payee);
        shares.push(share);
    }

    /// @notice Updates a payee to the distribution list
    /// @dev Ensures that both payee and share length match and also that there is no over assignment of shares.
    function updatePayee(address payee, uint16 share) external onlyOwner {
        require(address(this).balance == 0, "Must have a zero balance before updating payee shares");
        for (uint i=0; i < payees.length; i++) {
            if(payees[i] == payee) shares[i] = share;
        }
        require(totalShares() <= shareDenominator, "Cannot overassign share distribution.");
    }

    /// @notice Removes a payee from the distribution list
    /// @dev Sets a payees shares to zero, but does not remove them from the array. Payee will be ignored in the distributeFunds function
    function removePayee(address payee) external onlyOwner {
        for (uint i=0; i < payees.length; i++) {
            if(payees[i] == payee) shares[i] = 0;
        }
    }

    /// @notice Gets the total number of shares assigned to payees
    /// @dev Calculates total shares from shares[] array.
    function totalShares() private view returns(uint16) {
        uint16 sharesTotal = 0;
        for (uint i=0; i < shares.length; i++) {
            sharesTotal += shares[i];
        }
        return sharesTotal;
    }

    /// @notice Fund distribution function.
    /// @dev Uses the payees and shares array to calculate 
    function distributeFunds() external onlyOwner nonReentrant {

        uint currentBalance = address(this).balance;

        for (uint i=0; i < payees.length; i++) {
            if(shares[i] == 0) continue;
            uint share = (shares[i] * currentBalance) / shareDenominator;
            (bool sent,) = payable(payees[i]).call{value : share}("");
            require(sent, "Failed to distribute to payee.");
        }

        if(address(this).balance > 0) {
            (bool sent,) = msg.sender.call{value: address(this).balance}("");
            require(sent, "Failed to distribute remaining funds.");
        }
    }
}