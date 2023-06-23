//  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
//  |||||||||||||||||||||||||||||
//  |   "||,,,,. "|" .,,,,||"      ____
//  |    .d8888b.   .d8888b.      (    )          _____
// /|\  o8'  o '8o o8'o   `8o     |    |         (     )
// |||  o8.    .8o o8.    .8o     |    | _______ |     |
//       `Y8888P'   `Y8888P'      |    |(       )|     |
//      ,||''|| \   / ||''||,     |    ||       ||     |
//     ,||   ||, \ / .||   ||,    |    ||       ||     |
//     ||     ||  `  ||     ||    |    ||       ||     |
//    ,||     '||   ||'     ||,   |    ||       ||     | _
//    ||      '||   ||'      ||   |    ||       ||     || \
//    ||       |;   ;|       ||   |    ||       ||     ||  '
//    ||      ,|     |,      ||   |    ||       ||     ||   '
//    ||,    ,||     ||,    ,||   |    ||       ||     ||   |
//     ||,  ,|||     |||,  ,||    |    ||       ||     ||   |
//     '||,,||||,...,||||,,||     |    ||       ||     ||___|_
//       `|||..."|||"...|||'      (____)(_______)(_____)|____|
// |%%%%%%%%WWWW%%%%%%WWWW%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%|
// `""""""""""3$F""""#$F""""""""""""""""""""""""""""""""""""""""'
//            @$.... '$B
//           d$$$$$$$$$$:
//     __  ___     __                             _ __       
//    /  |/  /__  / /_____ __   _____  __________(_) /___  __
//   / /|_/ / _ \/ __/ __ `/ | / / _ \/ ___/ ___/ / __/ / / /
//  / /  / /  __/ /_/ /_/ /| |/ /  __/ /  (__  ) / /_/ /_/ / 
// /_/  /_/\___/\__/\__,_/ |___/\___/_/  /____/_/\__/\__, /  
//                                                  /____/             
//   
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library OpenSeaGasFreeListing {
    /**
    @notice Returns whether the operator is an OpenSea proxy for the owner, thus
    allowing it to list without the token owner paying gas.
    @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
    this function returns true.
     */
    function isApprovedForAll(address owner, address operator) internal view returns (bool) {
        ProxyRegistry registry;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
        }

        return address(registry) != address(0) && address(registry.proxies(owner)) == operator;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Metaversity is ERC721A, Ownable {
  
    uint256 basePrice = 0.065 ether;
    uint256 public constant maxSupply = 5555;
    string private _baseTokenURI;
    string public provenance;

    // states 0: closed, 1: benefactors & presale, 3: public 
    uint256 public saleState = 0;
    
    bytes32 public benefactorListMerkleRoot;
    bytes32 public presaleListMerkleRoot;

    uint public constant BENEFACTORS = 1;
    uint public constant PRESALE = 2;

    address private teamAddress = 0x3a21fA2EA2969435A64f6D723b487e2341a29627;

    mapping (address => uint) public presaleNumMinted;

    constructor(string memory baseURI) ERC721A("Metaversity", "MU", 25) {
        setBaseURI(baseURI);
    }
    
    // Setting & Getting Base Price 

    function setPrice(uint256 _price) public onlyOwner {
        basePrice = _price;
    }

    function getPrice() external view returns (uint256) {
        return basePrice; 
    }

    // Metadata  

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    // Setting & Getting Sale State

    function getSaleState() external view returns (uint256) {
        return saleState;
    }
    
    function setSaleState(uint newState) public onlyOwner {
        require(newState >= 0 && newState <= 2, "Invalid sale state, must be between 0 and 2");
        saleState = newState;
    }

    // Presale Verification Functions 

    function getPresaleNumMinted(address addr) external view returns (uint) {
        return presaleNumMinted[addr]; 
    }

    function verifyMerkle(address addr, bytes32[] calldata proof, uint whitelistType) internal view {
        require(isOnWhitelist(addr, proof, whitelistType), "User is not on whitelist");
    }

    function isOnWhitelist(address addr, bytes32[] calldata proof, uint whitelistType) public view returns (bool) {
        bytes32 root;
        if (whitelistType == BENEFACTORS) {
            root = benefactorListMerkleRoot;
        } else if (whitelistType == PRESALE) {
            root = presaleListMerkleRoot;
        } else {
            revert("Invalid whitelistType");
        }
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, root, leaf);
    }

    function setBenefactorListMerkleRoot(bytes32 newMerkle) public onlyOwner {
        benefactorListMerkleRoot = newMerkle;
    }

    function setPresaleListMerkleRoot(bytes32 newMerkle) public onlyOwner {
        presaleListMerkleRoot = newMerkle;
    }

    // Minting Functions

    function reserve(uint256 numberOfTokens) public onlyOwner {
        uint256 ts = totalSupply();
        require(ts + numberOfTokens <= maxSupply, "Purchase would exceed max tokens");  
        _safeMint(msg.sender, numberOfTokens);
    }

    function earlyMint(uint256 numberOfTokens, bytes32[] calldata merkleProof, uint whitelistType) public payable {

        require(saleState > 0, "Presale is not open yet");
        require(basePrice * numberOfTokens <= msg.value, "Insufficient ETH sent");
        require(numberOfTokens <= 25, "Can only mint 25 tokens per transaction");

        uint256 ts = totalSupply();
        require(ts + numberOfTokens <= maxSupply, "Purchase would exceed max tokens");

        // benefactors & presale
        if (saleState == 1) {

            presaleNumMinted[msg.sender] = presaleNumMinted[msg.sender] + numberOfTokens;

            // benefactors 
            if(whitelistType == 1) {
                require(presaleNumMinted[msg.sender] <= 50, "Cannot mint more than 50 per address in this phase");
                verifyMerkle(msg.sender, merkleProof, BENEFACTORS);
            } 
            
            // presale
            else if (whitelistType == 2) {
                require(presaleNumMinted[msg.sender] <= 4, "Cannot mint more than 4 per address in this phase");
                verifyMerkle(msg.sender, merkleProof, PRESALE);
            }
            
        }

        // public mint
        else {
            revert("Presale is over, use the public mint function instead.");
        }
        
        _safeMint(msg.sender, numberOfTokens);
        
    }

    function publicMint(uint256 numberOfTokens) public payable {

        require(saleState == 2, "Public sale must be active to mint tokens");
        require(numberOfTokens <= 6, "Cannot mint more than 6 per transaction");
        require(basePrice * numberOfTokens <= msg.value, "Insufficient ETH sent");

        uint256 ts = totalSupply();
        require(ts + numberOfTokens <= maxSupply, "Purchase would exceed max tokens");

        _safeMint(msg.sender, numberOfTokens);
    }

    // Withdraw Balance

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(teamAddress).transfer(balance);
    }

    // Open Sea Free Gas
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return OpenSeaGasFreeListing.isApprovedForAll(owner, operator) || super.isApprovedForAll(owner, operator);
    }

}