// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RefinedSavages is ERC721A, Ownable, ReentrancyGuard
{

    using Strings for string;

    uint public MAX_TOKENS = 2222;
    uint public NUMBER_RESERVED_TOKENS = 1500; 
    uint256 public PRICE = 0 ether;
    uint public perMintLimit = 2; 

    bool public saleIsActive = false; 
    bool public deadManSwitch = false;

    uint public reservedTokensMinted = 0;
    string private _baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmWTUekrP1eDyEoajAEej6QE72JQiLN8zfYPwRyPzo6A8X/";


    constructor() ERC721A("Refined Savages", "RFSS") {}

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }
    
    function deadManFlipSwitch() external onlyOwner
    {
        deadManSwitch = true;
    }

    function emergencyDeadManUndo() external onlyOwner
    {
        deadManSwitch = false;
    }

    function adjustMax_Tokens(uint256 newMax) external onlyOwner
    {
        require(!deadManSwitch, "Contract is closed");
        MAX_TOKENS = newMax;
    }

    function adjustReserves(uint256 newReserve) external onlyOwner
    {
        require(!deadManSwitch, "Contract is closed");
        NUMBER_RESERVED_TOKENS = newReserve;
    }

    function mintToken(uint256 amount) external payable
    {
        require(!deadManSwitch, "Contract is closed");
        require(saleIsActive, "Sale must be active to mint");
        require(amount > 0 && amount <= perMintLimit, "Max 2 NFTs per transaction");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");

        _safeMint(msg.sender, amount);
    }

   
    function setPrice(uint256 newPrice) external onlyOwner
    {
        require(!deadManSwitch, "Contract is closed");
        PRICE = newPrice;
    }

    function setPerMintLimit(uint newLimit) external onlyOwner 
    {
        require(!deadManSwitch, "Contract is closed");
        perMintLimit = newLimit;
    }

    function flipSaleState() external onlyOwner
    {
        require(!deadManSwitch, "Contract is closed");
        saleIsActive = !saleIsActive;
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner
    {
        require(!deadManSwitch, "Contract is closed");
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        reservedTokensMinted+= amount;
        _safeMint(to, amount);
    }


    function withdraw() external nonReentrant
    {
        require(msg.sender == owner(), "Invalid sender");
        (bool success, ) = owner().call{value: address(this).balance}(""); 
        require(success, "Transfer 1 failed");
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        require(!deadManSwitch, "Contract is closed");
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                                                                                                                                                       
//                                                                                                                 .o,                                                                                   //
//                                                                                                      ;x,        oWk.        .d:                                                                       //
//                     .,codl,.                                                                         oWK;      ;XMNl       'OWx.                                                                      // 
//                 .;oOXWKd;.                                                            ;:            .kMMXl.   .OMMMK,     :KMMK,    .ol.                                                              // 
//               'o0WMWOc.                                                               cXOc.         ,KMMMNd.  oWMMMMk.  .lXMMMNc  .c0Wd                                                               // 
//             ,xNMMMXl.                                                                 .kMWKo'       cWMMMMWk':XMMMMMWl .dNMMMMMx.;OWMMd                                                               // 
//           'xNMMMWO,                                                                    lWMMMXd,   .'xMMMMMMMXXMMMMMMMKokWMMMMMMX0NMMMMo        .'.                                                    // 
//          cKMMMMWk.                                                        ..           '0MMMMMNk:.'d0MMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMo     .,d0l                                                     // 
//        .dNMMMMMO.                                'o:.                     .oxl;.        oWMMMMMMW0OXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc   'l0WMk.                                                     // 
//       .xWMMMMMK;      ..                         cNWx.                     ,0MWXkl;.    ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc.ckNMMMX;                                                      // 
//      .oWMMMMMMd    .cxl.                         ;XMWo                      ,KMMMMWXko;..dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKXMMMMMWo   .;,                                                 // 
//      :XMMMMMMN:  .lXNl                           cNMMX;                      ;KMMMMMMMWXk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc;okKO,                                                 // 
//     .kMMMMMMMX; .kWMk.                          .xMMMMx.                      :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNWMWO'                                                  // 
//     ;XMMMMMMMX;.xWMMx.                          ;XMMMM0'                       cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO.  .;ldl.                                           // 
//     lWMMMMMMMWl:XMMMO.                         .kMMMMMN:          ....          cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNxlx0XWWO'                                            // 
//     oMMMMMMMMMOkNMMMWx.              :c       .xWMMMMMN:          ;k000OkkxddolloKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.                                             // 
//     oMMMMMMMMMWNWMMMMWO;.          .o0:      'kWMMMMMMN:           .:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc                                               // 
//     lWMMMMMMMMMMMMMMMMMW0d:,...';lkXWx.    .cKMMMMMMMMK,              'dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl','.                                            // 
//     ;XMMMMMMMMMMMMMMMMMMMMMWNNNNWMMNx.   .:OWMMMMMMMMMx.                .cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKko,                                             // 
//     .kMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:  .,o0WMMMMMMMMMMN:                   .;xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.                                               //
//      :XMMMMMMMMMMMMMMMMMMMMMMMN0xl;,:d0NMMMMMMMMMMMMWd.             ...',;cld0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.                                                  // 
//       oWMMMMMMMMMMMMMMMMMMMMMWXOO0XWMMMMMMMMMMMMMMMMO.    .,;:lodxkO0KXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                                                   // 
//       .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,     .cx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK;                                                    // 
//        .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.         .'cd0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;                                                     // 
//          :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.              .':oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;                                                     //
//           .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                     .:dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdxko:;,..                                           // 
//             'dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:                   .,:okXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKko;.                                       // 
//               .ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,              .:okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx;.                                    // 
//                  .:dOXWMMMMMMMMMMMMMWXOkXMMMMMMMMNx'            .',;:clodxkO0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;                                   // 
//                      .,:ldxkkkkkxol:,.  .c0WWMMMMMMXo.                     'oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,                                 // 
//                                          ;Ok0WWMMMMMMXo.                .ckXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;                                // 
//                                         .dk,kOxNMMMMMMMXo.           .ckXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                               // 
//                                         :0:.ko.:XMMMMMMMW0c.      .ckXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:                               // 
//                                        ,0o .Oo  ,OWMMMMMMMW0c. .ckXMMMMWWWNXXK00XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXXNMMMMMMMN:                               // 
//                                       .kx. ;Kl   .xWMMMMMMMMW0ddolll::;,''.... .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkoc;,'',lONMMMMMMM0'                               // 
//                                      ,kx.  lK;    .lXMMMMMMMMMNk:.            .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkl,.      ,OWMMMMMMMMMx.                               // 
//                                    'xNK,  .kx.      ;KMMMMMMMMMMWNxc,        :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk'         ,KMMMMMMMMMMMNl                               // 
//                                   ;KW0:   o0,        'kWMMMMMMMMMMMWd.     .dNWWXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKxxxxxkko' oMMMMMMMMMMMMMO.                              // 
//                                   ;oc.  .dKc          .xWMMMMMMMMMMO.      ;l:;',xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'cNMMMMMMMMMMMMO.                              // 
//                                        ;OKl.           :XMMMMMMMMMMNk,          oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;.dNMMMMMMMMMMX:                               // 
//                                       'ol'              oWMWNWMMMMMMMXo.      .oNMMMMMMMMMMMN0XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxdKWWMMMMMMNk,                                //
//                                                         .:c;'cKWMMMMMMW0o.    lNMMMWKkokNNOl''kMMMMMMWNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl,:lool:'                                  // 
//                                                               .dXWMMMMMMMKl. cXNOdc,..;dl'   lNMMWKOo;oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'                                           // 
//                                                                 .xWMMMMMMMWOol:.      .     :XMW0c. .l0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl.                                             //                                                                  .lKMMMMMMMMXo'            ;KNOc. ;lkOkKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxc'                                                // 
//                                                                    'xXWMMMMMMMXo.          ;0k;  'x0OdoKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl                                                  //
//                                                                      ;0WMMMMMMMWO,        .:clddxX0l:dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:                                                  // 
//                                                                       .oXMMMMMMMMXx;      .dWMMMMNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.                                                   // 
//                                                                         ,xNMMMMMMMMNx'.,cd0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKONMMMMMMMK0NXx,                                                     //
//                                                                          .cKWMMMMMMMMXKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,,dxxKMMKo..'.                                                       // 
//                                                                           .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0Oxc;ld:.                                                            //
//                                                                     .,lxO0KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNO:                                                              // 
//                                                                 .:okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;.                                                           // 
//                                                              .ckXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l'                                                         // 
//                                                            .l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx:ldo;.                                                  // 
//                                                          .c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk;..                                               // 
//                                                         .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kxoc'                                          // 
//                                                         oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.                                       // 
//                                                        lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;                                      // 
//                                                       lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;                                     // 
//                                                      cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                                    // 
//                                                     :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                                    // 
//                                                    ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                                   // 
//                                                  .:0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;                                   // 
//                                              .;okXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,                                  // 
//                                         ..:okXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                                  // 
//                                    ..;lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                 // 
//                               .,:ox0NWMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,                                // 
//                      ..',:ldk0XWMMMMMMMMMMMMW0d:cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd.                              // 
//        ,cc:cccoodxxkO0XNWMMMMMMMMMMMMMMMN0xl,.  .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'                             // 
//        ,kNMMMMMMMMMMMMMMMMMMMMMMMMWX0xo:'    .:dONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'                            // 
//          'cdk0XWMMMMMMMMMMWNK0Oxo:,.    .':dONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'                           // 
//              ..',;:cccc:;,'...     .':lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                          // 
//                              .';cdkKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.                         // 
//           .;;'.......',;cldk0XWMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                        // 
//           'OWNXXXXXXNWWMMMMMMMMMMMMMMMMWN0dlOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                       // 
//            .dXWMMMMMMMMMMMMMMMMMMMWX0xl;. .lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                      // 
//              .:dOKNWMMMMMWWNXKOxoc,..     ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                      // 
//                  .',;::::;'...            lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                     // 
//                                          .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'                    // 
//                                          ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                    // 
//                                          cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,                   // 
//                                         .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                   // 
//                                        .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                  // 
//                                        cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'                  // 
//                                       .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'                  // 
//                                       oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'                  // 
//                                      '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kkdl;.            // 
//                                      oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXko;.        // 
//                                     .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM_Kronos Starrwolf_*_ArtsAbide_:.      //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////