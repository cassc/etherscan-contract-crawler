// _______  _        _______           _______ _________ _______ 
//(  ____ \( \      (  ____ \     |\     /|(  ____ \\__   __/(       )
//| (    \/| (      | (    \/     | )   ( || (    \/   ) (   | () () |
//| (__    | |      | (__         | (___) || (__       | |   | || || |
//|  __)   | |      |  __)        |  ___  ||  __)      | |   | |(_)| |
//| (      | |      | (           | (   ) || (         | |   | |   | |
//| (____/\| (____/\| )           | )   ( || (____/\___) (___| )   ( |
//(_______/(_______/|/            |/     \|(_______/\_______/|/     \|

//SPDX-License-Identifier: MIT License
                                                               


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";



contract Elfheim is ERC721, Ownable{
    using Strings for uint256;
    bytes32 public merkleRoot;

    uint16 public nbElfIn = 0;

    uint16 constant TOTAL_ELF_POPULATION = 5555;

    uint16 constant TOTAL_FREE_ELF = 2222;

    uint public priceMint = 7_000_000_000_000_000;

    bool public isRevealed = false;

    mapping(address => uint8) public whitelistClaimed;

    mapping(address => uint8) public nbClaimedByAddress;

    string private _uriSuffix=".json";
    string private _uriPrefixUnrevealed="ipfs://QmbDgzTVNeCcY8Dc8Smr44esH19gJ7Y85eoJGCRRiwtTSQ/hidden_";
    string private _uriPrefixRevealed;

    address private elf1 = 0xC3cd318FfC6Cb5a05b2eabAaeBf447ea6ECA4fF8;
    address private elf2 = 0x236D9da0989021Fb341fDd0657B94E9Ee1862200;
    address private elf3 = 0xe9e1C6CB270Ff38DCd2B8b47C860CC4fb640d23E;

    uint16 private constant NB_ELF_FOR_TEAM = 200;

    constructor() ERC721("Elf Heim","ELF"){
        //For team : Just to enjoy the party
        _whouhouElvesAreComing(msg.sender, NB_ELF_FOR_TEAM);

    }

    function drinkWithElfForFree(uint8 _howMuchBuddy,bytes32[] calldata _merkleProof) public{
        require(nbElfIn + _howMuchBuddy <= TOTAL_FREE_ELF,"No more Elf in free mint");
        require(whitelistClaimed[msg.sender] + _howMuchBuddy <=1,"1 for free, isn't it enough ?");
        bytes32 _addresToVerify = keccak256(abi.encodePacked(msg.sender));
        require(merkleRoot[0]!=0,"Sorry no WL defined");
        require(MerkleProof.verify(_merkleProof,merkleRoot,_addresToVerify),"Sorry you are not in WL");
        whitelistClaimed[msg.sender] += _howMuchBuddy;
        _whouhouElvesAreComing(msg.sender,_howMuchBuddy);
    }

    function drinkWithElf(uint8 _howMuchBuddy) payable public{
        uint _totalValueSent=msg.value;
        require(nbElfIn>=TOTAL_FREE_ELF,"Patience is a virtue, we have to wait the premint phase to be finished. Btw, why you are not in WL ?");
        require(_howMuchBuddy * priceMint == _totalValueSent,"Please provide the good quantity of ETH, Elf are drunk not naive");
        require(nbElfIn + _howMuchBuddy <= TOTAL_ELF_POPULATION,"No more Elf, the party is full");
        require(nbClaimedByAddress[msg.sender] + _howMuchBuddy <=50,"You can only mint 50 Elfves");
        nbClaimedByAddress[msg.sender] += _howMuchBuddy;
        _whouhouElvesAreComing(msg.sender,_howMuchBuddy);

        //Tip for barmaid
        uint256 _toElf1 = _totalValueSent/3;
        uint256 _toElf2 = _toElf1;
        uint256 _toElf3 = _totalValueSent - _toElf1 - _toElf2;
        payable(elf1).transfer(_toElf1);
        payable(elf2).transfer(_toElf2);
        payable(elf3).transfer(_toElf3);
    }

    function _whouhouElvesAreComing(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            unchecked {
                nbElfIn += 1;
            }
            _safeMint(_receiver, nbElfIn);
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner{
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (isRevealed){
            return _uriPrefixRevealed;
        }else{
            return _uriPrefixUnrevealed;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        
        if (isRevealed){
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), _uriSuffix)) : "";
        }else{
            uint256 _nbUnrevealed = (tokenId % 3) + 1;
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _nbUnrevealed.toString(), _uriSuffix)) : "";
        }
    }

    function reveal(string memory _newUriPrefixRevealed) public onlyOwner{
        isRevealed=true;
        _uriPrefixRevealed = _newUriPrefixRevealed;
    }

    function airdropElfAreFlying(address[] memory _addresses) public onlyOwner{
        require(_addresses.length + nbElfIn<=TOTAL_ELF_POPULATION,"No more Elf");
        for (uint i=0; i<_addresses.length; i++) {
            _whouhouElvesAreComing(_addresses[i],1);
        }
    }

    function setPriceMint(uint256 _newPrice) public onlyOwner{
        priceMint=_newPrice;
    }
    
}