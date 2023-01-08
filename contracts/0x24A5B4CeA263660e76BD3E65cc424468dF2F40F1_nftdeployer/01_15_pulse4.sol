// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface Uni {
    function slot0() view external returns(uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
}

contract nftdeployer is ERC721A, Ownable{
    using Strings for uint256;
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 300;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public cost = 0 ether;

    bool public publicSale = true;
    bool public pause;

    mapping(address => uint256) public totalPublicMint;

    Uni uniPrice = Uni(0x60594a405d53811d3BC4766596EFD80fd545A270);

    // function getPrice() public view returns (uint cur) {
    //     (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked) =  uniPrice.slot0();

    //     return(uint(sqrtPriceX96).mul(uint(sqrtPriceX96)).mul(1e18) >> (96 * 2));
    // }

    function getPrice2() public view returns (string memory cur2) {
        Uni uniPrice2 = Uni(0x60594a405d53811d3BC4766596EFD80fd545A270);
        (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked) =  uniPrice2.slot0();

        string memory cur2 = Strings.toString(uint(sqrtPriceX96).mul(uint(sqrtPriceX96)).mul(1e18) >> (96 * 2));
        return(cur2);
    }

    constructor() ERC721A("Pulse", "P"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Pulse :: Cannot be called by a contract");
        _;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply!");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Already minted!");
        require(msg.value >= (cost * _quantity), "Below mint price!");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }



    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }


    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
           
        return _buildTokenURI(id);
    }




    function _buildTokenURI(uint256 id) public view returns (string memory) {
        require(_exists(id), "ERC721Metadata: URI query for nonexistent token");


        string memory curPrice = string(
                abi.encodePacked(
                    unicode'<text x="20" y="305">Ξ',
                    getPrice2(),
                    "</text>"
                )
            );

        // string memory decPrice = string(
        //         abi.encodePacked(
        //             unicode'<text x="20" y="305">Ξ',
        //             sqrtPriceX96ToUint(getPrice(), 18),
        //             "</text>"
        //         )
        //     );
        
        

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<?xml version="1.0" encoding="UTF-8"?>',
                        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 400 400" preserveAspectRatio="xMidYMid meet">',
                        '<style type="text/css"><![CDATA[text { font-family: monospace; font-size: 21px;} .h1 {font-size: 40px; font-weight: 600;}]]></style>',
                        '<rect width="400" height="400" fill="#87ceeb" />',
                        '<text class="h1" x="50" y="70">Pulse</text>',
                        '<text class="h1" x="80" y="120" ></text>',
                        unicode'<text x="70" y="240" style="font-size:100px;"></text>',
                        curPrice,
                        unicode'<text x="210" y="305">$',
                 
                        "</text>",
                        '<text x="20" y="350" style="font-size:28px;"> ',
                       
                        "</text>",
                        '<text x="20" y="380" style="font-size:14px;">0x',
                  
                        "</text>",
                        "</svg>"
                    )
                )
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Pulse", "image":"',
                                image,
                                unicode'", "description": "eth/dai price"}'
                            )
                        )
                    )
                )
            );
    }
}