//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
 
import "@openzeppelin/contracts/access/Ownable.sol";


interface IAniwarNft {
    function createManyAniwarItem(uint8 _count, address _owner, string memory _aniwarType) external;
    
    function aniwarItems(uint256 _id) external view returns(uint256, string memory);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
interface IERC20 { 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract AniwarBoxNft is Ownable {
    address public constant NULL_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    IAniwarNft public immutable ANIWAR_NFT_CONTRACT;
    IERC20 public immutable ANI_TOKEN;
    mapping (string => bool) public aniwarTypesAllowed;
    mapping (string => string) public aniwarBoxToType;
    mapping (string => string) public aniwarTypeToBox;

    constructor(address _aniwar_nft_contract, address _aniwar_token) {
        ANIWAR_NFT_CONTRACT = IAniwarNft(_aniwar_nft_contract);
        ANI_TOKEN = IERC20(_aniwar_token);
        aniwarBoxToType["BoxAni"] = "Ani";
        aniwarBoxToType["BoxItem"] = "Item";
        aniwarTypeToBox["Ani"] = "BoxAni";
        aniwarTypeToBox["Item"] = "BoxItem";
        aniwarTypesAllowed["Ani"] = true;
        aniwarTypesAllowed["Item"] = true;
    } 

    // Owner Only
    function mintManyBoxes(address owner, uint8 _count, string memory _boxType) public onlyOwner {
        require(aniwarTypesAllowed[aniwarBoxToType[_boxType]], "Type Not Allowed! Add before continue!");
        require(owner != address(0), "Address Zero!");
        ANIWAR_NFT_CONTRACT.createManyAniwarItem( _count, owner, _boxType); 
    }

    function OpenBox(uint256 _id) public {
        (uint256 aniwarNftId, string memory _boxType) = ANIWAR_NFT_CONTRACT.aniwarItems(_id);
        require(aniwarTypesAllowed[aniwarBoxToType[_boxType]], "Type not allowed!");
        ANIWAR_NFT_CONTRACT.transferFrom(
            msg.sender,
            NULL_ADDRESS,
            aniwarNftId
        );
        ANIWAR_NFT_CONTRACT.createManyAniwarItem(1, msg.sender, aniwarBoxToType[_boxType]); 
    }

    function withdrawToken(address _token, address _to, uint256 _amount) public onlyOwner {
        IERC20(_token).transferFrom(address(this), _to, _amount);
    }

    function setTypesAllowed(string[] memory types, bool state) public onlyOwner {
        for (uint8 i = 0; i < types.length; i++) {
            aniwarTypesAllowed[types[i]] = state;
        }
    }
    function setBoxesAndTypes(string[] memory boxes, string[] memory types) public onlyOwner {
        for (uint8 i = 0; i < types.length; i++) {
            aniwarTypesAllowed[types[i]] = true;
            aniwarBoxToType[boxes[i]] = types[i];
            aniwarTypeToBox[types[i]] = boxes[i];
        }
    }
    function aniwarType() public pure returns(string memory) {
        return "BoxNft";
    }
}