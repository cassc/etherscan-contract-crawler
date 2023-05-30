// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//             _____ _____ _____ _____ _ _ _ _____ _____ _____             //
//            |_   _| __  |     |   | | | | |  _  | __  |   __|            //
//              | | |    -|  |  | | | | | | |     |    -|__   |            //
//              |_| |__|__|_____|_|___|_____|__|__|__|__|_____|            //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

// @author: miinded.com

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../libs/ERC721Mint.sol";
import "../libs/MultiMint.sol";
import "../libs/Withdraw.sol";

contract TronX is ERC721Mint, MultiMint, Withdraw {

    IERC721 public TronWars;
    mapping (uint256 => bool) tronWarsClaimed;

    constructor(string memory baseURI, address _tronWars) ERC721("TronX", "TRONX") Withdraw(){

        setMaxSupply(8_888);
        setReserve(1);
        setBaseUri(baseURI);

        setMint("CLAIM", Mint(1650663000, 1650922199, 0, 25, 0, false, true));
        setMint("PUBLIC", Mint(1650922200, 1966525200, 0, 5, type(uint256).max, false, true));

        withdrawAdd(Part(0x3DD0f8a99E5FacF618DbF9D6fe175e7cCe1106Fd, 100));

        setTronWarsCollection(_tronWars);
    }

    //******************************************************//
    //                      Mint                            //
    //******************************************************//
    function claim(uint256[] memory _tokenIds) public payable canMint("CLAIM", _tokenIds.length) notSoldOut(_tokenIds.length) nonReentrant {

        address wallet = _msgSender();

        for (uint16 i = 0; i < _tokenIds.length; i++) {
            require(TronWars.ownerOf(_tokenIds[i]) == wallet , "Not owner of this TronWars token");
            require(isTronWarsClaimed(_tokenIds[i]) == false, "The TronWars token has already been claimed");
            tronWarsClaimed[_tokenIds[i]] = true;

            _mintToken(wallet);
        }
    }
    function buy(uint32 _count) public payable canMint("PUBLIC", _count) notSoldOut(_count) nonReentrant {
        _mintTokens(_msgSender(), _count);
    }

    //******************************************************//
    //                      Base                            //
    //******************************************************//
    function _baseURI() internal view virtual override returns (string memory) {
        return getBaseTokenURI();
    }

    function isTronWarsClaimed(uint256 _tokenId) public view returns (bool){
        return tronWarsClaimed[_tokenId];
    }

    function isTronWarsTokenIdsClaimed(uint256[] memory _tokenIds) public view returns (bool[] memory){
        bool[] memory claimed = new bool[](_tokenIds.length);
        for(uint256 i = 0; i < _tokenIds.length; i++){
            claimed[i] = isTronWarsClaimed(_tokenIds[i]);
        }
        return claimed;
    }

    function setTronWarsCollection(address _tronWars) public onlyOwner{
        TronWars = IERC721(_tronWars);
    }

    function reserve(uint32 _tokenId) public virtual override onlyOwner {
        super.reserve(1);
        tronWarsClaimed[uint256(_tokenId)] = true;
    }
}