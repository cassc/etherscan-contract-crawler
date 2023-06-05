// SPDX-License-Identifier: MIT
/*     
    _    _             _                _           
    | \ | |           | |              | |          
    |  \| |   ___     | |        __ _  | |__    ___ 
    | . ` |  / _ \    | |       / _` | | '_ \  / __|
    | |\  | | (_) |   | |____  | (_| | | |_) | \__ \
    |_| \_|  \___/    |______|  \__,_| |_.__/  |___/ 
*/

pragma solidity ^0.8.19;
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract PePe is ERC721A, Ownable, ERC2981 {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 888;
    uint256 public constant MAX_OG_MINT = 5;
    uint256 public constant MAX_PUBLIC_MINT = 2;
    
    string public contractURI;
    string public baseTokenUri;
    string public placeholderTokenUri;

    bool public isRevealed;
    bool public freeMintSale;
    bool public publicSale;
    
    bytes32 public merkleRootFree;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalFreeMint;

    constructor(
        string memory _contractURI,
        string memory _placeholderTokenUri,
        bytes32 _merkleRootFree,
        uint96 _royaltyFeesInBips,        
        address _teamAddress
    ) ERC721A("Jose the PePe", "PePe") {
        setRoyaltyInfo(_teamAddress, _royaltyFeesInBips);
        contractURI = _contractURI;
        merkleRootFree = _merkleRootFree;
        placeholderTokenUri = _placeholderTokenUri;
        _mint(_teamAddress, 80);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function publicMint(uint256 _quantity) external callerIsUser {
        require(publicSale, "Not Yet Active");        
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Cannot mint beyond max supply"
        );
        require(
            (totalPublicMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT,
            "Cannot mint beyond max limit"
        );
        totalPublicMint[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }  

    function freeMint(bytes32[] memory _merkleProof) external callerIsUser {
        require(freeMintSale, "Not Yet Active");
        require(
            isValidMerkleProof(_merkleProof, msg.sender, merkleRootFree),
            "You are not OG"
        );
        require(
            (totalSupply() + 5) <= MAX_SUPPLY,
            "Cannot mint beyond max supply"
        );
        require(
            (totalFreeMint[msg.sender] + 5) <= MAX_OG_MINT,
            "Cannot mint beyond max limit"
        );
        totalFreeMint[msg.sender] += 5;
        _mint(msg.sender, 5);
    }

    function isValidMerkleProof(
        bytes32[] memory proof,
        address _addr,
        bytes32 _merkleRoot
    ) public pure returns (bool) {
        bytes32 sender = keccak256(abi.encodePacked(_addr));
        return MerkleProof.verify(proof, _merkleRoot, sender);
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
            merkleRootFree = _merkleRoot;        
    }

    function getFreeMerkleRoot() external view returns (bytes32) {
        return merkleRootFree;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function toggleFreeMintSale() external onlyOwner {
        freeMintSale = !freeMintSale;
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