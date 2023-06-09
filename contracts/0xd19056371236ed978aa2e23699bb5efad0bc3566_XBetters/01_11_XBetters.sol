// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//@author: Angel Moratilla
//@title: XBetters
// 
//                          [email protected]@@                                                                       
//                         @@@#                                                                        
//                       %@@@*                                                        (@@@@@           
//                      @@@@                                           ,%         @@@@@%@@@     ,@@@   
//             (@.    *@@@(       (@@&             *     ,#@@@@@@@@@@@@@/         @@# @@@    @@@@      
//             @@@#  @@@@    @@@@@@@@@.    (@@@@@@@@            @@@      (&@@@@,  @@@@@/   %@@@  * ..  
//              @@@ @@@@  @@@@(  @@@(  [email protected]@@@@        ,@@@@@@@@@[email protected]@@   &@@@@      /@@@@@    ,@@@@@@@@@@ 
//              @@@@@@@  @@@   @@@@     #@@       @@@@@@@@     [email protected]@@   @@@@@A    #@@ @@@%       &@@@@  
//               @@@@    @@@(@@@@@@*    @@@@@@@@*      @@@     @@@  *@@@@        [email protected]%   @@@@  #@@@&     
//             &@@[email protected]@.   @@@   .(%@@@@@[email protected]@@            @@@     @@@   @@@        /%       @@@@@#        
//            @@@&%@@@   .         ,@@@ @@@     //,    @@&     @@    @@@@@@@@@@        @@@@@@@I        
//          ,@@@#  @@@@         @@@@@  /@@*@@@@@,      @@&         @@@@@@@.         &@@@     @@@       
//         @@@@.    @@@#  /@@@@@@#      @@@@          @@*          (                          #@@@     
//       @@@@.      @@@@@@@&,           /             #&                                         @     
//      @@&     @@@@/%@@@                                                                              
//    [email protected]@@            &@@*                                                                             
//   @@                                                                                                
//
//

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";


contract XBetters is ERC721A, DefaultOperatorFilterer, Ownable {
    uint256 private constant MAX_SUPPLY = 3000;

    uint256 private MAX_WLA_MINTS_PER_ADDRESS = 1000;
    uint256 private MAX_WLB_MINTS_PER_ADDRESS = 1000;
    uint256 private MAX_PUB_MINTS_PER_ADDRESS = 100;
    
    uint256 public whitelistAMintPrice = 0.12 ether;
    uint256 public whitelistBMintPrice = 0.12 ether;
    uint256 public mintPrice = 0.15 ether;

    bool public revealed = false;

    bytes32 private merkleRootA;
    bytes32 private merkleRootB;
    address private fiatMinter = 0x349560B18AF0aC8474dFa15221C5430A94A5E3C6;

    enum Phase{
        Before,
        WhitelistA,
        WhitelistB,
        Public,
        Soldout,
        Reveal
    }

    Phase public phase = Phase.Before;

    string public baseURI = "ipfs://QmTSq1ini2popkUZez3vm8qrfpcHZE33T9RNyhfgV5aA8M/";
    string public notRevealedUri = "ipfs://QmTSq1ini2popkUZez3vm8qrfpcHZE33T9RNyhfgV5aA8M/XB_unrevealed.json";

    constructor() ERC721A("XBetters", "XBET") {
        // Premint 300 tokens for the team
        _safeMint(msg.sender, 300);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setNotRevealedUri(string memory _newNotRevealedUri) public onlyOwner {
        notRevealedUri = _newNotRevealedUri;
    }
    function setFiatMinter(address _fiatMinter) public onlyOwner {
        fiatMinter = _fiatMinter;
    }
    function getFiatMinter() external view onlyOwner returns (address) {
        return fiatMinter;
    }

// Reveal
    function reveal() public onlyOwner {
        revealed = true;
        phase = Phase.Reveal;
    }

// Phase
    function setPhase(int _phase) external onlyOwner {
        phase = Phase(_phase);
    }

// Opensea hoop we have to jump through... Enforce creator fees operators
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
// Whilelists management
    function setMerkleRootA(bytes32 _merkleRoot) public onlyOwner {
        merkleRootA = _merkleRoot;
    }
    function getMerkleRootA() external view onlyOwner returns (bytes32) {
        return merkleRootA;
    }
    function setMerkleRootB(bytes32 _merkleRoot) public onlyOwner {
        merkleRootB = _merkleRoot;
    }
    function getMerkleRootB() external view onlyOwner returns (bytes32) {
        return merkleRootB;
    }
    function leaf(address _account) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(_account));
    }
    function _verifyA(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRootA, _leaf);
    }
    function _verifyB(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRootB, _leaf);
    }
    function isWhitelistedA(address _account, bytes32[] calldata _proof) internal view returns (bool) {
        return _verifyA(leaf(_account), _proof);
    }    
    function isWhitelistedB(address _account, bytes32[] calldata _proof) internal view returns (bool) {
        return _verifyB(leaf(_account), _proof);
    }

// MINT
    // Mitigation for bots minting
    modifier callerIsUSer() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }
    // Fiat mint can only be called by fiatMinter
    modifier onlyFiatMinter() {
        require(fiatMinter == msg.sender, "Caller is not minter");
        _;
    }
    function whitelistAMint(uint _quantity, bytes32[] calldata _proof) external payable callerIsUSer {
        require(phase == Phase.WhitelistA, "Whitelist A phase is not active");
        require(isWhitelistedA(msg.sender, _proof), "Not whitelisted");
        require(_numberMinted(msg.sender) + _quantity <= MAX_WLA_MINTS_PER_ADDRESS, "Exceeded the address limit");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= (whitelistAMintPrice * _quantity), "Not enough ether sent");
        _safeMint(msg.sender, _quantity);
    }
    function whitelistBMint(uint _quantity, bytes32[] calldata _proof) external payable callerIsUSer {
        require(phase == Phase.WhitelistB, "Whitelist B phase is not active");
        require(isWhitelistedB(msg.sender, _proof), "Not whitelisted");
        require(_numberMinted(msg.sender) + _quantity <= MAX_WLB_MINTS_PER_ADDRESS, "Exceeded the address limit");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= (whitelistBMintPrice * _quantity), "Not enough ether sent");
        _safeMint(msg.sender, _quantity);
    }
    function publicMint(uint _quantity) external payable callerIsUSer {
        require(phase == Phase.Public, "Public phase is not active");
        require(_numberMinted(msg.sender) + _quantity <= MAX_PUB_MINTS_PER_ADDRESS, "Exceeded the address limit");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= (mintPrice * _quantity), "Not enough ether sent");
        _safeMint(msg.sender, _quantity);
    }
    function fiatMint(address _account, uint _quantity) external onlyFiatMinter {
        require(phase == Phase.Public, "Public phase is not active");
        require(_numberMinted(_account) + _quantity <= MAX_PUB_MINTS_PER_ADDRESS, "Exceeded the address limit");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Not enough tokens left");
        _safeMint(_account, _quantity);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
// MISC
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        if(revealed){
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
        } else {
            return notRevealedUri;
        }
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function getPhaseMaxValue(int _phase) external view onlyOwner returns (uint256) {
        if (Phase(_phase) == Phase.WhitelistA){
            return MAX_WLA_MINTS_PER_ADDRESS;
        } else if (Phase(_phase) == Phase.WhitelistB){
            return MAX_WLB_MINTS_PER_ADDRESS;
        } else if (Phase(_phase) == Phase.Public){
            return MAX_PUB_MINTS_PER_ADDRESS;
        } else {
            return 0;
        }
    }
    function setPhaseMaxValue(int _phase, uint256 _value) external onlyOwner {
        if (Phase(_phase) == Phase.WhitelistA){
            MAX_WLA_MINTS_PER_ADDRESS = _value;
        } else if (Phase(_phase) == Phase.WhitelistB){
            MAX_WLB_MINTS_PER_ADDRESS = _value;
        } else if (Phase(_phase) == Phase.Public){
            MAX_PUB_MINTS_PER_ADDRESS = _value;
        }
    }

    function setWhitelistAMintPrice(uint256 _whitelistAMintPrice) public onlyOwner {
        whitelistAMintPrice = _whitelistAMintPrice;
    }
    function setWhitelistBMintPrice(uint256 _whitelistBMintPrice) public onlyOwner {
        whitelistBMintPrice = _whitelistBMintPrice;
    }
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }
}