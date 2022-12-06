// SPDX-License-Identifier: MIT
// Ermine Virtual Miners (EVM) :: https://ermine.pro 

//  ███████╗██████╗$███╗$$$███╗██╗███╗$$$██╗███████╗██╗$$$██╗███╗$$$███╗
//  ██╔════╝██╔══██╗████╗$████║██║████╗$$██║██╔════╝██║$$$██║████╗$████║
//  █████╗$$██████╔╝██╔████╔██║██║██╔██╗$██║█████╗$$██║$$$██║██╔████╔██║
//  ██╔══╝$$██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██╔══╝$$╚██╗$██╔╝██║╚██╔╝██║
//  ███████╗██║$$██║██║$╚═╝$██║██║██║$╚████║███████╗$╚████╔╝$██║$╚═╝$██║
//  ╚══════╝╚═╝$$╚═╝╚═╝$$$$$╚═╝╚═╝╚═╝$$╚═══╝╚══════╝$$╚═══╝$$╚═╝$$$$$╚═╝

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ErmineVM is ERC1155Supply, Ownable  {
    uint[] public maxAmountEVM = new uint256[](12);
    uint[] public burnedEVM = new uint256[](12);
    uint256 public timeAddLE;
    address public addressErmineStore;
    bool VMpart1 = false;
    bool VMpart2 = false;
    string public name;
    string public symbol;  

event Burn(address indexed from, uint evm_id, uint256 amount);

struct Admin {
    bool sys;
}

mapping(address => Admin) public checkAdmin;

constructor(string memory _uri, string memory _name, string memory _symbol) ERC1155(_uri) {
    name = _name;
    symbol = _symbol;
    checkAdmin[msg.sender].sys = true;
    //Mint to the developers' wallet to distribute them to community members for fulfilling certain conditions (competitions)
    //100 miners with 1 IPS each
    _mint(msg.sender, 0, 100, "");
    //Setting the maximum number of EVMs for each category
    maxAmountEVM[0] = 1000000;
    maxAmountEVM[1] = 500000;
    maxAmountEVM[2] = 300000;
    maxAmountEVM[3] = 100000;
    maxAmountEVM[4] = 50000;
    maxAmountEVM[5] = 20000;
    maxAmountEVM[6] = 10000;
    maxAmountEVM[7] = 5000;
    maxAmountEVM[8] = 50000;
    maxAmountEVM[9] = 20000;
    maxAmountEVM[10] = 3000;
    maxAmountEVM[11] = 1000;
}

modifier onlyAdmin() {
    require(checkAdmin[msg.sender].sys);
    _;                              
} 

//EVM mint for Ermine store part 1
function mintEVMforStore() external onlyOwner {
require(addressErmineStore != address(0), "Ermine store address not specified! Set the store address and try again!");
require(!VMpart1, "Virtual miners have already been sent to the Ermine store. Can't be repeated!");
    VMpart1 = !VMpart1;
    _mint(addressErmineStore, 0, (maxAmountEVM[0] - 100), "");
    for (uint i = 1; i < 8; i++) {
    _mint(addressErmineStore, i, maxAmountEVM[i], "");
    //Setting the time to transfer VM LE to the Ermine store. VM LE release will be available in 181 days.
    timeAddLE = block.timestamp + 15638400;
    }
}

//EVM mint for Ermine store part 2. Available one time. The call is available to everyone.
function mintEVMLEforStore() external {
require(block.timestamp >= timeAddLE, "It is not yet possible to ship the EVM LE to the Ermine store. Less than 181 days have passed since the first shipment!");
require(VMpart1, "Release the EVM in the first batch first!");
require(!VMpart2, "Virtual miners have already been sent to the Ermine store. Can't be repeated!");
    VMpart2 = !VMpart2;
    for (uint i = 8; i < 12; i++) {
    _mint(addressErmineStore, i, maxAmountEVM[i], "");
    }
}

//Burning is available to everyone
function burnMyEVM(uint evm_id, uint256 amount) external { 
    require(balanceOf(msg.sender, evm_id) >= amount, "You don't have enough EVM to burn them!");
    _burn(msg.sender, evm_id, amount);
    burnedEVM[evm_id] += amount;
    emit Burn(msg.sender, evm_id, amount);
}

//Set Ermine store address (you can only set the store address once)
function setErmineStore(address _ErmineStore) external onlyOwner {
    require(addressErmineStore == address(0), "The address of the Ermine store is already set!");
    addressErmineStore = _ErmineStore;
    checkAdmin[addressErmineStore].sys = true;
}

//Set URI
function setURI(string memory newuri) public onlyAdmin {
    _setURI(newuri);
}

//Remove Admin Rights
function RemoveAdmin() public onlyAdmin {
    require(checkAdmin[msg.sender].sys, "You cannot relinquish admin rights as you are not an admin!");
    checkAdmin[msg.sender].sys = !checkAdmin[msg.sender].sys;
}

//View URI
function uri(uint256 _id) public view override returns (string memory) {
    require(exists(_id), "URI: nonexistent EVM token");
    return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
}

}