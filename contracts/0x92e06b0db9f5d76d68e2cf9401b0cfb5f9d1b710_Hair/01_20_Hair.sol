//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import './utils/Base64.sol';
import './utils/HexStrings.sol';
import './auth/Ownable.sol';
import './ToHairColor.sol';
import './HairTypes.sol';
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract Hair is ERC721Enumerable, Ownable, HairTypes {

  using Strings for uint256;
  using HexStrings for uint160;
  using ToHairColor for bytes3;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;



  uint256 public constant limit = 1000;
  uint256 public constant curve = 1005; // price increase 0,5% with each purchase
  uint256 public price = 0.002 ether;

  mapping (uint256 => bytes3) public color;
  mapping (uint256 => bytes3) public style;
  ERC721Enumerable public miloogy;

  constructor(address owner_, ERC721Enumerable miloogy_) ERC721("Miloogy Hair", "MLGHAIR") {
    _initializeOwner(owner_);
    miloogy = miloogy_;
  }

  function mintItem() public payable returns (uint256) {
      require(_tokenIds.current() < limit, "DONE MINTING");
      require(msg.value >= price, "NOT ENOUGH");

      price = (price * curve) / 1000;

      _tokenIds.increment();

      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);

      bytes32 genes = keccak256(abi.encodePacked( id, blockhash(block.number-1), msg.sender, address(this) ));
      color[id] = bytes2(genes[0]) | ( bytes2(genes[1]) >> 8 ) | ( bytes3(genes[2]) >> 16 );
      style[id] = bytes2(genes[3]) | ( bytes2(genes[4]) >> 8 ) | ( bytes3(genes[5]) >> 16 );

      return id;
  }

  function withdraw() public onlyOwner {
      bool success;
      uint donation = address(this).balance/5;
      (success, ) = 0x1F5D295778796a8b9f29600A585Ab73D452AcB1c.call{value: donation}(""); //vectorized.eth
      assert(success);
      (success, ) = 0x97843608a00e2bbc75ab0C1911387E002565DEDE.call{value: donation}(""); //buidlguidl.eth
      assert(success);
      (success, ) = owner().call{value: address(this).balance}("");
      assert(success);
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      string memory name = string(abi.encodePacked('Miloogy Hair #',id.toString()));

      H memory top = getTop(id);
      H memory bangs = getBangs(id);
      H memory back = getBack(id);

      // string memory crazyText = '';
      // string memory crazyValue = 'false';
      // if (crazy[id]) {
      //   crazyText = ' and it is crazy';
      //   crazyValue = 'true';
      // }
      string memory description = string(abi.encodePacked('This Miloogy Hair is the color #',color[id].toHairColor(),' Style: ', 'top ', top.trait, ', bangs ', bangs.trait, ', back ', back.trait, '.'));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));
      string memory traits = getTraits(id);

      return
        string(
          abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(
              bytes(
                abi.encodePacked(
                  '{"name":"',
                  name,
                  '", "description":"',
                  description,
                  '", "external_url":"https://www.fancymiloogys.com/hair/',
                  id.toString(),
                  '", "attributes": [',
                  traits,
                  '], "owner":"',
                  (uint160(ownerOf(id))).toHexString(20),
                  '", "image": "',
                  'data:image/svg+xml;base64,',
                  image,
                  '"}'
                )
              )
            )
          )
        );
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    return string(abi.encodePacked(
      
      renderTokenByIdBack(id),
      string(abi.encodePacked(
        '<g id="headfill" fill="#ddd" >',
          '<ellipse cx="222" cy="144"  rx="89" ry="90" />',
          '<ellipse cx="155" cy="202"  rx="75" ry="14" transform="rotate(22,155,202)"/>',
          '<ellipse cx="159" cy="165"  rx="75" ry="22" transform="rotate(-7,159,165)"/>',
        '</g>'
      )),
      renderTokenByIdFront(id)
    
    ));
  }

  function renderTokenByIdFront(uint256 id) public view returns (string memory) {
    string memory braids = keccak256(abi.encodePacked(getBack(id).trait)) == keccak256("braids") ? 
      string(abi.encodePacked(
        '<g id="hair-back-braids-bottom">',
        '<path id="braid-left"  d="m104.80562,225.092l23.02047,-0.30938c0.21741,0.21741 5.602,5.57905 -0.57064,16.3671c6.04305,5.92739 0.54766,11.61439 0.82148,16.33986c4.54433,9.11162 0.8006,8.47828 -0.41177,13.4762c4.97211,7.44285 -3.06962,8.49757 0.49329,12.23242c3.56291,3.73485 -4.23285,6.41763 0.41242,12.62072c4.64527,6.20309 -3.23013,7.96612 0.05869,12.58882c3.28882,4.6227 -2.80736,6.49056 -0.42303,9.81972c2.38433,3.32916 -4.44677,4.74637 -1.74123,9.50668c2.70554,4.76031 -3.48313,4.47255 -3.42182,11.39632c-3.47826,-3.33333 0.25501,-7.86859 -3.22325,-11.20192c-2.2624,-2.08055 -3.56326,-5.84379 -0.29683,-7.44358c-3.63991,-2.94315 -5.11635,-6.84783 -1.54473,-9.55059c-3.61517,-2.58397 -3.86496,-6.36985 -0.50899,-8.95381c-2.20823,-3.17499 -4.89722,-7.5519 -1.817,-10.4865c-4.21142,-3.49551 -2.41324,-7.71216 -0.37468,-10.24613c-4.70457,-3.341 -5.80336,-8.36468 -2.81563,-12.18644c-3.74303,-3.18074 -3.39953,-10.6884 -0.4118,-14.34991c-4.10534,-3.38839 -5.56646,-10.38253 -1.97951,-14.49207c-4.39938,-2.39827 -5.91413,-10.56576 -5.26544,-15.12749z" />',
        '<path id="braid-right" d="m301.74553,218.06715l-18.81333,1.644c0.72115,3.76602 -2.88461,10.41665 0.72115,11.29806c-2.08333,4.0064 -0.32052,10.41665 1.68269,11.29806c-1.68269,4.08653 -0.96154,8.41345 0.72115,9.37498c-1.68832,1.92621 -2.78318,7.11637 0.72115,8.89422c-2.6586,4.26744 -1.60819,7.79308 0.48077,10.5769c-2.07706,2.80448 -1.63197,6.94422 0,8.41345c-1.9168,3.50184 -1.1631,7.15206 0.48077,9.61537c-2.52214,4.11907 -2.07706,7.79308 0,10.5769c-1.90491,2.49587 -1.58439,5.58517 0.96154,7.93268c-1.51616,3.47805 -0.36182,7.40119 1.68269,8.65383c-2.06203,4.99735 2.5522,5.24715 3.60576,10.09614c0.53675,-3.91408 -1.35626,-7.94807 1.76873,-10.11153c1.55009,-0.63027 2.95182,-3.18923 1.53469,-8.41871c1.80412,-1.58191 1.97627,-6.87285 0.51645,-8.3064c2.18973,-2.13592 1.56061,-5.75545 0.78312,-8.18809c1.79223,-2.7037 2.2492,-6.44593 0.18404,-10.48488c2.38567,-3.02421 2.84265,-6.49351 1.22257,-10.25953c2.23732,-2.56723 2.39757,-6.46972 0.48077,-10.81729c2.24921,-2.3713 2.42136,-5.48439 0.96154,-8.89421c3.2195,-3.08056 3.47178,-7.64471 1.20192,-10.57691c1.98817,-2.62357 1.42007,-6.13329 -0.15243,-9.79539c4.49386,-6.44842 -0.08273,-6.97923 -0.74574,-12.52164z" />',
        '</g>'
      )) : "";

    string memory style = string(abi.encodePacked(
        '<g fill="#',
        color[id].toHairColor(),
        '">'));

    return string(abi.encodePacked(style, braids, getBangs(id).code,'</g>'));
  }
  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenByIdBack(uint256 id) public view returns (string memory) {
    string memory style = string(abi.encodePacked(
        '<g fill="#',
        color[id].toHairColor(),
        '">'));
    return string(abi.encodePacked(style, getTop(id).code, getBack(id).code,'</g>'));
  }

  function getTraits(uint id) public view returns(string memory) {
    H memory top = getTop(id);
    H memory bangs = getBangs(id);
    H memory back = getBack(id);
    string memory dyed = uint256(uint8(color[id][0])) <= 5 ? "crazy" : uint256(uint8(color[id][0])) < 30 ? "yes" : "no";
    string memory traits = string(abi.encodePacked(
      '{"trait_type": "hair-top", "value": "',
      top.trait,
      '"},{"trait_type": "hair-bangs", "value": "',
      bangs.trait,
      '"},{"trait_type": "hair-back", "value": "',
      back.trait,
      '"},{"trait_type": "hair-color", "value": "#',
      color[id].toHairColor(),
      '"},{"trait_type": "hair-dyed", "value": "',
      dyed,
      '"}'
    ));
    return traits;
  }

  function getTop(uint id) internal view returns(H storage) {
      bytes3 value = style[id];
      return uint256(uint8(value[0])) > 222 ? topFro : topPlain;      
  }

  function getBangs(uint id) internal view returns(H storage) {
      bytes3 value = style[id];
      return uint256(uint8(value[1])) > 170 ? bangsStraight : uint256(uint8(value[1])) < 85 ? bangsLong : bangsShort;
  }

  function getBack(uint id) internal view returns(H storage) {
      bytes3 value = style[id];
      return uint256(uint8(value[2])) > 191 ? backBraids : uint256(uint8(value[2])) > 127 ? backFlip : uint256(uint8(value[2])) <= 63 ? backPlain : backShort;
  }

}