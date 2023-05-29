// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title DaoPunks
 * DaoPunks - Smart contract for DaoPunks characters
 */
contract DaoPunks is ERC721, Ownable {
    address openseaProxyAddress;
    string public contract_ipfs_json;
    string public contract_base_uri;
    string private baseURI;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 MAX_NFTS = 1111;
    uint256 minting_price = 0.08 ether;
    bool collection_locked = false;
    uint256 public MIN_BANK = 35000000000000000000000;
    bool whitelist_active = true;
    mapping(address => uint256) private _purchases;
    mapping(address => bool) private _whitelisted;
    IERC20 private BANK;
    
    constructor(
        address _openseaProxyAddress,
        string memory _name,
        string memory _ticker,
        string memory _contract_ipfs,
        address _bankAddress
    ) ERC721(_name, _ticker) {
        openseaProxyAddress = _openseaProxyAddress;
        contract_ipfs_json = _contract_ipfs;
        contract_base_uri = "https://ipfs.io/ipfs/QmRF2B8gotBTWidw34uwSyF9egEu88Jkhgviu6rrD1U6V6/";
        BANK = IERC20(_bankAddress);
    }

    function _baseURI() internal override view returns (string memory) {
        return contract_base_uri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory _tknId = Strings.toString(_tokenId);
        return string(abi.encodePacked(contract_base_uri, _tknId, ".json"));
    }

    function contractURI() public view returns (string memory) {
        return contract_ipfs_json;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalNFTs = totalSupply();
            uint256 resultIndex = 0;
            uint256 nftId;

            for (nftId = 1; nftId <= totalNFTs; nftId++) {
                if (ownerOf(nftId) == _owner) {
                    result[resultIndex] = nftId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /*
        This method will first mint the token to the address.
    */
    function mintNFT() public payable {
        bool canMint = false;
        if(whitelist_active){
            uint256 bank_balance = BANK.balanceOf(msg.sender);
            if(bank_balance >= MIN_BANK){
                canMint = true;
            }else{
                canMint = isWhitelisted(msg.sender);
            }
        }else{
            canMint = true;
        }
        require(canMint, "DaoPunks: You can't mint because don't have minimum $BANK or whitelisted");
        require(msg.value % minting_price == 0, 'DaoPunks: Amount should be a multiple of minting cost');
        uint256 amount = msg.value / minting_price;
        require(amount >= 1, 'DaoPunks: Amount should be at least 1');
        require(amount <= 2, 'DaoPunks: Amount must be less or equal to 2');
        uint256 reached = amount + _tokenIdCounter.current();
        require(reached <= MAX_NFTS, "DaoPunks: Hard cap reached.");
        uint256 purchases = _purchases[msg.sender] + amount;
        require(purchases <= 2, 'DaoPunks: Cannot purchase more than 2');
        _purchases[msg.sender] = _purchases[msg.sender] + amount;
        uint j = 0;
        for (j = 0; j < amount; j++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            _mint(msg.sender, newTokenId);
        }
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function bankBalance(address _address) public view returns (uint256) {
        uint256 bank_balance = BANK.balanceOf(_address);
        return bank_balance;
    }
    
    function amountPurchased(address _address) public view returns (uint256) {
        return _purchases[_address];
    }

    /*
        This method will allow owner to fix the contract details
     */

    function fixContractDescription(string memory newDescription) public onlyOwner {
        contract_ipfs_json = newDescription;
    }

    /*
        This method will allow owner to fix the bank address
     */

    function fixBankAddress(address _bankAddress) public onlyOwner {
        BANK = IERC20(_bankAddress);
    }

    /*
        This method will allow owner to fix the minting price
     */

    function fixPrice(uint256 price) public onlyOwner {
        minting_price = price;
    }

    /*
        This method will allow owner to fix the minimum bank treshold
     */

    function fixMinBank(uint256 amount) public onlyOwner {
        MIN_BANK = amount;
    }

    /*
        This method will allow owner to fix the whitelist role
     */

    function fixWhitelist(bool state) public onlyOwner {
        whitelist_active = state;
    }

    /*
        This method will allow owner to fix the contract baseURI
     */

    function fixBaseURI(string memory newURI) public onlyOwner {
        require(!collection_locked, "DaoPunks: Collection is locked.");
        contract_base_uri = newURI;
    }

    /*
        This method will allow owner to lock the collection
     */

    function lockCollection() public onlyOwner {
        collection_locked = true;
    }

    /*
        This method will allow owner to mint tokens
     */
    function ownerMint() public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _mint(msg.sender, newTokenId);
    }
    
    /*
        These methods will add or remove from whitelist
    */

    function isWhitelisted(address _toCheck) public view returns (bool) {
        return _whitelisted[_toCheck] == true;
    }

    function addWhitelist(address _toAdd) public onlyOwner {
        _whitelisted[_toAdd] = true;
    }

    function removeWhitelist(address _toRemove) public onlyOwner {
        _whitelisted[_toRemove] = false;
    }

    /*
        This method will allow owner to get the balance of the smart contract
     */

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /*
        This method will allow owner to withdraw all ethers
     */

    function withdrawEther() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'DaoPunks: Nothing to withdraw!');
        payable(msg.sender).transfer(balance);
    }

    /**
     * Override isApprovedForAll to whitelist proxy accounts
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        override
        view
        returns (bool isOperator)
    {
        // Opensea address
        if (
            _operator == address(openseaProxyAddress)
        ) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }
}