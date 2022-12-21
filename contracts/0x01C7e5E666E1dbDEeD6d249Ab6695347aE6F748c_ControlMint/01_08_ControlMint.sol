//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./../permission/ContractRestricted.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IControlMint.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


//El freemint debe tener una variable de control apra saber cuantos nft puede mintear un address

contract ControlMint is ContractRestricted, IControlMint {
    using Counters for Counters.Counter;
    using Strings for string; 


    Counters.Counter private implementAddressFreemintList;
    Counters.Counter private mintsFreemintList = Counters.Counter(1);
    Counters.Counter private implementAddressWhitelistList;
    Counters.Counter private mintsWhitelistList;

    uint16 private maxMintAddressFreemintList = 100;
    uint16 private maxMintAddressWhitelistList = 500;

    uint32 private numMaxForAddress = 5; 
    uint64 private event1MoreCount = 0;
    mapping(address => uint64) private event1MoreLastMint;
    bool private event1More = false;

    mapping(address => AccessFreemint) private addressFreemintList;
    mapping(address => AccessWhitelist) private addressWhitelistList;

    mapping(address => uint32) private quantityMintForAddress;

    constructor(address accessContract) ContractRestricted(accessContract) {}

    function addAddressFreemintList(address[] memory newMinters) public override onlyOwner{

        require(newMinters.length <= 50, "List can only have a maximum of 50.");
        require(mintsFreemintList.current() < maxMintAddressFreemintList, "Insufficient gaps in the whitelist.");

        for (uint256 i = 0; i < newMinters.length; i++) {
            implementAddressFreemintList.increment();

            addressFreemintList[newMinters[i]] = AccessFreemint(
                addressFreemintList[newMinters[i]].active ? addressFreemintList[newMinters[i]].numMints + 1 : 1,
                true
            );
            emit NewAccessFreemint (newMinters[i], block.timestamp);
        }
    }

    function addAddressWhitelistList(address[] memory newMinters) public override onlyOwner{

        require(newMinters.length <= 50, "List can only have a maximum of 50.");
        require(mintsWhitelistList.current() < maxMintAddressWhitelistList, "Insufficient gaps in the whitelist.");

        for (uint256 i = 0; i < newMinters.length; i++) {
            implementAddressWhitelistList.increment();
            
            if(addressWhitelistList[newMinters[i]].active){
                continue;
            }

            addressWhitelistList[newMinters[i]] = AccessWhitelist(
                0,
                true,
                event1MoreCount
            );

            emit NewAccessWhitelist(newMinters[i], block.timestamp);
        }

    }

    function getAddressFreemintListCount() public override view onlyOwner returns(uint256){
        return implementAddressFreemintList.current();
    }

    function getAddressWhitelistListCount() public override view onlyOwner returns(uint256){
        return implementAddressWhitelistList.current();
    }

    function getMintsFreemintCount() public override view returns(uint256){
        return mintsFreemintList.current();
    }

    function getMintsWhitelistCount() public override view returns(uint256){
        return mintsWhitelistList.current();
    }

    function checkMinterFreemint(address minter) public override view returns(bool){

        require(addressFreemintList[minter].active, "This address is not included in the whitelist");
        require(getMintForAddress(minter) < numMaxForAddress, "Your mint limit reached");
        require(addressFreemintList[minter].numMints > 0, "No mints available");

        return true;
    }

    function checkMinterWhiteList(address minter) public override view returns(bool){

        require(addressWhitelistList[minter].active, "This address is not included in the whitelist");
        require(getMintForAddress(minter) < numMaxForAddress, "Your mint limit reached");

        if(addressWhitelistList[minter].numMints > 0){
            if(event1More){
                if(event1MoreLastMint[minter] == event1MoreCount){
                    revert("You have already minted 1 more for this event");
                }
                return true;
            }
            revert("No mints available");
        }
        return true;
    }

    function minterUseFreemint(address minter) public override onlyOwnerOrContract returns(bool){
        require(mintsFreemintList.current() < maxMintAddressFreemintList, "Freemint mint limit reached");     
        require(checkMinterFreemint(minter), "Minter cannot mint");
        mintsFreemintList.increment();
        addressFreemintList[minter].numMints--;
        return true;
    }

    function minterUseWhitelist(address minter) public override onlyOwnerOrContract returns(bool){
        require(mintsWhitelistList.current() < maxMintAddressWhitelistList, "Whitelist mint limit reached");     

        if(!checkMinterWhiteList(minter)){
            revert("No posiible whitelist  mint");
        }
        
        if(addressWhitelistList[minter].numMints > 0){
            event1MoreLastMint[minter] = event1MoreCount;
        }
        mintsWhitelistList.increment();
        addressWhitelistList[minter].numMints++;
        return true;
    }

    function addMintForAddress(address minter) public override onlyOwnerOrContract{
        quantityMintForAddress[minter] ++;
    }

    function activeEvent1MoreWhitelist(bool active) public override onlyOwner {
        event1More = active;
        if(active){
            event1MoreCount++;
        }
        emit Event1More(event1More, event1MoreCount, block.timestamp);
    }

    function getNumEvent1More() public override view onlyOwner returns(uint64){
        return event1MoreCount;
    }

    function getStateEvent1More() public override view onlyOwner returns(bool){
        return event1More;
    }

    function getMintForAddress(address minter) public override view returns(uint32){
        return quantityMintForAddress[minter];
    }

    function getAvailableMintForAddressPS(address minter) public override view returns(uint32){
        return numMaxForAddress - quantityMintForAddress[minter];
    }

    function getAvailableMintForAddressFM(address minter) public override view returns(uint32){

        if(addressFreemintList[minter].active && addressFreemintList[minter].numMints > 0 && quantityMintForAddress[minter] < numMaxForAddress){
            if(quantityMintForAddress[minter] + addressFreemintList[minter].numMints <= numMaxForAddress){
                return addressFreemintList[minter].numMints;
            }else{
                return numMaxForAddress - quantityMintForAddress[minter];
            }
        }
        return 0;

    }

    function getAvailableMintForAddressWL(address minter) public override view returns(uint32){
        if(addressWhitelistList[minter].active && quantityMintForAddress[minter] < numMaxForAddress){
            if(event1More){
                if(event1MoreLastMint[minter] < event1MoreCount && addressWhitelistList[minter].numMints > 0){
                    return numMaxForAddress - quantityMintForAddress[minter] >= 1 ? 1 : 0;
                }else if(event1MoreLastMint[minter] < event1MoreCount && addressWhitelistList[minter].numMints == 0){
                    return numMaxForAddress - quantityMintForAddress[minter] >= 2 ? 2 : numMaxForAddress - quantityMintForAddress[minter];
                }else if(event1MoreLastMint[minter] == event1MoreCount){
                    return 0;
                }
            }else{
                if(addressWhitelistList[minter].numMints > 0){
                    return 0;
                }else{
                    return numMaxForAddress - quantityMintForAddress[minter] >= 1 ? 1 : 0;
                }
            }
        }
        return 0;
    }

    function checkAddressActive(address minter) public override view returns(bool, bool){
        return (addressFreemintList[minter].active, addressWhitelistList[minter].active);
    }

}