// SPDX-License-Identifier: GPL-3.0                                                                                               
//  _______                             _______         __              
// |_     _|.----.--.--.-----.----.    |   |   |.-----.|__|.-----.-----.
//   |   |  |   _|  |  |     |  __|    |   |   ||     ||  ||  _  |     |
//   |___|  |__| |_____|__|__|____|    |_______||__|__||__||_____|__|__|
                                                                     
pragma solidity >=0.7.0 <0.9.0;
import "./ERC721A.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract TruncUnionClub is ERC721A {
    uint256 maxPerTx = 10;
    address public owner;
    address unionCoin;
    uint256 unionCoinRate;
    uint256 cost = 0.001 ether;
    uint256 public maxSupply = 3333;
    string  uri = "ipfs://QmSUDDU7oCBZrNocgaawasNxvM59QogbPXuEuSamGu7aLU/";

    function mint(uint256 amount) payable public {
        require(totalSupply() + amount <= maxSupply, "SoldOut");
        require(msg.value >= amount * cost, "No enough ether");
        require(amount <= maxPerTx, "MaxPerTx");
        _safeMint(msg.sender, amount);
    }

    function mint() public {
        require(msg.sender == tx.origin, "EOA");
        require(totalSupply() <= maxSupply, "No Free");
        require(balanceOf(msg.sender) == 0, "Only Once");
        _safeMint(msg.sender, calculate());
    }

    function setCost(uint256 newcost, uint256 newmaxtx) public onlyOwner  {
        cost = newcost;
        maxPerTx = newmaxtx;
    }

    function calculate() public view returns (uint256) {
        if (totalSupply() < 1000) {
            return 3;
        } else if (totalSupply() < 1800) {
            return 2;
        }
        return 1;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "No Permission");
        _;
    }

    constructor() ERC721A("Trunc Union Club", "TUN") {
        owner = msg.sender;
        maxPerTx = 20;
    }

    function setURI(string memory uri_) public onlyOwner {
        uri = uri_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(uri, _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}