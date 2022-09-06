/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: multiClaim.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface passNFT {
    function mint(uint256 _mintAmount) external;
    //function mint(uint256 _mintAmount,uint256 pra2,address add) external;
    function Mint(uint256 _mintAmount) external;
    function mintToken(uint256 pra1) external;
    function claim(address receiver,uint256 tokenId,uint256 quantity,bytes32[] calldata proofs) external;
}


//contract multiClam is Ownable {
contract multiClam is Ownable {
    address contra = address(0xd9145CCE52D386f254917e481eB44e9943F39138);
    function getContract() public view returns(address) {
        return contra;
    }
    function setContract(address setcontra) public onlyOwner {
        contra = setcontra;
    }
    
    function mint(uint256 times,uint256 eachAmount) public {
        for(uint i=0;i<times;++i){
            new mintAmount(contra,eachAmount);
        }
    }
    function mintEach1(uint256 times) public {
        for(uint i=0;i<times;++i){
            new mintEachOne(contra);
        }
    }
    function mintToken(uint256 times,uint256 pra1) public {
        for(uint i=0;i<times;++i){
            new mintTokenC(contra,pra1);
        }
    }
    
}


contract mintAmount{
    constructor(address contra,uint256 eachAmount) {
        //bytes32[] memory proofs;
        passNFT(contra).mint(eachAmount);
        //passNFT(contra).claim(address(tx.origin),2,1,proofs);
        selfdestruct(payable(address(msg.sender)));
    }
}

contract mintEachOne{
    constructor(address contra){
        passNFT(contra).mint(1);
        selfdestruct(payable(address(msg.sender)));
    }
}

contract claimer{
    constructor(address contra) {
        bytes32[] memory proofs;
        passNFT(contra).claim(address(tx.origin),2,1,proofs);
        selfdestruct(payable(address(msg.sender)));
    }
}

contract mintTokenC{
    constructor(address contra,uint256 pra1) {
        passNFT(contra).mintToken(pra1);
        selfdestruct(payable(address(msg.sender)));
    }
}