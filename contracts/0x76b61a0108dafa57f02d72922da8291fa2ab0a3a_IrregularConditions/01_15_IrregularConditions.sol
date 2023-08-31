// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";



/*

 ______   ____    ____    ____    ____    __  __  __       ______  ____               
/\__  _\ /\  _`\ /\  _`\ /\  _`\ /\  _`\ /\ \/\ \/\ \     /\  _  \/\  _`\             
\/_/\ \/ \ \ \L\ \ \ \L\ \ \ \L\_\ \ \L\_\ \ \ \ \ \ \    \ \ \L\ \ \ \L\ \           
   \ \ \  \ \ ,  /\ \ ,  /\ \  _\L\ \ \L_L\ \ \ \ \ \ \  __\ \  __ \ \ ,  /           
    \_\ \__\ \ \\ \\ \ \\ \\ \ \L\ \ \ \/, \ \ \_\ \ \ \L\ \\ \ \/\ \ \ \\ \          
    /\_____\\ \_\ \_\ \_\ \_\ \____/\ \____/\ \_____\ \____/ \ \_\ \_\ \_\ \_\        
    \/_____/ \/_/\/ /\/_/\/ /\/___/  \/___/  \/_____/\/___/   \/_/\/_/\/_/\/ /        
                                                                                      
                                                                                      
 ____     _____   __  __  ____    ______  ______  ______   _____   __  __  ____       
/\  _`\  /\  __`\/\ \/\ \/\  _`\ /\__  _\/\__  _\/\__  _\ /\  __`\/\ \/\ \/\  _`\     
\ \ \/\_\\ \ \/\ \ \ `\\ \ \ \/\ \/_/\ \/\/_/\ \/\/_/\ \/ \ \ \/\ \ \ `\\ \ \,\L\_\   
 \ \ \/_/_\ \ \ \ \ \ , ` \ \ \ \ \ \ \ \   \ \ \   \ \ \  \ \ \ \ \ \ , ` \/_\__ \   
  \ \ \L\ \\ \ \_\ \ \ \`\ \ \ \_\ \ \_\ \__ \ \ \   \_\ \__\ \ \_\ \ \ \`\ \/\ \L\ \ 
   \ \____/ \ \_____\ \_\ \_\ \____/ /\_____\ \ \_\  /\_____\\ \_____\ \_\ \_\ `\____\
    \/___/   \/_____/\/_/\/_/\/___/  \/_____/  \/_/  \/_____/ \/_____/\/_/\/_/\/_____/
                                                                                  


Irregular Conditions
An eightfold colour story collection created by Martin Houra, which captures an appreciation of controlled chaos.
2022

irregularconditions.art

*/

contract IrregularConditions is ERC721A, IERC2981, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    event baseURIUpdated(string newBaseURL);

    constructor() ERC721A ("Irregular Conditions", "IC") {}

    bool public mintActive = false;

    uint256 public constant maxSupply = 500;
    uint256 public constant mintPrice = 0.08 ether;
    uint256 public constant maxMints = 5;
    uint256 public constant artistProofs = 10;

    address payable public withdrawalAddress;
    uint256 public royaltyFeeBp = 1500;
    
    bool public baseURILocked = false;
    string public baseURI;

    // metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    // metadata update
    function setBaseURI(string memory _url) public onlyOwner {
        require(!baseURILocked, "Metadata on IPFS are locked.");
        emit baseURIUpdated(_url);
        baseURI = _url;
    }

    // metadata lock
    function setBaseLocked() public onlyOwner returns (bool) {
        baseURILocked = true;
        return baseURILocked;
    }

    // mint on/off button
    function mintState() public onlyOwner returns(bool) {
        // mint on/off button
        mintActive = !mintActive;
        return mintActive;
    }

    function mintArtistProofs() public onlyOwner {
        require(totalSupply() == 0, "Can only mint Artist Proofs before Public Sale.");
        _mintToken(artistProofs, msg.sender, false);
    }

    function mintToken(uint256 quantity) public payable {
        require(mintActive, "Minting is not currently active.");
        require(
            quantity <= maxMints,
            "You can mint that many at once."
        );
        _mintToken(quantity, msg.sender, true);
    }

    function amountLeft() public view returns (uint256) {
        return maxSupply - totalSupply();
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setRoyaltyFeeBp(uint256 _royaltyFeeBp) public onlyOwner {
        royaltyFeeBp = _royaltyFeeBp;
    }

    function _mintToken( uint256 quantity, address mintTo, bool requirePayment) private {
        require(amountLeft() >= quantity, "Sold out.");
        
        if (requirePayment) {
            require( msg.value == quantity * mintPrice, "ETH amount not correct."
            );
        }

        _safeMint(mintTo, quantity);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Token doesn't exist.");
        return (withdrawalAddress, (salePrice * royaltyFeeBp) / 10000);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}