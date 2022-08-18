// SPDX-License-Identifier: MIT
// Author: etherice.eth

pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC721A.sol";
import "Whitelist.sol";

contract AlphaMutants is Ownable, ERC721A, Whitelistable {

    uint public constant MAX_NFTS = 11094;
    uint public constant GENESIS_KEYS = 1094;

    uint public MAX_QTY_PER_MINT = 10;
    uint256 public price = 0.025 ether;
    uint256 public totalGenesisMinted = 0;

    bool public hasPublicSaleStarted;
    bool public hasWLSaleStarted;
    bool public hasGenesisSaleStarted;
    bool public hasAirdropped = false;
    string public baseIPFS;
    string public baseHashURI;
    string public baseContractURI;

    mapping (address => uint) private wlCount;
    mapping (address => bool) private genesisMinted;
    bool[MAX_NFTS] public genesisTokenList;

    constructor(address _whitelistAdmin) 
        ERC721A("Alpha Mutants","AM") 
        Whitelistable(_whitelistAdmin) {
            baseIPFS = "https://ipfs.io/ipfs/";
    }

///////////////////////////////////  Getters  ////////////////////////////////////////////////////////

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseHashURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseHashURI;
    }

    function getWLMintedForAddress(address _wlAddress) public view returns(uint) {
        return wlCount[_wlAddress];
    }

    function hasAddressMigrated(address _wlAddress) public view returns(bool) {
        return genesisMinted[_wlAddress];
    }

    function isTokenGenesis(uint256 _tokenID) public view returns(bool) {
        return genesisTokenList[_tokenID];
    }

    function tokenURI(uint256 _tokenID) override public view returns (string memory) {
        return string(abi.encodePacked(baseIPFS, baseHashURI, "/", Strings.toString(_tokenID)));
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) internal view returns (uint256) {
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        // Execution should never reach this point.
        revert();
    }

    function numGenesisTokens() public view returns(uint256) {
        return totalGenesisMinted;
    }

    function numNonGenesisTokens() public view returns(uint256) {
        return totalSupply() - totalGenesisMinted;
    }

///////////////////////////////////  Seters  ////////////////////////////////////////////////////////

    function setBaseURI(string memory _newBaseHashURI) public onlyOwner {
        baseHashURI = _newBaseHashURI;
    }

    function setBaseIPFS(string memory _baseIPFS) public onlyOwner {
        baseIPFS = _baseIPFS;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        baseContractURI = _contractURI;
    }

    function set_MAX_QTY_PER_MINT(uint256 _newMaxPerMint) public onlyOwner {
        MAX_QTY_PER_MINT = _newMaxPerMint;
    }

    function startPublicSale() public onlyOwner { 
        hasPublicSaleStarted = true;
    }

    function pausePublicSale() public onlyOwner {
        hasPublicSaleStarted = false;
    }

    function startWLSale() public onlyOwner {
        hasWLSaleStarted = true;
    }

    function pauseWLSale() public onlyOwner {
        hasWLSaleStarted = false;
    }

    function startGenesisSale() public onlyOwner {
        hasGenesisSaleStarted = true;
    }

    function pauseGenesisSale() public onlyOwner {
        hasGenesisSaleStarted = false;
    }

    function updatePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

///////////////////////////////////  Minting  ////////////////////////////////////////////////////////

    function mintGenesis(uint256 _numNFTz, bytes memory _proof) public isWhitelisted(keccak256(
            abi.encodePacked(
                _numNFTz,
                msg.sender
            )
        ), _proof) {
        require(hasGenesisSaleStarted, "Genesis drop hasn't started");
        require(!genesisMinted[msg.sender], "Address has already minted Genesis keys");
        require(totalGenesisMinted + _numNFTz <= GENESIS_KEYS, "Exceeds number of Genesis Keys");

        uint tokenNum = totalSupply();
        for (uint i = tokenNum; i < tokenNum + _numNFTz; i++) {
            genesisTokenList[i] = true;
        }

        totalGenesisMinted += _numNFTz;
        genesisMinted[msg.sender] = true;
        _safeMint(msg.sender, _numNFTz);
    }

    function mintMultiWLNFT(uint256 _numNFTz, bytes memory _proof, uint256 _maxWLForAccount) public payable isWhitelisted(keccak256(
            abi.encodePacked(
                msg.sender,
                _numNFTz,
                _maxWLForAccount
            )
        ), _proof) {
        require(hasWLSaleStarted, "Drop hasn't started");
        require(wlCount[msg.sender] + _numNFTz <= _maxWLForAccount, "Exceeded max allowed mint");
        require(numNonGenesisTokens() + _numNFTz <= MAX_NFTS - GENESIS_KEYS, "Exceeds MAX_NFTz - GENESIS_KEYS");
        require(msg.value >= price * _numNFTz, "Ether value sent is below the price");

        wlCount[msg.sender] += _numNFTz;
        _safeMint(msg.sender, _numNFTz);
    }

    function mintNFT(uint256 _numNFTz) public payable {
        require(hasPublicSaleStarted, "Drop hasn't started");
        require(_numNFTz <= MAX_QTY_PER_MINT, "You can mint minimum 1, maximum 10 NFTz per mint");
        require(numNonGenesisTokens() + _numNFTz <= MAX_NFTS - GENESIS_KEYS, "Exceeds MAX_NFTz - GENESIS_KEYS");
        require(msg.value >= price * _numNFTz, "Ether value sent is below the price");

        _safeMint(msg.sender, _numNFTz);
    }

    function reserveAirdrop() public onlyOwner {
        require(!hasPublicSaleStarted, "Sale has already started");
        require(!hasAirdropped, "You can only airdrop once");
        // Reserved for airdrops and giveaways
        for (uint256 i = 0; i < 10; i++){
            genesisTokenList[i] = true;
        }
        totalGenesisMinted += 10;
        _safeMint(msg.sender, 20);
    }

///////////////////////////////////  Withdraw  ////////////////////////////////////////////////////////

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}