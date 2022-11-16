// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AA is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost = 0.064 ether;
    uint256 public maxSupply = 777;
    uint256 public maxMintAmountPerTx = 1;

    address internal __walletTreasury; // Address of the treasury wallet
    address internal __walletSignature; // Address of the signature wallet
    bool public mainSale = false; // Main Sale is disabled by default
    bool public paused = true;
    bool public revealed = false;

    constructor(address walletTreasury_, address walletSignature_) ERC721("Alpha Apes", "AA") {
        __walletTreasury = walletTreasury_;
        __walletSignature = walletSignature_;
        setHiddenMetadataUri("https://alphaapes-app.herokuapp.com/images/reveal.json");
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        require(!paused, "The contract is paused!");
        require(mainSale, "The main sale is close");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _mintLoop(msg.sender, _mintAmount);
    }

    function mintWL(uint256 _mintAmount,bytes memory signature) public payable mintCompliance(_mintAmount) {
        require(!paused, "The contract is paused!");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        if(!mainSale){
            require(verify(signature, msg.sender), "wallet is not whitelisted");
        }
        _mintLoop(msg.sender, _mintAmount);
    }

    function freeMint(uint256 _mintAmount,bytes memory signature) public payable mintCompliance(_mintAmount) {
        require(!paused, "The contract is paused!");
        require(verify(signature, msg.sender), "wallet is not whitelisted");
        require(supply.current() + _mintAmount <= 20, "Max supply for OG exceeded!");
        require(balanceOf(msg.sender) == 0 , 'Each address may only own one ape');
        _mintLoop(msg.sender, _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
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

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
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
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
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

    function updateMainSaleStatus(bool _mainSale) public onlyOwner {
        mainSale = _mainSale;
    }

    function withdraw() public onlyOwner {

        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    /**
   * Verify if the signature is legit
   * @param signature The signature to verify
    * @param target The target address to find
    **/
    function verify(bytes memory signature, address target) public view returns (bool) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature);
        bytes32 senderHash = keccak256(abi.encodePacked(target));

        //return (owner() == address(ecrecover(senderHash, v, r, s)));
        return (__walletSignature == address(ecrecover(senderHash, v, r, s)));
    }

    /**
    * Split the signature to verify
    * @param signature The signature to verify
    **/
    function splitSignature(bytes memory signature) public pure returns (uint8, bytes32, bytes32) {
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
        // first 32 bytes, after the length prefix
            r := mload(add(signature, 32))
        // second 32 bytes
            s := mload(add(signature, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }
        return (v, r, s);
    }

    /**
    * Set the new wallet treasury
    * @param _wallet The eth address
    **/
    function setWalletTreasury(address _wallet) external onlyOwner {
        __walletTreasury = _wallet;
    }

    /**
    * Set the new wallet signature
    * @param _wallet The eth address
    **/
    function setWalletSignature(address _wallet) external onlyOwner {
        __walletSignature = _wallet;
    }
}