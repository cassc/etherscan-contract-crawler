//SPDX-License-Identifier: MIT

/*
  
   __________________________                                ,.,,uod8B8bou,,.,
   \________|:|______________\                        .:i!T?TFRRBBBBBBBBBBBBBBBB8bou,..
           _|:|_________                             ||||||||||||||||?TFRRBBBBBBBBBBBBBB8m:.
        __|:::|  \      \__                          ||||     '""^^!!||||||||TFRRBBBVT!:---!
      _/  |:::|   \        \_                        ||||              '""^^!!|||||||?!:---!
    _/    |:::|    \         \_                      ||||         |^_^|          ||||------!
   /      |:::|     \__________\        S            ||||                        ||||------!
  |_______|:::|______\__________\       S            ||||      [1]               ||||------!
  |     /:::::::\       __  __   |      s            ||||      [ ] [3]           ||||------!
  |    |:::::::::|     |__||__|  |      s            ||||      [1] [1] [*]       ||||------!       
  |    | ::::::::|               |      s            ||||          [2] [ ]       ||||------!     
  |    | ::::::::|             __|______             ||||              [ ]       ||||------!
   \    \_______/     ________|_________O            |||||||-._                  ||||------!
    \_                        _/                      ':!||||||||||||-._.        ||||------!
      \_                    _/                   .dBBBBBBBBB86ior!|||||||||||-..:|||!------'
        \__              __/                     .= =!?TFBBBBBBBBB86ijaad|||||||||||!!BBBBBY-',!
      \\\  \____________/               _        .= = = = = = !?TFBBBBBBBBB86ijiaadBBBBBBBBY-',!
       \\\       \ \_     _____________|*|______ .= = = = = = = = = = !?TFBBBBBBBBBBBBBBBY- -',!
        \\\       \  \___/              =      .od86ioi.= = = = = = = = = = = = !?TFBBBY- - -','
          \\\      \_ \_____________________ .d888888888888aioi.= = = = = = = = = = = - - -','
           \\\       \__   \___            .d88888888888888888888aioi.= = = = = = = = - -','
            \\\         \__    \____     .d888888888888888888888888888888aioi.= = = = -','
              \\\          \        \  !|Ti998888888888888888888888888888888899aioi',','
             _                   __                          
 _ __ ___   [_]  _ __     ___   / _|   ___   _ __   ___     _|#|_   
| '_ ` _ \  | | | '_ \   / _ \ | |_   / _ \ | '__| / __|  _/#####\_      
| | | | | | | | | | | | |  __/ |  _| |  __/ | |    \__ \ |#|#####|#|      
|_| |_| |_| |_| |_| |_|  \___| |_|    \___| |_|    |___/  -\#####/-                    
                                                            -|#|- 
  
  
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract Minefers is ERC721A, Ownable {
    string public constant PROVENANCE = "0x61f26565ff0c361a38e4d45af36f1257";
    uint256 public constant MAX_TOKEN_SUPPLY = 10005;

    uint256 public maxWhitelistNum = 2000;
    uint256 public claimedWhitelistNum = 0;

    bytes32 public whitelistMerkleRoot = 0x0;

    mapping(address => uint256) public addrWhitelistNum;
    mapping(address => uint256) public addrPublicNum;

    string private baseURI;

    constructor(uint256 _maxWhitelistNum) ERC721A("Minefers", "Minefers") {
        maxWhitelistNum = _maxWhitelistNum;
    }

    modifier verifySupply(uint256 mintNum) {
        require(mintNum > 0, "At least mint 1 token!");
        require(
            totalSupply() + mintNum <= MAX_TOKEN_SUPPLY,
            "Exceed max supply!"
        );

        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function reserveMint(address to, uint256 quantity)
        external
        onlyOwner
        verifySupply(quantity)
    {
        _safeMint(to, quantity);
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function whitelistMint(bytes32[] calldata _merkleProof)
        public
        verifySupply(1)
    {
        require(addrWhitelistNum[msg.sender] == 0, "Only allow mint 1");
        require(
            claimedWhitelistNum + 1 <= maxWhitelistNum,
            "Reach max whitelist limit!"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Invalid Merkle proof."
        );
        claimedWhitelistNum += 1;
        addrWhitelistNum[msg.sender] += 1;

        _safeMint(msg.sender, 1);
    }

    function publicMint(uint256 quantity)
        public
        payable
        verifySupply(quantity)
    {
        if (
            !((quantity == 1 && msg.value >= 0.01 ether) ||
                (quantity == 3 && msg.value >= 0.02 ether) ||
                (quantity == 5 && msg.value >= 0.03 ether))
        ) {
            revert("invalid quantity or ether value");
        }

        addrPublicNum[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os);
    }
}