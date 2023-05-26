//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/ITheCreepz.sol";
import "./interfaces/ITheCreepzDescriptor.sol";


contract TheCreepz is ERC721Enumerable, Ownable, ITheCreepz, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    //
    mapping(uint256 => Creepz) private _detail;
    //
    mapping(bytes32 => bool) private creepz;
    //
    address private immutable _tokenDescriptor;

    uint256 public constant MAX_CREEPZ = 10000;
    uint256 public constant CREEPZ_PRICE = 50000000000000000; //0.05 ETH
    uint256 private constant CREEPZ_PER_TX = 10;
    uint256 private constant PRESALE_MAX_CREEPZ = 64;
    //
    bool private _isPreSaleActive = false;
    bool private _isPublicSaleActive = false;
    //
    event GenerateCreepz( uint256 tokenId );
    //
    enum FounderMemberClaimStatus { Invalid, Unclaimed, Claimed }
    mapping (address => FounderMemberClaimStatus) private _foundingMemberClaims;
    struct Founder {
      address wallet;
      uint8 mintpass;
    }
    mapping(address => Founder) _founders;


    constructor(address _tokenDescriptor_)
      ERC721("TheCreepz", "CREEPZ")
    {
      _tokenDescriptor = _tokenDescriptor_;
    }

    function _baseURI() internal view virtual override returns (string memory) {}
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return ITheCreepzDescriptor(_tokenDescriptor).tokenURI(this, tokenId);
    }

    function details(uint256 tokenId) external view override returns (Creepz memory detail) {
        detail = _detail[tokenId];
    }
    function founders(address wallet) external view returns (Founder memory founder) {
        founder = _founders[wallet];
    }

    function isPreSaleActive() external view returns (bool status) {
        return _isPreSaleActive;
    }
    function togglePreSale() external onlyOwner {
        _isPreSaleActive = !_isPreSaleActive;
    }
    function isPublicSaleActive() external view returns (bool status) {
        return _isPublicSaleActive;
    }
    function togglePublicSale() external onlyOwner {
        _isPublicSaleActive = !_isPublicSaleActive;
    }
    function addFoundingMembers(Founder[] memory members) external onlyOwner {
        for (uint256 i = 0; i < members.length; i++) {
            _foundingMemberClaims[members[i].wallet] = FounderMemberClaimStatus.Unclaimed;
            _founders[members[i].wallet] = members[i];
        }
    }

    function generateCreepz(Creepz memory newCreepz, uint8 path) internal {

      newCreepz.original = copyCreepz(newCreepz);
      require(newCreepz.original, "This Creepz exist allready !");
      //
      _detail[_tokenIds.current()] = newCreepz;
      _safeMint(msg.sender, _tokenIds.current());
      emit GenerateCreepz(_tokenIds.current());
      //
      if(path == 0){
        _founders[msg.sender].mintpass = _founders[msg.sender].mintpass - 1;
        if( _founders[msg.sender].mintpass == 0){
          _foundingMemberClaims[msg.sender] = FounderMemberClaimStatus.Claimed;
        }
      }
    }
    function create(Creepz memory rolls, uint8 path) internal nonReentrant {

        _tokenIds.increment();
        //
        uint8 bgLen;
        bgLen = rolls.bg == 7 ? rolls.bgLen % 6 : rolls.bgLen;
        bgLen = rolls.bg == 8 ? rolls.bgLen % 5 : rolls.bgLen;
        //
        uint8 bgFill;
        bgFill = bgLen == 0 ? 2 : rolls.bgFill;
        bgFill = rolls.bg > 7 ? 1 : rolls.bgFill;
        //
        Creepz memory newCreepz = Creepz({
              bgColor1: rolls.bgColor1,
              bgColor2: rolls.bgColor2,
              bg: rolls.bg,
              bgFill: bgFill,
              bgAnim: rolls.bgAnim,
              bgLen: bgLen,
              body: rolls.body,
              bodyColor1: rolls.bodyColor1,
              bodyColor2: rolls.bodyColor2,
              face: rolls.face,
              faceColor1: rolls.faceColor1,
              faceColor2: rolls.faceColor2,
              faceAnim: rolls.faceAnim,
              typeEye: rolls.typeEye,
              eyes: rolls.eyes,
              pupils: rolls.pupils,
              access: rolls.access,
              original: true,
              timestamp: block.timestamp,
              creator: msg.sender
          });
          //
          generateCreepz(newCreepz,path);
    }

    function mintFoundingMember(Creepz[] memory _rolls) external payable {
        require(_isPreSaleActive, "Pre-sale is not active");
        require(_foundingMemberClaims[msg.sender] != FounderMemberClaimStatus.Claimed, "You've already claimed your Creepz");
        require(_foundingMemberClaims[msg.sender] == FounderMemberClaimStatus.Unclaimed, "You are not a founding member");
        require(totalSupply() + 1 < PRESALE_MAX_CREEPZ);
        require(totalSupply() + 1 <= MAX_CREEPZ);
        //
        for (uint256 i; i < _rolls.length; i++) {
          require(_founders[msg.sender].mintpass > 0,"No more Mintpass");
          require(_verify(_rolls[i]));
          create(_rolls[i],0);
        }
    }

    function mintPublic(Creepz[] memory _rolls ) external payable{
        require(_isPublicSaleActive, "Public sale is not active");
        require(_rolls.length > 0 && _rolls.length <= CREEPZ_PER_TX, "You can't mint that many Creepz");
        require(totalSupply() + _rolls.length <= MAX_CREEPZ, "Mint would exceed max supply of Creepz");
        require(msg.value >= _rolls.length * CREEPZ_PRICE, "You didn't send the right amount of eth");
        //
        for (uint256 i; i < _rolls.length; i++) {
          require(_verify(_rolls[i]));
          create(_rolls[i],1);
        }
    }

    function _verify(Creepz memory newCreepz) internal pure returns (bool){
      require(newCreepz.bgColor1 < 13);
      require(newCreepz.bgColor2 < 13);
      require(newCreepz.bg < 9);
      require(newCreepz.bgFill < 2);
      require(newCreepz.bgAnim < 8);
      require(newCreepz.bgLen < 10);
      require(newCreepz.body < 13);
      require(newCreepz.bodyColor1 < 13);
      require(newCreepz.bodyColor2 < 13);
      require(newCreepz.face < 20);
      require(newCreepz.faceColor1 < 13);
      require(newCreepz.faceColor2 < 13);
      require(newCreepz.faceAnim < 12);
      require(newCreepz.typeEye < 2);
      if(newCreepz.typeEye == 0){
        require(newCreepz.eyes < 15);
        require(newCreepz.pupils < 11);
      }
      if(newCreepz.typeEye == 1){
        require(newCreepz.eyes < 6);
        require(newCreepz.pupils < 8);
      }
      require(newCreepz.access < 8);
      return true;
    }
    function stack(Creepz memory detail) internal pure returns (bytes memory) {
      return abi.encode(
          detail.face,
          detail.faceColor1,
          detail.faceColor2,
          detail.faceAnim,
          detail.typeEye,
          detail.eyes,
          detail.pupils
      );
    }
    function copyCreepz(Creepz memory detail) internal returns (bool) {
        bytes32 hash = keccak256(
            abi.encode(
                detail.bgColor1,
                detail.bgColor2,
                detail.bg,
                detail.bgFill,
                detail.bgAnim,
                detail.bgLen,
                detail.body,
                detail.bodyColor1,
                detail.bodyColor2,
                stack(detail)
            )
        );
        if (!creepz[hash]) {
            creepz[hash] = true;
            return true;
        } else {
            return false;
        }
    }

    function withdraw() public payable onlyOwner {
        uint256 amount = address(this).balance;
        require(payable(0x6A40A7029082AC592546506353f0Cf811a0E8974).send((amount * 30) / 100)); //Dao
        require(payable(0xb5d8cD851d13c06567371498190f4aaA37C8ef5E).send((amount * 35) / 100)); //Artist
        require(payable(0x120698b4fc29B6108aBaAEBc0EA03f88Cc46eC67).send((amount * 35) / 100)); //Dev
    }

}