// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";



interface CredsInterface {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burnFrom(address sender, uint256 amount) view external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


}


interface DystoPunks {
    function balanceOf(address account) external view returns (uint256);
}

contract DystolabCrates is ERC1155Supply, Ownable   {


    address constant public CredsAddress = 0xc13F4F0F865bAc08F62654B57E38669EbC4747a3;
    address constant public DystoAddress = 0xbEA8123277142dE42571f1fAc045225a1D347977;
    address constant public BurnAddress = 0x000000000000000000000000000000000000dEaD;
    bool public saleIsActive = true;
    uint private _tokenId = 77;
    uint constant MAX_TOKENS = 7777;
    uint constant TOKEN_PRICE = 300 ether;



    constructor(string memory uri) ERC1155(uri) {
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function totalAvailable(address ownwer) external view returns (uint) {
        uint value = CredsInterface(CredsAddress).balanceOf(ownwer);
        return value;
    }

    function mint(uint numberOfTokens) public  {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(totalSupply(_tokenId) + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        uint valueHold = CredsInterface(CredsAddress).balanceOf(msg.sender);
        require(TOKEN_PRICE * numberOfTokens <= valueHold, "Value is not correct");
        uint punks = DystoPunks(DystoAddress).balanceOf(msg.sender);
        require(punks > 0, "Value of punks is not correct");
        uint value = TOKEN_PRICE * numberOfTokens;
        CredsInterface(CredsAddress).transferFrom(msg.sender,BurnAddress,value);

        _mint(msg.sender, _tokenId, numberOfTokens, "");

    }


}