//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// <-.(`-') (`-')  _  (`-').->(`-')  __(`-')    
//  __( OO) (OO ).-/  ( OO)_  ( OO).-( (OO ).-> 
// '-'---.\ / ,---.  (_)--\_)(,------.\    .'_  
// | .-. (/ | \ /`.\ /    _ / |  .---''`'-..__) 
// | '-' `.)'-'|_.' |\_..`--.(|  '--. |  |  ' | 
// | /`'.  (|  .-.  |.-._)   \|  .--' |  |  / : 
// | '--'  /|  | |  |\       /|  `---.|  '-'  / 
// `------' `--' `--' `-----' `------'`------'  
//
//                       :::!~!!!!!:.
//                   .xUHWH!! !!?M88WHX:.
//                 .X*#[email protected]$!!  !X!M$$$$$$WWx:.
//                :!!!!!!?H! :!$!$$$$$$$$$$8X:
//               !!~  ~:~!! :~!$!#$$$$$$$$$$8X:
//              :!~::!H!<   ~.U$X!?R$$$$$$$$MM!
//              ~!~!!!!~~ .:XW$$$U!!?$$$$$$RMM!
//                !:~~~ .:!M"T#$$$$WX??#MRRMMM!
//                ~?WuxiW*`   `"#$$$$8!!!!??!!!
//              :X- M$$$$       `"T#$T~!8$WUXU~
//             :%`  ~#$$$m:        ~!~ ?$$$$$$
//           :!`.-   ~T$$$$8xx.  .xWW- ~""##*"
// .....   -~~:<` !    ~?T#[email protected]@[email protected]*?$$      /`
// [email protected]@M!!! .!~~ !!     .:XUW$W!~ `"~:    :
// #"~~`.:x%`!!  !H:   !WM$$$$Ti.: .!WUn+!`
// :::~:!!`:X~ .: ?H.!u "$$$B$$$!W:U!T$$M~
// .~~   :[email protected]!.-~   [email protected]("*$$$W$TH$! `
// Wi.~!X$?!-~    : ?$$$B$Wu("**$RM!
// [email protected]~~ !     :   ~$$$$$B$$en:``
// [email protected]~    :     ~"##*$$$$M~
// :W$B$$$W!     :        ~$$$$$$
// ~"T$$$R!      :            ~M$$
// ~#M$$$$$$     ~-~~~-.__.-~~~-~
// contract code written by @bluederpyfi (O_o)
// contract code destroyed by @basedmoneygod 凸(￣□￣」)

contract Mojimon is VRFConsumerBase, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    bool public isMintingActive = false;
    uint256 public price = 0.09 * 10 ** 18; //0.09 ETH
    uint256 public _maxSupply = 10000;
    bool public isVRFIndexSet = false;
    uint256 public VRFIndex;
    bytes32 internal keyHash;
    uint256 internal fee;
    string internal baseURI;
    string internal customMojimonURI;
    address payable internal multisig;
    bool private LockUri = false;
    string[10000] public mojimonNames;

    constructor(
        address payable _multisig
    ) VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
        0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
    ) ERC721(
        "Mojimon",
        "MOJI"
    )  {
        multisig = _multisig;
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; // 0.1 LINK (Varies by network)
    }

    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        isVRFIndexSet = true;
        VRFIndex = randomness % 8800;
    }
    function asciiToInteger(bytes32 x) public pure returns (uint256) {
        uint256 y;
        for (uint256 i = 0; i < 32; i++) {
            uint256 c = (uint256(x) >> (i * 8)) & 0xff;
            if (48 <= c && c <= 57)
                y += (c - 48) * 10 ** i;
            else
                break;
        }
        return y;
    }
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function getVRFIndex() public view returns (uint256) {
        return VRFIndex;
    }
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }
    function setName(uint256 tokenId, string memory name) public {
        require(ownerOf(tokenId) == msg.sender, "You must be the owner to change the name");
        require(bytes(name).length < 50, "Max name length is 50 characters");
        mojimonNames[tokenId] = name;
    }
    function viewName(uint256 tokenId) public view returns (string memory) {
        return mojimonNames[tokenId];
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(tokenId < 200){
            return bytes(customMojimonURI).length > 0 ? string(abi.encodePacked(customMojimonURI, uint2str(tokenId))) : "https://moji-api.vercel.app/api/0";
        }
        else if(isVRFIndexSet){
            uint256 index = tokenId.add(VRFIndex);
            if(index >= _maxSupply){
                index = index.sub(_maxSupply).add(200);
            }
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, uint2str(index))) : "https://moji-api.vercel.app/api/0";
        }
        else{
            return "https://moji-api.vercel.app/api/0";
        }
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function setBaseUri(string memory uri) public onlyOwner{
        require(LockUri == false, "URI locked");
        baseURI = uri;
    }
    function setCustomMojimonURI(string memory uri) public onlyOwner{
        require(LockUri == false, "URI locked");
        customMojimonURI = uri;
    }
    function lockUri() public onlyOwner{
        LockUri = true;
    }

    function startMinting() public onlyOwner {
        require(totalSupply() < _maxSupply, "Better luck next time");
        LINK.approve(address(this), 1000000000000000000);
        isMintingActive = true;
        
    }

    function stopMinting() internal {
        isMintingActive = false;
    }

    function presaleMint(uint256 quantity) public onlyOwner{

        require(totalSupply().add(quantity) <= 1200, "There are only 1000 presales and 200 giveway Mojimon");
                
        for(uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < _maxSupply) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mint(uint256 quantity) public payable {
        require(isMintingActive, "Minting is off");
        require(totalSupply().add(quantity) <= _maxSupply, "There are not enough Mojimon remaining");
        require(price.mul(quantity) <= msg.value, "Invalid amount of Eth");
        require(quantity <= 20, "Max mint is 20");
        
        
        for(uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < _maxSupply) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        (bool success, ) = multisig.call{value: address(this).balance}("");
        require(success, "ETH Transfer failed.");
        if(_maxSupply == totalSupply()){
          stopMinting();
        }
    }
    function HAMMER() public onlyOwner{
        require(isVRFIndexSet == false, "VRF Index already set");
        getRandomNumber();
    }
    function withdraw() public onlyOwner{
        (bool success, ) = multisig.call{value: address(this).balance}("");
            require(success, "ETH Transfer failed.");
    }
}