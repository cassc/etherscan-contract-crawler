// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @title: Where My Vans Go
// @creator: Isaac Wright
// @author: andrewjiang.eth, built on manifold.xyz creator core

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//  ··_·······____···················__··___·····_····__·················______·····  //
//  ·| |·····/ / /_··___··________··/  |/  /_··_| |··/ /___·_____··_____/ ____/___··  //
//  ·| |·/|·/ / __ \/ _ \/ ___/ _ \/ /|_/ / /·/ / |·/ / __ `/ __ \/ ___/ /·__/ __ \·  //
//  ·| |/ |/ / /·/ /  __/ /··/  __/ /··/ / /_/ /| |/ / /_/ / / / (__  ) /_/ / /_/ /·  //
//  ·|__/|__/_/·/_/\___/_/···\___/_/··/_/\__, / |___/\__,_/_/ /_/____/\____/\____/··  //
//  ····································/____/······································  //
//  ·····················-░░░░░░▓░···························----))))--·············  //
//  ·····················)░░░░░░▓░···························░░░░░░░▓░░··-----------  //
//  ·····················)░░░░░░▓░···························░░░▓▓░░▓░░-)░░░░░░░░▓░░  //
//  ·····················)░░░░░░▓░··········(················░░░▓░░░░▓▓░░░░░░░░░░▓▓░  //
//  ·····················)▓▓░░░▓▓░·······(▓███▓··············░░▓▓░░░▓░░░░░░░░░░▓▓▓▓░  //
//  ·····················)▓▓░░░▓▓░·······)███▓▓▓·············░░░▓▓░░░▓░░░▓▓░░░░▓▓▓░░  //
//  ········░░░░░··░--░▓▓▓▓▓░░░▓▓▓········)█████-············░░░▓░░░░░░░▓▓▓▓░░░▓▓▓▓░  //
//  ········░▓▓░░░-░░░░▓▓▓▓▓░░░▓▓▓·······-░░▓██▓▓░░░)-·······░░░░▓░░░░░░░░▓▓▓▓░···░░  //
//  )))))···░▓▓░░▓░░))▓░▓▓▓▓░░░▓▓░··░·░░░█▓▓▓▓▓▓▓▓▓▓▓▓▓--···-░░▓▓░▓░░░░░░░░▓▓▓░░░░░░  //
//  ▓▓▓▓▓▓░░░▓▓░░░░░▓▓▓▓▓▓▓▓░░░░▓░·)░░)░▓▓▓▓▓▓▓▓▓▓▓██▓▓▓░░░░░░░░░░░░░░░▓▓▓▓▓░░░░░░░░  //
//  ▓▓▓░░░░░▓▓▓░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░··░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░▓░░░░)░-░░░▓▓▓▓▓░░░░░░░  //
//  ▓▓▓▓░░░░░▓░░▓░░░▓▓▓▓▓▓▓▓(░░░░░░░░)▓▓░▓░░░▓▓▓▓▓▓▓▓░▓▓▓░░░)▓░░░░░░░░░░▓▓▓▓▓░░░░░░░  //
//  ▓▓▓▓▓▓▓▓▓▓▓▓▓░░░▓▓▓▓▓▓▓▓░░░░░░░░░▓▓▓░▓░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░*░░▓▓░░░░░░░░░░  //
//  ▓▓▓▓▓▓▓▓▓▓▓▓▓░░░▓▓▓▓▓▓▓░░░░░░░░░░▓█░░▓▓█████████▓▓▓▓▓▓▓▓▓░-----··--)▓▓▓▓▓▓▓▓▓░▓░  //
//  █▓▓▓▓▓▓▓▓▓▓▓▓░░░▓▓▓▓▓▓▓▓░░░░░░░░)██▓██████████████▓▓▓▓▓▓▓▓▓▓▓░▓▓▓░▓▓▓▓▓▓▓▓▓▓▓▓▓▓  //
//  ▓▓▓▓▓▓▓▓▓▓▓▓▓░░░▓▓░░░░(░░░░░░░░░░▓▓█████████████████▓▓▓▓░▓▓▓▓▓▓░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓  //
//  ░░(((░(░░░░░░░░░░░░░░((░░░░(░((-)▓███████████████████▓▓░░░░░░░░░░░░░░░░░░░░░·░░░  //
//  ███████████████████████████████▓▓█████████████████████████████████▓████████░▓███  //
//  █████████████▓████████████████████████████████████████████████████▓████▓███░████  //
//  ████████████▓████████████▓▓▓▓▓▓▓▓█████████████████████████████████▓████▓███░███▓  //
//  ███████████████████████████▓▓▓▓█▓█████████████████████████████████▓████▓███░███▓  //
//  ████▓▓▓▓▓▓▓█▓░░░░▓▓▓▓|·············████▓···||*▓░█████░░░▓░░░░░░░░░░░░░░░░░▓░░░▓▓  //
//  ███████▓▓▓██▓▓▓░░▓░░░·-············*▓███░)▓▓·░)░█████░░▓▓░░░░░░░░░░░░░▓▓▓░░░▓░▓░  //
//  █████▓██▓███▓░░▓▓▓·*░·(·░|*░)░))---·-░▓▓▓░░░░))░▓▓▓█░░░░░░░░▓▓▓▓▓░░▓░░░-░░░░▓░▓░  //
//  ██████▓█████▓▓▓░░▓·░░···░)░░)-)░·||·░█▓░░░░░░(··)(░▓░-······░░░░░-*░░░░░░░░░▓░▓░  //
//  ██████▓▓▓░░·|░░░░▓·░░·░·░)░░(░(░·*░·░·░░░▓░░░░·░▓▓▓▓░···(·····)░(░░░░░░░░░░░··░░  //
//  ███░░░-·····()░░░░·░░·░·░)░░)░(░·*░·░·░░░░▓░░)·░░░░░░···(·····)░░░░░░░░░░░░░░░░░  //
//  ███▓▓░▓▓▓▓▓░▓▓▓▓░░·*░·░·░)░░(░(░░)░·░·░░░▓▓░░)·░░▓▓░░*··)·····)*░░░░░░░░░░░░░░vF  //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

// From coast to coast, between borders and beyond, this series represents the journey that has forged the person and artist that I am today. 
// By following my vans on this vast journey through time, I hope you will feel every step and heartbeat, I hope you will rise above fears with me.
// If this journey has taught me anything it is that everything is about our struggle and process, if you never climb, you never see the view. 
//
// This is the climb. 
// In snow and fog, sunshine and rain, from the tops of skyscrapers and bridges and through incarceration, here I learned to do whatever it takes. 
//
// These are the shoes that made me. 
// Welcome.

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";

interface ERC1155Partial {
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata) external;
}

contract WhereMyVansGo is ERC721Creator {

    constructor() ERC721Creator("Where My Vans Go", "WMVG") {}

    // * CONSTANTS * //
    uint8 public constant collectionSize = 125; // Contract enforced collection size limit

    // * STORAGE * //
    address public purgatory = address(0);
    address public originalContract = address(0);
    bytes32 public merkleRoot; // Merkle root to verify original token IDs and new token IDs are valid
    bool public merkleRootLocked = false; // Lock merkle root to prevent tampering
    uint8[] public migrationRange;
    string public contractMetadataURI;
    
    mapping(uint256 => address) public originalTokenIdToAddress;

    function setMigrationParameters(
        address _purgatory, 
        address _originalContract,
        uint8[] calldata _migrationRange,
        bytes32 _merkleRoot
    ) adminRequired public {
        purgatory = _purgatory;
        originalContract = _originalContract;
        migrationRange = _migrationRange;

        if(merkleRootLocked == false) {
            merkleRoot = _merkleRoot;
        }
    }

    function lockMerkleRoot() adminRequired public {
        require(merkleRoot != 0, "Merkle root has not yet been set");
        merkleRootLocked = true;
    }

    function setContractURI(string calldata _contractURI) adminRequired public {
        contractMetadataURI = _contractURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    // * MAIN FUNCTIONS * // 
    function sendTokenToPurgatory(
        uint256 originalTokenId, 
        uint256 newTokenId, 
        bytes32[] calldata merkleProof,
        string calldata uri
    ) external {
        require(purgatory != address(0), "Purgatory address cannot be the 0x0 address");
        require(originalContract != address(0), "Original contract address cannot be the 0x0 address");
        
        ERC1155Partial baseContract = ERC1155Partial(originalContract);
        require(baseContract.isApprovedForAll(msg.sender, address(this)), "Contract not yet approved for all transfers from original contract");
        
        bytes32 leaf = generateLeaf(originalTokenId, newTokenId);
        require(verifyMerkleProof(merkleProof, merkleRoot, leaf),"Invalid proof"); // Ensures original and new tokenIds are valid

        baseContract.safeTransferFrom(msg.sender, purgatory, originalTokenId, 1, "");
        originalTokenIdToAddress[originalTokenId] = msg.sender;
        resurrect(msg.sender, newTokenId, uri);
    }

    function resurrect(
        address owner, 
        uint256 newTokenId,
        string calldata uri
    ) internal virtual nonReentrant {
        require(bytes(uri).length > 0, "URI cannot be empty");
        
        _tokensExtension[newTokenId] = address(this);

        _safeMint(owner, newTokenId);
        _tokenURIs[newTokenId] = uri;
    }

    function mint(address to, uint8 tokenId, string calldata uri) public virtual nonReentrant adminRequired returns(uint256) {
        require(tokenId < collectionSize, "Token ID must be less than max collection size");
        require(tokenId < migrationRange[0] || tokenId > migrationRange[1], "Token ID must be outside of migration range");
        require(bytes(uri).length > 0, "URI cannot be empty");

        _tokensExtension[tokenId] = address(this);

        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = uri;
    }

    // * UTILITY FUNCTIONS * //
    function verifyMerkleProof(bytes32[] memory proof, bytes32 root, bytes32 leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function generateLeaf(uint256 originalTokenId, uint256 newTokenId) public pure returns (bytes32){
        string memory originalTokenStr = convertUintToString(originalTokenId);
        string memory newTokenStr = convertUintToString(newTokenId);
        string memory leaf = string(abi.encodePacked(originalTokenStr, " ", newTokenStr));
        return keccak256(abi.encodePacked(leaf));
    }

    function convertUintToString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // * DISABLING PARENT MINT FUNCTIONS * //
    function mintBase(address to) public virtual override nonReentrant adminRequired returns(uint256) {}
    function mintBase(address to, string calldata uri) public virtual override nonReentrant adminRequired returns(uint256) {}
    function mintBaseBatch(address to, uint16 count) public virtual override nonReentrant adminRequired returns(uint256[] memory tokenIds) {}
    function mintBaseBatch(address to, string[] calldata uris) public virtual override nonReentrant adminRequired returns(uint256[] memory tokenIds) {}
    function mintExtension(address to) public virtual override nonReentrant extensionRequired returns(uint256) {}
    function mintExtension(address to, string calldata uri) public virtual override nonReentrant extensionRequired returns(uint256) {}

}