// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title: NFTBoil
/// @author: HayattiQ
/// @dev: This contract using NFTBoil (https://github.com/HayattiQ/NFTBoil)
/// @update: This contract updated by takuya_nft

//.........`.``.``````````````````````````````````````````,)````.r````````````````````````````````````````.``.`...........
//.....````.``.```````````````````````````````````````````.$````.\`````````````````````````````````````.```.``.```.`......
//....`..`.`````.``.`````````````````````` `` ` ` ` `  ` ` S` ` J!` ` ` ` ` `` `````````````````````````````.``.``.``.....
//..``.``.``.```````````````````` `  `  ` `  ` ` ` ` `` ` `X_` `d  ` ` ` ` `  `      `  ` `` ``````````````````.`.`.`.`...
//.`.`.````````````````````` `  `` `` `  ` `` ` ` ` `  ` ` ()` .D` `  ` ` ` `` ```` ` `` ` `` ````````````````````.`.`.`..
//..`.`..`.`````````````` ` `` ` ` ` ` `` `  ` ` `  ` ` ` `,$ `.% ` ` `  `  ` `  ` ``  `` ` `  `  ````````````.````.``..`.
//`.``.``````````````` ` `` ` ` ` `  `  `  `      `         H  J:    `     `   `    ` `  ` ` `` ``  ````````````.```.``..`
//.`.``````````````` `` `  ` ` `  ` `    `  ` ` `  ` ` ` `  q;.K ` `  ` `  `  `  `   ` `  ` `  ` ``  ` ````````````.`.``..
//`.``.``.````````` ` ` ` ` `  `   `  ``     `   `    `   ` ,b.]  `      `   `   ` `    `   ` ` ` `` `  ``````````````.``.
//.``.``````````` `` ` ` ` `  `  `      ` `         `       .=?>     `        `   `  `  `  `  ` `  `` `` `````````.``.`..`
//`.```.````````` ` ` ` ` `  `  `  ` `     `  ` `  `   `  ` j  I `  `  `  `     `   `  `  `  `  ` `  `` `  ``````````.``.`
//``.``````````` `` ` `  `  `    `  `  `     `              j ?5           ` `        `     `  ` ` ` ` ```` ``````````.``.
//.```.````````` ` ` ` `   `  `         `         `     `   ?!__        `      `  `     ` `   `   ` ` `  ` `` ``````.``.`.
//`.``````````` ``  ` ` ` `  `  `  `     ` `   `     `      .((_   `             `  `      `   `   ` ` `` `````````````.``
//``.````````` `` `` `   `       `   `                      !   _     `    `  `      ` `    `  ` `  ` ` ` ` `` ```````.`.`
//.``.````````` ` ` ` `   ` `  `      `      `              -. _`                       `    `    `  ` ` ` ` ````````.```.
//``````````` `` ` `  ` `    `    `     `            ..(&wXZZZZZZXX&(..         `  `     `  `   `  ` ` `` ``` `````````.``
//.`.````````` ` ` ` `   ` `    `   `      `     .JwyyyyyyyyZyZyyyyyyyyyX&..         `        `  `  `  ` ` ````````````.`.
//`.``.```````` ` ` ` `  `  `  `       `      .dXyyyyZZZZZZZZZZZZZZZZyyyyyyXG..        `  `  `   `  ` ` ` `  `` `````.``.`
//``````````` `` ` `   `         `         .JXyyyyZZZZZZZuuZuuuuZuZZZZZZZyyyyyXo.`  `    `    `  `  `  ` ` `` ``````````.`
//.`.```````` `` `` ``  ` ` `  `    `    .JZyyyZZZZZuuuuuuuuuuuuuuuuuuuZZZZZyyyyXn,        `   `  `  `` `` ````````````.`.
//```.```````` ` `  ` `  `   `    `   ` (XyyyyZZZZuuuuuzzzzzzzzzzzzzzuuuuuZZZyyyVyXn. ` `   `   `  ` `  ` ` ` ````````.``.
//`.````````` ``` ``   `  `     `     .XyyyyZZZZuuuuzzzzvvvvrrrrrvrvvvzzuuuZZZZyyyVVk,   `   `   `  ` `` `` `` ````````.``
//.```.``````` ` ` `` `  `  `  `     (yyyyyZZZuuuzzzvvrrrrrrrrrrrrrrrrvvzzuuuZZZyyyVVyn       ` `  `  ` ` `````````````.`.
//``.`````````` ` `  ` `  `  `    `.dyVyyyZZZuuuzzvrrrrttrtttrtttttttrrrrvzuuuZZZyyyVfVk. ` `    `  `` ` ` ` `` `````.``.`
//`.```````` ``` `` ` `  `    `   .dyVyyyZZZuuzzvrrrttttttttttttttttttttrrvzXXuZZyyyyVffk.   ` `  ` ` ` ` `` ``````````.``
//.```.``````` `` ` `  `  ` `  ` .dVVVyyZZZuuzzvrrtttltttlttttttltlllttttrAdHHuuZZZyyVffpk.   `  ` ` ` `` ````````````.`..
//`.``````````` `` ` `` `  `     dffVyyZZZuuuzvAKMHOtllllttltltltlllllttGdHSvzuuuZZyyVVfppk.`   ` ` ` ` `` `` ```````.```.
//`.`.`````````` `` ` ` `  ` `  JffVyyyZZZuuzvrWHkX6lltlltttltttlttttlltdNmrvzuuuZZyyyVVfpph` ` `  ` ` ` `` ``````````.`.`
//.```.``````` `` `` ` ` `  `  .ppfVyyyZZuuuzvrrZUttttttlttttttttttttttttrTHkzzuuZZyyyyffppp[  ` `` ` `` ````````````.`.`.
//`.````````````` ` ` ` ` `    XfpfVyyyZZZuuzzvrrrttttttttttttttttttttrrrrrwMHuuZZZyyyyffpppk. `  ` `` `` `` ```````.``.`.
//.`..``.````````` `` `` ` `` .ppffVyyyZZZuuuzzvrrrrrtdQkrrrrrrrrrrdkkrrrvvzzuuuZZZyyyVfpppbp[` `` ` `` ``` `````````.``.`
//```.````````` ``` ``  ` `  `dpppffVyyyZZZuuuuzzvvrrQH#rrrrAQmyvvvvHWmvzzuuuuuZZZyyyyVffppbbR ` ` `` `` ```````````.`..`.
//..``.``````````` `` `` ` `  WbpppfVVyyyZZZZuuuuuzzwHMSzzwdWMMNHwzzdNMkuuuuuZZZyyyyVVfpppbkkW  ` ` ` `````````````.``.`..
//.`.`.`.```````` ``` `` `` ` WbbppfffVyyyyZZZZZuuuuXNMkXQHMBuudNWmkXMHHZuZZZZyyyyyVVfpppbbkqH ` ``` `` `` ````````.`.``..
//`.`.`.```````````` ` ``  `  [email protected] `` ` ``````````````.`.`..`.
//.`.```.`.```````````` ``` ``,kkkkbbppfffVVVyyyyyyyyZZZZZZZZZZZZZyZyyyyyyyyVVVfffppppbbkqqqk\` `` ``` ``````````.``.`....
//..`..``.````````` ```` ` `` `jqqkkkbbpppfffffVVVyyyyyyyyyyyyyyyyyyyyyVVVVfffpppppbbkkqqqqqf`` ````` ```````````.`.`.``..
//..`.`.````.````````` ``` ` ` `?HqqqqkkbbbppppfffffffffffVVfVVffffffffffpppppppbbkkqqqmmmHY`` ` ` ````````````.``.`..`...
//.`.`.`..``````````````` ``` ` `.4Hmmmqqqkkkbbbbppppppppppfppppppppppppppbbbkkkkqqqmgggg9'` `````` ```````````.`.`.`.....
//....`.`..`.`````````````````` `` [email protected]!`` `` ```````````````.`.`.`..`...
//..`..```.``.```````` ``` ` ``` ```` [email protected]@[email protected]@@@@HBY!`` ```` `` ````````````.``.`..`..`..
//...`...``.``.`````````` ```` ``` ````` `[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@[email protected]@@MBY"!```` `` ` `````` ``````````.`.`.`.......
//....`...`..``.````````````````` ` ` ` `` ````` ??WWHHHHHHHHHHHHHHHMMMHHY!``` ` ` ` ````` ````````````````.``.`...`......
//.....`.`.``.``.```````````` ``````````` ``  ` `` <<<<<<<<<<<<<<<<<<11zz```` ``` ``` ` ````` `````````````.`.`.`...`.....
//........`..`.`.``.```````````` ``` `` ```` `` ` `_::~~~~~~.~~~~~~~::;>:`` ` ` ``` ```` `````````````````.`.`...`........
//......`...`.`.`.```````````````````````` ```````  ~:~~~.........~~~~:< ` ````` ```````````````````````..`.`..`..........
//........`..`.`.`..`.``````````````````````` `` ``` ~~~~.........~~~:<````` ``````` `````````````````.``.``..`..`........
//..............`.``.`.`````````````````````````````` <:~~~~..~.~~~~(<````` ``` ````````````````````.``.`....`..........~.
//.~.......`..`..`..``..`.``````````````````````` ```` ~<_~~~~~~~~(<<``````````````````````````````.`..`.`.`............~~
//~..........`...`..`.``.`..````````````````````````````.<<___:(++<!````````````````````````````.`.`.`....`...`........~.~
//~.~...........`..`...`.``....`.````````````````````````` ?<<??!````````````````````````````.`.`.`.`.`.`............~~.~.
//~~.~~..............`....```.`.`..`.````````````````````````````````````````````````````.`..`..`......`............~.~~.~
//~.~~.~.~............`.`....`.`.``.`..`.``.````````````````````````````````````````.`..`..`.`.`..`..`............~.~~.~~~
//~~.~.~~..........................`.`..`..`.`..`.``.````.``.``.``.`.```````.``.`..`.`.`.`..`....`..`............~.~.~~~~~
//~~~~~.~~~~.~............`..`.`......`..`.`..`..`..`..`.`..`.`.`.`.`..`...`.`..`.`.`.`...`...`...............~.~~~.~~.~~~
//~~~~~~.~.~.~..~................`..`..`..`..`.``.`.`.`..``.`.``.`.``.`.`.`.`.`..`.......`..................~..~~.~~~~~~~~
//~~~~~~~.~~~.~~..~.........................`......`..`....`.`..`.`..`.`..`....`...`...`.................~.~~~~.~~~~~~~~~~
//~~~~~~~~~~~~~.~~.~.~.................................`..`..........................................~.~~.~.~~.~~~~~~~~~~~
//~~~~~~~~~~~~.~~~~.~~~.~~..~.....................................................................~.~.~~.~~~.~~~~~~~~~~~~:
//::~~~~~~~~~~~~~~~~.~~~~.~~.~.~.............................................................~.~~~.~~~.~~~~~~~~~~~~~~~:~:~
//:~::~:~~~~~~~~~~~~~~~.~~~.~~~~~~~~.~.~...............................................~.~~.~~.~~.~~~.~~~~~~~~~~~~~~:~::~:

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// This NFT License is a16z Can't be Evil Lisence
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

contract ShimejiKeychain is ERC721A, ERC2981 , Ownable, Pausable, CantBeEvil(LicenseVersion.CBE_NECR_HS)  {
    using Strings for uint256;

    string private baseURI = "";

    uint256 public preCost = 0 ether;
    uint256 public publicCost = 0.005 ether;
    bool public presale = true;
    uint256 public presale_max = 2;
    bool public mintable = true;
    address public royaltyAddress;
    uint96 public royaltyFee = 750;

    uint256 constant public MAX_SUPPLY = 2500;
    string constant private BASE_EXTENSION = ".json";
    uint256 constant private PUBLIC_MAX_PER_TX = 5;
    address constant private BULK_TRANSFER_ADDRESS = 0x100f565d55091A85568169E6E37A9D7CBd947843;
    address constant private DEFAULT_ROYALITY_ADDRESS = 0x100f565d55091A85568169E6E37A9D7CBd947843;
    bytes32 public merkleRoot;
    mapping(address => uint256) private whiteListClaimed;

    uint256 public max_per_wallet = 5;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {
        _setDefaultRoyalty(DEFAULT_ROYALITY_ADDRESS, royaltyFee);
        _mintERC2309(BULK_TRANSFER_ADDRESS, 88);
        for (uint256 i; i < 4; ++i) {
            _initializeOwnershipAt(i * 10);
        }
    }

    modifier whenMintable() {
        require(mintable == true, "Mintable: paused");
        _;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION));
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function publicMint(uint256 _mintAmount) public
    payable
    whenNotPaused
    whenMintable
    {
        uint256 cost = publicCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(!presale, "Presale is active.");
        require(
            _mintAmount <= PUBLIC_MAX_PER_TX,
            "Mint amount over"
        );

        _mint(msg.sender, _mintAmount);
    }

    function preMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        whenMintable
        whenNotPaused
    {
        uint256 cost = preCost * _mintAmount;
        mintCheck(_mintAmount,  cost);
        require(presale, "Presale is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        require(
            whiteListClaimed[msg.sender] + _mintAmount <= presale_max,
            "Already claimed max"
        );

        _mint(msg.sender, _mintAmount);
         whiteListClaimed[msg.sender] += _mintAmount;
    }

    function mintCheck(
        uint256 _mintAmount,
        uint256 cost
    ) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(_numberMinted(msg.sender) + _mintAmount <= max_per_wallet, "Only can mint maximum 5");
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "MAXSUPPLY over"
        );
        require(msg.value >= cost, "Not enough funds");
        
    }

    function ownerMint(address _address, uint256 count) public onlyOwner {
       _mint(_address, count);
    }

    function setPresale(bool _state) public onlyOwner {
        presale = _state;
    }

    function setPreCost(uint256 _preCost) public onlyOwner {
        preCost = _preCost;
    }

    function setPublicCost(uint256 _publicCost) public onlyOwner {
        publicCost = _publicCost;
    }

    function setMintable(bool _state) public onlyOwner {
        mintable = _state;
    }

    function setMax(uint256 _max) public onlyOwner {
        max_per_wallet = _max;
    }

    function getCurrentCost() public view returns (uint256) {
        if (presale) {
            return preCost;
        } else{
            return publicCost;
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981,CantBeEvil) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        // - CantBeEvil
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            CantBeEvil.supportsInterface(interfaceId);
    }

}