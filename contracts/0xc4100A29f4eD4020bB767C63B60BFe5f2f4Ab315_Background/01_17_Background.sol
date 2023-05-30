//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./auth/Ownable.sol";
import './utils/Base64.sol';
import './utils/HexStrings.sol';
import './interfaces/INftMetadata.sol';

contract Background is ERC721Enumerable, Ownable {

  using Strings for uint256;
  using HexStrings for uint160;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  uint256 public constant limit = 1000;
  uint256 public constant curve = 1005; // price increase 0,5% with each purchase
  uint256 public price = 0.002 ether;
  uint public basicBgAmount;
  INftMetadata public bgContract;
  ERC721Enumerable public miloogy;

  mapping (uint256 => bytes32) public genes;

  constructor(address owner_, ERC721Enumerable miloogy_) ERC721("Miloogy Backgrounds", "MILBG") {
    _initializeOwner(owner_);
    miloogy = miloogy_;
  }

  function mintItem() public payable returns (uint256) {
      require(_tokenIds.current() < limit + basicBgAmount, "DONE MINTING");
      require(msg.value >= price, "NOT ENOUGH");
      require(address(bgContract) != address(0), "NOT MINTING YET");
      price = (price * curve) / 1000;
      uint id = _mintBg(msg.sender);
      genes[id] = keccak256(abi.encodePacked( id, blockhash(block.number-1), msg.sender, address(this) ));
      return id;
  }

  function mintBasicBg() public {
    require(address(bgContract) == address(0), "done minting basic BG");
    require(miloogy.balanceOf(msg.sender) != 0, "must own a miloogy");
    basicBgAmount = _mintBg(msg.sender);
  }

  function _mintBg(address sender) internal returns(uint){
    _tokenIds.increment();
    uint256 id = _tokenIds.current();
    _mint(sender, id);
    return(id);
  }

  function setBg(INftMetadata newBg) public onlyOwner {
    require(address(bgContract) == address(0), "can only set once");
    bgContract = newBg;
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
    if(id > basicBgAmount){
      assert(address(bgContract) != address(0));
      return(bgContract.tokenURI(id));
    } else {
      string memory name = string(abi.encodePacked('Miloogy Background #',id.toString()));
      string memory description = "basic miloogy background for OGs only";
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
                            '", "external_url":"https://www.miloogymaker.net/background/',
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
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  function renderTokenById(uint256 id) public view returns (string memory) {
    if(id > basicBgAmount){
      assert(address(bgContract) != address(0));
      return(bgContract.renderTokenById(id));
    } else {
      return string(abi.encodePacked(
        
        renderTokenByIdBack(id),
        renderTokenByIdFront(id)
      
      ));
    }
  }

  function renderTokenByIdFront(uint256 id) public view returns (string memory) {
    if(id > basicBgAmount){
      assert(address(bgContract) != address(0));
      return(bgContract.renderTokenByIdFront(id));
    } else {
      return "";
    }
  }
  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenByIdBack(uint256 id) public view returns (string memory) {
    if(id > basicBgAmount){
      assert(address(bgContract) != address(0));
      return(bgContract.renderTokenByIdBack(id));
    } else {
      string memory render = string(abi.encodePacked(
        '<g class="background" >',
            '<rect fill="#84D3DB" x="-1.2495" y="-2.99957" width="403.12397" height="292.49937" />',
            '<path fill="#CBFFFF" d="m80.70573,53.96501l-28.7063,13.49248c0.00672,0.00738 2.0567,18.00711 2.04998,17.99982c0.00672,0.00738 16.40645,1.13232 16.39981,1.12494c0.00672,0.00738 13.33153,0.00738 13.3248,0c0.00672,0.00738 16.40645,7.88225 16.39981,7.87487c0.00672,0.00738 25.63138,-8.99253 25.62466,-8.99991c0.00672,0.00738 25.63138,-1.11765 25.62466,-1.12494c0.00672,0.00738 13.33153,-21.36745 13.3248,-21.37474c0.00672,0.00738 -14.34311,-12.36754 -14.34983,-12.37483c0.00672,0.00738 -42.01774,-2.2426 -42.02446,-2.24998"/>',
            '<path fill="#CBFFFF" d="m221.78798,120.44581l41.13254,-19.15541l40.13577,0l35.11876,10.44533l22.07467,2.6113l11.0373,23.50196l-28.09504,8.70444l-66.22393,2.6113l-23.07803,-10.44533l-42.14255,-2.6113" />',
            '<path fill="#ffffff" d="m99.72496,53.08348l-37.89233,14.23899c0.00731,0.01169 3.35007,10.69969 3.34276,10.68801c0.00731,0.01169 26.74965,5.35562 26.74243,5.34393c0.00731,0.01169 14.49275,-7.11365 14.48544,-7.12534c0.00731,0.01169 1.12153,17.82503 17.83551,7.13702c16.71398,-10.68801 40.11365,-14.25068 26.74243,-26.71995l-25.63543,-1.79295" />',
            '<path fill="#ffffff" d="m233.62297,125.95281c10.60362,-6.37415 6.36217,-19.12251 32.87117,-17.30132l26.50213,1.81522l41.35406,10.92717c0.00696,0.00597 21.2141,-11.83183 20.15379,0.91653l-1.06728,12.74239l-48.77664,8.19534l-53.018,-10.01654" />',
            '<path fill="#894F3F"  d="m-1.87059,271.24999l115.09964,7.56846l105.69873,4.23894l88.88305,-0.84777l92.48642,5.93455l1.20109,107.66959l-1.20109,5.93455l-402.359,0.15223l0.19115,-130.65053z" />',
            '<path transform="rotate(3.02109 32.4992 267.064)"  d="m-8.00227,274.06446l40.50142,-14.00049l40.50142,14.00049l-81.00285,0z"  fill="#332D40"/>',
            '<path transform="rotate(3.07186 108.267 271.519)"  d="m49.26492,279.01959l59.00197,-15.00051l59.00197,15.00051l-118.00393,0z"  fill="#332D40"/>',
            '<path transform="rotate(1.70055 189.685 276.025)"  d="m134.18272,282.02474l55.50194,-12.00041l55.50194,12.00041l-111.00389,0z"  fill="#462735"/>',
            '<path  d="m233.57626,283.04478l15.00052,-7.00023l15.00052,7.00023l-30.00103,0z"  fill="#462735"/>',
            '<path transform="rotate(3.96457 367.816 282.756)"  d="m341.31507,286.75622l26.50094,-8.00028l26.50094,8.00028l-53.00189,0z"  fill="#462735"/>',
            '<path  d="m257.40207,282.86108l32.50114,-10.00034l32.50114,10.00034l-65.00228,0z"  fill="#462735"/>',
          '</g>'
        ));

      return render;
    }
  }

  function getTraits(uint id) public view returns(string memory) {
    if(id > basicBgAmount){
      assert(address(bgContract) != address(0));
      return(bgContract.getTraits(id));
    } else {
      return string(abi.encodePacked(
      '{"trait_type": "background", "value": "OG"}'
      ));
    }
  }
}