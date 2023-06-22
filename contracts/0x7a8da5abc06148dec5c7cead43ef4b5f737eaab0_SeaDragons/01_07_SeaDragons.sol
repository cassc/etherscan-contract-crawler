// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SeaDragons is ERC721A, Ownable, Pausable {

    using Address for address payable;

    event ClaimAptosTokens(address indexed claimer, uint indexed amount, string indexed aptosWallet);

    struct Infos {
        uint256 regularCost;
        uint256 memberCost;
        uint256 whitelistCost;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 maxMintPerAddress;
        uint256 maxMintPerTx;
    }

    string metadata = "ipfs://QmVfpPWygypTXdik8e45hee7dcebPM9opkjCAPJPb69y9J";
    mapping(address => bool) public whitelistedAddresses;

    uint regularCost = 0.09 ether;
    uint whitelistCost = 0.0777 ether;
    uint maxSupply = 8800;
    uint maxPerTransaction = 50;

    constructor() ERC721A("SeaShrine VIP", "SeaDragon") {}

    function getInfo() public view returns (Infos memory) {
        Infos memory allInfos;
        allInfos.regularCost = regularCost;
        allInfos.memberCost = 0;
        allInfos.whitelistCost = whitelistCost;
        allInfos.maxSupply = maxSupply;
        allInfos.totalSupply = totalSupply();
        allInfos.maxMintPerTx = maxPerTransaction;
        allInfos.maxMintPerAddress = 0;

        return allInfos;
    }

    function setMetadata(string calldata _metadata) public onlyOwner {
        metadata = _metadata;
    }

    function isWhitelist(address _address) public view returns(bool) {
        return whitelistedAddresses[_address];
    }

    function setCost(uint256 _regularCost, uint256 _whitelistCost) public onlyOwner {
        regularCost = _regularCost;
        whitelistCost = _whitelistCost;
    }

    function mint(uint256 quantity) external payable whenNotPaused {
        require(quantity > 0, "need to mint at least 1 NFT");
        require(quantity <= canMint(msg.sender), "over max");
        uint256 supply = totalSupply();
        uint cost = mintCost(msg.sender);
        uint total = quantity * cost;
        require(total <= msg.value, "insufficient funds");
        _mint(msg.sender, quantity);
    }

    function canMint(address _address) public view virtual returns(uint256){
        uint leftToMint = maxSupply - totalSupply();
        if(leftToMint > maxPerTransaction) leftToMint = maxPerTransaction;
        return leftToMint;
    }

    function mintCost(address _address) public view returns (uint256) {
        require(_address != address(0), "not address 0");
        return isWhitelist(_address) ? whitelistCost : regularCost;
    }

    function addWhiteList(address[] calldata _addresses) public onlyOwner {
        uint len = _addresses.length;
        for(uint i = 0; i < len; i = unsafe_inc(i)) {
            whitelistedAddresses[_addresses[i]] = true;
        }        
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        return metadata;
    }
    
    function addWhiteListAddress(address _address) public onlyOwner {
        whitelistedAddresses[_address] = true;
    }

    function unsafe_inc(uint x) private pure returns (uint) {
        unchecked { return x + 1; }
    }

    function requestMigration(uint256[] calldata tokens, string calldata aptosWallet) external {
        uint len = tokens.length;
        for(uint i = 0; i < len; i = unsafe_inc(i)){
            _burn(tokens[i], true);
        }
        emit ClaimAptosTokens(msg.sender, len, aptosWallet);
    }

    function withdraw() public onlyOwner{
        payable(msg.sender).sendValue(address(this).balance);
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }
}