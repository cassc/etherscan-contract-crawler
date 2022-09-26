// Art by Figure31
// Contract by Morgan Ali

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Limit is Context, ERC721, Ownable {

    uint maxNbr = 340;
    uint counterId = 0;

    bool public activePreSale = false;
    bool public activeSale = false;
    event Mint(address buyer, uint256 price, uint256 [] tokenIds);

    constructor() ERC721("LIMIT", "LMT") {}

    struct dataNmValue {uint nmValue;}
    struct dataXCoord {string xCoord;}
    struct dataYCoord {string yCoord;}
    struct dataZCoord {string zCoord;}
    struct dataColor {string colorValue;}

    mapping (uint => dataNmValue) public mapNm;
    mapping (uint => dataXCoord) public mapX;
    mapping (uint => dataYCoord) public mapY;
    mapping (uint => dataZCoord) public mapZ;
    mapping (uint => dataColor) public mapColor;

    function setDataNmValue(dataNmValue[] memory _data )external onlyOwner {
        for(uint256 i = 0; i < _data.length; i ++){
                     mapNm[i] = _data[i];
        }
    }

    function setDataXcoord(dataXCoord[] memory _data )external onlyOwner {
        for(uint256 i = 0; i < _data.length; i ++){
                     mapX[i] = _data[i];
        }
    }

    function setDataYcoord(dataYCoord[] memory _data )external onlyOwner {
        for(uint256 i = 0; i < _data.length; i ++){
                     mapY[i] = _data[i];
        }
    }

    function setDataZcoord(dataZCoord[] memory _data )external onlyOwner {
        for(uint256 i = 0; i < _data.length; i ++){
                     mapZ[i] = _data[i];
        }
    }

    function setDataColor(dataColor[] memory _data )external onlyOwner {
        for(uint256 i = 0; i < _data.length; i ++){
                     mapColor[i] = _data[i];
        }
    }

    address public addressOne;
    function setAddressOne(address _addressOne) external onlyOwner  {
        addressOne = _addressOne;
    }

    address public addressTwo;
    function setAddressTwo(address _addressTwo) external onlyOwner  {
        addressTwo = _addressTwo;
    }

    uint percentOne;
    uint percentTwo;
    function setPercent(uint _percentOne, uint _percentTwo) external onlyOwner  {
        percentOne = _percentOne;
        percentTwo = _percentTwo;
    }

    uint256 public price;
    function setPrice(uint256 _price) external onlyOwner  {
        price = _price;
    }

    mapping(address => uint) private _allowList;
    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = maxNbr;
        }
    }

    function changePreSaleState() external onlyOwner {
        activePreSale = !activePreSale;
    }

    function minItemPresale() public payable returns (uint256){
        require(activePreSale);
        require(counterId <= 240);

        preMintItemLogic();

        payable(addressOne).transfer(msg.value * percentOne / 100);
        payable(addressTwo).transfer(msg.value * percentTwo / 100);

    return counterId;
    }

    function preMintItemLogic() private returns (uint256 [] memory) {
        require(msg.value >= price);
        require(msg.value <= 1000000000000000000);

        uint256 amount = msg.value / price;

        require(amount <= _allowList[msg.sender]);
        require(counterId + amount <= maxNbr + 1);
        uint256 [] memory tokensMinted = new uint256[](amount);

        for(uint256 i = 0; i < amount; i ++){

            _safeMint(msg.sender, counterId);
            tokensMinted[i] = counterId;
            counterId += 1;
        }

        emit Mint(msg.sender, msg.value, tokensMinted);
    return tokensMinted;
    }

    function changeSaleState() external onlyOwner {
        activeSale = !activeSale;
    }

    function mintItem() public payable returns (uint256){

        require(activeSale);
        require(counterId < maxNbr);

        mintItemLogic();

        payable(addressOne).transfer(msg.value * percentOne / 100);
        payable(addressTwo).transfer(msg.value * percentTwo / 100);

    return counterId;
    }

    function mintItemLogic() private returns (uint256 [] memory) {

        require(msg.value >= price);
        require(msg.value <= 1000000000000000000);

        uint256 amount = msg.value / price;
        require(counterId + amount <= maxNbr + 1);
        uint256 [] memory tokensMinted = new uint256[](amount);

        for(uint256 i = 0; i < amount; i ++){

            _safeMint(msg.sender, counterId);
            tokensMinted[i] = counterId;
            counterId += 1;
        }

        emit Mint(msg.sender, msg.value, tokensMinted);
    return tokensMinted;
    }

    function ownerMint(uint256 count) external onlyOwner() {
    require(counterId + count < maxNbr);

    for (uint256 i = 0; i < count; i++) {
      _safeMint(msg.sender, counterId);
       counterId += 1;
    }
  }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function tokenURI(uint256 tokenId) override view public returns (string memory) {
            string[11] memory parts;

            parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 200 200"> <style>.base { fill: #1a1a1a; font-size: 0px; font-family:sans-serif;}</style><rect width="100%" height="100%" fill="#fafafa" /><text x="0" y="0" class="base" text-anchor="middle"><tspan dy="100px" x="50%" font-size="45px" font-weight="bold">';
            parts[1] = toString(mapNm[tokenId].nmValue);
            parts[2] = ' NM</tspan><tspan dy="15px" x="50%" font-size="12px" font-weight="bold">(';
            parts[3] = mapX[tokenId].xCoord;
            parts[4] = ', ';
            parts[5] = mapY[tokenId].yCoord;
            parts[6] = ', ';
            parts[7] = mapZ[tokenId].zCoord;
            parts[8] = ')</tspan><tspan dy="19px" x="50%" font-size="17px">';
            parts[9] = mapColor[tokenId].colorValue;
            parts[10] = ' REGION</tspan></text></svg>';

            string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6],parts[7], parts[8], parts[9], parts[10]));

            string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', toString(mapNm[tokenId].nmValue), ' NM", "description": "Each LIMIT token represents a monochromatic colour-a pure hue of a single wavelength that cannot be rendered by inks or computer screens. Imagination is the only tool at our disposal to visualize these colours. Released on the occasion of the Tribute to Herbert W. Franke.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '", "attributes": [{"trait_type":"WAVELENGTH (nm)","value":"',toString(mapNm[tokenId].nmValue),'"},{"trait_type":"CIE 1931 X TRISTIMULUS","value":"',mapX[tokenId].xCoord,'"},{"trait_type":"CIE 1931 Y TRISTIMULUS","value":"',mapY[tokenId].yCoord,'"},{"trait_type":"CIE 1931 Z TRISTIMULUS","value":"',mapZ[tokenId].zCoord,'"},{"trait_type":"COLOR REGION","value":"',mapColor[tokenId].colorValue,'"}] }'))));
            output = string(abi.encodePacked('data:application/json;base64,', json));

            return output;
        }

    function contractURI() public pure returns (string memory){
               string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "LIMIT", "description": "LIMIT is a collection of 341 on-chain text tokens tracing the spectral locus as defined by the CIE 1931 chromaticity diagram."}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

}

/// [MIT License]
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