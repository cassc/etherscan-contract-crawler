// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Verify.sol";

contract VimptoWorlds is Ownable, ERC721Enumerable, ReentrancyGuard, VerifySignature {

    using Counters for Counters.Counter;
    using Strings for uint256;

    struct MintPayload {
        address to;
        uint256 nonce;
        uint8 _toMint;
    }

    uint256 public whitelistPrice = 200000000000000000;
    bool public whitelistMintStarted = false;
    uint256 public whitelistMintingLimitPerAddress = 3;
    uint256 public constant maxTotalSupply = 2000;

    bool public freeMintStarted = false;

    mapping(address => bool) public mintedInwhitelist;
    mapping(address => uint) public freeMintAt;

    Counters.Counter public _tokenIds;

    string public ipfsGateway = "https://gateway.pinata.cloud/ipfs/";
    string public ipfsHash = "QmX49QfWRfNwot4c6k6FAP6jNXcn4ssCwjndLjNyToUyZT";

    address private verificationAdmin;

    constructor(address _verificationAdmin) ERC721("VimptoWorlds", "VWS") {
        verificationAdmin = _verificationAdmin;
    }

    // PUBLIC

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(ipfsGateway, ipfsHash, '/', _tokenId.toString(), '.json'));

    }

    // EXTERNAL

    function mintWhitelist(MintPayload calldata _payload, bytes memory _signature) external payable nonReentrant {

        require(whitelistMintStarted, "Whitelist mint not started yet");
        require(totalSupply() + _payload._toMint <= maxTotalSupply, "Supply finished");
        require(balanceOf(msg.sender) + _payload._toMint <= whitelistMintingLimitPerAddress, "Whitelist minting limit reached for this address");
        require(verifyOwnerSignature(_payload, _signature), "Invalid Signature");
        uint price = _payload._toMint * whitelistPrice;
        require(msg.value >= price,"Mint price incorrect");
        if(balanceOf(msg.sender) + _payload._toMint == whitelistMintingLimitPerAddress){
             mintedInwhitelist[msg.sender] = true;
        }
        mintMultiple(msg.sender, _payload._toMint);

    }

    function mintFree(MintPayload calldata _payload, bytes memory _signature) external nonReentrant{

        require(freeMintStarted, "Free mint not started yet");
        require(_payload._toMint == 1, "Only one NFT at a time");
        require(totalSupply() + _payload._toMint <= maxTotalSupply, "All 2,000 NFT's have been minted");
        require(mintedInwhitelist[msg.sender], "You are not eligible for free minting");
        require(freeMintAt[msg.sender] < block.timestamp, "Only one NFT per address per hour");
        require(verifyOwnerSignature(_payload, _signature), "Invalid Signature");
        freeMintAt[msg.sender] = block.timestamp + 1 hours;
        mint(msg.sender);

    }

    function ownerMint(address _to, uint8 _toMint) external onlyOwner{

        require(_tokenIds.current() + _toMint <= maxTotalSupply, "All 2,000 NFT's have been minted");
        mintMultiple(_to, _toMint);

    }
    
    function arrayOfTokenIdsByAddress(address _owner) external view returns(uint256[] memory) {

            uint tokenCount = balanceOf(_owner);
            uint256[] memory tokensId = new uint256[](tokenCount);
            for(uint i = 0; i < tokenCount; i++){
                tokensId[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return tokensId;
    }

    // EXTERNAL ONLY OWNER

    function startWhitelist(bool _start) external onlyOwner {
         whitelistMintStarted = _start;
    }

    function startFreeMint(bool _start) external onlyOwner {
         freeMintStarted = _start;
    }

    function setWhitelistMintingLimit(uint _mintingLimit) external onlyOwner {
        whitelistMintingLimitPerAddress = _mintingLimit;
    }

    function withdrawal() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw.");
        payable(owner()).transfer(address(this).balance);
    }

    function setVerificationAdmin(address _verificationAdmin) external onlyOwner {
        verificationAdmin = _verificationAdmin;
    }

    function setIPFSGateway(string memory _ipfsgateway) external onlyOwner {
        ipfsGateway = _ipfsgateway;
    }

    function setIPFSHash(string memory _ipfshash) external onlyOwner {
        ipfsHash = _ipfshash;
    }

    function setWhitelistPrice(uint _whitelistPrice) external onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    // INTERNAL

    function verifyOwnerSignature(MintPayload calldata _payload, bytes memory _signature) internal view returns(bool) {
        bytes32 ethSignedHash = getEthSignedMessageHash(getMessageHash(_payload.nonce.toString(), _payload.to));
        return recoverSigner(ethSignedHash, _signature) == verificationAdmin;

    }

    function mintMultiple(address _addr,uint8 _toMint) internal {
        for (uint8 i = 0; i < _toMint; i++) {
            mint(_addr);
        }
    }

    function mint(address _addr) internal {
             uint256 newItemId;
            _tokenIds.increment();
            newItemId = _tokenIds.current();
            _safeMint(_addr, newItemId);
    }

}