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

// @title : CoolSkullClub
// @version: 1.0
// @description: Cool Skull Club NFT Project for the Ethereum Ecosystem
// @license: MIT
// @developer: @0xKayaoglu - kayaoglu.eth                                                                                                                                
// @artist: @0xRuhsten - ruhsten.eth
// @advisor: @cipekci - canipekci.eth
// @community: @thepunktum - punktum


pragma solidity ^0.8.13;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CoolSkullClub is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 113; 
    uint256 public constant MAX_PER_WALLET = 3; 
    uint256 public constant MINT_PRICE = 0.0666 ether; 

    string private BASE_URI = ''; // Real meta data uri
    string private constant HIDDEN_URI = 'ipfs://QmeoArPda6YBgrDeJaauMYnxKjAxNdiG2sw6BGtfNLdkH2/metadata.json'; // Start of hidden meta data uri
    string private constant URI_SUFFIX = '.json';

    bool public PAUSED = true;
    bool public REVEALED = false;
    
    enum ProjectStatus {
        Before,
        Mint,
        SoldOut
    }

    ProjectStatus public pStatus = ProjectStatus.Before;

    constructor() ERC721A("COOL SKULL CLUB", "CSKC") {}

    function _claimToken(uint256 _mintAmount, uint256 _mintPrice) internal virtual {
        require(_mintAmount > 0, "COOL SKULL CLUB : Amount cannot be zero!");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "COOL SKULL CLUB : Reached max supply!");
        require(msg.value >= _mintPrice * _mintAmount, "COOL SKULL CLUB : Not enough balance!");
        _mint(_msgSender(), _mintAmount);
    }

    function publicMint(uint256 _mintAmount) public payable nonReentrant {
        require(!PAUSED, "COOL SKULL CLUB : This contract is paused!");
        require(pStatus == ProjectStatus.Mint, "COOL SKULL CLUB : Public Mint not enabled!");
        _claimToken(_mintAmount, MINT_PRICE);
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

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
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

    function setPaused(bool _pauseStatus) public onlyOwner {
        PAUSED = _pauseStatus;
    }

    function restart() external onlyOwner {
        pStatus = ProjectStatus.Before;
    }

    function setSoldOut() external onlyOwner {
        pStatus = ProjectStatus.SoldOut;
    }


}