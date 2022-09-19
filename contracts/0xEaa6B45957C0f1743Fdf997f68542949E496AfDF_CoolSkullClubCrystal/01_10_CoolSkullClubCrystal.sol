// SPDX-License-Identifier: MIT
                                                                                                                                                       
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                  :-                                                                            
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                            /\                                                                            //
//                                                                           /=*\                                                                           //
//                                                                          -+  -#.\                                                                        //
//                                                                          #.  =#*=\                                                                       //
//                                                                     /\ -+      @ //                                                                      //
//                                                                    /*  .#       *:./.                                                                    //
//                                                                 :# .+==+.       *-=%\                                                                    //
//                                                                 +=  +=+         =*#.//                                                                   //
//                                                                 :#                . +-\                                                                  //
//                                                              :.  %.    ::@@@@@@::    .# \                                                                //
//       [email protected]@@@@@@@@@@@%#.                           ::::        %*-=* :+%@@@@@@@@@@@%+. -**%.          [email protected]@@@@@@@@@@@%*   :::.              @@:              //
//        [email protected]@@@####%@@@@-                          [email protected]@@+       -+ . :#@@@@@@@@@@@@@@@@@#:  -*           [email protected]@@@####%@@@@. [email protected]@@=              @@:              //
//        %@@@=    [email protected]@@%                           %@@@        ==  [email protected]@@@@@@@@@@@@@@@@@@@@*. %.         [email protected]@@@-    #@@@#  @@@%              [email protected]@@.             //
//       [email protected]@@%     :+#@:                          [email protected]@@=        :* *@@@ COOL SKULL CLUB @@@%.*         *@@@#     -+%@. [email protected]@@=               @@@%              //
//       %@@@=           :#######:   .####### :  [email protected]@@@          #[email protected]@@@@@@@@@@@@@@@@@@@@@@@@#%.        [email protected]@@@:          [email protected]@@% :###:   :###: *@@@+####:        //
//      [email protected]@@%          [email protected]@@@@@@@@@# *@@@@@@@@@@+ [email protected]@@-          [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@=         *@@@*           *@@@- %@@@   :@@@*[email protected]@@@@@@@@@@:       //
//     [email protected]@@@-         [email protected]@@%[email protected]@@=:@@@*...%@@@:[email protected]@@#            @@@@@%@@@@@@@@@@@@@@@@@@@@%         [email protected]@@@.          [email protected]@@# [email protected]@@=   %@@@.*@@@[email protected]@@%        //
//     [email protected]@@%       := *@@@-   @@@@ %@@@.  :@@@# *@@@:            *@@@@=-----#@@@#-----%@@@@*         #@@@*       :-  *@@@: %@@@   [email protected]@@*[email protected]@@#   *@@@=        //
//    [email protected]@@@:    +#@@*[email protected]@@#   [email protected]@@[email protected]@@+   #@@@:[email protected]@@#             .*@@=      :@@@   \,/  *@@*.       [email protected]@@@.    +#@@+ :@@@# [email protected]@@=   %@@@ *@@@.  :@@@%         //
//    [email protected]@@*    [email protected]@@@:*@@@:  [email protected]@@% %@@@   [email protected]@@* #@@@:               @@+     .*@@@-  /'\  #@@         #@@@+    [email protected]@@@. #@@@: @@@@   [email protected]@@=:@@@*   #@@@:         //
//    @@@@@%%%%@@@@+ @@@@###%@@@:[email protected]@@@###@@@@.:@@@@.              [email protected]@@#**[email protected]@-#[email protected]@%***%@@@=        [email protected]@@@@%%%%@@@@= [email protected]@@@[email protected]@@@%%%@@@@ #@@@%##%@@@+          //
//    -*#########*-  +########*: .*########+. +####*:              *@@@@@@@@. * :@@@@@@@@*          =*#########+:  +####*=*###**%@@%-:########*=.           //
//                                                                  .=+:[email protected]@@@@@%@@@@=-+=.                                                                   //
//                                                                       @@@@@@@@@@@                                                                        //
//                                                                       *@@@@@@@@@*                                                                        //
//                                                                         /SKULL/                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// @title : CoolSkullClub Crystals
// @version: 1.0
// @description: Cool Skull Club Crystals NFT Project for the Ethereum Ecosystem
// @license: MIT
// @developer: @0xKayaoglu - kayaoglu.eth                                                                                                                                
// @artist: @0xRuhsten - ruhsten.eth
// @advisor: @cipekci - canipekci.eth
// @community: @thepunktum - punktum
// @community: @0xsurprimes - surprimes


pragma solidity ^0.8.13;

import "./ERC721A/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CoolSkullClubCrystal is ERC721AQueryable, Ownable, ReentrancyGuard {

    using Strings for uint256;

    bytes32 public OGMerkleRoot;
    bytes32 public WLMerkleRoot;

    uint256 public constant MAX_SUPPLY = 444; 
    uint256 public constant MINT_PRICE = 0.0 ether;

    string private BASE_URI = ''; // Real meta data uri
    string private constant HIDDEN_URI = 'ipfs://QmeoArPda6YBgrDeJaauMYnxKjAxNdiG2sw6BGtfNLdkH2/metadata.json'; // Start of hidden meta data uri
    string private constant URI_SUFFIX = '.json';

    bool public REVEALED = false;
    
    enum ProjectStatus {
        Before,
        OGMint,
        WLMint,
        PublicMint,
        SoldOut
    }

    ProjectStatus public pStatus = ProjectStatus.Before;

    constructor() ERC721A("COOL SKULL CLUB CYRSTALS", "CSCC") {}

    function _claimToken(uint256 _mintAmount) internal virtual {
        require(_mintAmount > 0, "COOL SKULL CLUB : Amount cannot be zero!");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "COOL SKULL CLUB : Reached max supply!");
        _mint(_msgSender(), _mintAmount);
    }

    function publicMint() public nonReentrant {
        require(pStatus == ProjectStatus.PublicMint, "COOL SKULL CLUB : Public Mint not enabled!");
        _claimToken(1);
    }

    function OGMint(uint256 _mintAmount, bytes32[] calldata _OGMerkleProof) public nonReentrant {
        require(pStatus == ProjectStatus.OGMint, "COOL SKULL CLUB : OG Mint not enabled!");
        require(MerkleProof.verify(_OGMerkleProof, OGMerkleRoot, keccak256(abi.encodePacked(_msgSender()))), "COOL SKULL CLUB : There is no Legendary at the address!");
        _claimToken(_mintAmount);
    }

    function WLMint(bytes32[] calldata _WLMerkleProof) public nonReentrant {
        require(pStatus == ProjectStatus.WLMint, "COOL SKULL CLUB : OG Mint not enabled!");
        require(MerkleProof.verify(_WLMerkleProof, WLMerkleRoot, keccak256(abi.encodePacked(_msgSender()))), "COOL SKULL CLUB : There is no Legendary at the address!");
        _claimToken(1);
    }

    function reserveNFT(address _to, uint256 _amount) public onlyOwner {
        require(_amount > 0, "COOL SKULL CLUB : Amount cannot be zero!");
        require(totalSupply() + _amount <= MAX_SUPPLY, "COOL SKULL CLUB : Reached the max supply!");
        _mint(_to, _amount);
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }

    function setOGMerkleRoot(bytes32 _root) public onlyOwner {
        OGMerkleRoot = _root;
    }

    function setWLMerkleRoot(bytes32 _root) public onlyOwner {
        WLMerkleRoot = _root;
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "COOL SKULL CLUB: URI query for nonexistent token");

        if (REVEALED == false) {
            return HIDDEN_URI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), URI_SUFFIX))
            : '';
    }

    function setRevealed(bool _revealStatus) public onlyOwner {
        REVEALED = _revealStatus;
    }

    function restart() external onlyOwner {
        pStatus = ProjectStatus.Before;
    }

    function setOGMint() external onlyOwner {
        pStatus = ProjectStatus.OGMint;
    }

    function setWLMint() external onlyOwner {
        pStatus = ProjectStatus.WLMint;
    }

    function setPublicMint() external onlyOwner {
        pStatus = ProjectStatus.PublicMint;
    }

    function setSoldOut() external onlyOwner {
        pStatus = ProjectStatus.SoldOut;
    }


}