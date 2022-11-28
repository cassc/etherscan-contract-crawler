// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721APausable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kdlclox0NMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.',;:::;;:oONMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:. .cxOOOOOkd:'.,xNMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc. .ck0000OOOo:dx:..c0WMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx;..;lkOOOO0000Oc;xOkl. .dNM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk;.;oxOOOOO000KKK0xxOOOko. .cX
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKc.,oO0OOO000KKXXXXXKK0OOOOo. .o
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'.:xOOO000KKXXXXXXXXXK00OOOO:  ;
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;..lkOO00KKXXXXXXXXXXXXKK0OOO0o. '
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl. 'oOO00KKXXXXXXXXXXXXXXK00OOO0x. '
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd'  ;xO000KXXXKKKKKXXXXXXXXK0OOOOOc  ,
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOo;  .ck000KKKOddkO0000KKXXKKK00OOOkc. .x
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.   .oO00KKXXKOxl:cxOOO000KKK00OOOOc. .oN
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,    ;x000KXXXXXKK0kc:dOOOO00000OOOOl. .oNM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl.  .,lk00KKXXXXXXXK00Ol,lkOOOOOOOOOkc. ,kNMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk'   ,xO000KKXXXXXXXXXK00kc..,:loooolc,..oXWMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKc.  .lO000KKXXXXXXXXXXXXK00Od;.        .c0WMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'  .;x000KKKXXXXXXXXXXXXXKKK000xlc:,.  .xNMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMW0:   .oO00KKKXXXXXXXXXXXKKKKKKKK00OOOd,  'OWMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMXo.  .:x000KKXXXXXXXXXXKKK00000KK00OOOo.  ;OWMMMMMMMMM
MMMMMMMMMMMMMMMMMMWMMMMMWk,   'oO00KKXXXXXXXXKKKK0Odok00000OOOOd.  ;0WMMMMMMMMMM
MMMMMMMMMMMMMMMMMKxKMMWKl.  .lk00KKXXXXXXXKKKK0xl:;cxO0000OOOOx,  :KWMMMMMMMMMMM
MMMMMMMMMMMMMMMMMx'oWNd'  .;x0KKKXXXXXKKKK0Odc,..;dO00000OOOOx; .lXMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWd.,d:   'o0KKKKXXKKK0Okkxl:;;cok0000000OOOOd, .oNMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWo.    .ck00KKKK0kdllloxkkkO000OOO00000OOOOo. .dNMMMMMMMMMMMMMMM
MMMMMMMNOKWMMMMMXc    ;d00000OdlccloxO0KK0koc;'';d0000OOOkc. .kWMMMMMMMMMMMMMMMM
MMMMMMMWOldXMMWO:   'oO00000Oxddk00KK0Odc:,,,:lok0000OOOx;  'kWMMMMMMMMMMMMMMMMM
MMMMMMMMWKl:k0l.   .o000KK0OkxdddxO000OxdxkO0000K000OOOd'  ,OWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMNo..  .,,ckKKKKKKOxdddxk000000K000000000OOOkl.  ,OWMMMMMMMMMMMMMMMMMMM
MMMMMMMMMNk,  .;x00KKKKKKKKK00KK00000000000000000OOOkc.  ,OWMMMMMMMMMMMMMMMMMMMM
MMMMMMMNk;.  'oOKKKXXXXKKKK0000Odlclx00000000000OOOx:.  ,0WMMMMMMMMMMMMMMMMMMMMM
MMMMMMXl.  .lk00KKXXXXXKK0000000kxxkO0000000000OOOx;   ;0MMMMMMMMMMMMMMMMMMMMMMM
MMMMNk,  .:x00KKKXXXXXXKK00K00000000000000000OOOOd,   :KMMMMMMMMMMMMMMMMMMMMMMMM
MMW0c. .;x000KKXXXXXXXXKK00KK0KK00000000K000OOOOo.   :KMMMMMMMMMMMMMMMMMMMMMMMMM
MXd.  ,o0KKKKXXXXXXKKKKKKKKKK0K000000000000OOOk:.    lNMMMMMMMMMMMMMMMMMMMMMMMMM
O;   :0KKKKXXXXXKKKKKKKKKKKK0000KKKK000000OOOd,  .   .xWMMMMMMMMMMMMMMMMMMMMMMMM
c    .ldxOKXXXXKKKKKKKKKKKKK000KKKKK000OOOOkl...cdc.  ,KMMMMMMMMMMMMMMMMMMMMMMMM
Ko;..   ..;okKXKKKKKKKKKKKKK0KKKKKK00OOOOOd:',lxOOk;  .kMMMMMMMMMMMMMMMMMMMMMMMM
MMWX0xl;.   .,oO0KKKKK00KKKKKKKKK00OOOOxol:cdkkdxOOl. .dWMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMWXkc'   .ck0KKKKKKKXXKKKK00OO00kdodkkdl:cdOOo. .dWMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMWXx;.  .ckKKXXXXXXKK00OOOOO0Okxdc;,:okOOOo. .kMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNk;.  'dKXXXKkoooollllllcc::::lxOOOOOOl. '0MMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNx'  .cOK0kdoodk00000OkkkkkOOOOOOOOx,  cNMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMKc.  ,xkdooddk0KKK000OOOOOOOOOOOkc. .kWMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMNd.  .dKKKKKKKKK00OOOOOOOOOOOOkl.  lNMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMWx.  .o0KKKKK000OOOOOOOOOOOOkl.  ;KMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMWk.  .o0KKK000OOOOOOOOOOOOx:.  ,0WMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMWx.  .d0000OOOOOOOOOOOOOd,   ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMWx.  'd0OOOOOOOOOOOOOxc.  .cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMNd.  ,xOOOOOOOOOOOxc.  .:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMNl   :kOOOOOOkdc;.  .lOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMK:  .oOOOkdc,.  .;dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWk.  :do:'. .,ox0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMXc   .  .;d0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMWd..':okXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMW0dkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
**/
contract GoblinDickButtz is ERC721A, ERC721AQueryable, ERC721APausable, ERC721ABurnable, Ownable, ReentrancyGuard {
    uint public PRICE;
    uint public maxSupply;
    uint public MAX_MINT_AMOUNT_PER_TX;
    uint16 public MAX_FREE_MINTS_PER_WALLET;
    string private BASE_URI;
    bool public SALE_IS_ACTIVE = true;

    uint public totalFreeMinted;

    constructor(uint price,
        uint _maxSupply,
        uint maxMintPerTx,
        uint16 maxFreeMintsPerWallet,
        string memory baseUri) ERC721A("GoblinDickButtz", "GDB") {
        PRICE = price;
        maxSupply = _maxSupply;
        MAX_MINT_AMOUNT_PER_TX = maxMintPerTx;
        MAX_FREE_MINTS_PER_WALLET = maxFreeMintsPerWallet;
        BASE_URI = baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function getFreeMints(address addy) external view returns (uint64) {
        return _getAux(addy);
    }

    function setPrice(uint price) external onlyOwner {
        PRICE = price;
    }

    function setMaxMintPerTx(uint maxMint) external onlyOwner {
        MAX_MINT_AMOUNT_PER_TX = maxMint;
    }

    function setMaxFreeMintsPerWallet(uint16 maxFreeMintsPerWallet) external onlyOwner {
        MAX_FREE_MINTS_PER_WALLET = maxFreeMintsPerWallet;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }

    function setSaleState(bool state) external onlyOwner {
        SALE_IS_ACTIVE = state;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    modifier mintCompliance(uint _mintAmount) {
        require(_currentIndex + _mintAmount <= maxSupply, "Max supply exceeded!");
        require(_mintAmount > 0, "Invalid mint amount!");
        _;
    }

    function getDickPic(uint32 _mintAmount) public payable mintCompliance(_mintAmount) {
        require(_mintAmount <= MAX_MINT_AMOUNT_PER_TX, "Mint limit exceeded!");
        require(SALE_IS_ACTIVE, "Sale not started");

        uint price = PRICE * _mintAmount;

        uint64 usedFreeMints = _getAux(msg.sender);
        uint64 remainingFreeMints = 0;
        if (MAX_FREE_MINTS_PER_WALLET > usedFreeMints) {
            remainingFreeMints = MAX_FREE_MINTS_PER_WALLET - usedFreeMints;
        }
        uint64 freeMinted = 0;

        if (remainingFreeMints > 0) {
            if (_mintAmount >= remainingFreeMints) {
                price -= remainingFreeMints * PRICE;
                freeMinted = remainingFreeMints;
                remainingFreeMints = 0;
            } else {
                price -= _mintAmount * PRICE;
                freeMinted = _mintAmount;
                remainingFreeMints -= _mintAmount;
            }
        }

        require(msg.value >= price, "Insufficient funds!");
        _safeMint(msg.sender, _mintAmount);

        totalFreeMinted += freeMinted;
        _setAux(msg.sender, usedFreeMints + freeMinted);
    }

    function sendDickPic(address _to, uint _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    function withdraw() public onlyOwner nonReentrant {
        uint balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint startTokenId,
        uint quantity
    ) internal virtual override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}