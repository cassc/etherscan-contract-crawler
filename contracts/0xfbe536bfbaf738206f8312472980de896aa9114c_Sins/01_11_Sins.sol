// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/*
                       ****[email protected]@//##*[email protected]@**                      
                  *****[email protected]@//##/,,@@..**                    
                **[email protected]@@@@@@@@[email protected]@@@@@@@@@@#,,[email protected]@..***                 
              **[email protected]@##(((((((@@@@@@(((((((////#@@,,@@.....**               
           ,**[email protected]@@##((@@((%@@(((((((((//@@@@@@@@@,,[email protected]@.....**             
         **,[email protected]@###@@((((@@%((((((//@@@@@@@@@@@@@@,,,,@@.....**             
         **,[email protected]@##@@@@@((@@(((((//@@@@@@@@@@@@@@@@@@@@,,@@.......**           
       **[email protected]@##@@@@@((((##//#@@@@@@@@@@@@@@@@@@@@@@@@,,[email protected]@@....**           
     **....(@@##@@@@(((##//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,@@@......**,        
     **....(@@##@@@@###//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,[email protected]@....**,        
     **....(@@##@@#####//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##,,,@@....**,        
     **....(@@#########//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##,,,@@....**,        
     **....(@@######///@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((%%,,,[email protected]@..**,        
     **[email protected]@@@##///@@@@@@@@@@@@@@@@@&&&&&&&&&&&&@@@@((%%###,,@@..**,        
     **[email protected]@@@@@///@@@@@@@@@@@@@&&&&@@@%%%%%%@@&&&@@@@//###,,@@..**,        
       @@@@([email protected]@@@##@@@@@@@@@&&&@@[email protected]@//   @@%%@@  (@@//@@//%%%,,[email protected]@**,        
   @@  @@@@@@@@@@@##///@@@@&&&&&@@..    &&&@@%%&&@@/    @@@@///##,,@@     @@    
   @@@@@@@@@@@@@@@@@///@@@@@@&&&&&&&&&&&@@@%%%%%%&&&@@%%@@@@///%%,,[email protected]@@@@&&@@  
@@@@@&&@@@@@@@@@@@((@@@@@@@&&@@&&&%%%%%%%%%%%%%%%%%%%%%%@@@@///%%##[email protected]@@&&%%@@@@
@@@@@%%@@@@@@@@@@@((@@@##@@&&@@&&&%%%%%%%%%%%%%%%%%%%%&&%%@@@@@//##,,@@@&&%%@@&&
%%%@@%%&&@@@@@##@@((@@@##@@@@%%%%%&&%%%%%%%%%%%%%&&&&&%%&&@@@@@//%%,,..(@@%%@@%%
%%%&&@@&&@@@@@##@@@@@@@((@@@@&&&&&%%%%%%%%%%%%%%%%%%%%&&&&@@@@@//%%##,,#@@%%@@%%
%%%&&@@%%@@@@@##@@@@@@@((##@@@@@@@&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@//##,,#@@@@&&%%
%%%%%@@%%@@@@@##//@@@@@@@((((((%@@@@&&&&%%%%%%%%%%%%&&@@@@@@@@@@@//%%,,,[email protected]@&&%%
@@@%%&&@@&&@@@######///@@&&@@@@%((##((((@@@@@@@@@@@&####@@@@@@@@@@@//##/,,[email protected]@@@
&&&@@%%@@&&@@@####(((((//@@&&%%&@@@@(((((((((####(((((##@@&&@@@##@@//%%(,,[email protected]@%%
%%%&&@@%%@@&&&@@(((((((((//@@&&%%%%%@@@@(((((@@##@@%((@@%%@@///##@@//%%%##,,@@%%
@@@%%&&@@%%&@@@@((@@(((((((//@@@@@&&%%%%@@@@@((##((%@@%%&&@@(((####@@//(##,,[email protected]@
&&&@@%%&&@@&%%@@@@(((((((((((##(//@@@@&&%%%%%@@@@@@&%%&&@@//(((####@@//(%%,,,,@@
%%%&&@@@@%%&@@%%@@@@(((((((##(((####//@@@@@&&%%%%%%%&&@@//##%%%####@@//(%%##,,..
@@@@@%%&&@@&%%@@%%@@@@@((((##((///**####///@@@@@@@@@@@//##,,***##@@%%@@#//##,,..
&&&&&@@@@%%&@@%%@@&&@@@@@##((((#%%##,,,,#####((////(##**,,..%%%##@@%%@@#//%%,,,,
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { DefaultOperatorFilterer } from "./DefaultOperatorFilterer/DefaultOperatorFilterer.sol";


contract Sins is ERC721A, Ownable, ReentrancyGuard, Pausable, DefaultOperatorFilterer{

    // ====================== 🇽 VARIABLES 🇾 =======================
    uint256 public maxSupply = 5555;
    uint256 public mintPrice = 0.004 ether;
    uint256 public maxPerTxn = 10;
    uint256 public maxFree = 1;
    string public baseExtension = ".json";
    string public baseURI;
    bool public mintEnabled = false;
    bool public revealed = false;

    constructor (
    string memory _initBaseURI) 
    ERC721A("SINS", "SINS") {
        setBaseURI(_initBaseURI);
    }

    // ====================== 🖼️ MINT FUNCTIONS 🖼️ =======================
    function teamMint(address[] calldata _address, uint256 _amount) external onlyOwner nonReentrant {
        require(totalSupply() + _amount <= maxSupply, "Error: max supply reached");
        for (uint i = 0; i < _address.length; i++) {
            _safeMint(_address[i], _amount);
        }
    }

    function mint(uint256 _quantity) external payable whenNotPaused nonReentrant{
        uint256 previous = _getAux(_msgSender());  
        
        require(_quantity <= maxPerTxn, "SinsError: Cannot mint more than max per txn");
        require(mintEnabled, "SinsError: Mint is not live");
        require(totalSupply() + _quantity <= maxSupply, "SinsError: max supply reached");
        
        uint256 freeNFT = previous >= maxFree
        ? 0
        : maxFree - previous;
        uint256 paidNFT = _quantity > freeNFT
        ? _quantity - freeNFT
        : 0;
        
        require(msg.value >= mintPrice * paidNFT, "Not enough ether sent");

        _setAux(_msgSender(), uint64(previous += _quantity));
        _safeMint(msg.sender, _quantity);
    }

    
    // ====================== 🎨 BASE URI / TOKEN URI 🎨 =======================
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    
        if (revealed == false) {
            return baseURI;
        } else {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
            : "";
        }
        
    }


    // ====================== 🌊 OS OPERATOR FILTERER 🌊 =======================
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
    address from,
    address to,
    uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    // ====================== 🕹️ CONTROL FUNCTIONS 🕹️ =======================
    function amountMinted(address wallet) external view returns (uint256) {
        return _getAux(wallet);
    }

    function toggleMint() external onlyOwner nonReentrant{
        mintEnabled = !mintEnabled;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner nonReentrant{
        mintPrice = _mintPrice;
    }

    function setMaxFree(uint256 _maxFree) external onlyOwner nonReentrant{
        maxFree = _maxFree;
    }

    function setMaxPerTxn(uint256 _maxPerTxn) external onlyOwner nonReentrant{
        maxPerTxn = _maxPerTxn;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner nonReentrant {
        maxSupply = _maxSupply;
    }

    function pause() public onlyOwner nonReentrant{ 
        _pause();
    }

    function unpause() public onlyOwner nonReentrant{
        _unpause();
    }

    function setBaseURI(string memory _newURI) public onlyOwner nonReentrant{
        baseURI = _newURI;
    }

    function toggleReveal() public onlyOwner nonReentrant {
        revealed = !revealed;
    }


    // ====================== 💰 WITHDRAW CONTRACT FUNDS 💰 =======================
    function withdraw() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }
}