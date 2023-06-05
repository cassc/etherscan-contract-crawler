// SPDX-License-Identifier: MIT
 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                     //
//                                                                                                                     //
//     ____    ____   ______    ______  ____    ____            ___       ___    ___  _           _          __        //
//    |_   \  /   _|.' ___  | .' ___  ||_   \  /   _|         .'   `.   .' ..] .' ..](_)         (_)        [  |       //
//      |   \/   | / .'   \_|/ .'   \_|  |   \/   |          /  .-.  \ _| |_  _| |_  __   .---.  __   ,--.   | |       //
//      | |\  /| | | |       | |         | |\  /| |          | |   | |'-| |-''-| |-'[  | / /'`\][  | `'_\ :  | |       //
//     _| |_\/_| |_\ `.___.'\\ `.___.'\ _| |_\/_| |_         \  `-'  /  | |    | |   | | | \__.  | | // | |, | |       //
//    |_____||_____|`.____ .' `.____ .'|_____||_____|         `.___.'  [___]  [___] [___]'.___.'[___]\'-;__/[___]      //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                     .M                         .MM]                                 //
//                                                   .MMM]                      .MMMMM]                                //
//                                                 .MMMMMb                    [email protected](MM]                                //
//                                               [email protected](MMb                  .MMMB! ,MM]                                //
//                                             .MMMD   MMN.               .MMM#'   ,MM]                                //
//                                           .MMMD     -MMb            ..MMMB'     ,MM]                                //
//                                         .MMMD        ?MMh.       ..MMMM"        ,MM]                                //
//                                       .MMMD           &JOSH....BT!CAT^          .MM]                                //
//                                     .MMMD               &COCKROACH              MMN]                                //
//                                   .MMMD                                          dMM]                               //
//                                 .MMMD                                            -MM]                               //
//                               .MMMD                                               MMN                               //
//                             .MMMD         ..                            ..        JMM]                              //
//                           .MMMD         .MCCM.            ..          .MCCM.       JMM]                             //
//                        ..MMMD           LYDIA            with         ^MEOW^        XMMM                            //
//                     ..gMMMD                            DA   NIΞL                      MMMM                          //
//                    MMMM#D                                                                                           //
//                                                                                                                     //
//                                                                   .MCCM.    .MCCM.     .N   .M                      //
//                                                                 .MC       .MC         [email protected]  MWb                      //
//                                                                 dN,    +K dN,    +K  M#  GM  Mb                     //
//                                                                  369MCCM   369MCCM  Mb        Mb                    //
//                                                                                                                     //
//                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
 
pragma solidity ^0.8.16;
 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
 
contract MansionCatClubMeow is ERC721Enumerable, Ownable, ReentrancyGuard {
 
    using Strings for uint256;
 
    bool public _isSaleActive = false;
    bool public _revealed = false;
 
    uint256 public constant MAX_SUPPLY = 66666;
    uint256 public mintPrice = 0.0963 ether;
    uint256 public maxMint = 369;
 
    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";
 
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) public addressMintMccmBalance;
 
    constructor(string memory initBaseURI, string memory initNotRevealedUri)
    ERC721("Mansion Cat Club Meow", "MCCM") {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
    }
 
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
 
    function mintMccm(uint256 tokenQuantity)
        public
        payable
        nonReentrant
        callerIsUser
    {
        require(totalSupply() + (tokenQuantity) <= MAX_SUPPLY, "Sold Out!");
        require(_isSaleActive, "Sale must be active to mint Mccm");
        require(
            tokenQuantity > 0 && tokenQuantity <= maxMint,
            "Exceeded the maximum purchase quantity"
        );
        require(mintPrice * (tokenQuantity) == msg.value, "wrong mint value");
        _mintMccm(tokenQuantity);
    }
 
    function _mintMccm(uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                addressMintMccmBalance[msg.sender]++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
 
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
       
        if (_revealed == false) {
            return notRevealedUri;
        }
 
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
 
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }
 
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
 
    //only owner
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }
 
    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }
 
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }
 
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
 
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
 
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }
 
    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }
 
    function withdraw(address to) public onlyOwner{
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}