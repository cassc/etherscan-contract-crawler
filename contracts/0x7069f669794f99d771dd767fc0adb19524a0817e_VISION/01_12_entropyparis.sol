//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract VISION is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public selfieIDs;

    mapping(uint256 => uint256) private tokenLookup;

    address private operator = 0xC94380575Ab07A7c8Df8bA5f31FcD0938D50703b;
    uint256 public price = 700000000000000;
    bool public isOpen = true;
    bytes32[3] private baseURI;

    constructor() ERC721("ENTROPY PARIS", "VISION") {
    }


    modifier onlyAllowed() {
        _checkCaller();
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

    function withdraw() public onlyAllowed {
        transferTo(operator, address(this).balance);
    }

    function tokenURI(uint256 tid) public view virtual override returns (string memory) {
        require(_exists(tid), "Unminted");
        uint256 tokenId = tokenLookup[tid];
        return string(abi.encodePacked(baseURI[0], baseURI[1], baseURI[2], tokenId.toString()));
    }

    function transferTo(address _to, uint256 _value) internal {
        payable(_to).transfer(_value);
    }

    function mintSelfie(uint256 aid) public payable {
        require(msg.value >= price, "price too low");
        uint256 sid = selfieIDs.current();
        selfieIDs.increment();
        _safeMint(msg.sender, sid);
        tokenLookup[sid] = aid;
    }

    function setOperator(address _nop) public onlyAllowed {
        operator = _nop;
    }


    function getoperator() public view virtual returns (address) {
        return operator;
    }


    function _checkCaller() internal view virtual {
        require(getoperator() == msg.sender || owner() == msg.sender, "Only Allowed");
    }

    receive() external payable {}

    fallback() external payable {}
}