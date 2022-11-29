// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IEscrow.sol";
import "./IModerator.sol";

contract Moderator is IModerator,ERC721,ERC721Enumerable,Ownable {
    using SafeMath for uint256;
    // max supply
    uint256 public maxSupply = 41000; 

    // mod's total score
    mapping(uint256 => uint256) public modTotalScore;

    // mod's success score
    mapping(uint256 => uint256) public modSuccessScore;

    // mod's success rate
    mapping(uint256 => uint8) public modSuccessRate;

    // mint event
    event Mint(
        uint256 indexed modId
    );

    // update score event
    event UpdateScore(
        uint256 indexed modId,
        bool indexed ifSuccess
    );

    // escrow contract address
    address payable public escrowAddress;

    constructor()  ERC721("VBHex Moderator", "MOD")  {

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,/* firstTokenId */
        uint256 batchSize
    )
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://vbhex.com/rest/V1/vc/mod/id/";
    }



    function contractURI() public pure returns (string memory) {
        return "https://vbhex.com/rest/V1/vc/mod/contract/info";
    }



    // set escrow contract address
    function setEscrow(address payable _escrow) public onlyOwner {
        IEscrow EscrowContract = IEscrow(_escrow);
        require(EscrowContract.getModAddress()==address(this),'Mod: wrong escrow contract address');
        escrowAddress = _escrow; 
    }

    // mint a new mod
    function mint() public onlyOwner {
        uint256 tokenId                     = super.totalSupply().add(1);
        require(tokenId <= maxSupply, 'Mod: supply reach the max limit!');
        _safeMint(_msgSender(), tokenId);
        // set default mod score
        modTotalScore[tokenId]   =   1;  
        // emit mint event
        emit Mint(
            tokenId
        );
    }

    // get mod's total supply
    function getMaxModId() external view override returns(uint256) {
        return super.totalSupply();
    }

    // get mod's owner
    function getModOwner(uint256 modId) external view override returns(address) {
        require(modId <= super.totalSupply(),'Mod: illegal moderator ID!');
        return ownerOf(modId);
    }

    // update mod's score
    function updateModScore(uint256 modId, bool ifSuccess) external override returns(bool) {
        //Only Escrow contract can increase score
        require(escrowAddress == msg.sender,'Mod: only escrow contract can update mod score');
        //total score add 1
        modTotalScore[modId] = modTotalScore[modId].add(1);
        if(ifSuccess) {
            // success score add 1
            modSuccessScore[modId] = modSuccessScore[modId].add(1);
        } else if(modSuccessScore[modId] > 0) {
            modSuccessScore[modId] = modSuccessScore[modId].sub(1);
        } else {
            // nothing changed
        }
        // recount mod success rate
        modSuccessRate[modId] = uint8(modSuccessScore[modId].mul(100).div(modTotalScore[modId]));
        // emit event
        emit UpdateScore(
            modId,
            ifSuccess
        );
        return true;

    }

}