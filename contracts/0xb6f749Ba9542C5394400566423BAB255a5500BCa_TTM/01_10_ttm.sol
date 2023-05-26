// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error AlreadyClaimed();
error MintClosed();
error ShouldBeMultisig();

contract TTM is ERC1155, Ownable {

    bool public freemintSwitch;
    mapping(address => bool) public claimed;
    address public multiSig;

    constructor(address _multiSig)
        ERC1155("ipfs://QmVCnSaBd1jpkBMYRAMSj54QbC7QS6a9fx6iwAgWx7Urdt/{id}.json")
    {
        multiSig = _multiSig;
        freemintSwitch = false;
    }

    function setMintSwitch(bool _switch) public onlyOwner{
        freemintSwitch = _switch;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint() 
        public
    {
        if (claimed[msg.sender] == true) revert AlreadyClaimed();
        if (freemintSwitch == false) revert MintClosed();
        _mint(msg.sender,1, 1, "");
        claimed[msg.sender] = true;
    }
    
    //The NFTs minted by multisig will be airdropped to our friends helped this project
    function multiSigMint()
        public
    {
        if (msg.sender != multiSig) revert ShouldBeMultisig();
        if (claimed[msg.sender] == true) revert AlreadyClaimed();
        _mint(msg.sender,0, 166, "");
        claimed[msg.sender] = true;
    }

}