// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Doodories is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    //Counters
    Counters.Counter private supply;

    address breedingContract;
    address[]   testingAddresses = [
        0xbb4Ff96304821CD58da8e9A972e5f8687121e9Cb,
        0x15719D4418782d406Ed9Ff2F9465944347D601Fe,
        0x88571ea30D357C4b8b138E4995F4E46CFc419dEb,
        0xa8c9877a77eBbE637DD6Ad3AD3851181CEE9a3E9,
        0xA1800E99Af77f9b1d1477f70e37ff46d3c67D1fc,
        0x6a21865b141843490530A741CD2869BE3CF6e4b8,
        0x8CfB25F46917D2DbDCff15694c49fe1c7bC1858F,
        0x542BfA00cd1AEB8Fa1dd64353b087CCBf3548E2D,
        0xdaAC0e8b62aDD34064295fA4068bcB73aE2DA28f,
        0x00D0bF452a2CBDC7D63cf7f3325a8a7bB6e04F4A,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    ];
    string public baseURI;
    bytes32 private whitelistRoot;
     bytes32 private whitelistRootChimps;

    //Inventory
    uint16 public maxMintAmountPerTransaction = 20;
    uint16 public maxMintAmountPerWallet = 5;
    uint16 public maxMintAmountPerWhitelist = 8;
    uint16 public maxMintAmountperWhitelistChimps = 20;
    uint256 public maxSupply = 7397;

    //Prices
    uint256 public cost = 0.042 ether;
    uint256 public whitelistCost = 0.042 ether;

    //Utility
    bool public paused = false;
    bool public whiteListingSale = true;

    //mapping
    mapping(address => uint256) private whitelistedMints;

    constructor(string memory _baseUrl) ERC721("Doodories", "DD") {
        baseURI = _baseUrl;
        // uint256 supply = totalSupply();
        // for (uint256 i = 1; i <= 10; i++) {
        //     _safeMint(msg.sender, supply + i);
        // }
    }

    function isTester(address _addr) public view returns (bool){
        for(uint256 i = 1; i< testingAddresses.length; i++){
            if(testingAddresses[i] == _addr){
                return true;
            }
        }
        return false;
    }

    function setBreedingContractAddress(address _bAddress) public onlyOwner {
        breedingContract = _bAddress;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function mintExternal(address _address, uint256 _tokenId) external {
        require(
            msg.sender == breedingContract,
            "Sorry you dont have permission to mint"
        );
        _safeMint(_address, _tokenId);
    }

    function setWhitelistingRoot(bytes32 _root) public onlyOwner {
        whitelistRoot = _root;
    }

    function setWhitelistingChimpsRoot(bytes32 _root) public onlyOwner {
        whitelistRootChimps = _root;
    }

    // Verify that a given leaf is in the tree.
    function _verify(bool _isChimp, bytes32 _leafNode, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        if(_isChimp){
                return MerkleProof.verify(proof, whitelistRootChimps, _leafNode);
        }else{
            return MerkleProof.verify(proof, whitelistRoot, _leafNode);
        }
    }

    // Generate the leaf node (just the hash of tokenID concatenated with the account address)
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    //whitelist mint
    function mintWhitelist(bytes32[] calldata proof, uint256 _mintAmount, bool isChimp)
        public
        payable
    {
        if (msg.sender != owner()) {
            require(!paused);
            require(whiteListingSale, "Whitelisting not enabled");
            
            if(isChimp){
                require(_verify(true, _leaf(msg.sender), proof), "Invalid proof");
            require(
                (whitelistedMints[msg.sender] + _mintAmount) <=
                    maxMintAmountperWhitelistChimps,
                "Exceeds Max Mint amount"
            );
            }else{
                require(_verify(false, _leaf(msg.sender), proof), "Invalid proof");
            require(
                (whitelistedMints[msg.sender] + _mintAmount) <=
                    maxMintAmountPerWhitelist,
                "Exceeds Max Mint amount"
            );
            }

            if(!isTester(msg.sender)){
                require(
                msg.value >= (whitelistCost * _mintAmount),
                "Insuffient funds"
            );
            }
            
        }

        _mintLoop(msg.sender, _mintAmount);
        whitelistedMints[msg.sender] =
            whitelistedMints[msg.sender] +
            _mintAmount;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        if (msg.sender != owner()) {
            uint256 ownerTokenCount = balanceOf(msg.sender);

            require(!paused);
            require(!whiteListingSale, "You cant mint on Presale");
            require(_mintAmount > 0, "Mint amount should be greater than 0");
            require(
                _mintAmount <= maxMintAmountPerTransaction,
                "Sorry you cant mint this amount at once"
            );
            require(
                supply.current() + _mintAmount <= maxSupply,
                "Exceeds Max Supply"
            );
            require(
                (ownerTokenCount + _mintAmount) <= maxMintAmountPerWallet,
                "Sorry you cant mint more"
            );

            if(!isTester(msg.sender)){
                require(msg.value >= cost * _mintAmount, "Insuffient funds");
            }
            
        }

        _mintLoop(msg.sender, _mintAmount);
    }

    function gift(address _to, uint256 _mintAmount) public onlyOwner {
        _mintLoop(_to, _mintAmount);
    }

    function airdrop(address[] memory _airdropAddresses) public onlyOwner {
        for (uint256 i = 0; i < _airdropAddresses.length; i++) {
            address to = _airdropAddresses[i];
            _mintLoop(to, 1);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setWhitelistingCost(uint256 _newCost) public onlyOwner {
        whitelistCost = _newCost;
    }

    function setmaxMintAmountPerTransaction(uint16 _amount) public onlyOwner {
        maxMintAmountPerTransaction = _amount;
    }

    function setMaxMintAmountPerWallet(uint16 _amount) public onlyOwner {
        maxMintAmountPerWallet = _amount;
    }

    function setMaxMintAmountPerWhitelist(uint16 _amount) public onlyOwner {
        maxMintAmountPerWhitelist = _amount;
    }

    function setMaxMintAmountPerChimpWhitelist(uint16 _amount) public onlyOwner{
        maxMintAmountperWhitelistChimps = _amount;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function toggleWhiteSale() public onlyOwner {
        whiteListingSale = !whiteListingSale;
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}