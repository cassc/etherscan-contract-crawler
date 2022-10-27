// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Poopsie is ERC721A, Ownable, ERC2981 {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1234;
    uint256 public constant MAX_PUBLIC_MINT = 2;
    uint256 public constant MAX_WHITELIST_MINT = 3;
    string public contractURI;
    string private baseTokenUri;
    string public placeholderTokenUri;

    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;    

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor(        
        string memory _contractURI,
        string memory _placeholderTokenUri,
        bytes32 _merkleRoot,
        uint96 _royaltyFeesInBips,
        address _royaltyAddress,       
        address _teamAddress   
    ) ERC721A("Poopsie", "POOP") {
        setRoyaltyInfo(_royaltyAddress, _royaltyFeesInBips);
        contractURI = _contractURI;
        merkleRoot = _merkleRoot;        
        placeholderTokenUri = _placeholderTokenUri;        
        _mint(_teamAddress,234);
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Cannot be called by a contract"
        );
        _;
    }

    function publicMint(uint256 _quantity) external callerIsUser {
        require(publicSale, "Not Yet Active");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Beyond Max Supply"
        );
        require(
            (totalPublicMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT,
            "Already minted 1"
        );
        totalPublicMint[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity)
        external
        callerIsUser
    {
        require(whiteListSale, "Minting is on Pause");
        require(isValidMerkleProof(_merkleProof, msg.sender), "You are not whitelisted");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Cannot mint beyond max supply"
        );
        require(
            (totalWhitelistMint[msg.sender] + _quantity) <= MAX_WHITELIST_MINT,
            "Cannot mint beyond whitelist max mint!"
        );
        totalWhitelistMint[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function isValidMerkleProof(bytes32[] memory proof, address _addr)
        public
        view
        returns (bool)
    {
        bytes32 sender = keccak256(abi.encodePacked(_addr));
        return MerkleProof.verify(proof, merkleRoot, sender);
    } 

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata URI query for nonexistent token"
        );

        uint256 trueId = tokenId + 1;

        if (!isRevealed) {
            return placeholderTokenUri;
        }        
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, trueId.toString(), ".json")
                )
                : "";
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function toggleWhiteListSale() external onlyOwner {
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}