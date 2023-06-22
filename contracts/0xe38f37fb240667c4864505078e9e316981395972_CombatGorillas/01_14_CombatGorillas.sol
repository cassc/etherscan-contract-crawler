// SPDX-License-Identifier: MIT
























//  ▄████▄    ▄████  ▒█████   ██▀███  
// ▒██▀ ▀█   ██▒ ▀█▒▒██▒  ██▒▓██ ▒ ██▒
// ▒▓█    ▄ ▒██░▄▄▄░▒██░  ██▒▓██ ░▄█ ▒
// ▒▓▓▄ ▄██▒░▓█  ██▓▒██   ██░▒██▀▀█▄  
// ▒ ▓███▀ ░░▒▓███▀▒░ ████▓▒░░██▓ ▒██▒
// ░ ░▒ ▒  ░ ░▒   ▒ ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░
//   ░  ▒     ░   ░   ░ ▒ ▒░   ░▒ ░ ▒░
// ░        ░ ░   ░ ░ ░ ░ ▒    ░░   ░ 
// ░ ░            ░     ░ ░     ░     
// ░                                  



















pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CombatGorillas is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    mapping(address => uint256) public addressMintedBalance;
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri = "ipfs://QmPLb9tSKAikyiToc9dSeHPBPGUn64WwFWQ9B3oUcYFkq4";
    uint256 public cost = 0.07 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmountPerTx = 10;
    uint256 public nftPerAddressLimit = 10;
    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;
 

    constructor(
         
    ) ERC721("CombatGorillas", "CGOR") {

        setHiddenMetadataUri(hiddenMetadataUri);
    }

    fallback() external payable {}

    receive() external payable {}

    modifier mintCompliance(uint256 _mintAmount) {
          uint256 ownerMintedCount = addressMintedBalance[msg.sender];
          require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded" );
          require( _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
          _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
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
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[msg.sender], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[msg.sender] = true;
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
        onlyOwner
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

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }
        function setNftPerAddress(uint256 _nftPerAddressLimit)
        public
        onlyOwner
    {
        nftPerAddressLimit  =  _nftPerAddressLimit;
    }


    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
     uint256 contractBalance = address(this).balance;
     require(contractBalance > 0, "there is nothing in here");

    // marketing  wallet- 20% of balance
        (bool mkt, ) = payable(0x9919D3EC4e39Fc03B99dEBC7d46A0fEDa8EEe1D0).call{value: contractBalance * 20  / 100}("");
        require(mkt);

    // wildlife fund - 5% of balance 
        (bool wf, ) = payable(0xe55dbd4A71Be822be00B33481A99a880D18D716b).call{value: contractBalance * 5  / 100}("");
         require(wf);

           // dev wallet - 75% of balance
        (bool dev, ) = payable(0x19d0FB6d325d9d29Bc7ef6396F07843290932a76).call{value: address(this).balance }("");
        require(dev);

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