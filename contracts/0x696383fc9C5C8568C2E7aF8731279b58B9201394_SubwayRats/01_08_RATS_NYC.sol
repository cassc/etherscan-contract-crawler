// SPDX-License-Identifier: Unlicensed
/*
                                   .......                               .            .         .°°. 
     °*******°       ..          °*ooooOOoo°.   .°*°    .*°.     °°. O     .°..   .  *oo° °     oOOo 
   .*ooOOOOOOoo. o  °oo° #. °*.  .*ooo°.°ooO*   °OOO° . *OOo   .*oO* #   .°oOOo*.    OoO°     ° oOoo 
   .oooo°...°oo.   °ooo.   .ooo°   *oo   .oo*   .ooo.   *ooo   °Ooo*  # °oooooooo*   oooo°      oooo 
   .ooo°     *° . .ooo.  o  ooo°   *oo*.*o**.   .ooo.   *ooo   .*ooo.  °ooo*..*ooo.  °oooo°   .oooo* 
    .°oo°.        oooo      ooo.   *ooo°oo..    .oo°   *oooo    .ooo° .*oo°   .oooo    .*oo***oo**o  
       .****°°.   *oo*      o*o.  .*o*°°oooo°   .oo*  .*oooo*   .ooo° °ooo****oooo*      °oooooo.*o  
          .*oo.    *o*.   °**o*.  °oo.    °oo°   °oo**ooo**oo*.°**oo° °o*oo*. °ooo*       °o*oo. **  
 ....       °**.   °******o***.   °**.     *o*   .***oo*°  **ooooo*.  °o**.    ****     .°**o*°  °   
 ******°°°°°**°     .*******°     °***°°°°***.    .***°     *****.    °o*o.    ****   .°*o**°    °   
  .**********°        ......      ..°*****...                 .°       °*°     ****  .****°.     °   
      ..°°.                                                                     ..     .         °   
        ..   ..    ..........               .                            .                       ° .   
        ..      .°°°°°°°..°°°°.           .°°°...      .......   .....      ..°°°°°..                
                .°°°°°°    .°°°.       .°°°°°°°°°°.  .°°°°°°°°°°°°°°°°°   .°°°°°..°°°°  .            
                   °°°°     .°°.      °°°°°    .°°°.  .°°°°°°°°°°°°°°.°. °°°°°                       
                   °°°°    .°°.      .°°°°°    .*°*°    .°   °°°°°    .. .°°°°.                      
                   °****°°°**°       °******°.°°**°*.    °    °**°  . ..  °***°..                    
                    °*********°°.    °**************° .  .    ***°         .°°***°°..                
                    °****°.°.°***°   .****.    .°****. .   .  ***°  °    .     .*****°               
                    °***°      .°*°   °***      .****°        ***°               ****°               
                    °****        °**. °***       °****.      °**°        °°°    °****.               
                    °.***°       °**.  °*. .     .*****      ***°       °o**********°                
                    ° .*o°         .    .          °**°      .*.      o .°°*o****°..                 
                    *   ..                           °.                     ...*                     
                    °                                °.                        °                     
                                                     °.                        .                     
                                                     .                                                                                                                                            
*/
pragma solidity 0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SubwayRats is ERC721AQueryable, Ownable {
    constructor() ERC721A("SubwayRats", "SR") {}
   
    string public baseURI = "https://subwayrats.io/api/rats/";

    // Because our metadata is stored centrally you can check this Keccak-256 hash of our metadata json to ensure nothing has been edited.
    string public constant METADATA_HASH = "9e8d6662af4635a633aa155169d2027e49ff7d4288669e626ee289caad845927";

    uint256 public constant MAX_RATS = 10000;

    bytes32 public constant LrMerkleRoot = 0x0f027f799497bd43c64a57413bbb52ea5916a68b51bcfcd54c270e9b915a2234;
    bytes32 public constant RlMerkleRoot = 0x7be23501ca18dac35c0f076a9a831ddefdbfa77b19e4f9bfbbfec9b41440dbe3;
    bytes32 public constant ClMerkleRoot = 0x8475967ab5f6bd15f2d36aaef159189afcab791f0e4e41ad56e96a15f765dbe0;
    bytes32 public constant SlMerkleRoot = 0x92ee4bb0e837f053486a7a2047bd13de6e8028e10431cbd23cadc34aeb5e720c;
    uint256 public mintStage = 0;

    mapping(address => bool) public usedWL;

    function tokenURI(uint256 _tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, _toString(_tokenId), ".json"));
    }

    function setBaseURI(string memory _base) public onlyOwner {
        baseURI = _base;
    }
    
    function nextMintStage(uint _stage) public onlyOwner {
        mintStage = _stage;
    }

    function teamMint(uint _amount, address _recipient) public onlyOwner {
        require(_totalMinted() + _amount <= MAX_RATS, "Too many rats!");
        _mint(_recipient, _amount);
    }

    function labratMint(bytes32[] calldata _proof) public {
        require(!usedWL[msg.sender],"Proof already used");
        require(mintStage > 0, "Mint hasn't started for labrats yet.");
        require(MerkleProof.verify(_proof,LrMerkleRoot,keccak256(abi.encodePacked(msg.sender))),"Invalid proof.");
        require(_totalMinted() + 5 <= MAX_RATS, "All rats have already been minted!");
        usedWL[msg.sender] = true;
        _mint(msg.sender, 5);
    }

    function ratlistMint(bytes32[] calldata _proof) public {
        require(!usedWL[msg.sender],"Proof already used");
        require(mintStage > 0, "Mint hasn't started for ratlist yet.");
        require(MerkleProof.verify(_proof,RlMerkleRoot,keccak256(abi.encodePacked(msg.sender))),"Invalid proof.");
        require(_totalMinted() + 3 <= MAX_RATS, "All rats have already been minted!");
        usedWL[msg.sender] = true;
        _mint(msg.sender, 3);
    }

    function cheeselistMint(bytes32[] calldata _proof) public {
        require(!usedWL[msg.sender],"Proof already used");
        require(mintStage > 1, "Mint hasn't started for cheeselist yet.");
        require(MerkleProof.verify(_proof,ClMerkleRoot,keccak256(abi.encodePacked(msg.sender))),"Invalid proof.");
        require(_totalMinted() + 2 <= MAX_RATS, "All rats have already been minted!");
        usedWL[msg.sender] = true;
        _mint(msg.sender, 2);
    }

    function squeaklistMint(bytes32[] calldata _proof) public {
        require(!usedWL[msg.sender],"Proof already used");
        require(mintStage > 2, "Mint hasn't started for squeaklist yet.");
        require(MerkleProof.verify(_proof,SlMerkleRoot,keccak256(abi.encodePacked(msg.sender))),"Invalid proof.");
        require(_totalMinted() + 1 <= MAX_RATS, "All rats have already been minted!");
        usedWL[msg.sender] = true;
        _mint(msg.sender, 1);
    }
}