// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "src/interface/IMultiMerkleStash.sol";
import "src/interface/IVeSDT.sol";

contract ClaimAndLock {

    address public multiMerkleStash =
        address(0x03E34b085C52985F6a5D27243F20C84bDdc01Db4);
    address public constant VE_SDT =
        address(0x0C30476f66034E11782938DF8e4384970B6c9e8a);
    address public constant SDT = 
        address(0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F);

    constructor() {
        IERC20(SDT).approve(VE_SDT, type(uint256).max);
    }

    /// @notice Grouping tx for Claiming SDT from bribes and Lock it on veSDT
    /// @dev For locking SDT into veSDT, account should already have some veSDT
    /// @dev Can't lock SDT into veSDT for first time here
    /// @param token Address of bribes reward token
    /// @param index Index for the merkle tree 
    /// @param account Address of the bribes receiver
    /// @param amount Amount of bribes received
    /// @param merkleProof MerkleProof for this bribes session
    /// @param lock Boolean to lock or not SDT (if token == SDT)
    function claimAndLock(
        address token,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof, 
        bool lock
    ) public {
        IMultiMerkleStash(multiMerkleStash).claim(
            token,
            index,
            account,
            amount,
            merkleProof
        );
        if (token == SDT && lock) {
            IERC20(SDT).transferFrom(account, address(this), amount);
            IVeSDT(VE_SDT).deposit_for(account, amount);
        }
    }

    /// @notice Grouping tx for Claiming SDT from bribes and Lock it on veSDT
    /// @dev For locking SDT into veSDT, account should already have some veSDT
    /// @dev Can't lock SDT into veSDT for first time here
    /// @param account Address of the bribes receiver
    /// @param claims List containing claimParam structure argument needed for claimMulti 
    /// @param lock Boolean to lock or not SDT (if token == SDT)
    function claimAndLockMulti(address account, IMultiMerkleStash.claimParam[] memory claims, bool lock) external{
        //claim all bribes token
        IMultiMerkleStash(multiMerkleStash).claimMulti(account, claims);

        // find amount of SDT claimed
        uint256 amountSDT = 0;
        uint256 length = claims.length;
        for (uint256 i = 0; i < length;) {
            if (claims[i].token == SDT){
                amountSDT = claims[i].amount;
                break;
            }
            unchecked {
                ++i;
            }
        }

        // lock SDT 
        if (lock) {
            IERC20(SDT).transferFrom(account, address(this), amountSDT);
            IVeSDT(VE_SDT).deposit_for(account, amountSDT);
        }
        
    }
}