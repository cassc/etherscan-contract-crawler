// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/*                                                                                                                                            
                              **••%%%&&@@@&&&%%%•***                             
                         *•%&@@@@@@@@@@@@@@@@@@@@@@@@%•**                        
                     *•&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%•*                    
                  *•&@@@@@@@@@@@@@@@@@@&•%&@@@@@@@@@@@@@@@@@@%*                  
                *%@@@@@@@@@@@@@@@@@@%+*    *•%@@@@@@@@@@@@@@@@@&•*               
              *%@@@@@@@@@@@@@@@@%•*  *•% *%•*  *•&@@@@@@@@@@@@@@@@•              
             %@@@@@@@@@@@@@@&•*  *•%@@@@ *@@@@•   **%&@@@@@@@@@@@@@@•            
           •@@@@@@@@@@@@%•*  *•&@@@@@@@@ *@&•  +%@%•*  *•&@@@@@@@@@@@&*          
          %@@@@@@@@@@%*  *•%@@@@@@@@@@@@ *%  •@@@@@@@@%*  **%@@@@@@@@@@•         
        *&@@@@@@@@@@@  •@@@@@@@@@@@@@@@@   *%@@@@&%+**   *  *@@@@@@@@@@@%        
        &@@@@@@@@@@@@  %@@@@@@@@@@@@@@@@   %@@&•* **•%&@@@• *@@@@@@@@@@@@%       
       &@@@@@@@@@@@@@  %@@@@@@@@@@@@@@@@  •@%* *%@@@@@@@@@• *@@@@@@@@@@@@@•      
      •@@@@@@@@@@@@@@  %@@@@@@@@@@@@@@@@  %* *%@@@@@%%•**** *@@@@@@@@@@@@@@*     
     *@@@@@@@@@@@@@@@  %@@@@@@@@@@@@@@@@    •@@@%+*  **•••* *@@@@@@@@@@@@@@%     
     •@@@@@@@@@@@@@@@  %@@@@@@@@@@@@@@@&   %@&+  *•&@@@@@@• *@@@@@@@@@@@@@@@*    
     %@@@@@@@@@@@@@@@  %@@@@@@@@@@@@@@@•  •&* *•&@@@@@@@@@• *@@@@@@@@@@@@@@@•    
    *@@@@@@@@@@@@@@@@  %@@@@@@@@@@@@@@&   • *%@@@@@@@@@@@@• *@@@@@@@@@@@@@@@%    
    *@@@@@@@@@@@@@@@@  %@@@@@@@@@@@@@%     *&@@@@@@@@@@@@@• *@@@@@@@@@@@@@@@%    
    *@@@@@@@@@@@@@@@@  %@@@@@@@@@@@@•  •  *@@@@@@@@@@@@@@@• *@@@@@@@@@@@@@@@%    
     &@@@@@@@@@@@@@@@  %@@@@@@@@@&•* *&•  %@@@@@@@@@@@@@@@• *@@@@@@@@@@@@@@@•    
     •@@@@@@@@@@@@@@@  %@@@@@@&•*  +&@%  *@@@@@@@@@@@@@@@@• *@@@@@@@@@@@@@@@*    
     *@@@@@@@@@@@@@@@  *•+**  **•&@@@•   *@@@@@@@@@@@@@@@@• *@@@@@@@@@@@@@@%     
      %@@@@@@@@@@@@@@  **=••%&@@@@@&* *% *@@@@@@@@@@@@@@@@• *@@@@@@@@@@@@@@*     
      *&@@@@@@@@@@@@@  %@@@@@@@@@%* *%@• *@@@@@@@@@@@@@@@@• *@@@@@@@@@@@@@%      
       *@@@@@@@@@@@@@  %@@@@@&•*  *%@@&  *@@@@@@@@@@@@@@@@• *@@@@@@@@@@@@%       
        *&@@@@@@@@@@@  ****  **•&@@@@%   *@@@@@@@@@@@@@@@@• *@@@@@@@@@@@%        
         *&@@@@@@@@@@•*   +%@@@@@@@@•  % *@@@@@@@@@@@@&•*  *%@@@@@@@@@@%         
           %@@@@@@@@@@@&%** *•%@@&•  =&@ *@@@@@@@@@%** *+%@@@@@@@@@@@@=          
            *&@@@@@@@@@@@@@%•*  *  •&@@@ *@@@@@%•*  *•&@@@@@@@@@@@@@%*           
              •@@@@@@@@@@@@@@@@%•* **%&@ *@&•*  *•%@@@@@@@@@@@@@@@&*             
                *%@@@@@@@@@@@@@@@@@%•*      *•&@@@@@@@@@@@@@@@@@%*               
                  *•@@@@@@@@@@@@@@@@@@@%=•%@@@@@@@@@@@@@@@@@@&•*                 
                     +%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%*                    
                        *•%@@@@@@@@@@@@@@@@@@@@@@@@@@@&%=*                       
                            **•%%&@@@@@@@@@@@@@&&%•**                            
*/

contract Gummies is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer, ERC2981 {

    /* Variables */

    uint256 public mintPrice = 0.00 ether;
    uint128 public maxMintsPerTxn = 5;
    uint128 public maxSupply = 20000;
    string private _baseTokenURI;
    bool private _paused = true;
    address private _royaltyAddress = 0xF8F9B4A0Eb286ac2493723FAFD7b92Dee7d1a2EB;
    uint96 private _royaltyFee = 500;
    
    /* Construction */

    constructor() ERC721A("VitalFusion Labs: Gummies", "VFLG") {
        _setDefaultRoyalty(_royaltyAddress, _royaltyFee);
    }

    /* Config */

    /// @notice Gets the total minted
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /// @notice Gets all required config variables
    function config() external view returns(uint256, uint128, uint128, uint256, bool) {
        return (mintPrice, maxMintsPerTxn, maxSupply, _totalMinted(), _paused);
    }

    /* Mint */

    /// @notice Public mint function that accepts a quantity.
    /// @dev Mint function with price and maxMints checks.
    function mint(uint256 quantity) external payable nonReentrant {
        require(_paused == false, "Cannot mint while paused");
        require(msg.value == quantity * mintPrice, "Must send exact mint price.");
        require(quantity <= maxMintsPerTxn, "Cannot mint over maximum allowed mints per transaction");
        _internalMint(msg.sender, quantity);
    }

    /// @notice Minting functionality for the contract owner.
    /// @dev Owner mint with no checks other than those included in _internalMint()
    function ownerMint(uint256 quantity) external onlyOwner nonReentrant {
        _internalMint(msg.sender, quantity);
    }

    /// @notice Airdrop functionality for the contract owner.
    /// @dev Owner airdrop with no checks other than those included in _internalMint()
    function ownerAirdrop(address[] memory wallets, uint[] calldata tokens) external onlyOwner nonReentrant {
        require(wallets.length == tokens.length, "Airdrop wallets must have assocaited token assignment.");
        uint256 w;
        for (w = 0; w < wallets.length; w++) {
            _internalMint(wallets[w], tokens[w]);
        }
    }

    /// @dev Internal mint function that runs basic max supply check.
    function _internalMint(address to, uint256 quantity) private {
        require(_totalMinted() + quantity <= maxSupply, "Exceeded max supply");
        _safeMint(to, quantity);
    }

    /* Metadata */

    /// @dev Override to pass in metadata URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* Ownership */

    /// @notice Gets all the token IDs of an owner
    /// @dev Should not be called internally. Runs a simple loop to calcute all the token IDs of a specific address.
    function tokensOfOwner(address owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;
            uint256 id;

            for (id = 0; id < total; id++) {
                if (ownerOf(id) == owner) {
                    result[resultIndex] = id;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @notice Prevents ownership renouncement
    function renounceOwnership() public override onlyOwner {}

    /* Interface Support */

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /* Operator Filter */

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) payable public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) payable public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /* Fallbacks */

    receive() payable external {}
    fallback() payable external {}

    /* Owner Functions */

    /// @notice Sets the royalty fee
    function setRoyaltyFee(uint96 feeNumerator) external onlyOwner {
        _royaltyFee = feeNumerator;
        _setDefaultRoyalty(_royaltyAddress, _royaltyFee);
    }

    /// @notice Sets the royalty address
    function setRoyaltyAddress(address royaltyAddress) external onlyOwner {
        _royaltyAddress = royaltyAddress;
        _setDefaultRoyalty(_royaltyAddress, _royaltyFee);
    }

    /// @notice Sets the mint price in WEI
    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    /// @notice Sets the max supply of the collection
    function setMaxSupply(uint128 supply) external onlyOwner {
        maxSupply = supply;
    }

    /// @notice Sets the maximum number of tokens per mint
    function setMaxMintsPerTxn(uint128 maxMints) external onlyOwner {
        maxMintsPerTxn = maxMints;
    }

    /// @notice Sets the Token URI for the Metadata
    function setTokenURI(string memory uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    /// @notice Sets the public mint to paused or not paused
    function setPaused(bool pause) external onlyOwner {
        _paused = pause;
    }

    /* Funds */

    /// @notice Fund distribution function.
    /// @dev Pays out to the owner
    function distributeFunds() external onlyOwner nonReentrant {
        if(address(this).balance > 0) {
            (bool sent,) = msg.sender.call{value: address(this).balance}("");
            require(sent, "Failed to distribute remaining funds.");
        }
    }

    /// @notice ERC20 fund distribution function.
    /// @dev Pays out to the owner
    function distributeERC20Funds(address tokenAddress) external onlyOwner nonReentrant {
        IERC20 tokenContract = IERC20(tokenAddress);

        if(tokenContract.balanceOf(address(this)) > 0) {
            tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
        }
    }
}