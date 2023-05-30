// SPDX-License-Identifier: MIT

// ,,,,,,................ THE BYOPILL RESEARCH FACILITY ,,,,,,.....................
// ,,,,,,................                                       ................,.,
// ,,..............                                                 . .............
// .............                                                        ...........
// ...........                                                            .........
// ........ .                                                               .......
// ........         (#////*(#(/#/#                                          .......
// ......         ###(((((.((////////*(/,/&/(((*                             ......
// ....         ,######((((.(*******(&&&&###........,,,..//%                  .....
//              (######(#####((****(((((((((,*,,,*/(//(,..,,*/(                 ...
//              *((((((((,### .##(&&&&&&&&**,***,**,/*/*/%,,***/               ....
//               ,(((((((((((.((((%%%&&&&#((((//(/(#%#*(##,,***/*               ...
//                . (/(((*((/((((/#%####%(//(///(#%######(,******                ..
//               ..,**/////(/(///.(#######//(//(/(((/((((,******,                ..
//                     ....,,**//////%/((((((**//////////////(/....             ...
//                               ....,,,**//////(#(####((((/,,,,,........       ...
//                                         ...,,****////////***,,......          ..
//                                                   ............                 .
//                                                                                .
// ,,,,,,..................A BYOPILLS x LOSTBOY COLLABORATION,,,,,.................

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BYOCassette is ERC1155, ERC1155Supply, Ownable {

    // Constants
    uint256 public constant FIRST_MORNING_IDX = 0;

    // Contract data
    string  private m_Name;
    string  private m_Symbol;  
    string  private m_BaseURI = "";

    // Interface
    IERC721 public m_LandContract;

    // Merkle Roots
    bytes32 private m_FirstMorningRoot;
    bytes32 private m_CassetteRoot;
    bytes32 private m_LandBiomeRoot;

    // Storage Mappings
    mapping (address => bool) m_FirstMorningClaimed;        
    mapping (address => uint256) m_CassettesClaimed; 
    mapping (address => mapping (uint256 => bool)) m_BiomeCassetteClaimed; 

    bool    public m_MintingOpen = false;
    
    constructor(string memory _name,
        string memory _symbol, address _landContract) ERC1155("") {
        m_Name = _name;
        m_Symbol = _symbol;
        m_LandContract = IERC721(_landContract);
    }

    ////////////////////////////////////////
    // Owner only

    function ownerMint (uint256 _itemIdx, uint256 _numMints, address _receiver) external onlyOwner {
        _mint(_receiver, _itemIdx, _numMints, "");
    }

    function setBaseURI (string memory _baseURI) external onlyOwner {
        m_BaseURI = _baseURI;
    }

    function setFirstMorningEligibilityRoot (bytes32 _firstMorningRoot) external onlyOwner {
        m_FirstMorningRoot = _firstMorningRoot;
    }

    function setCassetteEligibilityRoot (bytes32 _cassetteRoot) external onlyOwner {
        m_CassetteRoot = _cassetteRoot;
    }

    function setLandBiomeVerificationRoot (bytes32 _biomeRoot) external onlyOwner {
        m_LandBiomeRoot = _biomeRoot;
    }

    function setLandContract (address _landContract) external onlyOwner {
        m_LandContract = IERC721(_landContract);
    }

    function toggleMinting () external onlyOwner {
        m_MintingOpen = !m_MintingOpen;
    }
    
    ////////////////////////////////////////
    // External

    function mintFirstMorning (uint256 _merkleIdx, bytes32[] calldata merkleProof) external isMintingOpen {    

        // Verify snapshot eligibility, and claim status       
        bytes32 nHash = keccak256(abi.encodePacked(_merkleIdx, msg.sender));
        require(
            MerkleProof.verify(merkleProof, m_FirstMorningRoot, nHash),
            "Invalid eligibility merkle proof !"
        );
        require (m_FirstMorningClaimed[msg.sender] == false, "Already claimed your First Morning cassette.");

        m_FirstMorningClaimed[msg.sender] = true;

        _mint(msg.sender, FIRST_MORNING_IDX, 1, "");

    }

    function mintCassette (uint256 _itemIdx, uint256 _eligiblityMerkleIdx, uint256 _maxAmount, uint256 _landId, 
    bytes32[] calldata _eligibiltyProof, bytes32[] calldata _biomeProof) external isMintingOpen {

        // First morning cannot be minted using this function           
        require (_itemIdx != FIRST_MORNING_IDX, "Cannot mint First Morning cassette using this function.");

        // Verify snapshot eligibility, max count, and biome claim status
        bytes32 eligibilityHash = keccak256(abi.encodePacked(_eligiblityMerkleIdx, msg.sender, _maxAmount));
        require(
            MerkleProof.verify(_eligibiltyProof, m_CassetteRoot, eligibilityHash),
            "Invalid eligibility merkle proof !"
        );
        require (m_CassettesClaimed[msg.sender] + 1 <= _maxAmount, "Cannot claim this much cassettes.");
        require (m_BiomeCassetteClaimed[msg.sender][_itemIdx] == false, "Cassette for biome already minted, 1 per wallet max.");

        // Verify land biome for cassette, and ownership
        bytes32 biomeVerificationHash = keccak256(abi.encodePacked(_landId, _itemIdx));
        require(
            MerkleProof.verify(_biomeProof, m_LandBiomeRoot, biomeVerificationHash),
            "Invalid biome merkle proof !"
        );
        require (m_LandContract.ownerOf(_landId) == msg.sender, "Sender not owner of land token ID.");
      

        m_CassettesClaimed[msg.sender] = m_CassettesClaimed[msg.sender] + 1;
        m_BiomeCassetteClaimed[msg.sender][_itemIdx] = true;

        _mint(msg.sender, _itemIdx, 1, "");

    }  

    // View

    function name() public view returns (string memory) {
        return m_Name;
    }

    function symbol() public view returns (string memory) {
        return m_Symbol;
    }      

    function uri(uint256 _id) public view override returns (string memory) {
        require(totalSupply(_id) > 0, "No token supply yet.");    
         return string(
            abi.encodePacked(
                m_BaseURI,
                Strings.toString(_id)
            )
        );
    }

    // Modifiers

    modifier isMintingOpen {
      require(m_MintingOpen, "Minting is not open yet.");
      _;
    }

    // Override

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }  

}