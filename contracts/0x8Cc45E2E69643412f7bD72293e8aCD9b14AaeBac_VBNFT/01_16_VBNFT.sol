// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VBNFT is ERC721A, Ownable, ReentrancyGuard ,AccessControl{

    using SafeMath for uint256;
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _baseTokenURI;

    string private _baseImage;

    struct Rare{
        uint256 start;
        uint256 end;
        uint256 rareIndex;
    }
    Rare[] private rareRange;

    mapping(uint256 => uint256) private rare;

    uint256 public maxSupply = 10000;

    uint256[4] public reserveSupply = [10,20,30,40];

    mapping(uint256 => uint256) public reserve;

    address public pool;
    

    constructor()ERC721A("Vitalik Blessing", "VB", 10)
    {
    } 

    modifier eoaOnly() {
        require(tx.origin == msg.sender, "EOA Only");
        _;
    }

    function init(address _pool) external onlyOwner
    {
        pool = _pool;
    }

    function addMinter(address minter) public onlyOwner
    {
        _setupRole(MINTER_ROLE, minter);
    }


    function reserveMint(address _to,uint256 _supplyIndex,uint256 _amount) external onlyOwner {
       
       uint totalSupply = totalSupply();

       require(totalSupply.add(_amount) <= maxSupply,"Reach the maximum supply.");
       
       uint256 reserveMintAmount = reserve[_supplyIndex];

       require(reserveMintAmount.add(_amount) <= reserveSupply[_supplyIndex],"Reach the maximum reserve supply.");
       
       reserve[_supplyIndex] = reserve[_supplyIndex].add(_amount);

       uint256 startToken = totalSupply;
       uint256 endToken = totalSupply.add(_amount).sub(1);
       uint256 rareIndex = _supplyIndex.add(1);

       Rare memory item;
       item.start = startToken;
       item.end = endToken;
       item.rareIndex = rareIndex;
       rareRange.push(item);

        _safeMint(_to,_amount);
    }


    function mint(address to,uint256 amount,uint256[5] memory preBlockNumbers) public {

        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter.");

        uint totalSupply = totalSupply();

        require(amount > 0 && amount <= 5, "Reach the maximum amount per tx.");

        require(totalSupply.add(amount) <= maxSupply,"Reach the maximum supply."); 

        for(uint256 i = 0 ; i < amount; i++){
            uint256 tokenId = totalSupply.add(i);
            bytes32 rand = getRandom(preBlockNumbers[i]);
            bytes memory seed = abi.encodePacked(rand, abi.encodePacked(i.add(totalSupply)));
            uint result = uint256(keccak256(seed)) % (100);
            if(result < 5){
                rare[tokenId] = 1;
            }else if(result >= 5 && result < 15){
                rare[tokenId] = 2;
            }else if(result >= 15 && result < 45){
                rare[tokenId] = 3;
            }else{
                rare[tokenId] = 4;
            }
        }

        _safeMint(to, amount);
        
    }


    function getRandom(uint256 blockNumber) private view returns (bytes32)
    {

        if (block.number - blockNumber > 256) {
            return keccak256(
                abi.encodePacked(
                    block.difficulty,
                    blockNumber,
                    block.timestamp,
                    block.number,
                    tx.origin
                )
            );
        } else {
            return blockhash(blockNumber);
        }
    }

    function tokenRare(uint256 tokenId) public view returns (uint256) {

        require(tokenId < totalSupply(),"Nonexistent token.");
        if(rare[tokenId] > 0){
            return rare[tokenId];
        }
        for(uint256 i = 0 ; i < rareRange.length; i++){
            Rare memory item = rareRange[i];
            if(tokenId >= item.start && tokenId <= item.end){
                return item.rareIndex;
            }
        }
        return 0;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }


    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setBaseImage(string calldata baseImage) external onlyOwner {
        _baseImage = baseImage;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseTokenURI;
        
        if(bytes(baseURI).length > 0){
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }else if(bytes(_baseImage).length > 0){
            uint256 rareToken = tokenRare(tokenId);
            string memory rareInfo;
            if(rareToken == 1){
                rareInfo = "Century";
            }else if(rareToken == 2){
                rareInfo = "Remains";
            }else if(rareToken == 3){
                rareInfo = "Treasure";
            }else if(rareToken == 4){
                rareInfo = "Classic";
            }else{
                return "";
            }

            string memory json = Base64.encode(
                bytes(
                    string(abi.encodePacked("{\"name\":\"VB #",tokenId.toString(),"\",\"image\":\"",_baseImage, tokenId.toString(),".png\",\"attributes\":[{\"trait_type\":\"LEVEL\",\"value\":","\"",rareInfo,"\"","}]}"))
                )
            );
            return string(abi.encodePacked("data:application/json;base64,", json));
        }else{
            return "";
        }
    }

    function withdrawETH() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public{

        require(ownerOf(tokenId) == msg.sender,"Not owner.");
        transferFrom(msg.sender,address(0x000000000000000000000000000000000000dEaD),tokenId);
    }


    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (operator == pool && pool != address(0)) {
            return true;
        }
        //OpenSea: Conduit
        if(operator == address(0x1E0049783F008A0085193E00003D00cd54003c71)){
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}