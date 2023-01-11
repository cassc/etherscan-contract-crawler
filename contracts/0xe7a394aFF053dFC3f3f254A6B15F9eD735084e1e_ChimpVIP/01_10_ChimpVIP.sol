// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ERC721{
    function tokensOfOwner(address owner)
        external
        view
        returns (string[] memory ownerTokens);
}

// implements the ERC721 standard
import "tiny-erc721/contracts/TinyERC721.sol";

contract ChimpVIP is TinyERC721{
    
    uint256 private MAX_TOKENS = 20000;
    bool private claimActive = true;

    address payable private _owner;

    mapping(string => bool) internal claimed;

    ERC721 mbContract = ERC721(0x9261B6239a85348E066867C366d3942648e24511);
    ERC721 bbContract = ERC721(0x6F1EEa7A85B0773abb2b3adf536B0225d2092F22);
    
    string private tokenURL = "https://invariantlabs.mypinata.cloud/ipfs/QmQXoYeEJy9j4hKkDHCb9XKYtqWXMVbQXQcBJqtgzennC2/token.json";

    constructor() TinyERC721("CVIP", "ChimpVIP", MAX_TOKENS) {
        _owner = payable(msg.sender);
    }

    function claim() external payable {
        require(claimActive == true, "Claim are currently close");
        require(totalSupply() < MAX_TOKENS, "Claim Over");
        
        string[] memory mbTokens = mbContract.tokensOfOwner(msg.sender);
        string[] memory bbTokens = bbContract.tokensOfOwner(msg.sender);
        uint256 totalClaim = 0;

        for (uint i=0; i< mbTokens.length; i++) {
            if (claimed[mbTokens[i]] == false) {
                claimed[mbTokens[i]] = true;
                totalClaim++;
            }
        }

        for (uint i=0; i< bbTokens.length; i++) {
            if (claimed[bbTokens[i]] == false) {
                claimed[bbTokens[i]] = true;
                totalClaim++;
            }
        }

        require(totalClaim > 0, "No tokens to Claim");
       _mint(msg.sender, totalClaim);
        
    }

    function setTokenURL(string memory url) public {
        require(msg.sender == _owner, "Only the owner can change the URL");
        tokenURL = url;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        return tokenURL;
    }

    function toogleClaim() public {
        require(msg.sender == _owner, "Only the owner can toggle the claim");

        claimActive = !claimActive;
    }

    function statusClaim() public view returns (bool status){
       return (claimActive);
    }
}