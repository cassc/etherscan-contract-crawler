//
//                       /^--^\     /^--^\     /^--^\
//                       \____/     \____/     \____/
//                      /      \   /      \   /      \
//                     |        | |        | |        |
//                      \__  __/   \__  __/   \__  __/
// |^|^|^|^|^|^|^|^|^|^|^|^\ \^|^|^|^/ /^|^|^|^|^\ \^|^|^|^|^|^|^|^|^|^|^|^|
// | | | | | | | | | | | | |\ \| | |/ /| | | | | | \ \ | | | | | | | | | | |
// ########################/ /######\ \###########/ /#######################
// | | | | | | | | | | | | \/| | | | \/| | | | | |\/ | | | | | | | | | | | |
// |_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|
//
//          ╔╦╗┌─┐┌┐ ┬  ┌─┐┌─┐┌┐┌┌─┐  ╔═╗┌┬┐┬  ┬┌─┐┌┐┌┌┬┐┬ ┬┬─┐┌─┐
//           ║║├─┤├┴┐│  │ ││ ││││└─┐  ╠═╣ ││└┐┌┘├┤ │││ │ │ │├┬┘├┤ 
//          ═╩╝┴ ┴└─┘┴─┘└─┘└─┘┘└┘└─┘  ╩ ╩─┴┘ └┘ └─┘┘└┘ ┴ └─┘┴└─└─┘
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DabloonsAdventure is ERC721A, Ownable {

    uint16 public maxSupply = 999;
    uint16 public teamSupply = 66;
    uint256 public price = 0.015 ether;
    
    bool public isMintingEnabled;
    bool public teamClaimed;
    
    string private baseURI;

    address public constant TEAM = 0x8b7Fe17f5CCa0A26f9bC9e17676BD568915baC3c;

    mapping (address => uint256) public mintCount;

    error MintingNotStarted();
    error ExceedsMaxMintQuantity();
    error ExceedsMaxSupply();
    error EthValueTooLow();
    error NoContractMints();

    constructor() ERC721A("Dabloons Adventure", "DBLN") {}

    function mint(uint256 quantity) external payable {
        if (!isMintingEnabled) revert MintingNotStarted();
        if (mintCount[msg.sender] + quantity > 2) revert ExceedsMaxMintQuantity();
        if (quantity + totalSupply() > maxSupply) revert ExceedsMaxSupply();
        if (msg.value < price * quantity) revert EthValueTooLow();
        if (msg.sender != tx.origin) revert NoContractMints();
        
        mintCount[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function teamClaim() external onlyOwner {
        require(!teamClaimed, "Team already claimed");
        teamClaimed = true;
        _mint(TEAM, teamSupply);
    } 

    function setMintingEnabled(bool _isMintingEnabled) external onlyOwner {
        isMintingEnabled = _isMintingEnabled;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function withdrawFunds() external onlyOwner {
        (bool teamSuccess, ) = TEAM.call{ value: address(this).balance } ("");
        require(teamSuccess, "Transfer failed.");
    }
}