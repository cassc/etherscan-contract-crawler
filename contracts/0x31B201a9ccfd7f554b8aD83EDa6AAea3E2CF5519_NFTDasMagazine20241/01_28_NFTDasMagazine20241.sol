//
//
//
///////////////////////////////////////////////////
//   __  __ _ _         _  _                     //
//  |  \/  (_) |_____  | || |__ _ __ _ ___ _ _   //
//  | |\/| | | / / -_) | __ / _` / _` / -_) '_|  //
//  |_|  |_|_|_\_\___| |_||_\__,_\__, \___|_|    //
//                               |___/           //
///////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTDasMagazine20241 is ERC1155Burnable, Ownable, DefaultOperatorFilterer {
    string public name = "NFTDasMagazineByMikeHager20241";
    string public symbol = "NFTDME20241";

    string public contractUri = "https://metadata.mikehager.de/20241enContract.json";

    address public NFTDasMagazinAddress = 0x76aF07CdCa572127aa8160f1466DE4776d157181;
    address public NFTDasMagazineAddress = 0x476Ae7237d50E01C84d8f04E7C8021909600A898;
    address public BAYCAddress = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address public CryptoPunksAddress = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    uint256 public publicPrice = 0.0199 ether;

    uint256 public holderPrice = 0.0099 ether;

    bool public isMintEnabled = true;

    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;

    constructor() ERC1155("https://metadata.mikehager.de/20241de.json") {
        _idTracker.increment();
    }

    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setContractURI(string memory newuri) public onlyOwner {
        contractUri = newuri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function getPublicPrice() public view returns (uint256) {
        return publicPrice;
    }

    function setPublicPrice(uint256 _price)
        public
        onlyOwner
    {
        publicPrice = _price;
    }

    function getHolderPrice() public view returns (uint256) {
        return holderPrice;
    }

    function setHolderPrice(uint256 _price)
        public
        onlyOwner
    {
        holderPrice = _price;
    }

    function setNFTDasMagazinAddress(address _address)  public onlyOwner {
        NFTDasMagazinAddress = _address;
    }

    function setNFTDasMagazineAddress(address _address)  public onlyOwner {
        NFTDasMagazineAddress = _address;
    }

    function setBAYCAddress(address _address)  public onlyOwner {
        BAYCAddress = _address;
    }

    function setCryptoPunksAddress(address _address)  public onlyOwner {
        CryptoPunksAddress = _address;
    }

    function setIsMintEnabled(bool isEnabled) public onlyOwner {
        isMintEnabled = isEnabled;
    }

    function airdrop(
        address[] memory to,
        uint256[] memory id,
        uint256[] memory amount
    ) public onlyOwner {
        require(
            to.length == id.length && to.length == amount.length,
            "Length mismatch"
        );
        for (uint256 i = 0; i < to.length; i++)
            _mint(to[i], id[i], amount[i], "");
    }


    function mintHolder(uint256 amount, uint256 tokenId) public payable {
        require(isMintEnabled, "Mint not enabled");
        require(msg.value >= holderPrice * amount, "Not enough eth");
        
        ERC1155 magazinToken = ERC1155(NFTDasMagazinAddress);
        ERC1155 magazineToken = ERC1155(NFTDasMagazineAddress);
        ERC721 BAYCToken = ERC721(BAYCAddress);
        IERC721 CryptoPunksToken = IERC721(CryptoPunksAddress);
   

        require(magazinToken.balanceOf(msg.sender, tokenId) == 1 
        || magazineToken.balanceOf(msg.sender, tokenId) == 1
        || BAYCToken.balanceOf(msg.sender) >= 1
        || CryptoPunksToken.balanceOf(msg.sender) >= 1, "Not eligible");

        for(uint256 i = 0; i < amount; i++){
            _mint(msg.sender, _idTracker.current(), 1, "");
            _idTracker.increment();
        }
    }

      function mintPublic(uint256 amount) public payable {
        require(isMintEnabled, "Mint not enabled");
        require(msg.value >= publicPrice * amount, "Not enough eth");

        for(uint256 i = 0; i < amount; i++){
            _mint(msg.sender, _idTracker.current(), 1, "");
            _idTracker.increment();
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

     function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}