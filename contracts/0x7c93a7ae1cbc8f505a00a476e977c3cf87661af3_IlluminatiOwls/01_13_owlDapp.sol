// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract IlluminatiOwls is ERC721A, Ownable {

    bytes32 public publicWhitelistMerkleRoot;
    bytes32 public hootWhitelistMerkleRoot;

    string private _baseUriExtended;
    uint256 public immutable MAX_SUPPLY = 6333;
    uint256 public mintFee;
    uint256 public whitelistMintFee;
    uint256 public wlStartTime;
    uint256 public wlEndTime;
    uint256 public publicStartTime;
    uint256 public hootStartTime;
    uint256 public hootEndTime;
    uint256 public totalHootLimit = 100;
    uint256 public totalHootMinted;

    constructor() ERC721A("illuminati Owls VIP", "ILO") {}

    function whitelistMint(uint256 quantity, bytes32[] memory proof) 
    external
    payable
    {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Max supply reached");

        if(block.timestamp > hootStartTime && block.timestamp < hootEndTime && verifyHootMerkleProof(proof)) {
            require(quantity + totalHootMinted <= totalHootLimit, "Max limit reached");
            _safeMint(msg.sender, quantity);
            totalHootMinted = totalHootMinted + quantity;
        } else if(block.timestamp > wlStartTime && block.timestamp < wlEndTime && verifyPublicMerkleProof(proof)) {
            require(msg.value == whitelistMintFee * quantity, "Insufficent ETH sent");
            _safeMint(msg.sender, quantity);

        } else {revert();}
    }

    function publicMint(uint256 quantity) 
    external
    payable
    {
        require(block.timestamp > publicStartTime , "Not Started");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Max supply reached");
        require(msg.value == mintFee  * quantity, "Insufficent ETH sent");
        _safeMint(msg.sender, quantity);
    }

    function setWlMintTime(uint256 _startTime) external onlyOwner{
        wlStartTime = _startTime;
         wlEndTime = _startTime + 2 hours;
         publicStartTime = wlEndTime;
    }

    function setHootMintTime(uint256 _startTime, uint256 _endTime) external onlyOwner{
        require(_startTime < _endTime, "Invalid Time");
        hootStartTime = _startTime;
        hootEndTime = _endTime;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner{
        _baseUriExtended = _baseUri;
    }

    function setMintingFee(uint256 fee) external onlyOwner{
        mintFee = fee;
    }

    function setWhitelistMintingFee(uint256 fee) external onlyOwner{
        whitelistMintFee = fee;
    }
    
    function withdrawEth(address owner) external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUriExtended;
    }
    
    // PUBLIC WHITELSITING
    function setPublicWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        publicWhitelistMerkleRoot = merkleRoot;
    }


    //HOOT WHITELISTING
    function setHootWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        hootWhitelistMerkleRoot = merkleRoot;
    }
    
    function verifyPublicMerkleProof(bytes32[] memory proof) internal view returns (bool) {
        return _verify(proof, publicWhitelistMerkleRoot, _hash(msg.sender));
    }

    function verifyHootMerkleProof(bytes32[] memory proof) internal view returns (bool) {
        return _verify(proof, hootWhitelistMerkleRoot, _hash(msg.sender));
    }

    //VERIFY AND HASH
    function _verify(bytes32[] memory proof, bytes32 merkleRoot, bytes32 addressHash)
    internal
    pure
    returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, addressHash);
    }

    function _hash(address add) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(add));
    }

    /**
     * @dev Returns the starting token ID. 
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}