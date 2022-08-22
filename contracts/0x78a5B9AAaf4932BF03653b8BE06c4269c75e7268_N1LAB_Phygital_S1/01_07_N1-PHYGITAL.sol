// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;


/**************************************************************************************                                
 **                                            @@@@@@@@@@@                           **
 **                                  (@@@@@@@@@@         @@@@                        **
 **                          @@@@@@@@@&                     @@@                      **
 **                       @@@@@@@@@@@                        @@/                     **
 **                     @@@@@@@@@@@@@@@@@@&                  @@@                     **
 **                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@                      **
 **                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                       **
 **                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                          **
 **                     @@@@@@@@@@@@@@@@@@@@@@@@@@@&                                 **
 **                        @@@@@@@@@@@@@@@@                                          **
 **                                                                                  **
 *************************************************************************************/
                                                                                

// Project  : N1-LAB Phygital S1
// Buidler  : Nero One
// Note     : Solmate gang~

import './LilOwnable.sol';
import 'solmate/src/tokens/ERC721.sol';
import 'solmate/src/utils/SafeTransferLib.sol';
import 'solmate/src/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

error NoTokensLeft();
error NotEnoughETH();
error NoQuantitiesAndRecipients();
error NonExistentTokenURI();

contract N1LAB_Phygital_S1 is LilOwnable, ERC721, ReentrancyGuard {
    using Strings for uint256;

    string private initImg = "ipfs://bafybeiddp6eorhu5h5lc3nktk3t4qoytbkcnofmy2wbymtmanvygkgh4ua";
    string private baseImg ;

    string private initAnim = "ipfs://bafybeigr5u7mxcncxhmyuldh7nydguobpg5jhuszubgvnjiqheptdckyhq";
    string private baseAnim ;

    string private initURI = "ipfs://bafkreigsaptxyhol3k3s2r73enifr7l4m6fvuwj6c2kr6itgsez4bhud2m";
    string private baseURI;

    string private baseExtension = ".json";
    
    uint256 private constant maxSupply = 45;

    uint256 public totalSupply;
    
    bool public revealed = false;
    bool public onchainData = false;

    constructor(string memory name_, string memory symbol_) payable ERC721(name_, symbol_) {
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setBaseImg(string memory _baseImg) external onlyOwner {
        baseImg = _baseImg;
    }

    function setBaseAnim(string memory _baseAnim) external onlyOwner {
        baseAnim = _baseAnim;
    }

    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    function setOnChainMetadata(bool _state) external onlyOwner {
        onchainData = _state;
    }

    function tokenURI(uint256 _id) public view override returns (string memory) {
        if (ownerOf(_id) == address(0)) revert NonExistentTokenURI();
        if (!onchainData) {
            if (!revealed) {
                return initURI;
            }
            return bytes(baseURI).length > 0 ? string((abi.encodePacked(baseURI, _id.toString(),baseExtension))) : initURI;
        }
        return genMetadata(_id);
    }

    function bulkMint(uint[] calldata qty, address[] calldata recipient) external nonReentrant onlyOwner {
        if (qty.length != recipient.length) revert NoQuantitiesAndRecipients();
		uint totalQty = 0;
		uint256 s = totalSupply;
		for(uint i = 0; i < qty.length; ++i){
			totalQty += qty[i];
		}
        if (s + totalQty > maxSupply) revert NoTokensLeft();
		delete totalQty;
        unchecked {
            for(uint i = 0; i < recipient.length; ++i){
                for(uint j = 0; j < qty[i]; ++j){
                _safeMint( recipient[i], s++);
                totalSupply++;
                }
		    }
        }
		delete s;	
	}

    function bulkTransfer(uint256[] calldata _id, address[] calldata _to) external onlyOwner {
        if (_id.length != _to.length) revert NoQuantitiesAndRecipients();

        unchecked {
            for(uint i; i < _to.length; ++i) {
                    safeTransferFrom(msg.sender, _to[i], _id[i]);
            }
        }
    }

    function genMetadata(uint _id) internal view returns (string memory) {

        uint _nuID = ++_id;

        string memory output;
        string memory _name = _nuID > 9 ? string(abi.encodePacked("[N1-LAB] Phygital S1-",_nuID.toString())) : string(abi.encodePacked("[N1-LAB] Phygital S1-0",_nuID.toString()));
        string memory _desc = "[N1-LAB] Phygital S1\\nFirst ever technology product by [N1-LAB].\\n\\nAt [N1-LAB] we believe that technology should be accessible to all. We see the future of products as a mix of physical and digital. This limited, NFC embedded  t-shirt is our first experiment in the world of phygital products. \\n\\nThank you for being part of this movement.\\n\\n'EXPERIMENT'";

        string memory _image = revealed ? baseImg : initImg;
        string memory _animURL = revealed ? baseAnim : initAnim;

        string memory _type = "Clothing";
        string memory _artist = "Nero One";
        string memory _artwork = "NFT";
        string memory _series = "Phygital S1";
        
        
        string[12] memory attr;
        
        attr[0] = "\"attributes\": [{";
        attr[1] = "\"trait_type\": \"Type\",\"value\": \"";
        attr[2] = _type;
        attr[3] = "\"},{\"trait_type\": \"ID\",\"value\": \"";
        attr[4] = _nuID.toString();
        attr[5] = "/45\"},{\"trait_type\": \"Artist\",\"value\": \"";
        attr[6] = _artist;
        attr[7] = "\"},{\"trait_type\": \"Artwork\",\"value\": \"";
        attr[8] = _artwork;
        attr[9] = "\"},{\"trait_type\": \"Series\",\"value\": \"";
        attr[10] = _series;
        attr[11] = "\"}]";

        string memory attributes = string(abi.encodePacked(attr[0],attr[1],attr[2],attr[3],attr[4],attr[5]));
        attributes = string(abi.encodePacked(attributes,attr[6],attr[7],attr[8],attr[9],attr[10],attr[11]));


        string memory json = Base64.encode(bytes(string(abi.encodePacked("{\"name\": \"",_name, "\", \"description\": \"", _desc ,"\", \"image\": \"", _image, "\", \"animation_url\": \"", _animURL , "\",",attributes,"}"))));
        output = string(abi.encodePacked("data:application/json;base64,", json));

        delete _name; delete _desc; delete _image; delete _type; delete _artist; delete _series; delete _artwork; delete attributes;
        
        return output;
    }

    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(LilOwnable, ERC721)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
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