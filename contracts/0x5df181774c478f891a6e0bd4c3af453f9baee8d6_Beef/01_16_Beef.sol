// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//                     need no permission                             //
//                     grazing on the lush grass hills                //
//                     both beef and babe chew                        //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                       0xfff.eth    //
//                                                                    //
////////////////////////////////////////////////////////////////////////

import "./BeefERC721.sol";

import {ConceptStruct} from "../libraries/ConceptStruct.sol";
import {Render} from "../libraries/Render.sol";
import {Util} from "../libraries/Util.sol";

uint256 constant PERMISSIONLESS = 1;
uint256 constant NO_EXTERNALITIES = 2;
uint256 constant OPENING_HOURS = 3;
uint256 constant DEAD_BEEF = 4;
uint256 constant MUTUAL_A = 5;
uint256 constant MUTUAL_B = 6;
uint256 constant FAIR_PRICE = 7;
uint256 constant BEEF_BABE = 8;
uint256 constant SATED = 9;
uint256 constant DARK = 10;
uint256 constant RETRACTED = 11;
uint256 constant BAD_BEEF = 12;
uint256 constant EOA = 13;
uint256 constant SAMEBLOCK_I = 14;
uint256 constant SAMEBLOCK_II = 15;
uint256 constant SAMEBLOCK_III = 16;
uint256 constant LIMITED_USE = 17;
uint256 constant DEAF_BABE = 18;
uint256 constant DECREASE = 19;
uint256 constant SECRET_POEM = 20;
uint256 constant LOCUS = 21;
uint256 constant PERMANENCE_I = 22;
uint256 constant BEEF_BEEF = 23;
uint256 constant DEPENDENT_A = 24;
uint256 constant DEPENDENT_B = 25;
uint256 constant LIGHT = 26;
uint256 constant INCREASE = 27;
uint256 constant DEAD_BABE = 28;
uint256 constant CONTINUOUS = 29;
uint256 constant SECRET_JOKE = 30;
uint256 constant PERMANENCE_II = 31;
uint256 constant DEAF_BEEF = 32;
uint256 constant MAXIMALISM = 33;
uint256 constant COINBASE = 34;
uint256 constant BABE_BEEF = 35;
uint256 constant BEEF_FACE = 36;
uint256 constant FEED_BEEF = 37;
uint256 constant SECRET_TRUTH = 38;
uint256 constant CHROMATIC = 39;
uint256 constant UNWIELDY = 40;
uint256 constant BAD_BABE = 41;
uint256 constant TRANSITORY_OWNERSHIP = 42;

error NoBeef();
error CurrentlyClosed();
error HalfOfTheTime();
error Codependent();
error MutuallyExclusive();
error NotFairPrice();
error NotLight();
error NotDark();
error NotChromatic();
error NotContract();
error NotCoinbase();
error NotContinuous();

contract Beef is BeefERC721 {

    /*//////////////////////////////////////////////////////////////
                             Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() BeefERC721("BEEF", "BEEF") {
        _mint(block.coinbase, TRANSITORY_OWNERSHIP);
        totalSupply++;
    }

    /*//////////////////////////////////////////////////////////////
                            Tokens / Mint
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply = 0;
    uint256 public editionSize = 42;
    uint256 constant public price = 0.1 ether;

    function mint(uint256 _tokenId) external payable {
        require(_tokenId > 0 && _tokenId <= editionSize); // starts at 1
        uint256 mintPrice = (_tokenId == UNWIELDY ? (1 ether + price) : price);
        require(msg.value == mintPrice);
        _mint(msg.sender, _tokenId);
        totalSupply++;
    }

    function withdraw(address payable _to) public onlyArtist {
        (bool success,) = _to.call{value: address(this).balance}("");
        require(success);
    }

    /*//////////////////////////////////////////////////////////////
                            Concept Data
    //////////////////////////////////////////////////////////////*/

    mapping (uint256 => ConceptStruct.Concept) concepts;
    mapping (uint256 => uint256) tokenIdToConcept;

    function setConceptData(ConceptStruct.Concept[] memory _concepts) public onlyArtist {
        for (uint i = 0; i < _concepts.length; i++) {
            ConceptStruct.Concept memory concept = _concepts[i];
            uint256 conceptId = concept._editionTokenRangeStart;
            concepts[conceptId] = concept;
            for (uint j = concept._editionTokenRangeStart; j < concept._editionTokenRangeStart + concept._editionSize; j++) {
                tokenIdToConcept[j] = conceptId;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            Custom State
    //////////////////////////////////////////////////////////////*/

    mapping (uint256 => uint256) sameBlockAt;
    mapping (uint256 => address) sameBlockTo;
    uint256 public fairPrice = 0.1 ether;
    uint96 public increasable = 1;
    uint96 public decreasable = 1111111111111111111111111111;
    uint256 public transfersLeft = 7;

    /*//////////////////////////////////////////////////////////////
                            Custom Methods
    //////////////////////////////////////////////////////////////*/

    function buyAtFairPrice() external payable {
        // Anyone can buy at fair price
        if (_ownerOf[FAIR_PRICE] == address(0)) {
            if (msg.value < fairPrice) revert NotFairPrice();
            _mint(msg.sender, FAIR_PRICE);
        } else if (msg.value > fairPrice) {
            fairPrice = msg.value;
            _transferFromInternal(_ownerOf[FAIR_PRICE], msg.sender, FAIR_PRICE);
        } else {
            revert NotFairPrice();
        }
    }

    function increase() external payable {
        // Anyone can increase
        increasable++;
    }

    function decrease() external payable {
        // Anyone can decrease
        decreasable--;
    }

    function retract() external onlyArtist {
        // The artist can retract this piece at any time
        _transferFromInternalNoHooksAndChecks(_ownerOf[RETRACTED], artist(), RETRACTED);
    }

    function isOpenHours() public view returns (bool) {
        // Opening hours are from  9-5 UTC
        uint256 daytime = block.timestamp % (24 * 3600);
        return (daytime >= 9 * 3600) && (daytime <= 17 * 3600);
    }

    function whereIs(address _address) public pure returns (uint256 x, uint256 y , uint256 z) {
        // This piece will output three spacial coordinates for the current address.
        // It can be used to spacially relate addresses
        uint256 addressNumber = uint256(keccak256(abi.encodePacked(_address)));
        x = addressNumber % 10e4;
        y = (addressNumber >> 8) % 10e4;
        z = (addressNumber >> 16) % 10e3;
    }

    function updateTransitory() external {
        _transferFromInternal(_ownerOf[TRANSITORY_OWNERSHIP], block.coinbase, TRANSITORY_OWNERSHIP);
    }

    /*//////////////////////////////////////////////////////////////
                          Hooks and Overrides
    //////////////////////////////////////////////////////////////*/

    function ownerOf(uint256 id) public view override returns (address) {
        if (id == TRANSITORY_OWNERSHIP) {
            return block.coinbase;
        } else if (
            (id == PERMANENCE_I  && block.number % 2 == 0) ||
            (id == PERMANENCE_II && block.number % 2 == 1)
        ) {
            revert HalfOfTheTime();
        } else if (id == OPENING_HOURS) {
            if(!isOpenHours()) revert CurrentlyClosed();
        }
        return super.ownerOf(id);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == block.coinbase) {
            return 1 + _balanceOf[owner];
        }
        return super.balanceOf(owner);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override payable {
        if (id == PERMISSIONLESS) {
            _transferFromInternal(from, to, id);
        } else if (id == TRANSITORY_OWNERSHIP) {
            _transferFromInternal(from, to, id);
        } else {
            super.transferFrom(from, to, id);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override payable {
        if (id == PERMISSIONLESS) {
            _transferFromInternal(from, to, id);
        } else if (id == TRANSITORY_OWNERSHIP) {
            _transferFromInternal(from, to, id);
        } else {
            super.transferFrom(from, to, id);
        }

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );

    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public override payable {
        if (id == PERMISSIONLESS) {
            _transferFromInternal(from, to, id);
        } else if (id == TRANSITORY_OWNERSHIP) {
            _transferFromInternal(from, to, id);
        } else {
            super.transferFrom(from, to, id);
        }

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {}

    function _beforeTokenTransfer(
        address /* from */,
        address to,
        uint256 tokenId
    ) internal override returns (bool) {
        if (tokenId == SATED) {

            // PERMANENCE SATED
            // This piece can only be transfered as the only transaction in a block
            uint256 waste; for (uint256 i = 0; i < 159160; i++) waste++;

        } else if (
            (tokenId == PERMANENCE_I  && block.number % 2 == 0) ||
            (tokenId == PERMANENCE_II && block.number % 2 == 1)
        ) {

            // PERMANENCE I & II
            // This piece exists half of the time
            revert HalfOfTheTime();

        } else if (tokenId == TRANSITORY_OWNERSHIP) {

            // TRANSITORY OWNERSHIP
            // This piece will always belong to the current validator
            require(to == block.coinbase);

        } else if (tokenId == OPENING_HOURS) {

            // OPENING HOURS
            // This piece has opening hours during which it exists and can be transferred
            if (!isOpenHours()) revert CurrentlyClosed();

        } else if (tokenId == DEAD_BEEF || tokenId == BEEF_BEEF || tokenId == FEED_BEEF || tokenId == DEAF_BEEF
                || tokenId == BAD_BEEF  || tokenId == BEEF_FACE || tokenId == BABE_BEEF || tokenId == BEEF_BABE
                || tokenId == BAD_BABE  || tokenId == DEAF_BABE || tokenId == DEAD_BABE
        ) {

            // DEAD BEEF
            // This piece can only be held by an address starting with DEAD and ending with BEEF
            bytes20 addr = bytes20(to);
            if (
                (
                    (tokenId == DEAD_BEEF && (addr & hex"ffff00000000000000000000000000000000ffff" == hex"dead00000000000000000000000000000000beef"))
                    ||
                    (tokenId == BEEF_BEEF && (addr & hex"ffff00000000000000000000000000000000ffff" == hex"beef00000000000000000000000000000000beef"))
                    ||
                    (tokenId == FEED_BEEF && (addr & hex"ffff00000000000000000000000000000000ffff" == hex"feed00000000000000000000000000000000beef"))
                    ||
                    (tokenId == DEAF_BEEF && (addr & hex"ffff00000000000000000000000000000000ffff" == hex"deaf00000000000000000000000000000000beef"))
                    ||
                    (tokenId == BAD_BEEF && (addr & hex"fff000000000000000000000000000000000ffff" == hex"bad000000000000000000000000000000000beef"))
                    ||
                    (tokenId == BEEF_FACE && (addr & hex"ffff00000000000000000000000000000000ffff" == hex"beef00000000000000000000000000000000face"))
                    ||
                    (tokenId == BABE_BEEF && (addr & hex"ffff00000000000000000000000000000000ffff" == hex"babe00000000000000000000000000000000beef"))
                    ||
                    (tokenId == BEEF_BABE && (addr & hex"ffff00000000000000000000000000000000ffff" == hex"beef00000000000000000000000000000000babe"))
                    ||
                    (tokenId == BAD_BABE && (addr & hex"fff000000000000000000000000000000000ffff" == hex"bad000000000000000000000000000000000babe"))
                    ||
                    (tokenId == DEAF_BABE && (addr & hex"ffff00000000000000000000000000000000ffff" == hex"deaf00000000000000000000000000000000babe"))
                    ||
                    (tokenId == DEAD_BABE && (addr & hex"ffff00000000000000000000000000000000ffff" == hex"dead00000000000000000000000000000000babe"))
                ) == false
            ) {
                revert NoBeef();
            }

        } else if (tokenId >= SAMEBLOCK_I && tokenId <= SAMEBLOCK_III) {

            // SAME BLOCK
            // The three pieces from this edition can only be transferred in the same block
            uint256 dependentIdA = tokenId == SAMEBLOCK_I ? SAMEBLOCK_II : SAMEBLOCK_I;
            uint256 dependentIdB = tokenId == SAMEBLOCK_I ? SAMEBLOCK_III : tokenId == SAMEBLOCK_II ? SAMEBLOCK_III : SAMEBLOCK_II;
            if (sameBlockAt[dependentIdA] == block.number && sameBlockAt[dependentIdB] == block.number) {
                _ownerOf[dependentIdA] == address(0)
                    ? _mintNoHooks(sameBlockTo[dependentIdA], dependentIdA)
                    : _transferFromInternalNoHooksAndChecks(_ownerOf[dependentIdA], sameBlockTo[dependentIdA], dependentIdA);
                _ownerOf[dependentIdB] == address(0)
                    ? _mintNoHooks(sameBlockTo[dependentIdB], dependentIdB)
                    : _transferFromInternalNoHooksAndChecks(_ownerOf[dependentIdB], sameBlockTo[dependentIdB], dependentIdB);
                return true;
            } else {
                sameBlockAt[tokenId] = block.number;
                sameBlockTo[tokenId] = to;
                return false;
            }

        } else if (tokenId == DEPENDENT_A || tokenId == DEPENDENT_B) {

            // CO-DEPENDENT
            // The two pieces of this edition are co-dependent. A piece can only be acquired if the sum of the
            // first three and of the last three digits of both the owning addresses are smaller than or equal
            // to 0xFFF = 4095 respectively
            uint256 dependentId = tokenId == DEPENDENT_A ? DEPENDENT_B : DEPENDENT_A;
            if (
                (
                    uint160(_ownerOf[dependentId]) % 4096 + uint160(to) % 4096 < 4096
                    &&
                    uint160(bytes20(_ownerOf[dependentId]) >> 148) % 4096 + uint160(bytes20(to) >> 148) % 4096 < 4096
                ) == false
            ) {
                revert Codependent();
            }

        } else if (tokenId == MUTUAL_A || tokenId == MUTUAL_B) {

            // MUTUALLY EXCLUSIVE
            // The two pieces of this edition are mutually exclusive. Each piece can only be
            // owned if the other owning address has no matching digits
            uint256 dependentId = tokenId == MUTUAL_A ? MUTUAL_B : MUTUAL_A;
            bytes20 bytesDependent = bytes20(_ownerOf[dependentId]);
            bytes20 bytesTo = bytes20(to);
            for (uint i = 0; i < 40; i++) {
                if (uint160(bytesDependent >> i * 4) % 16 == uint160(bytesTo >> i * 4) % 16) {
                    revert MutuallyExclusive();
                }
            }

        } else if (tokenId == LIGHT) {

            // LIGHT
            // This piece can only be held by addresses containing at least 13 instances of F and no instances of 0
            bytes20 bytesTo = bytes20(to);
            uint16 count;
            for (uint i ; i < 40; i++) {
                if (uint160(bytesTo >> i * 4) % 16 == 0) break;
                if (uint160(bytesTo >> i * 4) % 16 == 15) count++;
                if (count > 13) return true;
            }
            revert NotLight();

        } else if (tokenId == DARK) {

            // DARK
            // This piece can only be held by addresses containing at least 13 instances of 0 and no instances of F
            bytes20 bytesTo = bytes20(to);
            uint16 count;
            for (uint i ; i < 40; i++) {
                if (uint160(bytesTo >> i * 4) % 16 == 15) break;
                if (uint160(bytesTo >> i * 4) % 16 == 0) count++;
                if (count > 13) return true;
            }
            revert NotDark();

        } else if (tokenId == CHROMATIC) {

            // CHROMATIC
            // This piece can only be held by addresses containg at least 1 of each hexadecimal digit
            bytes20 bytesTo = bytes20(to);
            uint256 bitmap;
            for (uint256 i; i < 40; i++) {
                bitmap |= (1 << (uint160(bytesTo >> i * 4) % 16));
                if (bitmap == 65535) return true;
            }
            revert NotChromatic();

        } else if (tokenId == NO_EXTERNALITIES) {

            // NO EXTERNALITIES
            // This piece can only be held by a contract
            uint size;
            assembly { size := extcodesize(to) }
            if (size == 0) revert NotContract();

        } else if (tokenId == EOA) {

            // EOA
            // This piece cannot be held by a contract
            uint size;
            assembly { size := extcodesize(to) }
            require(size == 0);
            require(tx.origin == msg.sender);

        } else if (tokenId == LIMITED_USE) {

            // LIMITED USE
            // This piece can only be transfered 7 times after which it will self destruct
            if (transfersLeft > 0) {
                transfersLeft--;
            } else {
                // bye
                _transferFromInternalNoHooksAndChecks(_ownerOf[LIMITED_USE], address(0xdEaD), LIMITED_USE);
                return false; // don't transfer
            }

        } else if (tokenId == UNWIELDY) {

            // UNWIELDY
            // This piece requires burning 1 ETH to be transfered.
            require(msg.value >= 1 ether && msg.value <= 1 ether + price);
            (bool success,) = address(0).call{value: 1 ether}(""); // good bye
            require (success);

        } else if (tokenId == COINBASE) {

            // COINBASE
            // This piece can only transfered to the block.coinbase address.
            // As such it can only be received by validators
            if (to != block.coinbase) revert NotCoinbase();

        } else if (tokenId == CONTINUOUS) {

            // CONTINUOUS
            // This piece can only be transfered to an address that has the
            // first three digits of the previous address as its last three
            bytes20 bytesFrom = bytes20(_ownerOf[CONTINUOUS]);
            bytes20 bytesTo = bytes20(to);
            for (uint i = 0; i < 3; i++) {
                if (uint160(bytesFrom >> (i) * 4) % 16 != uint160(bytesTo >> (40 - (3 - i)) * 4) % 16) {
                    revert NotContinuous();
                }
            }

        }

        return true;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Metadata
    ///////////////////////////////////////////////////////////////////////////

    function renderSVG(uint256 _tokenId) external view returns (string memory) {
        ConceptStruct.Concept memory concept = _getConceptFromTokenId(_tokenId);
        return Render.renderSVG(_tokenId, concept, font);
    }

    function renderSVGBase64(uint256 _tokenId) external view returns (string memory) {
        ConceptStruct.Concept memory concept = _getConceptFromTokenId(_tokenId);
        return Render.renderSVGBase64(_tokenId, concept, font);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (
            (_tokenId == PERMANENCE_I  && block.number % 2 == 0) ||
            (_tokenId == PERMANENCE_II && block.number % 2 == 1)
        ) {
            revert HalfOfTheTime();
        } else if (_tokenId == OPENING_HOURS) {
            if(!isOpenHours()) revert CurrentlyClosed();
        }
        require(_ownerOf[_tokenId] != address(0), "NOT_MINTED");
        ConceptStruct.Concept memory concept = _getConceptFromTokenId(_tokenId);
        return Render.tokenURI(_tokenId, concept, font);
    }

    function _getConceptFromTokenId(uint256 _tokenId) private view returns (ConceptStruct.Concept memory) {
        uint256 conceptId = tokenIdToConcept[_tokenId];
        ConceptStruct.Concept memory concept = concepts[conceptId];

        if (_tokenId == FAIR_PRICE) {

            bytes32[] memory statusText = new bytes32[](1);
            statusText[0] = bytes32(abi.encodePacked("Price: ", Util.uint256ToString(uint256(fairPrice / 10e17)), ".", Util.uint256ToString(uint256((fairPrice / 10e16) % 10)), (fairPrice / 10e15) % 10 == 0 ? "" : Util.uint256ToString(uint256((fairPrice / 10e15) % 10)), " ETH"));
            concept._statusText = statusText;

        } else if (_tokenId == LIMITED_USE) {

            bytes32[] memory statusText = new bytes32[](1);
            statusText[0] = bytes32(abi.encodePacked("Transfers Left: ", Util.uint256ToString(uint256(transfersLeft))));
            concept._statusText = statusText;

        } else if (_tokenId == INCREASE) {

            concept._title = bytes32(abi.encodePacked(Util.uint256ToString(uint256(increasable))));

        } else if (_tokenId == DECREASE) {

            concept._title = bytes32(abi.encodePacked(Util.uint256ToString(uint256(decreasable))));

        } else if (_tokenId == OPENING_HOURS) {

            bytes32[] memory statusText = new bytes32[](1);
            statusText[0] = bytes32(abi.encodePacked("Currently ", isOpenHours() ? "Open" : "Closed"));
            concept._statusText = statusText;

        } else if (_tokenId == LOCUS) {

            bytes32[] memory statusText = new bytes32[](3);
            uint256 x; uint256 y; uint256 z;
            (x,y,z) = whereIs(_ownerOf[_tokenId]);
            statusText[0] = bytes32(abi.encodePacked(
                Util.uint256ToString(x), ", ",
                Util.uint256ToString(y), ", ",
                Util.uint256ToString(z)
            ));
            concept._statusText = statusText;

        }

        return concept;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Font
    ///////////////////////////////////////////////////////////////////////////

    string private font = "data:application/font-woff2;charset=utf-8;base64,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";

}