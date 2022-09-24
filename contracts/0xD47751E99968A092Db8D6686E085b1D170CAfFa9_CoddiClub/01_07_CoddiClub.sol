//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                 Coddi Club                                 //
//                                                                            //
//##############################################################################
//*#################%%%###################################%%%%%%%%%%%%%%######*#
//*%**(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((,*%*#
//*%/*#(/****************************************************************(#,*%*#
//*%/*#(*,.***********************************************************.,/(#,*%*#
//*%/*#(*,./                                                        C/.,*(#,*%*#
//*%/*#(*,./                                                        &/.,/(#,*%*#
//*%/*#(*,./                         &&&CC&&&&&%                     /.,*(#,*%*#
//*%/*#(*,./                  &&&&CC&%&C&C&&&&%&&&                   /.,/(#**%*#
//*%/*#(*,./                %%&%%%%%&&%#&&C&&CC&&C&                  /.,*(#**%*#
//*%/*#(*,./               CC%%CC#%#%%C&C&&&&&&C&CC%                 /.,/(#**%*#
//*%/*#(*,./               C%&C#&%&&%&%&C%%&%C&C%&%%%%               *.,*(#,*%*#
//*%**#(*,./               &&C%&......(%##%,(....&%%&%               *.,*(#,*%*#
//*%**#(*,./           *#* C&&,..*...#*/,#*/...*/,,&&, *#.           *.,*(#,*%*#
//*%/*#(*,./         ,%%**/&C%.**/CCC.,..#/.*///#(.%%%/**%%          *.,*(#,*%*#
//*%**#(*,./         #%%,...*C#.,*,,,/....#,*,,*(.%&*...,%%          *.,*(#,*%*#
//*%**#(*,.(          %%......*C%,..,**,.,*(...,%#C......%%          *.,*(#,*%*#
//*%**#(*,./           C%%%%%#%C%,.............,%C%#%#%%%(           *.,*(#,*%*#
//*%**#(*,./                   &%...............%&                   *.,*(#,*%*#
//*%/*#(*,./                  #%**%.../#%(,...,.*C                   *.,*(#,*%*#
//*%/*#(*,./                   %**/(,***(*******/%                   *.,*(#,*%*#
//*%/*#(*,./                    &C*......*,..###&#(                  *.,*(#,*%*#
//*%/*#(*,./                        &***%%%&%%%%%%%%                 *.,*(#,*%*#
//*%/*#(*,./                   %#&*.%%%&%%%%%%%%%%%%%&               *.,*(#**%*#
//*%/*#(*,./       ****     ##&###%&&* .%%%%%%%%%%%%&%               *.,*(#**%*#
//*%/*#(*,./  &C&%&&&&&&&&&&%%&C&%&&&&&C&%%%%%%%%%%%%#&&&%%%%%%&C&   *.,*(#**%*#
//*%/*#(*,./  C&C&&&&&&&&&&C&%#C#&C&CCC.,%%%%%%%%%%%&&C&&&&&&&&&&&CC ,.,*(#,*%*#
//*%**#(*,./ %CCC&&&C&C&&&&&%%%%&%&#.    /,%%%&%*(*%&%C&&&&&&&C&&&CCC,.,*(#,*%*#
//*%**#(*,./ CCC&&&&&&CC&&C&C%%%%C%##.     .%#&,&&&%&%C&&&&&CC&&&&CCC,.,*(#,*%*#
//*%**#(*,./ CC&&&&&&&C&CCC&&CC&%%&CCC%   .#&*##(&/     CC&CC&CC&&CC&,.,*(#,*%*#
//*%/*#(*,./%CC&&&&&&&&&CCC&&&CCC%&%%%&%&%%&%C#  &%%#%C%%%CCC&&&&&CC%,.,*(#,*%*#
//*%**#(*,.............................................................,*(#,*%*#
//*%**#(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((#,*%*#
//*%///////////////(((((////////////////(((/////////////(((////////////(////*%*#
////////////***********/////////********/////////*////////********/////////////#

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CoddiClub is ERC721A, Ownable {
    uint256 private constant RESERVED = 100;
    uint256 private constant PRESALE_MAX_PER_WALLET = 100;

    enum SaleStatus {
        PAUSED,
        PRESALE,
        PUBLIC,
        CLOSED
    }

    event StatusUpdate(SaleStatus indexed oldStatus, SaleStatus indexed newStatus);
    event PublicPriceUpdate(uint256 indexed oldPublicPrice, uint256 indexed newPublicPrice);
    event PresalePriceUpdate(uint256 indexed oldPresalePrice, uint256 indexed newPresalePrice);
    event SupplyUpdate(uint256 indexed oldSupply, uint256 indexed newSupply);

    address private _signer = 0x801Bd991f88C6c0A2D690dee79Ba677529C8c0b4;
    uint256 private _presalePrice = 0.057 ether;
    uint256 private _publicPrice = 0.1 ether;
    uint256 private _supplyCap = 10000;
    uint256 private _reserveMinted;
    SaleStatus public _saleStatus = SaleStatus.PRESALE;
    string __baseURI = 'https://metadata.coddiclub.com/';


    constructor() ERC721A("CoddiClub", "CC") {}

    function presaleMint(uint256 amount, bytes calldata signature) external payable {
        require(_saleStatus == SaleStatus.PRESALE, "The presale isn't active");
        require(_verifySignature(msg.sender, signature), "You are not whitelisted");
        require(_numberMinted(msg.sender) + amount <= PRESALE_MAX_PER_WALLET, "You can't mint that many");
        require(msg.value == _presalePrice * amount, "Invalid amount of ether sent");
        require(amount + totalSupply() + RESERVED - _reserveMinted <= _supplyCap, "Insufficient supply");

        _safeMint(msg.sender, amount);
    }

    function publicMint(uint256 amount) external payable {
        require(_saleStatus == SaleStatus.PUBLIC, "The public sale isn't active");
        require(msg.value == _publicPrice * amount, "Invalid amount of ether sent");
        require(amount + totalSupply() + RESERVED - _reserveMinted <= _supplyCap, "Insufficient supply");

        _safeMint(msg.sender, amount);
    }

    function publicPrice() external view returns(uint256) {
        return _publicPrice;
    }

    function presalePrice() external view returns(uint256) {
        return _presalePrice;
    }

    function supplyCap() external view returns(uint256) {
        return _supplyCap;
    }

    function status() external view returns(SaleStatus) {
        return _saleStatus;
    }

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(__baseURI, "contract"));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    /**
     * Owner only
     */
    function reserveMint(uint256 amount) external onlyOwner {
        require(amount + _reserveMinted <= RESERVED, "Insufficient reserve");
        _reserveMinted += amount;
        _safeMint(msg.sender, amount);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        __baseURI = uri;
    }

    function setPublicPrice(uint256 newPublicPrice) external onlyOwner {
        require(_publicPrice != newPublicPrice, "Nothing to change");
        emit PublicPriceUpdate(_publicPrice, newPublicPrice);
        _publicPrice = newPublicPrice;
    }

    function setPresalePrice(uint256 newPresalePrice) external onlyOwner {
        require(_presalePrice != newPresalePrice, "Nothing to change");
        emit PresalePriceUpdate(_presalePrice, newPresalePrice);
        _presalePrice = newPresalePrice;
    }

    function setSupply(uint256 newSupplyCap) external onlyOwner {
        require(newSupplyCap < _supplyCap, "You can only decrease the supply");
        emit SupplyUpdate(_supplyCap, newSupplyCap);
        _supplyCap = newSupplyCap;
    }

    function setSaleStatus(SaleStatus _status) external onlyOwner {
        require(_saleStatus != SaleStatus.CLOSED, "The sale is closed");
        require(_status != _saleStatus, "Nothing to change");
        emit StatusUpdate(_saleStatus, _status);
        _saleStatus = _status;
    }

    function setSigner(address signer_) external onlyOwner {
        require(_signer != signer_, "Nothing to change");
        _signer = signer_;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw failed");
    }

    /**
     * Internal and private methods
     */
    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function _verifySignature(address minter, bytes calldata signature) private view returns(bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(minter))
            )
        );
        return ECDSA.recover(hash, signature) == _signer;
    }
}