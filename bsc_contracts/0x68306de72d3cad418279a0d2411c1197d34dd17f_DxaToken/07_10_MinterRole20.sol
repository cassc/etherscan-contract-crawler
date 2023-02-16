// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/* import "@openzeppelin/contracts/utils/Context.sol";
 * function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */


contract MinterRole20 {  

    address private _vote_A;
    address private _vote_B;


    address private _new_vote_A;
    address private _new_vote_B;



    event OwnershipTransferredVote(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _restoreOwnerForRequest();
    }

    function _restoreOwnerForRequest() internal {
        
        _vote_A = msg.sender;
        _vote_B = msg.sender;

        _new_vote_A = msg.sender;
        _new_vote_B = msg.sender;

        address oldOwner = vote_A();
        emit OwnershipTransferredVote(oldOwner, msg.sender);
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyVoteA() {
        require(_vote_A == msg.sender, "is not the vote_A");
        _;
    }

    modifier onlyVoteB() {
        require(_vote_B == msg.sender, "is not the vote_B");
        _;
    }

    modifier onlyMinter() {
        require(_isUserVote(msg.sender), "is not the minter");
        _;
    }

    function _isUserVote(address operator) internal returns (bool) {
        return ((vote_A() == operator)||(vote_B() == operator));
    }

    function _checkAdrZero(address newOwner) internal {
        require(newOwner != address(0), "owner is zero address");
    }


    /**
     * @dev Returns the address of the current owner.
     */
    function vote_A() public view virtual returns (address) {
        return _vote_A;
    }
    function vote_B() public view virtual returns (address) {
        return _vote_B;
    }


    function new_vote_A() public view virtual returns (address) {
        return _new_vote_A;
    }
    function new_vote_B() public view virtual returns (address) {
        return _new_vote_B;
    }


   
    
    // @dev Transfers ownership of the contract to a new account (`newOwner`).
    // Can only be called by the current owner.    

    function ownerVoteA(address newOwner) public virtual onlyMinter{
        _checkAdrZero(newOwner);
        address oldOwner = _vote_A;

        if (vote_A() == msg.sender) {
            _new_vote_A = newOwner;

            if (vote_A() !=  vote_B()) {
                return;
            }
        }

        if ((vote_B() == msg.sender) && (new_vote_A() == newOwner))  {
            _vote_A = newOwner;
            emit OwnershipTransferredVote(oldOwner, newOwner);
            return;
        }
        revert();
    }

    function ownerVoteB(address newOwner) public virtual onlyMinter{
        _checkAdrZero(newOwner);
        address oldOwner = _vote_B;

        if (vote_B() == msg.sender) {
            _new_vote_B = newOwner;

            if (vote_A() !=  vote_B()) {
                return;
            }
        }

        if ((vote_A() == msg.sender) && (new_vote_B() == newOwner))  {
            _vote_B = newOwner;
            emit OwnershipTransferredVote(oldOwner, newOwner);
            return;
        }
        revert();
    }

}




 