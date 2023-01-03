// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface EtherRock {
  function sellRock (uint rockNumber, uint price) external;
  function giftRock (uint rockNumber, address receiver) external;
}

contract DropBox is Ownable {

    function Collect(uint256 rockId, EtherRock rockInt) public onlyOwner {
        rockInt.sellRock(rockId, type(uint256).max);
        rockInt.giftRock(rockId, owner());
    }
}

contract MersenneRocks is ERC721, ERC721Enumerable, Ownable {

    event DropBoxCreated(address indexed owner);
    event Wrapped(uint256 indexed pairId, address indexed owner);
    event Unwrapped(uint256 indexed pairId, address indexed owner);

    EtherRock public rockInt = EtherRock(0x37504AE0282f5f334ED29b4548646f887977b7cC);

    mapping(address => address) public dropBoxes;

    constructor() ERC721("MersenneRocks", "MR") {}

    function CreateDropBox() public {
        require(dropBoxes[msg.sender] == address(0), "Drop box already exists.");

        dropBoxes[msg.sender] = address(new DropBox());

        emit DropBoxCreated(msg.sender);
    }

    function Wrap(uint256 rockId, uint256 exponent) public { 
        address dropBox = dropBoxes[msg.sender];

        require(dropBox != address(0), "You must create a drop box first.");
        require(exponent >= 1 && exponent <= 256, "Exponent out of range.");
        require(2**exponent - 1 == rockId, "Invalid rock ID.");
        require(!_exists(rockId), "Token already exists.");

        DropBox(dropBox).Collect(rockId, rockInt);
        _mint(msg.sender, rockId);

        emit Wrapped(rockId, msg.sender);
    }

    function Unwrap(uint256 rockId) public {
        require(_exists(rockId), "Token does not exist.");
        require(msg.sender == ownerOf(rockId), "You are not the owner.");

        rockInt.giftRock(rockId, msg.sender);
        _burn(rockId);

        emit Unwrapped(rockId, msg.sender);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://mersenne.ethyearone.com/";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}