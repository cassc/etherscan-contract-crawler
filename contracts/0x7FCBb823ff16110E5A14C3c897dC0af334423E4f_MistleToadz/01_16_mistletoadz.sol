// SPDX-License-Identifier: MIT
/* 

                        MISTLETOADZ

    A holiday gift from the CrypToadz by GREMPLIN team

█████████████████████████████████████████████████████████
█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
█░░░░░░░░░░░░░░░░░░░░░█████████████████░░░░░░░░░░░░░░░░░█
█░░░░░░░░░░░░░░░░░░█████████████████████████░░░░░░░░░░░░█
█░░░░░░░░░░░░░░░██████████████████████████████▒▒▒▒▒█░░░░█
█░░░░░░░░░░░░█████████████████████████████████▒▒▒▒▒█░░░░█
█░░░░░░░░░░░█████████████████████████░░░░░░░░░▒▒▒▒▒█░░░░█
█░░░░░░░░░░█████████████████████████████░░░░░░▀▀▀▀▀▀░░░░█
█░░░░░░░░░░██████████████████████████████░░░░░░░░░░░░░░░█
█░░░░░░░▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█░░░░░░░░░░░░█
█░░░░░░░▐▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█░░░░░░░░░░░░█
█░░░░░░▄█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█░█░░░░░░░░░░░█
█░░░░░█░░█▒▒▒████████████▒▒████████████▒▒▒█░░█░░░░░░░░░░█
█░░░░█░░░░█▒▒▒░░░░░░░████▒▒░░░░░░░░████▒▒█▌░░▐░░░░░░░░░░█
█░░░░▌░░░░░█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█░░░░▌░░░░░░░░░█
█░░░░▌░░░████████████████████████████████░░░░░▌░░░░░░░░░█
█░░░░▌░░░██░░░█░░░█░░░█░░░█░░░█░░░█░░░██░░░░░░█░░░░░░░░░█
█░░░░▌░░░███████████████████████████████░░░░░░░█░░░░░░░░█
█░░░░▌░░░░░░░░░░░█░░░░░░░░░░░░░░░░░▄▄▄░░░░░░░░░░▀█░░░░░░█
█░░░░█░░░░░░░░░░░░█▄░░░░█░░░░░█░░░░░░░▀░░░░░░░░░░░█▄░░░░█
█░░░░░█▄░░░░░░░░░░░░▀░░░░█░░░░░▀▄░░░░░░░░░░░█▀▀▀▀▀▀▀░░░░█
█░░░░░░░█▄░░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░░░░▀▄░░░░░░░░░█
█░░░░░░░░░▀█▄░░░░░░░░░░░░░░░▀░░░░░░░░▀▀▀▀░░░░░░░▀▄░░░░░░█
█░░░░░░░░░░░░▀▀▀█▄▄▄▄▄░░░░░░░░░░░░░░░░░░░░░░▄▄▄▄▄▄██░░░░█
█░░░░░░░░░░░░░░░░░░░░░▀▀▀▀▀▀▀▀█▄▄░░░░░░░░░░░█▄░░░░░░░░░░█
█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▀▀▀▄▄▄▄▄▄▄▄▄██▌░░░░░░░░█
█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
█████████████████████████████████████████████████████████

*/
pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MistleToadz is ERC721, Ownable, ReentrancyGuard {
    uint256 public startingBlock = 999999999; 
    string private _contractURI;
    address payable public wallet0 = 0x794B675C0e69Fe8F586909Ca98915243cF689672;
    address payable public wallet1 = 0x794B675C0e69Fe8F586909Ca98915243cF689672;
    mapping (uint256 => bool) public claimed;
    IERC721Enumerable cryptoadz = IERC721Enumerable(0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6);

    constructor() public ERC721("MistleToadz", "MistleToadz"){
    }

    modifier claimStarted {
        require(block.number >= startingBlock, "Claim hasn't started yet!");
        _;
    }

    //MINTING

    //Note: Rather than revert, tokens that have already been claimed or that are not owned by msg.sender will be skipped and the remainder minted.
    function claimMany(uint256[] memory tokenIds) external claimStarted nonReentrant {
        for (uint256 i; i < tokenIds.length; i++){
            if (cryptoadz.ownerOf(tokenIds[i]) == msg.sender && !claimed[tokenIds[i]]) {
                _mintInternal(tokenIds[i]);
            }
        }
    }

    function claimOne(uint256 tokenId) external claimStarted nonReentrant {
        require (cryptoadz.ownerOf(tokenId)==msg.sender && !claimed[tokenId],"Croak! Not your toad or already claimed!");
        _mintInternal(tokenId);
    }

    function _mintInternal(uint256 tokenId) internal {
        claimed[tokenId] = true;
        _mint(msg.sender, tokenId);
    }

    //READ FUNCTIONS
    function getAllUnclaimedTokensByWallet(address wallet) external view returns (uint256[] memory) {
        uint256 balance = cryptoadz.balanceOf(wallet);
        uint256[] memory tokenIds = new uint256[] (balance);
        uint256 count;
        for (uint256 i; i < balance; i++){
            uint256 tokenId = cryptoadz.tokenOfOwnerByIndex(wallet,i);
            if (!claimed[tokenId]){
                tokenIds[count]=tokenId;
                count++;
            }
        }
        return tokenIds; //Note: returns 0 in place of claimed tokens held by msg.sender
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    //OWNER FUNCTIONS
    function setStartingBlock(uint256 _startingBlock) external onlyOwner {
        require (_startingBlock !=0);
        startingBlock=_startingBlock;
    }

    function setWallets (address payable _wallet0, address payable _wallet1) external onlyOwner {
        require (_wallet0 != address(0) && _wallet1 != address(0));
        wallet0 = _wallet0;
        wallet1 = _wallet1;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    //ROYALTY WITHDRAWAL
    function withdrawRoyalties() external {
        Address.sendValue(wallet0,address(this).balance/3);
        Address.sendValue(wallet1,address(this).balance);
    }

    receive () external payable {
    }
}