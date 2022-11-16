//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


/*
 ________  ___  ________  _______   ________  ___  ___  _______   ________  _________   
|\   ____\|\  \|\   ___ \|\  ___ \ |\   __  \|\  \|\  \|\  ___ \ |\   ____\|\___   ___\ 
\ \  \___|\ \  \ \  \_|\ \ \   __/|\ \  \|\  \ \  \\\  \ \   __/|\ \  \___|\|___ \  \_| 
 \ \_____  \ \  \ \  \ \\ \ \  \_|/_\ \  \\\  \ \  \\\  \ \  \_|/_\ \_____  \   \ \  \  
  \|____|\  \ \  \ \  \_\\ \ \  \_|\ \ \  \\\  \ \  \\\  \ \  \_|\ \|____|\  \   \ \  \ 
    ____\_\  \ \__\ \_______\ \_______\ \_____  \ \_______\ \_______\____\_\  \   \ \__\
   |\_________\|__|\|_______|\|_______|\|___| \__\|_______|\|_______|\_________\   \|__|
   \|_________|                              \|__|                  \|_________|        
                                                                                                                                                                                
*/

error SideQuest__Reserved();
error SideQuest__SaleInactive();
error SideQuest__Claimed(address _user);
error SideQuest__MaxSupplyReached();
error SideQuest__InvalidAmount(address _user, uint256 _amount);
error SideQuest__UserNotWhitelisted(address _user);
error SideQuest__UserNotOwner(uint256 _id, address _user);
error SideQuest__TeamClaimed();

contract SideQuest is ERC721A, Ownable {

    string private baseURI;
    address private constant DEV = 0x7Af047Dc65917aCD86D24F3F2033a002473bCcCe;
    address private constant ARTIST = 0x11620E1C627F08Ff1381aA89f4E24dAeCa1763aA;

    bool public saleActive = false;
    bool public teamClaimed = false;
    uint256 public MAX_SUPPLY;
    uint256 public TEAM_MINT_AMOUNT = 100;
    bytes32 public merkleRoot;

    mapping(address => uint256) public whitelistClaimed;
    mapping(address => bool) public claimedAddresses;

    constructor(uint256 _maxSupply) ERC721A("SideQuest", "SQ") {
        MAX_SUPPLY = _maxSupply;
    }

    function mint() external {
        uint256 supply = totalSupply();
        if (!saleActive) {
            revert SideQuest__SaleInactive();
        }
        if (claimedAddresses[msg.sender]) {
            revert SideQuest__Claimed(msg.sender);
        }
        if ((supply + 1) > MAX_SUPPLY) {
            revert SideQuest__MaxSupplyReached();
        }
        claimedAddresses[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function mintWhitelist(bytes32[] calldata _merkleProof, uint256 _amount) external {
        uint256 supply = totalSupply();
        uint256 claimed = whitelistClaimed[msg.sender];
        if ((claimed + _amount) > 2) {
            revert SideQuest__InvalidAmount(msg.sender, _amount);
        }
        if ((supply + _amount) > MAX_SUPPLY) {
            revert SideQuest__MaxSupplyReached();
        }
        if (!MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert SideQuest__UserNotWhitelisted(msg.sender);
        }
        whitelistClaimed[msg.sender] += _amount;
 
         _safeMint(msg.sender, _amount);
    }

    function teamMint() external onlyOwner {
        if (teamClaimed) {
            revert SideQuest__TeamClaimed();
        }
        _mintERC2309(DEV, TEAM_MINT_AMOUNT);
        _mintERC2309(ARTIST, TEAM_MINT_AMOUNT);
        teamClaimed = true;
    }

    function editMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}