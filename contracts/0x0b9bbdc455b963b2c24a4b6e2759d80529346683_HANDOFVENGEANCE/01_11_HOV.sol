//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HANDOFVENGEANCE is ERC721 {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public screenIDs;

    address private owner;
    uint256 public price = 0;
    bool public isOpen = true;
    bytes32[3] private baseURI;
    event Minted(address, uint256);

    constructor() ERC721("HAND OF VENGEANCE", "HOV") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function setMintPrice(uint256 _nPrice) public onlyOwner {
        price = _nPrice;
    }

    function closeContract() public onlyOwner {
        isOpen = false;
    }

    function setBaseURI(string calldata m1, string calldata m2, string calldata m3) public onlyOwner {
        require(isOpen, "Contract is closed");
        baseURI[0] = bytes32(bytes(m1));
        baseURI[1] = bytes32(bytes(m2));
        baseURI[2] = bytes32(bytes(m3));
    }

    function withdraw() public onlyOwner {
        transferTo(msg.sender, address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Unminted");
        return string(abi.encodePacked(baseURI[0], baseURI[1], baseURI[2], tokenId.toString()));
    }

    function transferTo(address _to, uint256 _value) internal {
        payable(_to).transfer(_value);
    }

    function mintHand() public payable {
        require(msg.value >= price, "price too low");
        uint256 sid = screenIDs.current();
        screenIDs.increment();
        _safeMint(msg.sender, sid);
        emit Minted(msg.sender, sid);
    }

    function getowner() public view virtual returns (address) {
        return owner;
    }

    function _checkOwner() internal view virtual {
        require(getowner() == _msgSender(), "Only Owner");
    }

    receive() external payable {}

    fallback() external payable {}
}