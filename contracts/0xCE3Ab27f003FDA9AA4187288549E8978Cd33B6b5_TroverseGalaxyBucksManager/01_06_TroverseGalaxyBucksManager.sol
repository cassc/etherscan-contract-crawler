// contracs/TroverseGalaxyBucksManager.sol
// SPDX-License-Identifier: MIT

// ████████╗██████╗  ██████╗ ██╗   ██╗███████╗██████╗ ███████╗███████╗    
// ╚══██╔══╝██╔══██╗██╔═══██╗██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝    
//    ██║   ██████╔╝██║   ██║██║   ██║█████╗  ██████╔╝███████╗█████╗      
//    ██║   ██╔══██╗██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝      
//    ██║   ██║  ██║╚██████╔╝ ╚████╔╝ ███████╗██║  ██║███████║███████╗    
//    ╚═╝   ╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface IYieldToken {
    function mint(address to, uint256 amount) external;
}


contract TroverseGalaxyBucksManager is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    bool public claimEnabled = false;
    mapping(address => uint64) public claimCount;
    mapping(address => uint64) public lastExpiryDate;
    
    address public signer;

    IYieldToken public yieldToken;

    event YieldTokenChanged(address _yieldToken);
    event ClaimStateChanged(bool _newState);
    event SignerChanged(address _newSigner);
    event Claimed(address _user, uint256 _amount, uint64 _claimNounce);


    constructor() { }


    modifier onlyOwnerOrSigner() {
        require(owner() == _msgSender() || signer == _msgSender(), "The caller is not the owner or signer");
        _;
    }


    function setYieldToken(address _yieldToken) external onlyOwner {
        require(_yieldToken != address(0), "Bad YieldToken address");
        yieldToken = IYieldToken(_yieldToken);

        emit YieldTokenChanged(_yieldToken);
    }
    
    function airdrop(address[] calldata _accounts, uint256[] calldata _amounts) external onlyOwnerOrSigner {
        for (uint256 i; i < _accounts.length; i++) {
            yieldToken.mint(_accounts[i], _amounts[i]);
        }
    }
    
    function claim(uint256 _amount, uint64 _claimNonce, uint64 _issueDate, uint64 _expiryDate, bytes calldata _signature) external nonReentrant {
        require(_expiryDate > block.timestamp, "The signature has expired");
        require(lastExpiryDate[_msgSender()] < _issueDate, "You have already claimed your available rewards.");
        require(verifyOwnerSignature(keccak256(abi.encode(_msgSender(), address(this), _amount, _claimNonce, _issueDate, _expiryDate)), _signature), "Invalid Signature");
        require(claimEnabled, "Claiming is not enabled.");

        yieldToken.mint(_msgSender(), _amount);

        claimCount[_msgSender()]++;
        lastExpiryDate[_msgSender()] = _expiryDate;

        emit Claimed(_msgSender(), _amount, _claimNonce);
    }

    function toggleClaim(bool _claimEnabled) external onlyOwner {
        claimEnabled = _claimEnabled;

        emit ClaimStateChanged(_claimEnabled);
    }

    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Bad Signer address");
        signer = _signer;

        emit SignerChanged(_signer);
    }

    function verifyOwnerSignature(bytes32 hash, bytes memory signature) private view returns (bool) {
        return hash.toEthSignedMessageHash().recover(signature) == signer;
    }
}