// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract ImBrokeAsShit is ERC1155Supply, Ownable {
    uint256 public constant MAX_SUPPLY = 696;
    uint256 public constant NFT_ID = 1;

    address public goblinsAddress;
    address public reservedRecepient;
    uint256[] public nftIds = [NFT_ID];
    uint256[] public reservedSupply = [69];
    uint256[] public perMint = [1];
    mapping (address => bool) public hasMinted;
    mapping (address => bool) public hasMintedPublic;
    uint public goblinMints = 0;
    uint public publicMints = 0;

    constructor(address _goblinsAddress, address _reservedRecepient) ERC1155("ipfs://QmXAxyRb14W1h64RWoYjpqiRyAzwBcKzJWjZ1mQva8mAcB/{id}.json"){
        goblinsAddress = _goblinsAddress;
        reservedRecepient = _reservedRecepient;
        _mintBatch(reservedRecepient, nftIds, reservedSupply, "");
    }

    function hasClaimed(address _claimer) public view returns (bool) {
        return hasMinted[_claimer];
    }

    function hasClaimedPublic(address _claimer) public view returns (bool) {
        return hasMintedPublic[_claimer];
    }

    function updateURI(string calldata newuri) external onlyOwner {
        _setURI(newuri);
    }

    function goblinMint() external {
        require(IERC721(goblinsAddress).balanceOf(msg.sender) > 0);
        require(!hasMinted[msg.sender]);
        require(totalSupply(NFT_ID) < MAX_SUPPLY);
        require(goblinMints < 300);
        _mintBatch(msg.sender, nftIds, perMint, "");
        hasMinted[msg.sender] = true;
        goblinMints++;
    }

    function publicMint() external {
        require(!hasMintedPublic[msg.sender]);
        require(totalSupply(NFT_ID) < MAX_SUPPLY);
        require(publicMints < 300);
        _mintBatch(msg.sender, nftIds, perMint, "");
        hasMintedPublic[msg.sender] = true;
        publicMints++;
    }
}