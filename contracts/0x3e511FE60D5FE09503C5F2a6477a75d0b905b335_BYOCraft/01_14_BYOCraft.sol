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
// ,,,,,,.............................,,,,.....,,,,,,...,,,,,,.....................

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interfaces/IERC1155.sol";

contract BYOCraft is ERC721, Ownable {

    using Counters for Counters.Counter;

    // Contract interfaces
    IERC721 public m_pillContract;
    IERC721 public m_apostleContract;
    IERC1155 public m_vapeContract;

    // Data storage
    Counters.Counter private m_craftIdTracker;
    string private m_baseURI;

    // Apostle / Craft tracking
    mapping(uint256 => uint256) private m_craftForApostle;
    mapping(uint256 => uint256) private m_apostleForCraft;

    // Mint properties
    bool private m_mintOpen;
    bytes32 private m_merkleRoot;
    uint256 public m_maxPerTx = 50;
    mapping(address => uint256) public m_craftClaims;

    constructor (string memory _name, string memory _symbol,
    address _pillContract, address _apostleContract, address _vapeContract) ERC721 (_name, _symbol) {
        m_pillContract = IERC721(_pillContract);
        m_apostleContract = IERC721(_apostleContract);
        m_vapeContract = IERC1155(_vapeContract);
    }

    //////////////////////////////////////////////////////
    // Public methods
    //////////////////////////////////////////////////////

    // Params passed in following format
    //  -   _pillIds: [5, 2, 6] => Array of pill IDs
    //  -   _apostleIds: [-1, 5, 0] => Array of apostle IDs, if no apostle is linked to craft, then -1 is passed
    function mintCrafts (uint256[] calldata _pillIds, int256[] calldata _apostleIds, 
        uint256 _merkleIdx,
        uint256 _maxAmount,
        bytes32[] calldata _merkleProof) public isMintOpen {

        uint256 amount = _pillIds.length;

        // Check base tx data.
        require (amount > 0 &&  _apostleIds.length > 0, "Invalid data.");
        require (amount == _apostleIds.length, "Invalid data.");
        require (amount <= m_maxPerTx, "More than max per transaction.");

        // Check snapshot properties, vape balance, max claims.
        bytes32 nHash = keccak256(abi.encodePacked(_merkleIdx, msg.sender, _maxAmount));
        require(MerkleProof.verify(_merkleProof, m_merkleRoot, nHash), "Invalid merkle proof !");
        require(m_craftClaims[msg.sender] + amount <= _maxAmount, "Minting more than available mints.");
        require(m_craftClaims[msg.sender] + amount <= m_vapeContract.balanceOf(msg.sender, 0), "Not enough vapes for mint.");

        m_craftClaims[msg.sender] = m_craftClaims[msg.sender] + amount;

        for (uint256 i = 0; i < amount; i++) {
            _mintCraft(_pillIds[i], _apostleIds[i]);
        }
    }

    //////////////////////////////////////////////////////
    // Public view
    //////////////////////////////////////////////////////

    function totalSupply () public view returns (uint256) {
        return m_craftIdTracker.current();
    }

    function pillUsed (uint256 _pillId) public view returns (bool) {
        return _exists(_pillId);
    }

    function craftForApostle (uint256 _apostleId) public view returns (int256) {
        if (m_craftForApostle[_apostleId] == 0) { return -1; }
        return int256(m_craftForApostle[_apostleId] - 1); // Offset by 1
    }

    function apostleForCraft (uint256 _craftId) public view returns (int256) {
        if (m_apostleForCraft[_craftId] == 0) { return -1; }
        return int256(m_apostleForCraft[_craftId] - 1); // Offset by 1
    }

    //////////////////////////////////////////////////////
    // Owner only
    //////////////////////////////////////////////////////

    function toggleMint () public onlyOwner {
        m_mintOpen = !m_mintOpen;
    }

    function setMerkleRoot (bytes32 _merkleRoot) public onlyOwner {
        m_merkleRoot = _merkleRoot;
    }

    function setMaxPerTX (uint256 _maxPerTx) public onlyOwner {
        m_maxPerTx = _maxPerTx;
    }

    function setBaseURI (string memory _uri) public onlyOwner {
        m_baseURI = _uri;
    }

    function updateContracts (address _pillContract, address _apostleContract, address _vapeContract) public onlyOwner {
        m_pillContract = IERC721(_pillContract);
        m_apostleContract = IERC721(_apostleContract);
        m_vapeContract = IERC1155(_vapeContract);
    }

    function ownerMint(uint256 _id) public onlyOwner { // Crafts for the infamous BYOP pills (1, 2)
        require (_id == 1 || _id == 2);
        m_craftIdTracker.increment();
        _safeMint (msg.sender, _id);
    }

    //////////////////////////////////////////////////////
    // Internal methods
    //////////////////////////////////////////////////////

    function _mintCraft (uint256 _pillId, int256 _apostleId) internal {
        require (!_exists(_pillId), "Craft already minted with pill.");
        require (m_pillContract.ownerOf (_pillId) == msg.sender, "Not owner of pill.");
        require (_apostleId >= -1 && _apostleId < 10000, "Invalid data.");
        if (_apostleId >= 0) { // Using an apostle, otherwise generic craft
            uint256 apostleId = uint256 (_apostleId);
            require (m_apostleContract.ownerOf (apostleId) == msg.sender, "Invalid apostle for mint.");
            require (m_craftForApostle[apostleId] == 0, "Apostle already used.");
            m_craftForApostle[apostleId] = _pillId + 1; // Offset by 1 since Pill 0 exists
            m_apostleForCraft[_pillId] = apostleId + 1; // Offset by 1 since Apostle 0 exists
        }
        m_craftIdTracker.increment();
        _safeMint(msg.sender,  _pillId);
    }

    function _baseURI() internal view override returns (string memory) {
        return m_baseURI;
    }

    //////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////

    modifier isMintOpen {
        require (m_mintOpen, "Minting not open.");
        _;
    }

}