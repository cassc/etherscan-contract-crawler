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



import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheCircle is ERC721, Ownable {
    using Strings for uint256; 
    bool public lockURI;
    mapping(uint256 => string) public newURI;
    string internal baseURI;
    struct AuthorizedReceiver {
        bool isAuthorized;
        address owner;
    }
    mapping (uint256 => mapping (address => AuthorizedReceiver)) public authorizedReceivers;
    mapping (uint256 => uint256) public totalSupply;
    mapping (uint256 => address) public tokenOwner;
    constructor(address[] memory initialAuthorizedWallets, uint256[] memory initialTokenIds)
        ERC721("The Circle", "CIRCLE")
    {
        require(initialAuthorizedWallets.length == initialTokenIds.length, "Arrays length mismatch");
        for (uint i = 0; i < initialAuthorizedWallets.length; i++) {
            authorizedReceivers[initialTokenIds[i]][initialAuthorizedWallets[i]].isAuthorized = true;
            authorizedReceivers[initialTokenIds[i]][initialAuthorizedWallets[i]].owner = initialAuthorizedWallets[i];
            tokenOwner[initialTokenIds[i]] = initialAuthorizedWallets[i];
            _mint(initialAuthorizedWallets[i], initialTokenIds[i]);
            totalSupply[initialTokenIds[i]] += 1;
        }
   }

    function _baseURI()
        internal
        view
        override(ERC721)
        returns (string memory)
    {
        return baseURI;
    }
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(!lockURI, "URI is locked");
        baseURI = newBaseURI;
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
        string memory id = uint2str(tokenId);
        string memory uri = string(abi.encodePacked(base, "/", id, ".json"));

        return uri;
    }
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }
    function mintAdminFor(address receiver, uint256 tokenId) public onlyOwner {
        require(tokenId >= 1 && tokenId <= 777, "Invalid token ID");
        require(totalSupply[tokenId] == 0, "Token already exists");
        _mint(receiver, tokenId);
        authorizedReceivers[tokenId][receiver].isAuthorized = true;
        authorizedReceivers[tokenId][receiver].owner = receiver;
        totalSupply[tokenId] += 1;
    }
    function autorizeReceivers(uint256 tokenId, address[] memory receivers) public {
        require(authorizedReceivers[tokenId][msg.sender].owner == msg.sender, "Unauthorized caller");
        for (uint i = 0; i < receivers.length; i++) {
            authorizedReceivers[tokenId][receivers[i]].isAuthorized = true;
            authorizedReceivers[tokenId][receivers[i]].owner = address(0);
        }
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
    function safeTransferFrom(address _from, address _to, uint256 _id, bytes memory _data) public override {
        require(totalSupply[_id] == 0 || authorizedReceivers[_id][_to].isAuthorized, "Receiver not authorized");
        super.safeTransferFrom(_from, _to, _id, _data);
    }
    function setApprovalForAll(address operator, bool approved) public override {
        require(msg.sender != operator, "Invalid operator");
        super.setApprovalForAll(operator, approved);
    }
    function transfer(address _to, uint256 _id) public {
        require(totalSupply[_id] == 0 || authorizedReceivers[_id][_to].isAuthorized, "Receiver not authorized");
        transferFrom(msg.sender, _to, _id);
    }
    function safeTransfer(address _to, uint256 _id) public {
        require(totalSupply[_id] == 0 || authorizedReceivers[_id][_to].isAuthorized, "Receiver not authorized");        
        safeTransferFrom(msg.sender, _to, _id, "");
    }
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner(), newOwner);
        _transferOwnership(newOwner);
    }

}