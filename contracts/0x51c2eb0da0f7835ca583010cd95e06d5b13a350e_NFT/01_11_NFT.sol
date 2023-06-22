// SPDX-License-Identifier: MIT


// ●vvvv●
// NomNOMn0mNOMnomNOMn0mNoMNomNOMn0mNOMnomNOMn0mNoMNomNOMn0mNOMnomNOMn0mNoM
// NomNOMn0mNOMnomNOMn0mNoMNomNOMn0mNOMnomNOMn0mNoMNomNOMn0mNOMnomNOMn0mNoM
// NomNOMn0mNOMnomNOMn0mNoMNomNOMn0mNOMnomNOMn0mNoMNomNOMn0mNOMnomNOMn0mNoM
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract NFT is ERC721A, Ownable {

    // collection details
    uint256 public constant price = 0 ether;
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant MAX_NOMNOMS_PER_TX = 3;
    uint256 public constant MAXNOMNOMS = 3;

    // variables and constants
    string public baseURI = 'ipfs://QmWRrzprsjZCs3TaiD99qMNdi3RpHD1ErGCyVRR2WhLqT8/';
    bool public isMintActive = false;
    mapping(address => uint256) public FreeNomNomsPerAddress;
    address public Wallet = 0x71643A9D5D300F10CebBf762D18676D26BD02202;

    constructor() ERC721A("NomNomSharks", "NomNomSharks") {

    }

    function mint(uint256 _quantity) external payable {
        // active check
        require(isMintActive
            , "Nom Nom Sharks: public mint is not active");
        // supply check
        require(_quantity + totalSupply() < MAX_SUPPLY
            , "Nom Nom Sharks: not enough remaining to mint this many");
        // Max Mint Check
        require(_quantity <= MAX_NOMNOMS_PER_TX
            , "Nom Nom Sharks: max mints per transaction exceeded, you can only mint 3");
        // Amount to mint Check
        require(_quantity > 0
            , "Nom Nom Sharks: Must mint at least 1");
        require(FreeNomNomsPerAddress[msg.sender] + _quantity <= MAXNOMNOMS
            , "Nom Nom Sharks: max 3 mints per address exceeded");
        FreeNomNomsPerAddress[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function setWallet(address _newWallet) external onlyOwner {
        Wallet = _newWallet;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function toggleMint() public onlyOwner {
        isMintActive = !isMintActive;
    }

    function devMint() external onlyOwner {
        _safeMint(_msgSender(), 100);
    }

    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0
            , "Nom Nom Sharks: nothing to withdraw");

        uint256 _balance = address(this).balance;

        // wallet
        (bool walletSuccess, ) = Wallet.call{
            value: _balance }("");
        require(walletSuccess
            , "Nom Nom Sharks: withdrawal failed");

    }


}