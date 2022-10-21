// SPDX-License-Identifier: GPL-3.0

/*
  roooooooooooooboooooooooooooot is coming                   
*/

pragma solidity 0.8.7;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "./ERC721A/contracts/ERC721A.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract rooooboooot is ERC721A {
    uint256 public immutable maxSupply = 999;
    uint256 _baseDifficulty = 10;
    uint256 _difficultyBais = 120;
    uint256 immutable _baseGasLimit = 80000;
    string uri = "ipfs://QmcoTHGdFXaEUPWzesFNM65QBzBhDJkkQGBpGj3kZ3kfit/";

    uint256 _price = 0.001 ether;
    uint256 _maxRobot = 10;
    address public owner;

    function mint(uint256 amount) payable public {
        require(totalSupply() + amount <= maxSupply, "Sold Out");
        require(amount <= _maxRobot);
        require(msg.value >= amount * _price, "Pay For");
        _safeMint(msg.sender, amount);
    }

    function mint() public {
        require(gasleft() > _baseGasLimit, "Need_More");       
        if (!raffle()) return;
        require(msg.sender == tx.origin, "No_EOA");
        require(totalSupply() + 1 <= maxSupply, "Sold_Out");
        require(balanceOf(msg.sender) == 0, "ONLY_ONE");
        _safeMint(msg.sender, 1);
    }

    function raffle() public view returns(bool) {
        uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;
        return num > difficulty();
    }

    function difficulty() public view returns(uint256) {
        return _baseDifficulty + totalSupply() * _difficultyBais / maxSupply;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "No Permission");
        _;
    }

    constructor() ERC721A("rooooboooot", "oooo") {
        owner = msg.sender;
    }

    function seturi(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(uri, _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}