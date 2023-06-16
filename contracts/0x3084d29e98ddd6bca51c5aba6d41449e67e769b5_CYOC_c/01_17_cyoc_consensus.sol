// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./cyoc.sol"; 

contract CYOC_c is Ownable, ERC721Enumerable {
    using Strings for uint256;
    CYOC cyoc; 

    // mapping for tokenId => NFT content
    mapping(uint256 => CYOC.Citation) public _citations;
    // mapping for showing NFT content proposed by each address
    mapping(address => CYOC.Citation[]) public _addressProposedCitations;

    // mapping to show whether each address proposed citation relationships 
    mapping(address => bool) private _addressHasProposed;
    // list of words proposed by each address
    // mapping(address => string[]) private _wordsAddressHasProposed;

    // mapping to show whether a given tokenId is accepted/rejected 
    mapping(uint256 => bool) private _tokenHasBeenAccepted;
    mapping(uint256 => bool) private _tokenHasBeenRejected;

    // list of proposed words 
    // string[] private proposedWords; 
    mapping(string => bool) private _proposedExists;
    // list of accepted words
    // string[] private acceptedWords; 
    mapping(string => bool) private _acceptedExists;
    // list of rejected words
    // string[] private rejectedWords; 
    mapping(string => bool) private _rejectedExists;
    //mapping(uint256 => bool) private _seenValues;

    // constructor
    constructor(address payable _addr) ERC721("Conceive Yourself of Your Own Context", "CYOC") {
        // acceptedWords.push("Seth Siegelaub");
        // acceptedWords.push("SUPERFLAT");
        // acceptedWords.push("Media Art");
        _acceptedExists["Seth Siegelaub"] = true;
        _acceptedExists["SUPERFLAT"] = true;
        _acceptedExists["Media Art"] = true;
        cyoc = CYOC(_addr);
    }

    // function to propose citation relationships
    function proposeCitations(string[] calldata words1, string calldata word2) external payable { 
        // address can propose up to five word1s per word2
        require(1 <= words1.length && words1.length <= 5, "The number of cited words must be between 1 and 5."); 
        require(words1.length * 0.05 ether <= msg.value, "You must pay 0.05 ether per citation proposal."); 
        //require(!_addressHasProposed[msg.sender], "You can only submit a proposal once.");
        // check that the citing word is not already proposed
        require(!_proposedExists[word2], "Citing word has already been proposed.");
        for (uint256 i = 0; i < words1.length; i++){
            // check that the cited word is already accepted
            require(_acceptedExists[words1[i]], "Cited words must be accepted.");

            uint256 tokenId = totalSupply() + 1;
            CYOC.Citation memory c = CYOC.Citation(CYOC.Type.Proposed, words1[i], word2);
            // record NFT content
            _citations[tokenId] = c;
            // mint proposedNFT
            _safeMint(msg.sender, tokenId);
            // connect minted NFT to address
            _addressProposedCitations[msg.sender].push(c);
        }
        // record minted action 
        _addressHasProposed[msg.sender] = true;
        //_wordsAddressHasProposed[msg.sender].push(word2);
        // proposedWords.push(word2);
        _proposedExists[word2] = true;
    }

    // function to return all NFTs proposed by a given address
    function getProposedCitations(address user) external view returns (CYOC.Citation[] memory) {
        return _addressProposedCitations[user];
    }

    // function to accept proposals (tentative) 
    function acceptCitation(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId) && _citations[tokenId]._type == CYOC.Type.Proposed, "This NFT is not for proposal.");
        require(!_tokenHasBeenRejected[tokenId], "This proposal has already been rejected.");
        require(!_tokenHasBeenAccepted[tokenId], "This proposal has already been accepted.");
        // mint new tokenID
        uint256 newId = totalSupply() + 1;
        // record NFT content
        _citations[newId] = CYOC.Citation(CYOC.Type.Accepted, _citations[tokenId].word1, _citations[tokenId].word2);
        // record 'accepted' result
        _tokenHasBeenAccepted[tokenId] = true;
        // record accepted words
        // acceptedWords.push(_citations[tokenId].word2);
        _acceptedExists[_citations[tokenId].word2] = true;

        // mint acceptedNFT
        _safeMint(msg.sender, newId);
    }
    
    // function to reject proposals (tentative)
    function rejectCitation(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId) && _citations[tokenId]._type == CYOC.Type.Proposed, "This NFT is not for proposal.");
        require(!_tokenHasBeenRejected[tokenId], "This proposal has already been rejected.");
        require(!_tokenHasBeenAccepted[tokenId], "This proposal has already been accepted.");
        // mint new tokenID
        uint256 newId = totalSupply() + 1;
        // record NFT content
        _citations[newId] = CYOC.Citation(CYOC.Type.Rejected, _citations[tokenId].word1, _citations[tokenId].word2);
        // record 'rejected' result
        _tokenHasBeenRejected[tokenId] = true;
        // record rejected words
        // rejectedWords.push(_citations[tokenId].word2);
        _rejectedExists[_citations[tokenId].word2] = true;
        
        // mint rejectedNFT
        _safeMint(msg.sender, newId);
    }
    
    // tokenURI function to show NFT content
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        // get NFT content
        CYOC.Citation memory citation = _citations[tokenId];
        // generate svg image
        string memory svgImage = cyoc.generateSVGImage(citation);
        // base64 encoding for svg images
        string memory svgImageBase64Encoded = Base64.encode(bytes(svgImage));
        // generate JSON data
        string memory json = string(
            abi.encodePacked(
                '{',
                '"name": "CYOC #', tokenId.toString(), '",',
                '"description": "(', _citations[tokenId].word2, ' ', 'cites', ' ', _citations[tokenId].word1, ')', ' ', 'is hereby', ' ', cyoc.nftTypeToString(_citations[tokenId]),'.",', 
                '"image": "data:image/svg+xml;base64,', svgImageBase64Encoded, '"',
                '}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json)))); 
        //return json;
    }

    function selfDestruct() external onlyOwner {
        selfdestruct(payable(owner()));
    }

    function transferContractBalance() external onlyOwner {
        require(address(this).balance > 0, "No balance to transfer");
        payable(owner()).transfer(address(this).balance);
    }

}