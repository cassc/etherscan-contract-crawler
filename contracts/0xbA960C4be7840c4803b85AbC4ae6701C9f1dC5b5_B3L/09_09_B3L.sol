//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//IMPORT IERC721
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error Paused();
error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error TokenAlreadyUsed();
error ArraysDontMatch();
error NotOwner();
error Soulbound();
contract B3L is ERC721AQueryable, Ownable  {

    /*///////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/

    bool public useSameBaseURIForAllTokens;
    string public sameUriToUseForAllTokens =  "https://b3l-staking-data.s3.amazonaws.com/metadata.json";
    string public baseURI;
    string public uriSuffix = ".json";
    bool private paused;

    //0 -> whitelist :: 1->public

    address private signer = 0x1522BbCC7D9247e2131212558Df31362Ec0Da5A2;
    IERC721 private constant B3LOG = IERC721(0xc0e68379A12601596bB091EB58eE4371214f9873);
    mapping(uint => bool) private originalIdUsed;
    
    mapping(uint => Token) private tokens;
    struct Token {
        bool init;
        uint96 childId;
        uint96 parentId;
    }



    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() ERC721A("stApe", "STAPE") {
    }


    function togglePause() external onlyOwner {
        paused = !paused;
    }


    /*///////////////////////////////////////////////////////////////
                          MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function mint(uint[] calldata tokenIds) external {
        if(paused)
            revert Paused();
        
        uint supply = totalSupply() + _startTokenId();
        
        for(uint i; i<tokenIds.length;++i){
            uint originalTokenId = tokenIds[i];
            //Check Ownership
            if(B3LOG.ownerOf(originalTokenId) != msg.sender)
                revert NotOwner();
            //Make sure not used
            if(originalIdUsed[originalTokenId]){
                revert TokenAlreadyUsed();
            }
            //Set it To Used
            originalIdUsed[originalTokenId] = true;
            //Set Parent Data For Off-Chain Lookup
            tokens[supply] = Token(true,uint96(supply), uint96(originalTokenId));
            ++supply;

            
        }
        _mint(msg.sender,tokenIds.length);
    }

    function getAllTokens() external view returns(Token[] memory){
        uint supply = totalSupply() + _startTokenId();
        Token[] memory allTokens = new Token[](supply);
        for(uint i; i<supply;++i){
            allTokens[i] = tokens[i];
        }
        return allTokens;
    }

    function _startTokenId() internal view override(ERC721A) virtual returns (uint256) {
        return 1;
    }


    /*///////////////////////////////////////////////////////////////
                          MINTING UTILITIES
    //////////////////////////////////////////////////////////////*/


    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function toggleUseSameBaseURIForAllTokens() external onlyOwner {
        useSameBaseURIForAllTokens = !useSameBaseURIForAllTokens;
    }
    function setSameUriToUseForAllTokens(string memory _sameUriToUseForAllTokens) external onlyOwner {
        sameUriToUseForAllTokens = _sameUriToUseForAllTokens;
    }
    /*///////////////////////////////////////////////////////////////
                                METADATA
    //////////////////////////////////////////////////////////////*/

    function tokenURI(
        uint256 tokenId
    ) public view override(IERC721A, ERC721A) returns (string memory) {
        if(useSameBaseURIForAllTokens) {
            return  sameUriToUseForAllTokens;
    }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(tokenId),
                        uriSuffix
                    )
                )
                : "";
    }


    //**SOULBOUND**/
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A) {
        if(from != address(0)) {
            revert Soulbound();
        }
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721A,ERC721A) {
        revert Soulbound();
    }

    function approve(address to, uint256 tokenId) public payable  override(IERC721A,ERC721A) {
        revert Soulbound();
    }
}