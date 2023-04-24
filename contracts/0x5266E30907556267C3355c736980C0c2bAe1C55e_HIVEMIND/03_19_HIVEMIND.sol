pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract HIVEMIND is ERC721Enumerable, Ownable, AccessControl{
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant PRICE = 1000 * 10**14; // 0.1 ETH
    string public baseURI = "https://hvmd.s3.amazonaws.com/metadata/";

    uint256 public _mintStartTimestamp;
    bool public _mintStarted = false;
    uint256 public constant PRIVATE_MINT_DURATION = 1 days;
    uint256 public constant PUBLIC_MINT_DURATION = 8 days;
    bytes32 public _merkleRoot;
    uint256 public zeroDayBurns;

    address public _zeroDayContract;
    address public _pfpContract;
    address public constant WITHDRAW_ADDRESS = 0xfEd3828938DD9A3D5F88e93926a07466e941D489;

    uint256 public _nextTokenId = 0;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    modifier onlyBurner() {
        require(
            msg.sender == _zeroDayContract || msg.sender == _pfpContract, "Caller is not a burner contract"
        );
        _;
    }

    constructor() ERC721("HIVEMIND NODES", "HVMD") {
        _grantRole(ADMIN_ROLE, 0x0a3C1bA258c0E899CF3fdD2505875e6Cc65928a8);
        _grantRole(ADMIN_ROLE, 0xE42E4F21A750C1cC1ba839E5B1e4EfC3eD1fe454);
    }

    function getMintStartTimestamp() public view returns (uint256) {
    return _mintStartTimestamp;
}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function setMerkleRoot(bytes32 merkleRoot) external onlyRole(ADMIN_ROLE) {
        _merkleRoot = merkleRoot;
    }

    function privateMint(uint256 numTokens, bytes32[] calldata merkleProof) public payable {
        require(_mintStarted, "Mint has not started yet");
        require(block.timestamp >= _mintStartTimestamp, "Private mint has not started");
        require(block.timestamp < _mintStartTimestamp + PRIVATE_MINT_DURATION, "Private mint has ended");
        require(verifyMerkleProof(merkleProof, msg.sender), "Invalid Merkle proof");

        _mintTokens(numTokens);
    }

    function publicMint(uint256 numTokens) public payable {
        require(_mintStarted, "Mint has not started yet");
        require(block.timestamp >= _mintStartTimestamp + PRIVATE_MINT_DURATION, "Public mint has not started");
        require(block.timestamp <= _mintStartTimestamp + PRIVATE_MINT_DURATION + PUBLIC_MINT_DURATION, "Minting period has ended");
        _mintTokens(numTokens);
    }

    function verifyMerkleProof(bytes32[] memory proof, address user) public view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }

    function _mintTokens(uint256 numTokens) private {
        uint256 newTotalSupply = totalSupply() + numTokens;
        require(newTotalSupply <= MAX_SUPPLY, "Minting would exceed max supply");
        require(numTokens > 0 && numTokens <= 10, "You can mint minimum 1, maximum 10 tokens");
        require(msg.value == PRICE * numTokens, "Incorrect ether amount sent");

                for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = _nextTokenId;
            _safeMint(msg.sender, tokenId);
            _nextTokenId++;
        }
    }

  function burn(uint256 tokenId) public onlyBurner {
        // Increment zeroDayBurns if the caller is _zeroDayContract
        if (msg.sender == _zeroDayContract) {
            zeroDayBurns++;
        }
        _burn(tokenId);
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }

        return result;
    }

    function startMint() public onlyRole(ADMIN_ROLE) {
        require(!_mintStarted, "Mint has already started");
        _mintStartTimestamp = block.timestamp;
        _mintStarted = true;
    }

    function setZeroDay(address zeroDayContract) public onlyRole(ADMIN_ROLE) {
        _zeroDayContract = zeroDayContract;

    }


      function setPFP(address pfpContract) public onlyRole(ADMIN_ROLE) {
        _pfpContract = pfpContract;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newuri) public onlyRole(ADMIN_ROLE){
        baseURI = newuri;
    }

    function withdraw() public onlyRole(ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(WITHDRAW_ADDRESS).transfer(balance);
    }
}