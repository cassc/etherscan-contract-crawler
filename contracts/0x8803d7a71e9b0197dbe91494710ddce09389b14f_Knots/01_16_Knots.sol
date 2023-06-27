// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Knots is ERC721, Ownable, Pausable {
    //                                    O
    //                                    OO
    //                                   OUUO
    //                                  OUPPUO
    //                                 OUPHHPUO
    //                                OUPHŌŌHPUO
    //                               OUPHŌRRŌHPUO
    //                              OUPHŌRKKRŌHPUO
    //                             OUPHŌRKNNKRŌHPUO
    //                            OUPHŌRKNOONKRŌHPUO
    //                           OUPHŌRKNOTTONKRŌHPUO
    //                          OUPHŌRKNOTSSTONKRŌHPUO
    //                         OUPHŌRKNOTSNNSTONKRŌHPUO
    //                        OUPHŌRKNOTSNOONSTONKRŌHPUO
    //                       OUPHŌRKNOTSNOVVONSTONKRŌHPUO
    //                      OUPHŌRKNOTSNOVEEVONSTONKRŌHPUO
    //                     OUPHŌRKNOTSNOVELLEVONSTONKRŌHPUO
    //                    OUPHŌRKNOTSNOVELPPLEVONSTONKRŌHPUO
    //                   OUPHŌRKNOTSNOVELPUUPLEVONSTONKRŌHPUO
    //                  OUPHŌRKNOTSNOVELPUNNUPLEVONSTONKRŌHPUO
    //                 OUPHŌRKNOTSNOVELPUNGGNUPLEVONSTONKRŌHPUO
    //                OUPHŌRKNOTSNOVELPUNGAAGNUPLEVONSTONKRŌHPUO
    //               OUPHŌRKNOTSNOVELPUNGATTAGNUPLEVONSTONKRŌHPUO
    //              OUPHŌRKNOTSNOVELPUNGATZZTAGNUPLEVONSTONKRŌHPUO
    //               OUPHŌRKNOTSNOVELPUNGATTAGNUPLEVONSTONKRŌHPUO
    //                OUPHŌRKNOTSNOVELPUNGAAGNUPLEVONSTONKRŌHPUO
    //                 OUPHŌRKNOTSNOVELPUNGGNUPLEVONSTONKRŌHPUO
    //                  OUPHŌRKNOTSNOVELPUNNUPLEVONSTONKRŌHPUO
    //                   OUPHŌRKNOTSNOVELPUUPLEVONSTONKRŌHPUO
    //                    OUPHŌRKNOTSNOVELPPLEVONSTONKRŌHPUO
    //                     OUPHŌRKNOTSNOVELLEVONSTONKRŌHPUO
    //                      OUPHŌRKNOTSNOVEEVONSTONKRŌHPUO
    //                       OUPHŌRKNOTSNOVVONSTONKRŌHPUO
    //                        OUPHŌRKNOTSNOONSTONKRŌHPUO
    //                         OUPHŌRKNOTSNNSTONKRŌHPUO
    //                          OUPHŌRKNOTSSTONKRŌHPUO
    //                           OUPHŌRKNOTTONKRŌHPUO
    //                            OUPHŌRKNOONKRŌHPUO
    //                             OUPHŌRKNNKRŌHPUO
    //                              OUPHŌRKKRŌHPUO
    //                               OUPHŌRRŌHPUO
    //                                OUPHŌŌHPUO
    //                                 OUPHHPUO
    //                                  OUPPUO
    //                                   OUUO
    //                                    OO
    //                                     O
    // Classification of embedded Knot categories:
    //
    // -EDEN-Green: East: wood, sunrise, spring, nurturing, sensitivity, sight, birth,
    //       windy, door, sour, rancid, finned						
    //////////////////////////////////
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    // -FIRE-Red: South: fire, midday, summer, advancing, creativity, speech, youth, hot,
    //    hearth, bitter, scorched, feathered
    ////////////
    // -ANIMALS-White: West: metal, sunset, autumn, divines, intuition, smell, mature,
    //       dry, gate, sharp, putrid, furry//////////////////////////
    /////////////////////////////////
    // -DIAL-Black: North: water, midnight, winter, receives, empathy, hearing, death,
    //     cold, pond/path, salty, musty, scaly/shelled/////
    //////////////////////
    //////
    //\\\\\\\\\
    // -Embed in lightlessness of background: voices noise my love-
    //        PATRICAALEADELKLEPOTHLOVEALL
    /////////////////////////////////////////////////////////////////////\\\\\\
    ////////////////////////////////////////////////////////////////\\\\\\\\\\\\\
    // INFO (of evocation): This Knot is a thick bodied serpent encircling a scarab
    // centered in the earth and as an interconnected network they collectively
    // follow the source of light///////////////////////////////////////
    /////////////////////////////////////////////////////////
    ////////////////////////////////////////////
    // CALL (voice of God): IAŌ SABAŌTH ADŌAI EILŌEIN SEBŌEIN TALLAM CHAUNAŌN SAGĒNAM\
    // ELEMMEDŌR CHAPSOUTHI SETTŌRA SAPHTHA NOUCHITHA, Abraham, Isaac, Jacob, CHATHATHICH
    // ZEUPEIN NĒPHYGOR ASTAPHAIOS KATAKERNĒPH KONTEOS KATOUT KĒRIDEU MARMARIŌTH LIKYXANTA
    // BESSOUM SYMEKONTEU, the opponent of Thoth, MASKELLI MASKELLŌTH PHNOU KENTABAŌTH//
    // OREOBAZAGRA HIPPOCHTHŌN RĒSICHTHŌN PYRIPĒGANYX NYXIŌ ABRŌROKORE KODĒRE MOUISDRŌ,\
    // King, THATH PHATH CHATH XEUZĒN ZEUZEI SOUSĒNĒ ELATHATH MELASIŌ KOUKŌR NEUSŌŌ PACHIŌ
    // XIPHNŌ THEMEL NAUTH BIOKLĒTH SESSŌR CHAMEL CHASINEU XŌCHŌIALLINŌI / SEISENGPHARANGĒS
    // MASICHIŌR IŌTABAAS CHENOUCHI CHAAM PHACHIARATH NEEGŌTHARA IAM ZEŌCH AKRAMMACHAMAREI
    // Cheroubei(m) BAINCHŌŌCH EIOPHALEON ICHNAŌTH PŌE XEPHITHŌTH XOUTHOUTH THOŌTHIOU////
    // XERIPHŌNAR EPHINARASŌR CHANIZARA ANAMEGAR IŌO XTOURORIAM IŌK NIŌR CHETTAIOS ELOUMAIOS
    // NŌIŌ DAMNAMENEU / AXIŌTHŌPH PSETHAIAKKLŌPS SISAGETA NEORIPHRŌR HIPPOKELEPHOKLŌPS////
    // ZEINACHA OAPHETHANA A E Ē I O Y Ō—[then complete consecration.///////////////////
    // Followed by Procedure: repeat three times each day in the third, sixth, and ninth
    // hour, and this for fourteen days, beginning when moon begins its third quarter./
    // Continue as directed in PGMXII. 270-350— synced to + nexus of locational reflection
    // in locality and chronology]//////////////////////////////////////////////////////
    ///////////////////////////////////////////////////
    /////////////////////////
    ////////////////////
    /////////////
    //////
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    // ACTIVATE (during use): when intended via OUPHŌR, etc.335—350 
    ///////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    ///////////////////////////////////////////


    event KnotMinted(
        address recipient,
        uint256 tokenId
    );

    uint MAX_KNOTS = 720;
    uint8 MAX_MINTS = 5;

    uint MINT_PRICE = 27e16;

    mapping (address => bool) hasVoucher;
    uint16[] knotsAvailable = new uint16[](MAX_KNOTS);
    uint public redeemStartsAt;
    uint public saleStartsAt;
    string baseURI;

    address payable wurmWallet;
    address payable violetWallet;
    address payable nemesisWallet;
    address payable atavisceralWallet;
    address payable delugeWallet;

    uint8 wurmShare = 20;
    uint8 violetShare = 30;
    uint8 nemesisShare = 10;
    uint8 atavisceralShare = 10;

    constructor(
        string memory metadataBaseURI,
        address payable _delugeWallet,
        address payable _wurmWallet,
        address payable _violetWallet,
        address payable _nemesisWallet,
        address payable _atavisceralWallet,
        uint _redeemStartsAt,
        uint _saleStartsAt,
        address[] memory novelTokenHolders
    ) ERC721("KNOTS", "KNOT") {
        for(uint16 i; i < MAX_KNOTS; i++) {
            knotsAvailable[i] = i+1;
        }

        wurmWallet = _wurmWallet;
        violetWallet = _violetWallet;
        nemesisWallet = _nemesisWallet;
        atavisceralWallet = _atavisceralWallet;
        delugeWallet = _delugeWallet;

        redeemStartsAt = _redeemStartsAt;
        saleStartsAt = _saleStartsAt;

        for (uint16 i = 0; i < novelTokenHolders.length; i++) {
            hasVoucher[novelTokenHolders[i]] = true;
        }

        baseURI = metadataBaseURI;

        // mint team supply
        mintKnot(wurmWallet, 0);
        mintKnot(wurmWallet, 0);
        mintKnot(wurmWallet, 0);
        mintKnot(violetWallet, 0);
        mintKnot(violetWallet, 0);
        mintKnot(nemesisWallet, 0);
        mintKnot(atavisceralWallet, 0);
        for (uint8 i = 0; i < 13; i++) {
            mintKnot(delugeWallet, 0);
        }
    }

    function mint(address recipient, uint seed, uint8 count) public payable whenNotPaused {
        require(knotsAvailable.length > 0, "Knots: sold out");
        require(count > 0 && count <= MAX_MINTS, "Knots: maximum mint count exceeded");

        if (hasVoucher[msg.sender]) {
            require(block.timestamp >= redeemStartsAt, "Knots: redeem window has not opened");
            require(msg.value == (count - 1)*MINT_PRICE, "Knots: invalid mint fee for novel token holder");
            hasVoucher[msg.sender] = false;
        } else {
            require(block.timestamp >= saleStartsAt, "Knots: sale has not started");
            require(msg.value == count*MINT_PRICE, "Knots: invalid mint fee");
        }

        for (uint8 i = 0; i < count; i++) {
            mintKnot(recipient, seed);
        }

        uint wurmReceives = msg.value * wurmShare / 100;
        uint violetReceives = msg.value * violetShare / 100;
        uint atavisceralReceives = msg.value * atavisceralShare / 100;
        uint nemesisReceives = msg.value * nemesisShare / 100;
        uint delugeReceives = msg.value - wurmReceives - violetReceives - atavisceralReceives - nemesisReceives;

        wurmWallet.transfer(wurmReceives);
        nemesisWallet.transfer(nemesisReceives);
        violetWallet.transfer(violetReceives);
        atavisceralWallet.transfer(atavisceralReceives);
        delugeWallet.transfer(delugeReceives);
    }

    // ============ PUBLIC VIEW FUNCTIONS ============

    function hasVouchers(address recipient) public view returns (bool) {
        return hasVoucher[recipient];
    }

    function totalSupply() public view returns (uint) {
        return MAX_KNOTS - knotsAvailable.length;
    }

    // ============ OWNER INTERFACE ============

    function updatePaused(bool _paused) public onlyOwner {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function updateBaseURI(string calldata __baseURI) public onlyOwner {
        baseURI = __baseURI;
    }

    function updateRedeemStartsAt(uint _redeemStartsAt) public onlyOwner {
        redeemStartsAt = _redeemStartsAt;
    }

    function updateSaleStartsAt(uint _saleStartsAt) public onlyOwner {
        saleStartsAt = _saleStartsAt;
    }

    // ============ INTERNAL INTERFACE ============

    function mintKnot(address recipient, uint _seed) internal {
        uint numKnots = knotsAvailable.length;
        require(numKnots > 0, "Knots: not enough knots available for mint");
        uint seed = uint(keccak256(abi.encodePacked(_seed)));
        uint index = seed % numKnots;

        uint tokenId = knotsAvailable[index];

        knotsAvailable[index] = knotsAvailable[numKnots-1];
        knotsAvailable.pop();

        _mint(recipient, tokenId);
        emit KnotMinted(recipient, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}

////////////////////////////////////////////
/////contract/by/wurmhumus-fabrik.net///////
////////////////////////////////////////////