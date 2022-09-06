// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721EnumLiteC.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ShoutoutNFT is Ownable, ERC721EnumerableLiteC {

    using Strings for uint256;

    string private baseTokenURI = "https://shoutout-labs.s3.amazonaws.com/";

    mapping(address => bool) public enabledMinter;  

    bool public paused = false;

    mapping(uint256 => uint256) public miscSetting;


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721C(_name, _symbol){
        setBaseURI(_initBaseURI);
    }

    // public
    function mint(address _to, uint256 _mintNumber) public {
        require(enabledMinter[msg.sender] , "!minter");
        uint256 supply = totalSupply();
        require(!paused, "paused" );

        _safeMint(_to, _mintNumber, "");
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return baseTokenURI;
    }
    function setBaseURI(string memory _value) public onlyOwner{
      baseTokenURI = _value;
    }


    function setMinter(address _minter, bool _option) public onlyOwner {
      enabledMinter[_minter] = _option;
    }
    function setMisc(uint256[] calldata  _ids, uint256[] calldata  _values) public {
      require(msg.sender == owner() || enabledMinter[msg.sender], "not whitelisted");
      require(_ids.length == _values.length, "Must provide equal ids and values" );
      for(uint256 i = 0; i < _ids.length; i++){
        miscSetting[_ids[i]] = _values[i];
      }
    }

    function pause(bool _state) public onlyOwner {
      paused = _state;
    }
}