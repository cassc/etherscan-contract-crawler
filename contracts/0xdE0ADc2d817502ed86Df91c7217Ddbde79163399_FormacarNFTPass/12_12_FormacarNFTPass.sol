// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FormacarNFTPass is ERC721 {
    uint256 public tokenCounter;
    uint256 maxToWlMint = 5000;
    uint256 wlMinted;
    uint256 public publicMintPrice = 0.03 ether;
    uint256 private constant maxtotalSupply = 10000;
    bytes32 public MerkleRootWL;

    bool public wlMint = false;
    bool public publicMint = false;

    constructor(
        string memory name,
        string memory symbol,
        string memory _uri,
        address _setOwner
    ) ERC721(name, symbol, _setOwner) {
        baseURI = _uri;
    }

    mapping(address => uint256) addresMintedWl;
    mapping(address => uint256) addresMintedPublic;

    function wlMintedAlready() public view returns (uint256) {
        return wlMinted;
    }

    function totalSupply() public view returns (uint256) {
        return tokenCounter;
    }

    function addMerkleRootWL(bytes32 _MerkleRoot) public onlyOwner {
        MerkleRootWL = _MerkleRoot;
    }

    /*Owner of contract can turn on/off wl mint*/
    function turnWlMint() public onlyOwner {
        wlMint = !wlMint;
    }

    /*Owner of contract can turn on/off public mint*/
    function turnPublicMint() public onlyOwner {
        publicMint = !publicMint;
    }

    function changePublicMintPrice(uint256 _price) public onlyOwner {
        publicMintPrice = _price;
    }

    function mintWL(bytes32[] calldata _merkleProof) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(wlMint == true, "Wl mint is close");
        require(wlMinted <= maxToWlMint, "Wl size was reached");
        require(
            addresMintedWl[msg.sender] < 1,
            "You have already minted max wl nft for your address"
        );
        require(
            MerkleProof.verify(_merkleProof, MerkleRootWL, leaf),
            "You are not in whitelist"
        );
        require(
            tokenCounter <= maxtotalSupply,
            "You have reched max total supply"
        );
        _safeMint(msg.sender, ++tokenCounter);
        wlMinted++;
        addresMintedWl[msg.sender] += 1;
    }

    function mintPublic() public payable {
        require(msg.value >= publicMintPrice, "Not enough ETH");
        require(publicMint == true, "Public mint didn't open");
        require(
            addresMintedPublic[msg.sender] < 1,
            "You have minted max per you address"
        );
        require(tokenCounter <= maxtotalSupply, "You reached maxtotal supply");

        _safeMint(msg.sender, ++tokenCounter);
        addresMintedPublic[msg.sender] += 1;
    }

    function setURI(string memory _set) public onlyOwner {
        baseURI = _set;
    }

    function tresuareMint(uint256 _amount) public onlyOwner {
        require(
            tokenCounter + _amount <= maxtotalSupply,
            "You reached maxtotal supply"
        );
        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, ++tokenCounter);
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function burn(uint256 _tokenid) public onlyOwner {
        _burn(_tokenid, _owner);
    }

    function checkOwner() public view returns (address) {
        return _owner;
    }

    function changeOwner(address _newowner) public onlyOwner {
        _owner = _newowner;
    }

    fallback() external payable {}

    receive() external payable {}
}