// SPDX-License-Identifier: no-license
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract CryptoCubs is ERC721Enumerable, Ownable {

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //  
    //                        *(/,%                                         //  
    //           **(,%,       %.%*.&                                        //
    //           &.*&.,%..,,,,,..%.,#                                       //
    //           &.//.,,,,,,,,,,,,,.%                                       // 
    //           #,.,,,,,%*,,,,,.,..,%                                      //   
    //          %.,,...(#%.,,,,%#....#                                      // 
    //          /*........,,,%%//%../,  *%%/....,..../%                     // 
    //           %........%,*#,/(..%,.%,,,,,,,,,,,,,,,,.%/%                 // 
    //             %#............*,,,,//,,,,,,,,,,,,,,,,,..%.               // 
    //               %.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,%,.&              //  
    //               */,,,,,,,,,,,,,,,,,,,,,,,,,,,%,,,,,,*#,,%              //  
    //                %.,,,,*(,,,,,,,,*,,,,,,,,,*%*,,,,,,%,,,(,             //  
    //                 /#,,,,%,,,,,,,,%,,,,,,,,,,,,,,,,,%,,,,.%             //  
    //                   %%,,*#,,,,,,%*,,,,,,(%,,,,,,,,&//,,,..%            //   
    //                    ,#.//....,#%%%%%%,,,,%,,,,,,,& /(,,,,..%          //  
    //                      %%.....#.       %*,,*%,,,,,*#  /%/,,*/#         //  
    //                      &.....%         .#...,(....(,                   // 
    //                    %,.....%        %,...,%.....%.                    //  
    //               #####%%%%%%##########%%%%%%%%#%%##########             //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    using SafeMath for uint256;
    
    address private signerWallet = 0x3051E3a779bC4b4dBE9724FE5414875E3dc286eD;
    address public cryptoWolvesContract = 0xAb83789d3f152118ebb5AA63190174AE0A6E0e6E;

    bool public mintActive = true;

    string public baseTokenURI = "ipfs://QmavYNrxA9ZXLt3zvdQu5gaMEi61zYUJBzdrimw8tGS6bc/";

    struct Parents {
        uint256 alphaId;
        uint256 betaId;
    }

    mapping (uint256 => bool) public bredIds;
    mapping (uint256 => Parents) public parentIds;

    constructor() ERC721("Crypto Wolf Cubs", "CWCB") {
    }

    ////////////////////////////////
    //          Events            //
    ////////////////////////////////
    event MintedOne(uint256 tokenId, address _to);

    ////////////////////////////////
    //      Getter functions      //
    ////////////////////////////////
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require (_exists(_tokenId), "Nonexistent token");
        return string(abi.encodePacked(
            _baseURI(),
            Strings.toString(_tokenId),
            ".json"
        ));
    }

    ////////////////////////////////
    //   Basic setter functions   //
    ////////////////////////////////
    function setBaseURI(string memory baseURI) public onlyOwner{
        baseTokenURI = baseURI;
    }

    function flipMintActive() public onlyOwner {
        mintActive = !mintActive;
    }

    function setCryptoWolvesContract(address _cryptoWolvesContract) public onlyOwner() {
        cryptoWolvesContract = _cryptoWolvesContract;
    }

    function setSignerWallet(address _signer) public onlyOwner() {
        signerWallet = _signer;
    }

    ////////////////////////////////
    //       Breed and mint       //
    ////////////////////////////////
    function _mintOne(address _to) internal {
        uint _tokenId = totalSupply();
        _safeMint(_to, _tokenId);
        emit MintedOne(_tokenId, _to);
    }

    function breed (
        uint256 alphaId,
        uint256 betaId,
        uint256 amount, 
        bytes calldata signature
    ) public {
        require(
            mintActive,
            "Minting disabled"
        );
        require (
            !bredIds[alphaId] && !bredIds[betaId], 
            "These wolves have already bred")
        ;
        require (
            _signatureWallet(
                alphaId, 
                amount, 
                signature
            ) == signerWallet, 
            "Invalid cubs count");
        require (
            IERC721(cryptoWolvesContract).ownerOf(alphaId) == msg.sender
            &&
            IERC721(cryptoWolvesContract).ownerOf(betaId) == msg.sender,
            "Not your wolves"
        );
        for (uint i = 0; i< amount; i++) {
            bredIds[alphaId] = true;
            bredIds[betaId] = true;
            parentIds[totalSupply()] = Parents({
                alphaId: alphaId,
                betaId: betaId
            });
            _mintOne(msg.sender);
        }
       
    }

    /////////////////////////////////
    //   Signature verification    //
    /////////////////////////////////
    function _signatureWallet(uint256 alphaId, uint256 amount, bytes memory _signature) internal view returns(address) {
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(
                    alphaId,
                    amount,
                    address(this)
                )
            )
        ), _signature);
    }

    

}