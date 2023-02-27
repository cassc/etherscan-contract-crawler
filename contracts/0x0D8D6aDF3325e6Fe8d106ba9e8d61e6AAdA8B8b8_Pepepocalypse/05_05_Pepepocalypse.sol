//SPDX-License-Identifier-MIT
pragma solidity ^0.8.0;
import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

//requirements
//mint function
//set the token uri function
//token uri

error WITHDRAW_FAILED();
error NOT_ENOUGH_ETH_SENT();
error MINT_OUT();
error MAX_TEN_ALLOWED();
error LIMIT_EXCEEDED();
error SALE_NOT_ACTIVE();

contract Pepepocalypse is ERC721A, Ownable {
    string public _baseTokenURI;
    uint public mintPrice = 0.002 ether;
    uint public constant maxSupply = 3333;
    uint public constant devMintSupply = 133;
    bool public revealed = false;
    string public defaultURI;
    bool public saleActive = false;
    uint public devMintCounter;


    mapping(address => uint) public userMints;



    constructor() ERC721A("Pepepocalypse", "PPLYPSE") {}

    function mint(uint quantity) external payable {
        if(msg.value < mintPrice * quantity)
        {
            revert NOT_ENOUGH_ETH_SENT();
        }
        if(quantity > 10)
        {
            revert MAX_TEN_ALLOWED();
        }
        if(userMints[msg.sender] + quantity > 10)
        {
            revert LIMIT_EXCEEDED();
        }
        //if total supply + dev mint supply + user mint supply is greater than max supply
        if(totalSupply() + devMintSupply  + quantity > maxSupply)
        {
            revert LIMIT_EXCEEDED();
        }
        if(totalSupply()   >= maxSupply)
        {
            revert MINT_OUT();
        }
        if(!saleActive)
        {
            revert SALE_NOT_ACTIVE();
        }

        userMints[msg.sender] = userMints[msg.sender] + quantity;
        _mint(msg.sender,quantity);
    }

    function devMint(uint _quantity) external onlyOwner{
        //check _quantity is not greater than devMintSupply
        if(_quantity > devMintSupply)
        {
            revert LIMIT_EXCEEDED();
        }

        _mint(msg.sender, _quantity);

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(!revealed)
        {
            return defaultURI;
        }
        else
        {
            return string(abi.encodePacked(_baseTokenURI, _toString(tokenId),".json"));
        }
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert WITHDRAW_FAILED();
        }
    }

    receive() external payable {}

    fallback() external payable {}

    function setMintPrice(uint _mintPrice) external onlyOwner{
        mintPrice = _mintPrice;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner{
        defaultURI = _defaultURI;
    }

    function setRevealed(bool _revealed) external onlyOwner{
        revealed = _revealed;
    }

    function setPublicSale(bool _saleActive) external onlyOwner{
        saleActive = _saleActive;
    }

  
}