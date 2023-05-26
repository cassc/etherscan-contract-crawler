// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./BlackholePrevention.sol";

contract FuzzleSpaceCases is 
    ERC1155, 
    Pausable, 
    Ownable,
    ERC1155Burnable, 
    ERC1155Supply, 
    BlackholePrevention, 
    ReentrancyGuard 
{
    using ECDSA for bytes32;

    uint256 public immutable RED_DWARF;
    uint256 public immutable BLUE_DWARF;
    uint256 public immutable CYBER_LIME;
    uint256 public immutable GALACTIC_AMETHYST;
    uint256 public immutable THERMAL_EMISSION;
    uint256 public immutable COSMIC_RUBY;

    uint256 public immutable QUANTITY;

    enum Phase { 
        MoH, 
        Whitelisted, 
        Public 
    }

    Phase public currentPhase;

    bytes32 private whitelistMerkleRoot;
    bytes32 internal passcode = "protected";

    mapping(address => mapping(Phase => bool)) private claimedList;
    mapping(uint256 => uint16) public maxSupplies;

    event MintSpaceCase(
        address indexed receiver,
        uint8 indexed id,
        uint8 indexed phase,
        uint256 timestamp
    ); 
   
    constructor() ERC1155("ipfs://Qmef7vu2wPMS1e8wyAoxMQ8mQCCU7qdK4yWaNKjLHWmRSN/{id}.json") {
        RED_DWARF = 0;
        BLUE_DWARF = 1;
        CYBER_LIME = 2;
        GALACTIC_AMETHYST = 3;
        THERMAL_EMISSION = 4;
        COSMIC_RUBY = 5;

        maxSupplies[RED_DWARF] = 2500;
        maxSupplies[BLUE_DWARF] = 2000;
        maxSupplies[CYBER_LIME] = 2000;
        maxSupplies[GALACTIC_AMETHYST] = 1500;
        maxSupplies[THERMAL_EMISSION] = 1000;
        maxSupplies[COSMIC_RUBY] = 1000;

        QUANTITY = 1;

        currentPhase = Phase.MoH;
    } 

    function name() external pure returns (string memory) {
        return "Fuzzle Space Cases";
    }

    function symbol() external pure returns (string memory) {
        return "FSPCA";
    } 

    function getClaimedPhase(address minter, Phase phase) external view returns (bool) {
        return claimedList[minter][phase];
    }

    function setCurrentPhase(Phase phase, bytes32 newMerkleRoot) external onlyOwner {
        require(uint8(phase) <= 2, 'invalid phase');
        currentPhase = phase;
        if (phase != Phase.Public) {
            require(newMerkleRoot != "", 'newMerkleRoot empty');
            whitelistMerkleRoot = newMerkleRoot;
        } else {
            whitelistMerkleRoot = '';
        }
    }

    function mintSpaceCase(
        uint8 id,
        bytes32[] calldata merkleProof, 
        bytes32 pCode
    )
        external 
        whenNotPaused
        nonReentrant
    {     
        require(
            pCode ==
            keccak256(bytes.concat(passcode, bytes20(address(msg.sender)))),
            "invalid passcode"
        );
        require(uint8(id) <= 5, 'invalid id');  
        require(uint8(currentPhase) <= 2, 'invalid phase');
        require(totalSupply(id) < maxSupplies[id], 'reached max supply'); 

        address minter = msg.sender;

        require(!claimedList[minter][currentPhase], 'already claimed');
        claimedList[minter][currentPhase] = true;

        if (currentPhase != Phase.Public) {
            require(whitelistMerkleRoot != "", 'merkle tree not set');
            bytes32 leaf = keccak256(abi.encodePacked(minter));
            require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf), 'invalid Merkle Proof');           
        } 

        _mintSpaceCase(minter, id); 
    }

    function _mintSpaceCase(address minter, uint8 id) internal {        
        _mint(minter, id, QUANTITY, "");
        emit MintSpaceCase(minter, id, uint8(currentPhase), block.timestamp);       
    }

    function uri(uint256 tokenId) override public pure returns (string memory) {
        return (
            string(abi.encodePacked(
                "ipfs://Qmef7vu2wPMS1e8wyAoxMQ8mQCCU7qdK4yWaNKjLHWmRSN/",
                Strings.toString(tokenId),
                ".json"
            ))
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }  

    function _beforeTokenTransfer(
        address operator, 
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    )
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setPasscode(string memory strPasscode) external onlyOwner {
        require(bytes(strPasscode).length <= 32, "less than 32 bytes");
        bytes32 passcode_;
        if (bytes(strPasscode).length == 0) {
            passcode_ = 0x0;
        } else {
            assembly {
                passcode_ := mload(add(strPasscode, 32))
            }
        }
        passcode = passcode_;
    }
    
    /***********************************|
    |            Only Admin             |
    |      (blackhole prevention)       |
    |__________________________________*/

    function withdrawEther(address payable receiver, uint256 amount) external virtual onlyOwner {
        _withdrawEther(receiver, amount);
    }
    
    function withdrawERC1155(address payable receiver, address tokenAddress, uint256 tokenId, uint256 amount) external virtual onlyOwner {
        _withdrawERC1155(receiver, tokenAddress, tokenId, amount);
    }
}