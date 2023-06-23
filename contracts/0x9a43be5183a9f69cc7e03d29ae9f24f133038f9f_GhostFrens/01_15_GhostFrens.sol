// SPDX-License-Identifier: MIT

// boo

pragma solidity >=0.8.9;

import "./Delegated.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GhostFrens  is ERC721, Delegated, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private supply;
    bytes32 public merkleRoot =
        0xf1e6b85d110e0557401c0a71950ce4a6279a3889ac2b77814466aa750b19ac7b;
    mapping(address => uint256) public addressMintedBalance;
    string public uriPrefix = "ipfs://notyet/";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri =
        "ipfs://QmZAt37LqQYQA3bxXNvYXiguAsbvsBMiKGf7a4f3Ep8AUN";
    uint256 public cost = 0.03 ether;
    uint256 public maxSupply = 5555;
    uint256 public maxMintAmountPerTx = 3;
    uint256 public nftPerAddressLimit = 3;
    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;
    address public treasuryWallet = 0x93b1778c7460A0bc56665dC7b64193E440CD582f;
    address public lazWallet = 0xED8b0B553188983Ae8743F3786d04e754a73cD3E;
    address public devWallet = 0xeB2B7dbf1D37B1495f855aCb2d251Fa68e1202ce;
    uint256 public laz = 35;

    constructor() ERC721("Ghost Frens", "GHOSTFRENS") {}

    modifier mintCompliance(uint256 _mintAmount) {
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(
            ownerMintedCount + _mintAmount <= nftPerAddressLimit,
            "max NFT per address exceeded"
        );
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );
        _mintLoop(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        _mintLoop(msg.sender, _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        external
        onlyDelegates
    {
        _mintLoop(_receiver, _mintAmount);
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

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyDelegates {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyDelegates {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyDelegates
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setNftPerAddress(uint256 _nftPerAddressLimit)
        public
        onlyDelegates
    {
        nftPerAddressLimit = _nftPerAddressLimit;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyDelegates {
        maxSupply = _maxSupply;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyDelegates
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyDelegates {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyDelegates {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyDelegates {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyDelegates {
        merkleRoot = _merkleRoot;
    }

    function setTreasuryWallet(address _treasuryWallet) external onlyDelegates {
        treasuryWallet = _treasuryWallet;
    }

    function setLazWallet(address _lazWallet) external onlyDelegates {
        lazWallet = _lazWallet;
    }


    function setWhitelistMintEnabled(bool _state) public onlyDelegates {
        whitelistMintEnabled = _state;
    }





    function withdraw() public onlyDelegates nonReentrant {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "there is nothing in here");
        uint256 totals = totalSupply();
        if (totals > 5554) {
            laz = 60;
        }
        (bool lz, ) = payable(devWallet).call{value: (contractBalance * 100) / 1000 }("");
        require(lz, "Transfer failed");

        (bool dv, ) = payable(lazWallet).call{value: (contractBalance * laz) / 1000}("");
        require(dv, "Transfer failed");

        (bool wd, ) = payable(treasuryWallet).call{value: address(this).balance}("");
        require(wd, "Transfer failed");
    }




    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            addressMintedBalance[msg.sender]++;
            _safeMint(_receiver, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

  
}

/////////////////////////////////////
// always prevent triangle attacks!
//  <|>   <|>  <|>
// rpatterson.eth
////////////////////////////////////