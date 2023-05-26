pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Surge is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant MAX_MINT = 888;

    uint256 public mintPrice = 0.1 ether;
    uint256 public maxMintAmount = 1;
    bool public paused = true;

    bytes32 private whitelistRoot;
    mapping(address => bool) private whitelistClaimed;

    string public baseURI;
    string public metadataURI;

    // Sets the baseURI in the constructor
    constructor(string memory tokenBaseURI, string memory tokenMetadataURI)
        ERC721("Surge", "surge")
    {
        setBaseURI(tokenBaseURI);
        setMetadataURI(tokenMetadataURI);
    }

    // Verify that a given leaf is in the tree.
    function _verify(bytes32 _leafNode, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, whitelistRoot, _leafNode);
    }

    // Generate the leaf node
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    // External
    function mint(uint256 _mintAmount, bytes32[] calldata _proof)
        public
        payable
    {
        uint256 totalMinted = _tokenIds.current();
        require(!paused, "Minting is paused");
        require(totalMinted.add(_mintAmount) <= MAX_MINT, "Not enough NFTs!");
        require(_mintAmount <= maxMintAmount, "Exceeds max per transactions");
        require(msg.value >= mintPrice.mul(_mintAmount), "Insuffcient funds");
        require(!whitelistClaimed[msg.sender], "You have already minted");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, whitelistRoot, leaf),
            "Invalid proof"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
        whitelistClaimed[msg.sender] = true;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // For OpenSea
    function contractURI() public view returns (string memory) {
        return metadataURI;
    }

    // Owner functions
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMetadataURI(string memory _newMetadataURI) public onlyOwner {
        metadataURI = _newMetadataURI;
    }

    function setWhilelistClaimed(address[] calldata _addresses, bool _state)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistClaimed[_addresses[i]] = _state;
        }
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        mintPrice = _newCost;
    }

    function setWhitelistRoot(bytes32 _root) public onlyOwner {
        whitelistRoot = _root;
    }

    function withdraw(address payable _to, uint256 _amount) public onlyOwner {
        _to.transfer(_amount);
    }
}