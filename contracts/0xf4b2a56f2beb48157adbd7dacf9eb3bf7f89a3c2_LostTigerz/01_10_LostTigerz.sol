// SPDX-License-Identifier: MIT 
// @author: @TigerWorldsTeam
pragma solidity ^0.8.4;

import './ERC721A.sol';
import './ERC721AQueryable.sol';
import './Ownable.sol';
import './ECDSA.sol';
import './SafeMath.sol';

contract LostTigerz is ERC721A, ERC721AQueryable, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    constructor() ERC721A("Lost Tigerz", "LTIGRZ") {}

    uint32 public constant maxLostTigerz = 10000;
    uint32 public constant teamMintAmount = 80;

    uint32 public constant maxReserveWalletLimit = 6;
    uint32 public constant maxFreelistWalletLimit = 4;
    uint32 public constant maxPublicWalletLimit = 2;

    bool public teamMintComplete = false;

    bool public mintEnabled = false; 
    bool public overflowMintEnabled = false; 
    bool public publicMintEnabled = false; 

    string public baseTokenURI = "https://metadata.tigerworlds.io/losttigerz/";
    address serverPublicAddress = 0x1234d2Ec636Fb1c3aecdAC214249217CFA0FFDd9;

    function reserveMint(uint amount, uint max, bytes memory signature) external {
        require(mintEnabled, "Be patient tiger, reserve not open!");
        require((_numberMinted(msg.sender) + amount <= max) && (max <= maxReserveWalletLimit), "Max limit reached for wallet");
        require(_totalMinted() + amount <= maxLostTigerz, "All lost tigerz sucessfully lost!");
        require(verify(serverPublicAddress, _msgSender(), 0, amount, max, signature), "Only reserve minting!");
        _mint(msg.sender, amount);
    }

    function freelistMint(uint amount, uint max, bytes memory signature) external {
        require(overflowMintEnabled, "Be patient tiger, reserve not open!");
        require((_numberMinted(msg.sender) + amount <= max) && (max <= maxFreelistWalletLimit), "Max limit reached for wallet");
        require(_totalMinted() + amount <= maxLostTigerz, "All lost tigerz sucessfully lost!");
        require(verify(serverPublicAddress, _msgSender(), 1, amount, max, signature), "Only reserve minting!");
        _mint(msg.sender, amount);
    }

    function publicMint(uint amount) external {
        require(publicMintEnabled, "Be patient tiger, public not open!");
        require(_numberMinted(msg.sender) + amount <= maxPublicWalletLimit, "Max limit reached for wallet");
        require(_totalMinted() + amount <= maxLostTigerz, "All lost tigerz sucessfully lost!");
        _mint(msg.sender, amount);

    }

    //Enables reserve & freelist minting
    function flipSale() public onlyOwner {
        require(teamMintComplete, "Team mint must conclude before mint begins!");
        mintEnabled = !mintEnabled;
    }

    //Enables freelist to access leftover reserve slots
    function flipOverflowSale() public onlyOwner {
        require(mintEnabled, "Reserve mint must be enabled prior to public!");
        overflowMintEnabled = !overflowMintEnabled;
    }

    //Enables public to mint
    function flipPublicSale() public onlyOwner {
        require(mintEnabled, "Reserve mint must be enabled prior to public!");
        require(overflowMintEnabled, "Overflow mint must be enabled prior to public!");
        publicMintEnabled = !publicMintEnabled;
    }

    function teamMint() external onlyOwner {
        require(!teamMintComplete, "Team minted already concluded!");
        require(_totalMinted() + teamMintAmount <= maxLostTigerz, "All lost tigerz sucessfully lost!");
        teamMintComplete = true;
        _mint(msg.sender, teamMintAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function getMessageHash(address _to, uint _mintType, uint _amount, uint _max) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _mintType, _amount, _max));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address _signer, address _to, uint _mintType, uint _amount, uint _max, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _mintType, _amount, _max);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v ) {
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

}