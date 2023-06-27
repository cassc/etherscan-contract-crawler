//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import './base64.sol';
import './Rando.sol';

/**

          ___  ___      ___        __   __        __  
|     /\   |  |__  |\ |  |   |  | /  \ |__) |__/ /__` 
|___ /~~\  |  |___ | \|  |  .|/\| \__/ |  \ |  \ .__/ 
                                                      
"77x7", troels_a, 2021


*/

contract LatentWorks_77x7 is ERC1155, ERC1155Supply, Ownable {

    using Counters for Counters.Counter;

    // Constants
    string public constant NAME = "Latent Works \xc2\xb7 77x7";
    string public constant DESCRIPTION = "latent.works";
    uint public constant MAX_WORKS = 77;
    uint public constant MAX_EDITIONS = 7;

    // Works
    Counters.Counter private _id_tracker;
    uint private _released = 0;
    uint private _editions = 0;
    uint private _minted = 0;
    uint private _curr_edition = 0;
    uint private _price = 0.07 ether;
    mapping(uint => string) private _seeds;
    mapping(uint => mapping(uint => address)) private _minters;
    mapping(uint => mapping(uint => uint)) private _timestamps;

    struct Work {
      uint token_id;
      string name;
      string description;
      string image;
      string[7] iterations;
      string[7] colors;
    }


    // Canvas
    mapping(uint256 => string[]) private _palettes;

    constructor() ERC1155("") {

      _palettes[1] = ["#82968c","#6a706e","#ffd447","#ff5714","#170312","#0cf574","#f9b4ed"];
      _palettes[2] = ["#f59ca9","#775253","#01fdf6","#cff27e","#294d4a","#0cf574","#0e103d"];
      _palettes[3] = ['rgba(90, 232, 89, 0.706)', 'rgba(255, 98, 98, 0.706)', 'rgba(79, 42, 109, 0.706)', 'rgba(0, 255, 208, 0.769)', 'pink', '#888', 'black'];

    }


    // State
    function getAvailable() public view returns (uint){
      return (_released - _minted);
    }

    function getMinted() public view returns (uint){
      return _minted;
    }

    function getEditions() public view returns(uint){
      return _editions;
    }

    function getCurrentEdition() public view returns(uint){
        return _curr_edition;
    }
    

    // Minting
    function releaseEdition(address[] memory to) public onlyOwner {
      require(_editions < MAX_EDITIONS, 'MAX_EDITIONS_RELEASED');
      _released = _released+MAX_WORKS;
      _editions++;
      for(uint256 i = 0; i < to.length; i++){
        _mintTo(to[i]);
      }
    }

    function mint() public payable returns (uint) {
      require(msg.value >= _price, "VALUE_TOO_LOW");
      require((getAvailable() > 0), "NOT_AVAILABLE");
      return _mintTo(msg.sender);
    }

    function _mintTo(address to) private returns(uint){
      
      _id_tracker.increment();

      uint256 token_id = _id_tracker.current();

      if(token_id == 1)
        _curr_edition++;

      uint edition = getCurrentEdition();

      if(edition == 1){
        _seeds[token_id] = string(abi.encodePacked(Strings.toString(token_id), block.timestamp, block.difficulty));
      }

      _mint(to, token_id, 1, "");
      _minted++;
      _minters[token_id][edition] = to;
      _timestamps[token_id][edition] = block.timestamp;

      if(token_id == MAX_WORKS){
        _id_tracker.reset();
      }

      return token_id;

    }


    // Media and metadata
    function _getIterationSeed(uint token_id, uint iteration) private view returns(string memory){
      return string(abi.encodePacked(_seeds[token_id], Strings.toString(iteration)));
    }

    function _getPaletteIndex(uint token_id) private view returns(uint) {
      return Rando.number(string(abi.encodePacked(_seeds[token_id], 'P')), 1, 3);
    }

    function getPalette(uint token_id) public view returns(string[] memory){
      uint index = _getPaletteIndex(token_id);
      return _palettes[index];
    }

    function getColor(uint token_id, uint iteration) public view returns(string memory){
      string[] memory palette = getPalette(token_id);
      return palette[Rando.number(string(abi.encodePacked(_getIterationSeed(token_id, iteration), 'C')), 1, 7)];
    }

    function getMinter(uint token_id, uint edition) public view returns(address){
      return _minters[token_id][edition];
    }

    function getWork(uint token_id) public view returns(Work memory){
      
      string[7] memory iterations;
      string[7] memory colors;

      uint supply = totalSupply(token_id);
      uint i = 0;
      while(i < supply){
        iterations[i] = getSVG(token_id, i+1, true);
        i++;
      }

      i = 0;
      while(i < supply){
        colors[i] = getColor(token_id, i);
        i++;
      }

      return Work(
        token_id,
        string(abi.encodePacked("Latent Work #", Strings.toString(token_id))),
        DESCRIPTION,
        getSVG(token_id, supply, true),
        iterations,
        colors
      );

    }

    function _getElement(uint token_id, uint iteration, string memory filter) private view returns(string memory){
      
      string memory svgSeed = _getIterationSeed(token_id, iteration);
      string memory C = getColor(token_id, iteration);
      uint X = Rando.number(string(abi.encodePacked(svgSeed, 'X')), 10, 90);
      uint Y = Rando.number(string(abi.encodePacked(svgSeed, 'Y')), 10, 90);
      uint R = Rando.number(string(abi.encodePacked(svgSeed, 'R')), 5, 70);

      return string(abi.encodePacked('<circle cx="',Strings.toString(X),'%" cy="',Strings.toString(Y),'%" r="',Strings.toString(R),'%" filter="url(#',filter,')" fill="',C,'"></circle>'));

    }


    function _getWatermark(uint token_id, uint iteration) private view returns (string memory) {
      return string(abi.encodePacked('<style>.txt{font: normal 12px monospace;fill: white;}</style><rect width="90" height="30" x="0" y="747" fill="#000" class="box"></rect><text x="12" y="766" class="txt">#',(token_id < 10 ? string(abi.encodePacked('0', Strings.toString(token_id))) : Strings.toString(token_id)),' \xc2\xb7 ',Strings.toString(iteration),'/',Strings.toString(MAX_EDITIONS),'</text><text x="103" y="766" class="txt">',Strings.toString(_timestamps[token_id][iteration]),'</text>'));
    }


    function getSVG(uint256 token_id, uint iteration, bool mark) public view returns (string memory){

        require(iteration <= totalSupply(token_id), 'EDITION_NOT_MINTED');

        string[4] memory parts;

        string memory elements = string(abi.encodePacked(_getElement(token_id, 70, "f1"), _getElement(token_id, 700, "f1")));
        uint i;
        while(i < iteration){
          elements = string(abi.encodePacked(elements, _getElement(token_id, i, "f0")));
          i++;
        }

        uint size = 777;
        string memory view_box_size = Strings.toString(size);
        string memory blur = Strings.toString(size/(iteration+1));

        parts[0] = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" preserveAspectRatio="xMinYMin meet" viewBox="0 0 ',view_box_size,' ',view_box_size,'"><defs><rect id="bg" width="100%" height="100%" fill="#fff" /><clipPath id="clip"><use xlink:href="#bg"/></clipPath><filter id="f0" width="300%" height="300%" x="-100%" y="-100%"><feGaussianBlur in="SourceGraphic" stdDeviation="',blur,'"/></filter><filter id="f1" width="300%" height="300%" x="-100%" y="-100%"><feGaussianBlur in="SourceGraphic" stdDeviation="700"/></filter></defs><rect width="100%" height="100%" fill="#fff" />'));
        parts[1] = string(abi.encodePacked('<g clip-path="url(#clip)"><use xlink:href="#bg"/>', elements, '</g>'));
        parts[2] = mark ? _getWatermark(token_id, iteration) : '';
        parts[3] = '</svg>';

        string memory output = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]))))));

        return output;

    }

    function uri(uint256 token_id) virtual public view override returns (string memory) {
        
        require(exists(token_id), 'INVALID_ID');
        Work memory work = getWork(token_id);

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', work.name, '", "description": "', work.description, '", "image": "', work.image, '"}'))));

        return string(abi.encodePacked('data:application/json;base64,', json));

    }

    // Balance
    function withdrawAll() public payable onlyOwner {
      require(payable(msg.sender).send(address(this).balance));
    }


    // Required overrides
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal override (ERC1155, ERC1155Supply) {
        super._mint(account, id, amount, data);
    }

    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override (ERC1155, ERC1155Supply) {
        super._mintBatch(to, ids, amounts, data);
    }

    function _burn(address account, uint256 id, uint256 amount) internal override (ERC1155, ERC1155Supply) {
        super._burn(account, id, amount);
    }

    function _burnBatch(address to, uint256[] memory ids, uint256[] memory amounts) internal override (ERC1155, ERC1155Supply) {
        super._burnBatch(to, ids, amounts);
    }

}