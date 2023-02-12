//
//
//
/////////////////////////////////////////////////////////////////
//                                                             //
//       ██████  ███████ ███    ██ ███    ██ ██ ███████        //
//       ██   ██ ██      ████   ██ ████   ██ ██ ██             //
//       ██   ██ █████   ██ ██  ██ ██ ██  ██ ██ ███████        //
//       ██   ██ ██      ██  ██ ██ ██  ██ ██ ██      ██        //
//       ██████  ███████ ██   ████ ██   ████ ██ ███████        //
//                                                             //
// ███████  ██████ ██   ██ ███    ███ ███████ ██      ███████  //
// ██      ██      ██   ██ ████  ████ ██      ██         ███   //
// ███████ ██      ███████ ██ ████ ██ █████   ██        ███    //
//      ██ ██      ██   ██ ██  ██  ██ ██      ██       ███     //
// ███████  ██████ ██   ██ ██      ██ ███████ ███████ ███████  //
//                                                             //
/////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract EditionsByDennisSchmelz is ERC1155PresetMinterPauser, Ownable, DefaultOperatorFilterer {
    string public name = "Editions by Dennis Schmelz";
    string public symbol = "EDS";

    string public contractUri = "https://metadata.dennisschmelz.de/editions/contract";

    bool public isMintEnabled = true;

    bytes32 public root = 0xed76b5c48f8b28555b31ee240a4e2d59e7d38a213735481c8dad773bb30926c9;
    
    mapping(address => uint256) public claimedNFTs;
    
    constructor() ERC1155PresetMinterPauser("https://metadata.dennisschmelz.de/editions/{id}") {}

    function setIsMintEnabled(bool isEnabled) public onlyOwner {isMintEnabled = isEnabled;}

    function setRoot(bytes32 newroot) public onlyOwner {root = newroot;}

    function setUri(string memory newuri) public onlyOwner {_setURI(newuri);}

    function setContractURI(string memory newuri) public onlyOwner {contractUri = newuri;}

    function contractURI() public view returns (string memory) {return contractUri;}

    function mint(uint256 amount, bytes32[] calldata proof) external {
        require(isMintEnabled, "Mint not enabled");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender, amount))), "Invalid merkle proof");
        require(claimedNFTs[msg.sender] < amount, "Wallet already claimed");
        
        _mint(msg.sender, 1, amount, "");
        
        claimedNFTs[msg.sender] = amount;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}