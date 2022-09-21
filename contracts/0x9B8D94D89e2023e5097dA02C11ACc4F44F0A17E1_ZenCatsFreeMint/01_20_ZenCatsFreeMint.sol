// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ZenCats.sol";
contract ZenCatsFreeMint is Ownable,Pausable {
    using Strings for string;

    address public nftAddress;
 
    uint public  supply;
    address signer;
    mapping(address => bool)  public minted;
    function setSigner(address _signer) external onlyOwner { 
        signer = _signer;
    }
    function pause() external onlyOwner{
        _pause();
    }

    function unpause() external onlyOwner{
        _unpause();
    }

    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
        supply = 1001;
    }


    function mint(bytes calldata signature) public whenNotPaused {
        require(isWhitelisted((signature)), "Not on Whitelist");
        require(supply > 0 ,"No more zen cats to mint");
        require(!minted[msg.sender],"you already minted");
        ZenCats zencatContract = ZenCats(nftAddress);
        zencatContract.mintTo(msg.sender,0);
        supply--;
        minted[msg.sender] = true;

    }


    
    function isWhitelisted(bytes calldata signature)  public view returns (bool) {
        bytes32 message = ECDSA.toEthSignedMessageHash(abi.encodePacked(msg.sender));
        address receivedAddress = ECDSA.recover(message, signature);
        return (receivedAddress != address(0) && receivedAddress == signer);
    }

}