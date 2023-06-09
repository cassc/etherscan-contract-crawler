// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Raccools is ERC721A, Ownable {
    uint256 private constant maxSupply = 6969;
    uint256 private constant amountPerTx = 6;
    mapping(address => bool) private mintedByAddress;
    string private baseURI;

    uint256 private constant teamAllocationAmount = 140; // 2%
    mapping(address => uint256) private teamAllocation;

    modifier onlyTeam() {
        require(teamAllocation[msg.sender] > 0, "Caller has no team allocation");
        _;
    }

    constructor() ERC721A("Raccools", "RACCOOL") {
        teamAllocation[0x70B4AbB819570055C60D215F16F2765cEec144c5] = 56;
        teamAllocation[0x5cc61632E181903cF2f476c420bF781F6ee53059] = 42;
        teamAllocation[0x0000D385e5DB73289B3F515b65e6cac6707Ac390] = 42;
        teamAllocation[0xD1688C4BfA1517502172CF0eD50306Ea1813e677] = 1;
    }

    function mint() external {
        require(_totalMinted() >= teamAllocationAmount, "Team allocation not fulfilled yet");
        require(_totalMinted() + amountPerTx <= maxSupply, "Would exceed max supply");
        require(msg.sender == tx.origin, "Cannot mint from a smart contract");
        require(mintedByAddress[msg.sender] == false, "Already minted");

        _safeMint(msg.sender, amountPerTx);
        mintedByAddress[msg.sender] = true;
    }

    function mintReserve() external onlyTeam {
        _safeMint(msg.sender, teamAllocation[msg.sender]);
        teamAllocation[msg.sender] = 0;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token not minted");

        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}