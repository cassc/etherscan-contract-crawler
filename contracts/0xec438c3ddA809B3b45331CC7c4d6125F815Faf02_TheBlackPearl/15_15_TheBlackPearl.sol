//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

/*
    ████████╗██╗  ██╗███████╗    ██████╗ ██╗      █████╗  ██████╗██╗  ██╗    ██████╗ ███████╗ █████╗ ██████╗ ██╗     
    ╚══██╔══╝██║  ██║██╔════╝    ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝    ██╔══██╗██╔════╝██╔══██╗██╔══██╗██║     
       ██║   ███████║█████╗      ██████╔╝██║     ███████║██║     █████╔╝     ██████╔╝█████╗  ███████║██████╔╝██║     
       ██║   ██╔══██║██╔══╝      ██╔══██╗██║     ██╔══██║██║     ██╔═██╗     ██╔═══╝ ██╔══╝  ██╔══██║██╔══██╗██║     
       ██║   ██║  ██║███████╗    ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗    ██║     ███████╗██║  ██║██║  ██║███████╗
       ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝                                                                                                                                                                                                                                                             
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @author Anduin
contract TheBlackPearl is ERC721,Ownable,ReentrancyGuard{
    using Strings for uint256;
    using Counters for Counters.Counter;

    // =========================================================================
    //                               Types
    // =========================================================================

    struct ContractState{
        uint256 genesisSupply;
        uint256 genesisPrice;
        bytes32 genesisRoot;
        uint256 genesisStart;
        uint256 genesisEnd;

        uint256 generalSupply;
        uint256 generalPrice;
        bytes32 generalRoot;
        uint256 generalStart;
        uint256 generalEnd;
    }

    // =========================================================================
    //                               Storage
    // =========================================================================

    ContractState public contractState;

    Counters.Counter public totalSupply;
    
    Counters.Counter public genesisId = Counters.Counter(1);
    Counters.Counter public generalId = Counters.Counter(67);

    mapping(address => bool) public alreadyMintedGeneral;
    mapping(address => bool) public alreadyMintedGenesis;

    string public baseURI = "ipfs://QmRETDHxkcnJUPXrm4eb9xv8UXHKhbXhrsVs8GQuVHDUA8/";

    // =========================================================================
    //                               Constants
    // =========================================================================

    uint256 constant genesisMaxId = 66;
    uint256 constant generalMaxId = 666;

    // =========================================================================
    //                               Modifier
    // =========================================================================

    modifier callerIsUser{
        require(tx.origin == msg.sender, "No Contract Please.");
        _;
    }

    modifier genesisMintStarted{
        require(
            block.timestamp >= contractState.genesisStart&&
            block.timestamp <= contractState.genesisEnd,
            "Genesis mint is closed."
        );
        _;
    }

    modifier generalMintStarted{
        require(
            block.timestamp >= contractState.generalStart&&
            block.timestamp <= contractState.generalEnd,
            "General mint is closed."
        );
        _;
    }


    // =========================================================================
    //                               Constructor
    // =========================================================================

    constructor() ERC721("TheBlackPearl","tbp-official"){
        _safeMint(0x5DE014da9ef0FDFF8A5D0465272A4BaF56CC2419,0);
        totalSupply.increment();
        contractState = ContractState(
            13,
            1.88 ether,
            0xe08c72da20dab0e1ba6e32eec734d0a5eb2320d53bbeabb1cdd2349441160c4f,
            1673787600,
            1673789400,

            100,
            0 ether,
            0xb6b10fccb7d0dfdd3e232a8d67d7322e8773da217b675283cc1ae020255f1bbc,
            1673789400,
            1673796600
        );
    }

    // =========================================================================
    //                               Function
    // =========================================================================
    
    function mintGenesis(bytes32[] calldata proof)external payable genesisMintStarted nonReentrant callerIsUser{
        require(inGenesisList(msg.sender,proof),"Not in genesis list.");
        require(msg.value >= contractState.genesisPrice,"Insufficient ETH sent.");
        require(!alreadyMintedGenesis[msg.sender],"Already minted genesis.");
        require(genesisId.current() <= genesisMaxId,"Genesis sold out.");
        require(contractState.genesisSupply > 0,"Genesis sold out in this phase.");
    
        alreadyMintedGenesis[msg.sender] = true;
        contractState.genesisSupply --;
        _safeMint(msg.sender,genesisId.current());
        genesisId.increment();
        totalSupply.increment();
    }
    
    function mintGeneral(bytes32[] calldata proof)external payable generalMintStarted nonReentrant callerIsUser{
        require(inGeneralList(msg.sender,proof),"Not in general list.");
        require(msg.value >= contractState.generalPrice,"Insufficient ETH sent.");
        require(!alreadyMintedGeneral[msg.sender],"Already minted general.");
        require(generalId.current() <= generalMaxId,"General sold out.");
        require(contractState.generalSupply > 0,"General sold out in this phase.");

        alreadyMintedGeneral[msg.sender] = true;
        contractState.generalSupply --;
        _safeMint(msg.sender,generalId.current());
        generalId.increment();
        totalSupply.increment();
    }


    function inGenesisList(address account,bytes32[] calldata proof) public view returns(bool){
        return verifyProof(account,proof,contractState.genesisRoot);
    }

    function inGeneralList(address account,bytes32[] calldata proof) public view returns(bool){
        return verifyProof(account,proof,contractState.generalRoot);
    }

    function verifyProof(address account, bytes32[] calldata proof,bytes32 merkleRoot) private pure returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, generateMerkleLeaf(account));
    }

    function generateMerkleLeaf(address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory){
        _requireMinted(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }

    function setContractState(ContractState memory _contractState) external onlyOwner{
        contractState = _contractState;
    }

    function burn(uint256 tokenId) external onlyOwner{
        _burn(tokenId);
        totalSupply.decrement();
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }
    
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: (address(this).balance)}("");
        require(success, "Transaction unsuccessful");
    }
}