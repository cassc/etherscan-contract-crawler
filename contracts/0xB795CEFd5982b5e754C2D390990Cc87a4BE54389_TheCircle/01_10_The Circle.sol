// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

 88888888888 888                      .d8888b.  d8b                  888          
    888     888                     d88P  Y88b Y8P                  888          
    888     888                     888    888                      888          
    888     88888b.   .d88b.        888        888 888d888  .d8888b 888  .d88b.  
    888     888 "88b d8P  Y8b       888        888 888P"   d88P"    888 d8P  Y8b 
    888     888  888 88888888       888    888 888 888     888      888 88888888 
    888     888  888 Y8b.           Y88b  d88P 888 888     Y88b.    888 Y8b.     
    888     888  888  "Y8888         "Y8888P"  888 888      "Y8888P 888  "Y8888  
                                                                                                                                                                */                                                                                 



import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheCircle is ERC1155, Ownable {
    string public constant name = "The Circle";
    struct AuthorizedReceiver {
        bool isAuthorized;
        address owner;
    }

    // A mapping to keep track of authorized token receivers
    mapping (uint256 => mapping (address => AuthorizedReceiver)) public authorizedReceivers;

    // A mapping to keep track of the total  Supply
    mapping (uint256 => uint256) public totalSupply;


    // A mapping to keep track of the owner of each token ID
    mapping (uint256 => address) public tokenOwner;


    constructor(address[] memory initialAuthorizedWallets, uint256[] memory initialTokenIds, uint256[] memory initialTokenAmounts, bytes memory initialData)
        ERC1155("ipfs://QmdSqR533EP3wLy8QWW4bKAmW4Ra57FYHJ3enYgf5VkpKk/{id}.json")
    {
        require(initialAuthorizedWallets.length == initialTokenIds.length && initialAuthorizedWallets.length == initialTokenAmounts.length, "Arrays length mismatch");
        for (uint i = 0; i < initialAuthorizedWallets.length; i++) {
            authorizedReceivers[initialTokenIds[i]][initialAuthorizedWallets[i]].isAuthorized = true;
            authorizedReceivers[initialTokenIds[i]][initialAuthorizedWallets[i]].owner = initialAuthorizedWallets[i];
            tokenOwner[initialTokenIds[i]] = initialAuthorizedWallets[i];
            _mint(initialAuthorizedWallets[i], initialTokenIds[i], initialTokenAmounts[i], initialData);
            totalSupply[initialTokenIds[i]] += initialTokenAmounts[i];
        }
   }

    function mintAdminFor(address receiver, uint256 tokenId, uint256 amount, bytes memory data) public onlyOwner {
        require(tokenId >= 1 && tokenId <= 777, "Invalid token ID");
        require(totalSupply[tokenId] == 0, "Token already exists");
        _mint(receiver, tokenId, amount, data);
        authorizedReceivers[tokenId][receiver].isAuthorized = true;
        authorizedReceivers[tokenId][receiver].owner = receiver;
        totalSupply[tokenId] += amount;
    }


    function mintForSelf(uint256 tokenId, uint256 amount, bytes memory data) public {
        require(msg.sender == tokenOwner[tokenId], "Unauthorized caller");
        _mint(msg.sender, tokenId, amount, data);
    }



    function autorizeReceivers(uint256 tokenId, address[] memory receivers) public {
        require(authorizedReceivers[tokenId][msg.sender].owner == msg.sender, "Unauthorized caller");
        for (uint i = 0; i < receivers.length; i++) {
            authorizedReceivers[tokenId][receivers[i]].isAuthorized = true;
            authorizedReceivers[tokenId][receivers[i]].owner = address(0);
        }
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner(), newOwner);
        _transferOwnership(newOwner);
    }


    function revokeReceivers(uint256 tokenId, address[] memory receivers) public {
        require(authorizedReceivers[tokenId][msg.sender].owner == msg.sender, "Unauthorized caller");
        for (uint i = 0; i < receivers.length; i++) {
            authorizedReceivers[tokenId][receivers[i]].isAuthorized = false;
            authorizedReceivers[tokenId][receivers[i]].owner = address(0);
        }
    }

    function isAuthorized(address receiver, uint256 tokenId) public view returns (bool) {
        return authorizedReceivers[tokenId][receiver].isAuthorized;
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) public override {
        require(totalSupply[_id] == 0 || authorizedReceivers[_id][_to].isAuthorized, "Receiver not authorized");
        super.safeTransferFrom(_from, _to, _id, _amount, _data);
    }


    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) public override {
        for (uint i = 0; i < _ids.length; i++) {
            require(totalSupply[_ids[i]] == 0 || authorizedReceivers[_ids[i]][_to].isAuthorized, "Receiver not authorized");
        }
        super.safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

}