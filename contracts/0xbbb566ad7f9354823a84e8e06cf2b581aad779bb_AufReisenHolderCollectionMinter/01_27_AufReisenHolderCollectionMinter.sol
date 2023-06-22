//
//
//
/////////////////////////////////////////////////////////////////
//                                                             //
//       ██████  ███████ ███    ██ ███    ██ ██ ███████        //
//       ██   ██ ██      ████   ██ ████   ██ ██ ██             //
//       ██   ██ █████   ██ ██  ██ ██ ██  ██ ██ ███████        //
//       ██   ██ ██      ██  ██ ██ ██  ██ ██ ██      ██        //
//       ██████  ███████ ██   ████ ██   ████ ██ ███████        //
//                                                             //
// ███████  ██████ ██   ██ ███    ███ ███████ ██      ███████  //
// ██      ██      ██   ██ ████  ████ ██      ██         ███   //
// ███████ ██      ███████ ██ ████ ██ █████   ██        ███    //
//      ██ ██      ██   ██ ██  ██  ██ ██      ██       ███     //
// ███████  ██████ ██   ██ ██      ██ ███████ ███████ ███████  //
//                                                             //
/////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AufReisenHolderCollectionMinter is Ownable {
    address public aufReisenHolderCollectionAddress = 0x5f8fFe705917eddC406a4273a120BE7Be125A46f;

    bool public isMintEnabled = true;
    
    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;
    
    mapping(uint256 => mapping(address => uint256)) public waveMints;
    uint currentWave = 0;

    constructor() {}

    function setIsMintEnabled(bool isEnabled) public onlyOwner {
        isMintEnabled = isEnabled;
    }

     function airdrop(
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) onlyOwner public {
        require(to.length == id.length && to.length == amount.length, "Length mismatch");
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(aufReisenHolderCollectionAddress);
        for (uint256 i = 0; i < to.length; i++)
            token.mint(to[i], id[i], amount[i], "");
    }

    function mint() public {
        require(isMintEnabled, "Mint not enabled");
        require(waveMints[currentWave][msg.sender] < 1, "Wallet already claimed");
        
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(aufReisenHolderCollectionAddress);
         
        token.mint(msg.sender, _idTracker.current(), 1, "");
        _idTracker.increment();
        
        waveMints[currentWave][msg.sender] += 1;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setCurrentWave(uint _currentWave) public onlyOwner {
        currentWave = _currentWave;
    }

    function setAufReisenHolderCollectionAddress(address newAddress) public onlyOwner {
        aufReisenHolderCollectionAddress = newAddress;
    }
}