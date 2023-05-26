//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "openzeppelin/contracts/token/ERC721/ERC721.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/security/Pausable.sol";
import "openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin/contracts/utils/Counters.sol";
import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
contract ProjectPassport is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public MAX_SUPPLY = 4200;
    uint256 public maxPerMint = 2;
    bool public allowlistMintEnabled  = false;
    bool public waitlistMintEnabled = false;
    address private signerAllowlist;
    address private signerWaitlist;
    bytes32 public allowlistMerkleRoot;
    bytes32 public waitlistMerkleRoot;
    mapping(address => bool) private allowListClaimed;
    mapping(address => bool) private waitListClaimed;
    string public preRevealImage;
    bool public isRevealedImage;
    string public baseURI;
    function setWaitlistRoot(bytes32 _hash) public onlyOwner {
        waitlistMerkleRoot = _hash;
    }
    function setAllowlistRoot(bytes32 _hash) public onlyOwner {
        allowlistMerkleRoot = _hash;
    }
    constructor (bytes32 waitlistHash, bytes32 allowlistHash, string memory _name, string memory _symbol) ERC721 (_name, _symbol) {
        setWaitlistRoot(waitlistHash);
        setAllowlistRoot(allowlistHash);
        _pause();
    }
    function mintToAddress(uint256 _quantity, address _addr) external onlyOwner {
        _multiMint(_quantity, _addr);
    }
    function verifyAddressAllowlist(bytes32[] calldata _proof) public view returns(bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));
        return MerkleProof.verify(_proof, allowlistMerkleRoot, leaf);
    }
    function verifyAddressWaitlist(bytes32[] calldata _proof) public view returns(bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));
        return MerkleProof.verify(_proof, waitlistMerkleRoot, leaf);
    }
    function allowlist_mint (uint256 _quantity, bytes32[] calldata _proof) external {
        require(allowlistMintEnabled == true, "currently in the allowlist phase");
        require(waitlistMintEnabled == false, "currently not in the waitlist phase");
        require(_quantity <= maxPerMint, "too many for this transaction");
        require(_quantity+ totalSupply() < MAX_SUPPLY, "max supply reached");
        require(allowListClaimed[msg.sender] != true, "already minted from allowlist");
        require(verifyAddressAllowlist(_proof),"not on allowlist");
        require(!paused(), "paused");
        _multiMint(_quantity, msg.sender);
        allowListClaimed[msg.sender] = true;
    }
    function waitlist_mint (uint256 _quantity, bytes32[] calldata _proof) external {
        require(allowlistMintEnabled == false, "currently in the waitlist phase");
        require(waitlistMintEnabled == true, "currently not in the waitlist phase");
        require(_quantity <= maxPerMint, "too many for this transaction");
        require(_quantity + totalSupply() < MAX_SUPPLY, "max supply reached");
        require(waitListClaimed[msg.sender] != true, "already minted from waitlist");
        require(verifyAddressWaitlist(_proof),"not on waitlist");
        require(!paused(), "paused");
        _multiMint(_quantity, msg.sender);
        waitListClaimed[msg.sender] = true;
    }
    function mint(uint256 _quantity) external {
        require(allowlistMintEnabled == false, "currently in the allowlist phase");
        require(waitlistMintEnabled == false, "currently in the waitlist phase");
        require(_quantity <= maxPerMint, "too many for this transaction");
        require(_quantity + totalSupply() < MAX_SUPPLY, "too many");
        require(!paused(), "paused");
        _multiMint(_quantity, msg.sender);
    }
    function _multiMint(uint256 _quantity, address _addr) internal {
        for(uint256 i = 0; i < _quantity; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _safeMint(_addr, newTokenId);
        }
    }
    function setAllowlistStatus (bool _status) external onlyOwner {
         allowlistMintEnabled = _status;
    }
    function setWaitlistStatus (bool _status) external onlyOwner {
         waitlistMintEnabled = _status;
    }
    function setBaseURI (string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setMaxSupply (uint256 _amount) public onlyOwner {
        MAX_SUPPLY = _amount;
    }
    
    function setMaxPerMint (uint256 _amount) public onlyOwner {
        maxPerMint = _amount;
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    function setPreRevealImage(string memory _uri) public onlyOwner {
        preRevealImage = _uri;
    }
    function setPreRevealStatus(bool status) public onlyOwner {
        isRevealedImage = status;
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
      if (isRevealedImage == true) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId),".json"));
      } else {
        return preRevealImage;
      }
    }
    function _burn(uint256 tokenId) internal override (ERC721) {
        super._burn(tokenId);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}