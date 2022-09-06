// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721EnumLiteC.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BeeNFT is Ownable, ERC721EnumerableLiteC {

    using Strings for uint256;

    string private baseTokenURI = "https:///";

    mapping(address => bool) public enabledMinter;  

    uint256 public maxSupply =  12380;  
    bool public paused = false;

    mapping(uint256 => uint256) public QueenRegistry; //ID to Int Status
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
        require(supply + 1 <= maxSupply, "OverMaxSupply" );

        _safeMint(_to, _mintNumber, "");
    }

    // function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
    //     require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );
    //     uint totalQuantity = 0;
    //     uint256 supply = totalSupply();
    //     for(uint i = 0; i < quantity.length; ++i){
    //       totalQuantity += quantity[i];
    //     }
    //     require( supply + totalQuantity <= maxSupply, "Mint/order exceeds supply" );
    //     delete totalQuantity;

    //     for(uint i = 0; i < recipient.length; ++i){
    //       for(uint j = 0; j < quantity[i]; ++j){
    //           _safeMint( recipient[i], supply++, "" );
    //       }
    //     }
    // }

    function _baseURI() internal view virtual override returns (string memory) {
      return baseTokenURI;
    }
    function setBaseURI(string memory _value) public onlyOwner{
      baseTokenURI = _value;
    }
        
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
      maxSupply = _maxSupply;
    }

    function setMinter(address _minter, bool _option) public onlyOwner {
      enabledMinter[_minter] = _option;
    }
    function setMisc(uint256[] calldata  _ids, uint256[] calldata  _values) public onlyOwner {
      require(_ids.length == _values.length, "Must provide equal ids and values" );
      for(uint256 i = 0; i < _ids.length; i++){
        miscSetting[_ids[i]] = _values[i];
      }
    }
    function setQueenRegistry(uint256[] calldata  _ids, uint256[] calldata  _values) public onlyOwner {
      require(_ids.length == _values.length, "Must provide equal ids and values" );
      for(uint256 i = 0; i < _ids.length; i++){
        QueenRegistry[_ids[i]] = _values[i];
      }
    }
    function pause(bool _state) public onlyOwner {
      paused = _state;
    }
}