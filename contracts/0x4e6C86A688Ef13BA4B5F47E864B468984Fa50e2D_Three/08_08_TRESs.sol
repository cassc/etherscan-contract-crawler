// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Three a Token provided by TheMetalorianDao
/// @notice Once locked values are set, they cannot be changed.
contract Three is ERC20Pausable, Ownable {

    /// @notice Used to lock an amount of tokens
    struct Lock {
        uint amount;
        uint unlockDate;
        bool withdrawn;
    }

    /// @notice Array with the locked tokens
    Lock[] public lockedTokens;

    /// @param owner Contract owner
    /// @param issueAmount Amount of tokens issued
    event IssueThree( address owner, uint issueAmount );

    /// @param _locksInfo Amounts of tokens that will be locked
    /// @param _amountInTGE Amount that will be available in the TGE
    constructor ( Lock[] memory _locksInfo, uint _amountInTGE ) ERC20( "Three", "TRSs"){

        // push the info in the lock array

        for (uint256 i = 0; i < _locksInfo.length; i++) {

            lockedTokens.push( _locksInfo[i] );
            
        }

        // mint the fixed supply

        _mint( address( this ) , 33_333_333 * 1e18 );

        // the amount available in the TGE are sent to the Contract owner

        _transfer( address( this ), msg.sender, _amountInTGE );
        
    }

    /// @notice Returns the total amount of tokens locked
    function getTokensLocked() public view returns( uint lockedAmount) {

        for (uint256 i = 0; i < lockedTokens.length; i++) {
                
            if( !lockedTokens[i].withdrawn ) lockedAmount += lockedTokens[i].amount;
            
        }

    }

    /// @notice Function to issue tokens check the lock amounts and dates to see availability 
    function issueThree() public onlyOwner {

        uint totalToIssue;

        for (uint256 i = 0; i < lockedTokens.length; i++) {

            if( block.timestamp >= lockedTokens[i].unlockDate ) {

                // tokens are only transferred if they have not been withdrawn
                
                if( !lockedTokens[i].withdrawn ) {

                    totalToIssue += lockedTokens[i].amount;

                    lockedTokens[i].withdrawn = true;

                }
                
            }
            
        }

        require( totalToIssue > 0, "Transfer Error: No tokens available" );

        _transfer( address( this ), owner(), totalToIssue );

        emit IssueThree( owner(), totalToIssue );

    }

    /// @notice Pause all type of transfers of the Token
    /// @dev see [ Pausable-_pause ] for more info
    function pauseTransfers() public onlyOwner returns ( bool isPaused ) {

        _pause();

        isPaused = paused();

    }

    /// @notice Unpause the transfers of the Token
    /// @dev see [ Pausable-_unpause ] for more info
    function unpauseTransfers() public onlyOwner returns ( bool isPaused ) {

        _unpause();

        isPaused = paused();
        
    }

}