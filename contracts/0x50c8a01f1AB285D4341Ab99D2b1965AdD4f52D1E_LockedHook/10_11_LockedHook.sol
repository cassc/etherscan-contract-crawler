// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./hooks/SafeHook.sol";
import "./sales/INFT.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@artman325/version/contracts/Version.sol";

//import "hardhat/console.sol";

contract LockedHook is SafeHook, ReentrancyGuard, Version {

    mapping(address => mapping(uint256 => address)) lockedMap;

    event TokenLocked(address nftContract, address indexed owner, uint256 indexed tokenId, address indexed custodian);
    event TokenUnlocked(address nftContract, address indexed owner, uint256 indexed tokenId, address indexed custodian);

    error AlreadyLocked(address nftContract, uint256 tokenId, address custodian);
    error NotLocked(address nftContract, uint256 tokenId);
    error Locked(address nftContract, uint256 tokenId);
    error NotAnOwner(address nftContract, uint256 tokenId);
    error NotACustodian(address nftContract, uint256 tokenId);
    error UnknownTokenId(address nftContract, uint256 tokenId);
    error WrongAddress(address account);

    constructor() {
        setVersionMetaData(1,0,0);
    }

    function executeHook(address from, address /*to*/, uint256 tokenId) external virtual override returns(bool success) {
        address nftContract = msg.sender;
        
        if (lockedMap[nftContract][tokenId] != address(0)) {
            // here we can't handle this custom error type
            // caller just  perfom try catch if if reason is a string like [revert("bla bla bla")] then it catch, 
            // otherwise just revert("Transfer Not Authorise") on caller side
            revert Locked(from, tokenId);
            //return false;
        } else {
            return true;
        }
        
        
    }

    function isLocked(address nftContract, uint256 tokenId) public view returns(bool locked, address custodian) {
        custodian = lockedMap[nftContract][tokenId];
        locked = custodian == address(0) ? false : true;
    }

    function lock(address nftContract, uint256 tokenId, address custodian) public nonReentrant {
        
        if (lockedMap[nftContract][tokenId] != address(0)) {
            revert AlreadyLocked(nftContract, tokenId, lockedMap[nftContract][tokenId]);
        }
        bool exists;
        address nftOwner;
        (, exists, , nftOwner) = INFT(nftContract).getTokenSaleInfo(tokenId);
        if (!exists) {
            revert UnknownTokenId(nftContract, tokenId);
        }
        if (nftOwner != msg.sender) {
            revert NotAnOwner(nftContract, tokenId);
        }
        if (custodian == address(0)) {
            revert WrongAddress(custodian);
        }
        lockedMap[nftContract][tokenId] = custodian;

        emit TokenLocked(nftContract, nftOwner, tokenId, custodian);
    }

    function unlock(address nftContract, uint256 tokenId) public nonReentrant {
        if (lockedMap[nftContract][tokenId] == address(0)) {
            revert NotLocked(nftContract, tokenId);
        }
        if (lockedMap[nftContract][tokenId] != msg.sender) {
            revert NotACustodian(nftContract, tokenId);
        }
        address nftOwner;
        (,,, nftOwner) = INFT(nftContract).getTokenSaleInfo(tokenId);
        emit TokenUnlocked(nftContract, nftOwner, tokenId, lockedMap[nftContract][tokenId]);

        lockedMap[nftContract][tokenId] = address(0);
    }
}