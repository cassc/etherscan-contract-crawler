// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract LonelyAlienNFT is ERC721, PaymentSplitter, Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    string private _api_entry;
//    bool private _mintIsRandom = false;
    uint256 private _itemPrice;
    uint256 private _maxNftAtOnce = 20;
    bool public saleIsActive = false;

    // 100 reserve and giveaways / promo
    uint256 public constant MAXNFT = 10000;

    mapping(uint256 => uint256) private _totalSupply;
    Counters.Counter private _tokenIdCounter;

    address[] private _team = [
	0xe20637FC210397C5742cBEF523E530F10086AE30, // 20
	0x2eeae9Fc6B7D805637c76F7489CE8CE9c8Fd10F2, // 15
	0xa7EEABD32775eE917F62aF113BA54D997CA7bAf2, // 15
	0xe754ae30F35Fd2193D0Bc04E2236129B066C1075, // 15
	0x31b5a9d4C73a55450625C7ee28E77EFef419406e, // 15
	0xac6881eaD6b4b11b07DeD96f07b1a2FFed6b9Fe6, // 10
	0xf49F0F3B364d3512A967Da5B1Cc41563cd60771d  // 10
    ];

    uint256[] private _team_shares = [20,15,15,15,15,10,10];

    constructor()
        PaymentSplitter(_team, _team_shares)
        ERC721("Loneley Aliens Space Club", "LASC")
    {
	_api_entry = "https://api.lonelyaliens.com/api/meta/LASC/";

  //      setRandomMintToggle();

        setItemPrice(60000000000000000);
    }

    function mineReserves(uint _amount) public onlyOwner {
        for(uint x = 0; x < _amount; x++){
	    master_mint();
        }
    }

    // --------------------------------------------------------------------

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return _api_entry;
    }

    function setBaseURI (string memory _uri) public onlyOwner  {
        _api_entry = _uri;
    }

    // function setRandomMintToggle() public onlyOwner {
    //    if (_mintIsRandom) {
    //        _mintIsRandom = false;
    //    } else {
    //        _mintIsRandom = true;
    //    }
    //}

    function getOneNFT() public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(msg.value == getItemPrice(), "insufficient ETH");
        require(_tokenIdCounter.current() <= MAXNFT, "Purchase would exceed max supply");
        master_mint();
    }

    function getMultipleNFT(uint256 _howMany) public payable {
	require(saleIsActive, "Sale must be active to mint");
	require(_howMany <= _maxNftAtOnce, "to many NFT's at once");
	require(getItemPrice().mul(_howMany) == msg.value, "insufficient ETH");
	require(_tokenIdCounter.current().add(_howMany) <= MAXNFT, "Purchase would exceed max supply");
		for (uint256 i = 0; i < _howMany; i++) {
			master_mint();
		}
	}

    function master_mint() private {
      //  if (_mintIsRandom) {
      //      for (uint256 i = 0; i < 99999; i++) {
     //           uint256 randID = random(
     //               1,
     //               100,
     //               uint256(uint160(address(msg.sender))) + i
     //           );
     //           if (_totalSupply[randID] == 0) {
     //               _totalSupply[randID] = 1;
     //               _mint(msg.sender, randID);
     //               _tokenIdCounter.increment();
     //               return;
     //           }
     //       }
     //       revert("ID ALREADY ALLOCATED");
     //   } else {
            _safeMint(msg.sender, _tokenIdCounter.current() + 1);
            _tokenIdCounter.increment();
     //   }
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getotalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return getotalSupply(id) > 0;
    }

    function mintID(address to, uint256 id) public onlyOwner {
        require(_totalSupply[id] == 0, "this NFT is already owned by someone");
        _tokenIdCounter.increment();
        _mint(to, id);
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    // set nft price
    function getItemPrice() public view returns (uint256) {
        return _itemPrice;
    }

    function setItemPrice(uint256 _price) public onlyOwner {
        _itemPrice = _price;
    }

    // maximum purchaseable items at once
    function getMaxNftAtOnce() public view returns (uint256) {
        return _maxNftAtOnce;
    }

    function setMaxNftAtOnce(uint256 _items) public onlyOwner {
        _maxNftAtOnce = _items;
    }

    function withdrawParitial() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
     
   //function random(
   //     uint256 from,
   //     uint256 to,
   //     uint256 salty
   // ) private view returns (uint256) {
   //     uint256 seed = uint256(
   //         keccak256(
   //             abi.encodePacked(
   //                 block.timestamp +
   //                     block.difficulty +
   //                     ((
   //                         uint256(keccak256(abi.encodePacked(block.coinbase)))
   //                     ) / (block.timestamp)) +
   //                     block.gaslimit +
   //                     ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
   //                        (block.timestamp)) +
   //                     block.number +
   //                     salty
   //             )
   //         )
   //     );
   //     return seed.mod(to - from) + from;
   // }

    function withdrawAll() public onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }

}