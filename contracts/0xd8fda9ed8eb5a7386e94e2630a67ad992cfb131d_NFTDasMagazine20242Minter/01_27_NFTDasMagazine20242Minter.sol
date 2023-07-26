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
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTDasMagazine20242Minter is Ownable {

    address public nftDasMagazinAddress = 0x07F027e77290c2337cf7046B48A1815150A0Abc9;
    address public nftDasMagazineAddress = 0x476Ae7237d50E01C84d8f04E7C8021909600A898;

    address public nftDasMagazine20242Address = 0x7ed81A876c74bbF0899aE9F1Bc1E09D45B60e223;
    address public nftDasMagazineVeeconByMikeHager2023 = 0x76ddAE3902041f00b9542aFBc3F6382E5B04cA0B;

    uint256 public publicPrice = 0.02 ether;

    uint256 public holderPrice = 0.01 ether;

    bool public isMintEnabled = true;

    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;
    Counters.Counter private _idTrackerVeecon;

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
        nftDasMagazinAddress = _address;
    }

    function setNFTDasMagazineAddress(address _address)  public onlyOwner {
        nftDasMagazineAddress = _address;
    }

    function setNFTDasMagazin20242Address(address _address)  public onlyOwner {
        nftDasMagazine20242Address = _address;
    }

    function setNFTDasMagazinVeeconByMikeHager2023(address _address)  public onlyOwner {
        nftDasMagazineVeeconByMikeHager2023 = _address;
    }

    function setIsMintEnabled(bool isEnabled) public onlyOwner {
        isMintEnabled = isEnabled;
    }

    function airdrop(
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) onlyOwner public {
        require(to.length == id.length && to.length == amount.length, "Length mismatch");
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(nftDasMagazine20242Address);
        for (uint256 i = 0; i < to.length; i++)
            token.mint(to[i], id[i], amount[i], "");
    }

    function airdropVeecon(
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) onlyOwner public {
        require(to.length == id.length && to.length == amount.length, "Length mismatch");
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(nftDasMagazineVeeconByMikeHager2023);
        for (uint256 i = 0; i < to.length; i++)
            token.mint(to[i], id[i], amount[i], "");
    }


    function mintHolder(uint256 amount, uint256 tokenId) public payable {
        require(isMintEnabled, "Mint not enabled");
        require(msg.value >= holderPrice * amount, "Not enough eth");
        require(amount > 0, "Amount must be greater than 0");
        
        ERC1155 magazinToken = ERC1155(nftDasMagazinAddress);
        ERC1155 magazineToken = ERC1155(nftDasMagazineAddress);
   
        require(magazinToken.balanceOf(msg.sender, tokenId) == 1 || magazineToken.balanceOf(msg.sender, tokenId) == 1, "Not eligible");

        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(nftDasMagazine20242Address);
        ERC1155PresetMinterPauser tokenVeecon = ERC1155PresetMinterPauser(nftDasMagazineVeeconByMikeHager2023);
        
        for(uint256 i = 0; i < amount; i++){
            token.mint(msg.sender, _idTracker.current(), 1, "");
            _idTracker.increment();
        }

        //Mint Veecon NFT if amount is greater or equal than 3
        if(amount >= 3){
            uint amountVeecon = amount / 3;
            for(uint256 i = 0; i < amountVeecon; i++){
                tokenVeecon.mint(msg.sender, _idTrackerVeecon.current(), 1, "");
                _idTrackerVeecon.increment();
            }
        }
    }

    function mintPublic(uint256 amount) public payable {
        require(isMintEnabled, "Mint not enabled");
        require(msg.value >= publicPrice * amount, "Not enough eth");
        require(amount > 0, "Amount must be greater than 0");

        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(nftDasMagazine20242Address);
        ERC1155PresetMinterPauser tokenVeecon = ERC1155PresetMinterPauser(nftDasMagazineVeeconByMikeHager2023);

        for(uint256 i = 0; i < amount; i++){
            token.mint(msg.sender, _idTracker.current(), 1, "");
            _idTracker.increment();
        }

        //Mint Veecon NFT if amount is greater or equal than 3
        if(amount >= 3){
            uint amountVeecon = amount / 3;
            for(uint256 i = 0; i < amountVeecon; i++){
                tokenVeecon.mint(msg.sender, _idTrackerVeecon.current(), 1, "");
                _idTrackerVeecon.increment();
            }
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}