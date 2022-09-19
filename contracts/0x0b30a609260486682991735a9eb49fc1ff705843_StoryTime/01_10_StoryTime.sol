// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Some old Victorian sketches, a weird telescope, a journal from 1875 left behind by a forgotten Astronomer, 
// and a story of friends, fascinated by what they see, far far away, in the sky – The Mignonverse.

// Embark to a journey with Lapin Mignon and Tagachi, following the steps of a brave lady, and creating their 
// own adventure, where imagination is the limit.

// We will embark a rocket, and full steam on a new Universe, to discover, planet by planet, brand new worlds, 
// cute, and where kindness is rewarded.

// A new kind of CryptoArt Project, generated, dynamic from hand made watercolour sketches. 

// Story Time NFT is a part of Mignonverse created by Lapin Mignon and Tagachi Studio
// All Right Reserved: Mignon Inc.

// @custom:security-contact [email protected]


contract StoryTime is ERC1155, Ownable {

    mapping(uint256 => uint256) private _totalSupply;

    uint256 constant public maxEditions = 777;
    uint256 constant public initialEditions = 17;

    uint256 public currentTokenId;

    uint256 private _price;
    mapping (uint256 => string) private _uris;

    mapping (address => uint256) public allowedListeners;

    address public multisigWallet;

    bool public isPublicMintActive;
    bool public isListenerMintActive;

    constructor() ERC1155("https://arweave.net/xQiv530FHgsfYvs4pPemFupT9-dOTUgOUzM0TmyZalU") {

        currentTokenId = 0;

        _price = 0.017 ether;

        multisigWallet = 0xEF247Fb4A0bb76398472af7729d9819bB446e4BB;

        isPublicMintActive = false;
        isListenerMintActive = true;
       
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Use your wallet to mint");
        _;
    }

    function totalSupply(uint256 tokenId) external view virtual returns (uint256) {
        return _totalSupply[tokenId];
    }

    function uri(uint256 tokenId) override public view returns (string memory){
        return(_uris[tokenId]);
    }

    function setTokenUri(uint256 tokenId, string memory tokenUri) public onlyOwner {
        _uris[tokenId] = tokenUri;
    }

    function setIsPublicMintActive() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function setIsListenerMintActive() external onlyOwner {
        isListenerMintActive = !isListenerMintActive;
    }    

    
    function addToAllowedListeners(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowedListeners[addresses[i]] = 1;
        }
    }


    function changeMultisigWallet(address multisigWallet_) external onlyOwner {
        multisigWallet = multisigWallet_;
    }

    function mintNewToken(uint256 id, uint256 amount, string memory tokenUri) public onlyOwner
    {
        if(currentTokenId < id){
            currentTokenId = id;
            _mint(msg.sender, id, amount, new bytes(0));
        } else {
            _mint(msg.sender, id, amount, new bytes(0));
        }

        _totalSupply[id] += amount;
        _uris[id] = tokenUri;
        
    }

    function mintMore(uint256 id, uint256 amount) public onlyOwner {

        _totalSupply[id] += amount;
        _mint(msg.sender, id, amount, new bytes(0));
    }


    function mintListeners(uint256 id) external payable callerIsUser {

        uint256 amount = 1;

        require(allowedListeners[msg.sender] > 0, "not eligible for listener mint");
        require(id <= currentTokenId, 'invalid token id requested');
        require(isListenerMintActive, 'minting not enabled');
        require(_totalSupply[id] + amount <= maxEditions, 'exceeds max editions');

        allowedListeners[msg.sender]--;

        _totalSupply[id]++;
        _mint(msg.sender, id, amount, new bytes(0));
    }


    function mintPublic(uint256 id, uint256 amount) external payable callerIsUser {

        require(id <= currentTokenId, 'invalid token id requested');
        require(isPublicMintActive, 'minting not enabled');
        require(msg.value >= amount * _price, 'wrong mint value');        
        require(_totalSupply[id] + amount <= maxEditions, 'exceeds max editions');

        _totalSupply[id] += amount;
        _mint(msg.sender, id, amount, new bytes(0));
    }


    function withdraw() external onlyOwner {
        uint256 _totalWithdrawal = address(this).balance;
        (bool successDao, ) = multisigWallet.call{ value: _totalWithdrawal }('');
        require(successDao, 'withdraw failed');
    }

}