// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract FashionLeagueBackstagePass is ERC1155, Ownable, ERC1155Supply {
    // max supply per token
    uint256 constant maxGold = 50;
    uint256 constant maxSilver = 150;
    uint256 constant maxBronze = 300;
    // max sum of tokens
    uint256 constant totalTokenLimit = 500;
    // currently total minted tokens
    uint256 numTokens;
    // nonce for randomness
    uint256 internal nonce;
    // indices list for randomness
    uint256[totalTokenLimit] public indices;
    // token URI
    string baseURI;
    string URISuffix;
    // the address that minted an NFT cannot mint it again. You would need to send your tokens to another address to mint again
    mapping(address => bool) addressMinted;
    // allow list
    mapping(address => bool) allowlist;
    // minting phases
    uint256 allowlistBegin;
    uint256 publicBegin;
    // test name
    string public name = "FL Backstage Pass";
    string public symbol = "FLBSP";
    constructor() ERC1155("") {
        numTokens = 0;
        nonce = 0;
        allowlistBegin = 1666195200; //Oct 19 2022 18:00:00 CEST
        publicBegin = 1666197000; //Oct 19 2022 18:30:00 CEST
        URISuffix = ".json";
    }
    // set new uri string without suffix
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), _URISuffix()));
    }
    // returns uri suffix
    function _URISuffix() internal view returns (string memory) {
        return URISuffix;
    }
    // set new uri suffix
    function setURISuffix(string memory _suffix) public onlyOwner {
        URISuffix = _suffix;
    }
    // returns whether given address already minted
    function minted(address _address) public view returns (bool) {
        return addressMinted[_address];
    }
    // returns whether given address is on allow list
    function allowlisted(address _address) public view returns (bool) {
        return allowlist[_address];
    }
    // add addresses to allow list
    function addAddressesToAllowlist(address[] memory addrs) public onlyOwner{
        for (uint256 i = 0; i < addrs.length; i++) {
            allowlist[addrs[i]] = true;
        }
    }
    // remove addresses from allow list
    function removeAddressesFromAllowlist(address[] memory addrs) public onlyOwner{
        for (uint256 i = 0; i < addrs.length; i++) {
            allowlist[addrs[i]] = false;
        }
    }
    function mintGold(address _to) internal {
        _mint(_to, 1, 1, "");
    }
    function mintSilver(address _to) internal {
        _mint(_to, 2, 1, "");
    }
    function mintBronze(address _to) internal {
        _mint(_to, 3, 1, "");
    }
    function mint() public {
        // maximum tokens should not be exceeded
        require(globalTotal() < totalTokenLimit, "mint exceeds max");
        // only one mint per address
        require(!addressMinted[msg.sender], "already minted");
        // check whether on allowlist during allowlist mint
        if(block.timestamp >= allowlistBegin && block.timestamp < publicBegin) {
            require(allowlist[msg.sender], "not on allowlist");
        }
        // check whether public mint phase active if not allowlist
        else {
            require(block.timestamp >= publicBegin, "public mint not yet active");
        }
        // get randomness
        uint256 value = randomIndex();
        numTokens++;
        // based on randomness mint rarity
        if(value > 200) {
            mintBronze(msg.sender);
        }
        else if(value > 50) {
            mintSilver(msg.sender);
        }
        else {
            mintGold(msg.sender);
        }
        // add minter to adrress minted
        addressMinted[msg.sender] = true;
    }
    // batch mint
    function batchMint(uint256 _quantity) public onlyOwner {
        require(_quantity <= totalTokenLimit - globalTotal(), "batchMint exceeds max");
        for(uint256 i = 0; i < _quantity; i++) {
            uint256 value = randomIndex();
            numTokens++;
            if(value > 200) {
                mintBronze(msg.sender);
            }
            else if(value > 50) {
                mintSilver(msg.sender);
            }
            else {
                mintGold(msg.sender);
            }
        }
    }
    /*
    Specify an array of addresses (receivers) that will receive 1 token of
    specific token id:
    batchTransfer(["0x123...", "0xabc...", ...], id = 1)
    e.g. batchTransfer(["0x123...", "0xabc..."], 2);
    would transfer 1 token of id 2 to each address 0x123..., 0xabc... etc.
    */
    function batchTransfer(address[] memory _addresses, uint256 _id) public {
        uint256 leng = _addresses.length;
        require(balanceOf(msg.sender, _id) >= leng, "insufficient type qantity");
        for(uint256 i = 0; i < leng; i++) {
            address _address = _addresses[i];
            safeTransferFrom(msg.sender, _address, _id, 1, "");
        }
    }
    //sets the publicBegin time in unix time
    function setPublicBegin(uint256 publicBeginTime) public onlyOwner {
        publicBegin = publicBeginTime;
    }
    //sets the allowlistBegin time in unix time
    function setAllowlistBegin(uint256 allowlistBeginTime) public onlyOwner {
        allowlistBegin = allowlistBeginTime;
    }
    // returns public mint begin time
    function getPublicBegin() public view returns(uint256) {
        return publicBegin;
    }
    // returns public mint begin time
    function getAllowlistBegin() public view returns(uint256) {
        return allowlistBegin;
    }
    // returns total global of tokens minted
    function globalTotal() public view returns (uint256) {
        return (totalSupply(1) + totalSupply(2) + totalSupply(3));
    }
    // logic behind randomness
    function randomIndex() internal returns (uint256) {
        uint256 totalSize = totalTokenLimit - numTokens;
        uint256 index = (uint256(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize);
        uint256 value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }
        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        // Don’t allow a zero index, start counting at 1
        return value + 1;
    }
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}