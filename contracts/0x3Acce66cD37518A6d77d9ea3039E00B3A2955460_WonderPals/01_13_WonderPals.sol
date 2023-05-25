// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
                              ▄▄▄▄▄▄             ,▄▓███▄▄
                            ██████████▄        ▄██████████▄
                           ███╬╬╬╬╬╬████▌    ╓████▒╬╬╬╬╬███▌
                           ███╬╬╬╬╬▒╬╬╬███  ▄███▒╬╬▒╬╬╬╬╣███
                           ╙███▒╬╣████╬╬███▄███╬╬████╬╬▓███¬
                            ╙████▓╬█████╬█████▒████▓╬████▀
                              ╙▀███████████████████████▀
                                 ╙▀█████████████████▀─
                                     └▀▀███████▀▀└              ,▄▄▓███▓▄▄,
            ▄▓█████████▄,                 ███               ,▄██████▀▀▀██████▄
         ▄████▀▀▀╙╙╙▀▀████▓▄    ,▄▄▄▓███████████████▓▓▄▄▄▄▄████▀└        '╙████,
       ╓███▀└          └╙████████████▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀████████▀└              ╙███▄
      ┌███⌐                └╙╙╙└└                       '                    └███
      ███▌                                                                    ███
      ███⌐                                                                    ███
      ╟██▌                                                                   ▐██▌
       ███⌐                                                                  ███¬
       ▐██▌                                                                  ███▌
       ▓██▌                                                                  '███▄
      ▐███                                                                    └███
      ███⌐                                                                     ╟███
     ▐██▌                                                                       ███
     ███⌐                                                                       ╫██▌
     ███                  ▄▄▄                              ▄▓▓▄                 ▐███
    ▐███                 █████                            ▐████⌐                :███
    ▐██▌                 ╙▀█▀└                             ╙▀▀└                 j███
    ▐███                                                                        ▐███
     ███                          ████▄▄▄▄▄▄▄▄▄▄▄▄▄████⌐                        ███▌
     ███▌                         ╙▀▀███████████████▀▀~                        j███
      ███,                                                                     ███▀
      ╙███'                                                                   ███▌
       ╙███▄                                                                ,███▀
        ╙███▌                                                              ▄███¬
          ▀███▄                                                          ▄███▀
           '▀███▄,                                                    ╓▓███▀
              ▀████▄,                                              ▄▄████▀
                ╙▀█████▄▄                                     ,▄▄█████▀─
                    ╙▀██████▓▄▄▄,                      ,▄▄▄███████▀╙
                        └╙▀█████████████████████████████████▀▀╙─
                               ─└╙╙▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀╙╙└
---
dev: bueno.art
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Ticketed.sol";

error SaleInactive();
error SoldOut();
error InvalidPrice();
error InvalidQuantity();
error WithdrawFailed();

contract WonderPals is ERC721, Ownable, Ticketed {
    uint256 public nextTokenId = 1;
    uint256 public price = 0.08 ether;

    // tokenIds will range from 1-10000
    uint256 public constant SUPPLY = 10000;

    string public _baseTokenURI;

    bool public saleActive = false;

    address private b1 = 0x985AFcA097414E5510c2C4faEbDb287E4F237A1B;
    address private a1 = 0xCe95FD4D8CaBaAEDC35E0F3582b77709E6d1F0A4;

    constructor(string memory baseURI) ERC721("WonderPals", "WNDR") {
        _baseTokenURI = baseURI;
    }

    function mintOne(bytes calldata _signature, uint256 spotId)
        external
        payable
    {
        uint256 _nextTokenId = nextTokenId;
        if (!saleActive) revert SaleInactive();
        if (_nextTokenId > SUPPLY) revert SoldOut();
        if (msg.value != price) revert InvalidPrice();

        // invalidate the spotId passed in
        _claimAllowlistSpot(_signature, spotId);
        _mint(msg.sender, _nextTokenId);

        unchecked {
            _nextTokenId++;
        }

        nextTokenId = _nextTokenId;
    }

    function mint(bytes[] calldata _signatures, uint256[] calldata spotIds)
        external
        payable
    {
        uint256 _nextTokenId = nextTokenId;
        if (!saleActive) revert SaleInactive();
        // offset by 1 because we start at 1, and nextTokenId is incremented _after_ mint
        if (_nextTokenId + (spotIds.length - 1) > SUPPLY) revert SoldOut();
        if (msg.value != price * spotIds.length) revert InvalidPrice();

        for (uint256 i = 0; i < spotIds.length; i++) {
            // invalidate the spotId passed in
            _claimAllowlistSpot(_signatures[i], spotIds[i]);
            _mint(msg.sender, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }

        nextTokenId = _nextTokenId;
    }

    function devMint(address receiver, uint256 qty) external onlyOwner {
        uint256 _nextTokenId = nextTokenId;
        if (_nextTokenId + (qty - 1) > SUPPLY) revert InvalidQuantity();

        for (uint256 i = 0; i < qty; i++) {
            _mint(receiver, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }
        nextTokenId = _nextTokenId;
    }

    function totalSupply() public view virtual returns (uint256) {
        return nextTokenId - 1;
    }

    function setSaleState(bool active) external onlyOwner {
        saleActive = active;
    }

    function setClaimGroups(uint256 num) external onlyOwner {
        _setClaimGroups(num);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool s1, ) = b1.call{value: (address(this).balance * 15) / 100}("");
        (bool s2, ) = a1.call{value: (address(this).balance)}("");

        if (!s1 || !s2) revert WithdrawFailed();
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setSigner(address _signer) external onlyOwner {
        _setClaimSigner(_signer);
    }

    function tokensOf(address wallet) public view returns (uint256[] memory) {
        uint256 supply = totalSupply();
        uint256[] memory tokenIds = new uint256[](balanceOf(wallet));

        uint256 currIndex = 0;
        for (uint256 i = 1; i <= supply; i++) {
            if (wallet == ownerOf(i)) tokenIds[currIndex++] = i;
        }

        return tokenIds;
    }
}