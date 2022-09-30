// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

////////////////////////////////////////////////// Main Contract //////////////////////////////////////////////////
//By @SuperShyGuy0 (ultra.eth)

contract AlphaCats is ERC721A, ERC2981, Ownable {
    using Strings for uint256;

    //////////////////////////////////////////////////  Modifiers //////////////////////////////////////////////////

    modifier noContracts() {
        require(msg.sender == tx.origin);
        _;
    }

    ////////////////////////////////////////////////// Constants //////////////////////////////////////////////////

    // The withdraw address for contract funds
    address public withdrawAddress = 0x9F60F511551D0d368ED662D20c07F845a178FC30;

    // The Merkle Tree root
    bytes32 public merkleRoot;

    uint256 public maxAlpha = 200;
    uint256 public mintPrice = 0;

    // Atribute Map
    mapping(uint256 => Attr) public attributes;

    // Sale on or off
    bool public isSaleActive;

    // Attribute structure
    struct Attr {
        string name;
        string image;
    }

    // Addresses that have minted
    mapping(address => bool) public minted;

    ////////////////////////////////////////////////// Constructor //////////////////////////////////////////////////

    constructor() ERC721A("Alpha Cats", "ACATS") {
        _setDefaultRoyalty(withdrawAddress, 1500);
    }

    ////////////////////////////////////////////////// Interface Functions //////////////////////////////////////////////////
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {

        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the baseURI of the collection
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    ////////////////////////////////////////////////// Function Overrides //////////////////////////////////////////////////
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        attributes[tokenId].name,
                        '",',
                        '"image_data": "',
                        attributes[tokenId].image,
                        '",',
                        '"attributes": [{"trait_type": "Collection", "value": "Genesis"}]}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    ////////////////////////////////////////////////// Owner Funtions //////////////////////////////////////////////////
    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setSupply(uint256 newSupply) external onlyOwner {
        maxAlpha = newSupply;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function setMerkle(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function airdrop(
        address to,
        string memory svg,
        string memory name
    ) external onlyOwner {
        uint256 nextID = totalSupply();
        require(nextID < maxAlpha, "AlphaCats: Exceeds Max Supply");
        attributes[nextID] = Attr(name, svg);
        _mint(to, 1);
    }

    function ReplaceMetadata(
        uint256 id,
        string memory svg,
        string memory name
    ) external onlyOwner {
        require(id < totalSupply(), "AlphaCats: Invalid ID");
        // Save the metadata.
        attributes[id] = Attr(name, svg);
    }

    function ReplaceName(
        uint256 id,
        string memory name
    ) external onlyOwner {
        require(id < totalSupply(), "AlphaCats: Invalid ID");
        // Save the metadata.
        attributes[id].name = name;
    }

    function withdrawFunds() external {
        (bool sent, ) = payable(withdrawAddress).call{
            value: address(this).balance
        }("");
        require(sent);
    }

    ////////////////////////////////////////////////// External Funtions //////////////////////////////////////////////////

    function mint(
        string memory svg,
        string memory name,
        bytes32[] calldata _proof
    ) external payable noContracts {
        require(isSaleActive, "AlphaCats: Sale Inactive");
        require(mintPrice <= msg.value, "AlphaCats: Insufficient Funds");
        require(!minted[msg.sender], "AlphaCats: This address minted already");
        uint256 nextID = totalSupply();
        require(nextID < maxAlpha, "AlphaCats: Exceeds Max Supply");

        // Check the Merkle Tree
        require(
            MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, svg, name))),
            "AlphaCats: Invalid Proof"
        );

        // Save the metadata.
        attributes[nextID] = Attr(name, svg);

        // Mark address as has minted
        minted[msg.sender] = true;
        _mint(msg.sender, 1);
    }
 
}