//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DickleButts is ERC1155, Ownable, Pausable {
    uint private constant MAX_SUPPLY = 5000;
    uint private constant MAX_PER_TX = 10;
    
    // Metadata
    uint private counter;

    // Price
    uint256 public price;
    address payable public receiver;

    constructor (
        string memory _tokenURI,
        address payable _receiver,
        uint _mintingFee
    ) ERC1155(_tokenURI) {
        receiver = _receiver;
        price = _mintingFee;
        counter = 0;
        _pause();
    }

    function setPause(bool pause) external onlyOwner {
        if(pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function totalSupply() external view returns (uint) {
        return counter;
    }

    function mint(uint amount) external payable whenNotPaused {
        require(amount < MAX_PER_TX + 1, "amount can't exceed 10");
        require(amount > 0, "amount too little");
        require(msg.value == price * amount, "insufficient fund");
        require(counter + amount < MAX_SUPPLY, "no more left to mint");

        mintBatch(msg.sender, amount);
    }

    function mintBatch(address to, uint amount) private {
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);
        uint c = 0;
        for(uint i = counter; i < counter + amount; i++) {
            ids[c] = i+1; // token starts from 1
            amounts[c] = 1;
            c++;
        }
        counter += amount;
        _mintBatch(to, ids, amounts, "");
    }

    function airdrop(address[] calldata target, uint[] calldata amount) external onlyOwner {
        require(target.length > 0, "no target");
        require(amount.length > 0, "no amount");
        require(target.length == amount.length, "amount and target mismatch");
        uint totalAmount = 0;
        for(uint i; i < amount.length; i++){
            totalAmount += amount[i];
        }
        require(counter + totalAmount < MAX_SUPPLY, "no more left to mint");
        for(uint i; i < target.length; i++) {
            mintBatch(target[i], amount[i]);
        }
    }

    // Minting fee
    function setPrice(uint amount) external onlyOwner {
        price = amount;
    }
    function setReceiver(address payable _receiver) external onlyOwner {
        receiver = _receiver;
    }
    function claim() external {
        require(receiver == msg.sender, "invalid receiver");
        receiver.transfer(address(this).balance);
    }

    // Metadata
    function setTokenURI(string calldata _uri) external onlyOwner {
        _setURI(_uri);
    }
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(
            super.uri(_tokenId),
            "/",
            Strings.toString(_tokenId),
            ".json"
        ));
    }
}