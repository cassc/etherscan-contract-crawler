pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error fouRsUCkersAliVe();
error maxVitRioLaAAa();
error sUckERuSeD();
error SUcKERsNotlIVeTOBurN();
error nOtSuCkErOwNeR();
contract Vitriol is ERC721AQueryable, ERC721ABurnable, Ownable {

    enum SaleState {
        NOT_LIVE,
        LIVE
    }

    SaleState public state;
    IERC721 sucKeRcONtRACt;
    
    uint256 public viTriOL_SuPPLY = 2500;
    address constant SuCker_hoLe = 0x000000000000000000000000000000000000dEaD;
    string private _baseTokenURI;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address private _royaltyAddress;
    uint256 private _royaltyPercentage;

    mapping(uint256 => bool) public cLAImEdSucKEr;

    constructor(IERC721 _suckerContract, string memory baseTokenURI) ERC721A("V.I.T.R.I.O.L", "PURE") {
        sucKeRcONtRACt = _suckerContract;
        _royaltyAddress = 0x580D6297B86Dc34FF6b87A5ab67B1E3873959301;
        _royaltyPercentage = 750;
        _baseTokenURI = baseTokenURI;
    }

    function crEATevITrIoL(uint256[] calldata BurnthESUckErs) external {
        //@notice No supply check needed max serums are 2222 for this function
        if(state != SaleState.LIVE) revert SUcKERsNotlIVeTOBurN();
        uint256 sUckErLeNgTH = BurnthESUckErs.length;
        if(sUckErLeNgTH != 4) revert maxVitRioLaAAa();
        for(uint256 i; i < sUckErLeNgTH;) {
            uint256 cuRrENTSuCKEr = BurnthESUckErs[i];
            if(sucKeRcONtRACt.ownerOf(cuRrENTSuCKEr) != msg.sender) revert nOtSuCkErOwNeR();
            if(cLAImEdSucKEr[cuRrENTSuCKEr]) revert sUckERuSeD();
            cLAImEdSucKEr[cuRrENTSuCKEr] = true;
            if(i < 3) {
                sucKeRcONtRACt.transferFrom(msg.sender, SuCker_hoLe, cuRrENTSuCKEr);
            }
            unchecked { i++; }
        }
        _mint(msg.sender, 1);
    }

    function OWnErMiNT(address to, uint256 amount) external onlyOwner {
        if(totalSupply() + amount > viTriOL_SuPPLY) revert maxVitRioLaAAa();
        _mint(to, amount);
    }
    
    function editviTriOLSupPLy(uint256 _viTriOL_SuPPLY) external onlyOwner {
        viTriOL_SuPPLY = _viTriOL_SuPPLY;
    }

    function editviTriOLStAtE(SaleState _viTriOLStAtE) external onlyOwner {
        state = _viTriOLStAtE;
    }

    function editRoyaltyFee(address to, uint256 percent) external onlyOwner {
        _royaltyAddress = to;
        _royaltyPercentage = percent;
    }

    function editBaseURI(string memory _base) external onlyOwner {
        _baseTokenURI = _base;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyAddress, value * _royaltyPercentage / 10000);
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        return _baseURI();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}