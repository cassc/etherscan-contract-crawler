// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ERC721A.sol";
import "./SVG.sol";
import "./Utils.sol";

interface Uni {
    function slot0() view external returns(uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
}

interface Rend {
    function render(uint256 id, uint160 sqrtPriceX96) view external returns(string memory);
}


contract pepethdeployer is ERC721A, Ownable {

    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 250;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public cost = .03 ether;
    bool public publicSale;
    bool public pause;
    address public uniPool = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;
    mapping(address => uint256) public totalPublicMint;


    constructor() ERC721A("pepethereum", "PE"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Can't be called by a contract");
        _;
    }

    function getRender(uint256 id) public view returns (string memory img) {
        Rend toRend = Rend(0xD15d1450382BCC50C819E722be6079593493E603);
        string memory img = toRend.render(id, getPrice3());
        return(img);
    }

    function getPrice3() public view returns (uint160 sqrtPriceX96) {
        Uni uniPrice = Uni(uniPool);
        (uint160 sqrtPriceX96 , , , , , ,) =  uniPrice.slot0();
        return(sqrtPriceX96);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setPool(address _newPool) public onlyOwner {
        uniPool = _newPool;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Not Yet Active");
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
        string memory r = getRender(id);

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(r)
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
                                '{"name":"PepEmotion #',
                                id.toString(),unicode'", "image":"',
                                image,
                                unicode'", "description": "Does eth make u :) or :("}'
                            )
                        )
                    )
                )
            );
    }


}