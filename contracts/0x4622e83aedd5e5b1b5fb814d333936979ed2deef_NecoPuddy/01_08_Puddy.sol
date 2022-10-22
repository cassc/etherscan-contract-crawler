// SPDX-License-Identifier: GPL-3.0

// .  .           .__      .  .   
// |\ | _  _. _   [__). . _| _|  .
// | \|(/,(_.(_)  |   (_|(_](_]\_|
//                             ._|
                                                                                     

pragma solidity >=0.7.0 <0.9.0;
import "./ERC721A.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract NecoPuddy is ERC721A {

    uint256 maxTx = 10;
    uint256 boneCoinBais;
    address boneCoinAddress;
    uint256 public cost = 0.001 ether;
    uint256 public maxSupply = 2999 + 1;

    function mint(uint256 amount) payable public {
        require(totalSupply() + amount <= maxSupply, "Out");
        require(msg.value >= (amount - 1) * cost, "NoEther");
        require(amount <= maxTx, "MaxTx");
        _safeMint(msg.sender, amount);
    }

    function mint() public {
        require(msg.sender == tx.origin, "EOA");
        require(totalSupply() <= maxSupply, "No Free");
        require(balanceOf(msg.sender) == 0, "Only Once");
        _safeMint(msg.sender, freenum());
    }

    address public owner;
    modifier onlyOwner {
        require(owner == msg.sender, "No Permission");
        _;
    }

    function freenum() public view returns (uint256) {
        if (totalSupply() < 1200) return 3;
        return 1;
    }

    constructor() ERC721A("NecoPuddy", "NPD") {
        owner = msg.sender;
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked("ipfs://QmSW8ZK9MTeGf5TGiAncvX2RE3pJ8W8FkrLsfrThs7F66J/", _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}