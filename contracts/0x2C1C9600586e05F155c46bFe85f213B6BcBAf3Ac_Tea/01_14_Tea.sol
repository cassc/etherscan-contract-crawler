// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Tea is ERC721A, Ownable, ReentrancyGuard{

    using SafeMath for uint256;
    using Strings for uint256;

    string private _baseImage;

    uint256 public maxSupply = 10000;

    uint256 public freeSupply = 500;

    bool public freeOpen = false;

    bool public open = false;

    uint256 public perTxAmount = 5;

    uint256 public price = 0.0088 ether;

    mapping(address => bool) public freeMinted;

    bool public approvedOs;
    

    constructor()ERC721A("Tea", "Tea", 500)
    {
    } 

    modifier eoaOnly() {
        require(tx.origin == msg.sender, "EOA Only");
        _;
    }

    modifier freeOpened() {
        require(freeOpen, "Free mint not open.");
        _;
    }

    modifier opened() {
        require(open, "Mint not open.");
        _;
    }

    function toggleApproveOs(bool _approvedOs) external eoaOnly onlyOwner
    {
        approvedOs = _approvedOs;
    }

    function toggleFreeOpen(bool _freeOpen) external eoaOnly onlyOwner
    {
        freeOpen = _freeOpen;
    }

    function toggleOpen(bool _open) external eoaOnly onlyOwner
    {
        open = _open;
    }

    function setPerTxAmount(uint256 _perTxAmount) external eoaOnly onlyOwner
    {
        perTxAmount = _perTxAmount;
    }

    function setPrice(uint256 _price) external eoaOnly onlyOwner
    {
        price = _price;
    }

    function setFreeSupply(uint256 _freeSupply) external eoaOnly onlyOwner
    {
        require(_freeSupply <= maxSupply,"Reach the maximum supply.");
        freeSupply = _freeSupply;
    }


    function reserveMint(address _to,uint256 _amount) external payable eoaOnly onlyOwner {
       
       uint totalSupply = totalSupply();

       require(totalSupply.add(_amount) <= maxSupply,"Reach the maximum supply.");

        _safeMint(_to,_amount);
    }


    function reserveMintBatch(address[] memory _tos,uint256 [] memory _amounts) external payable eoaOnly onlyOwner {
       
       require(_tos.length == _amounts.length,"Length error.");

       uint256 totalAmount;

       uint totalSupply = totalSupply();

       for(uint256 i = 0 ; i < _amounts.length; i++){

           totalAmount = totalAmount.add(_amounts[i]);

           require(totalSupply.add(totalAmount) <= maxSupply,"Reach the maximum supply.");

           _safeMint(_tos[i],_amounts[i]);
       } 
    }

    function freeMint() public eoaOnly freeOpened payable{

        uint totalSupply = totalSupply();

        require(totalSupply.add(1) <= freeSupply,"Reach the maximum free supply."); 

        require(!freeMinted[msg.sender],"Free minted.");

        freeMinted[msg.sender] = true;
        
        _safeMint(msg.sender, 1);
    }

    function mint(uint256 amount) public eoaOnly opened payable{

        uint totalSupply = totalSupply();

        require(amount > 0 && amount <= perTxAmount, "Reach the maximum amount per tx.");

        require(totalSupply.add(amount) <= maxSupply,"Reach the maximum supply."); 

        require(msg.value >= price.mul(amount),"Insufficient funds.");

        _safeMint(msg.sender, amount);
    }


    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }


    function setBaseImage(string calldata baseImage) external onlyOwner {
        _baseImage = baseImage;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory json = Base64.encode(
            bytes(
                string(abi.encodePacked("{\"name\":\"TEA #",tokenId.toString(),"\",\"image\":\"",_baseImage, "\"}"))
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }


    function withdrawETH(address _to) public onlyOwner{
        payable(_to).transfer(address(this).balance);
    }
    

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        //OpenSea: Conduit
        if(approvedOs && operator == address(0x1E0049783F008A0085193E00003D00cd54003c71)){
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