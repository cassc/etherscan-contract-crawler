// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "IERC20.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "ECDSA.sol";
import "Counters.sol";
import "Strings.sol";
import "ReentrancyGuard.sol";

contract DILDAO is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using Strings for uint256;

    /**
    * @dev A giant bag of dicks 8====D~~~
    * */

    // mint variables
    uint256 public totalSupply = 6969;
    uint256 public PRICE = 0.00 ether;
    uint256 public constant RESERVED = 70;
    uint256 public constant TEAM = 30;
    
    uint256 public amountMintable = 1;
    uint256 public mainsaleStart;
    uint256 public presaleStart;
    mapping(address => uint256) public amountMinted;
    IERC20 public suck;

    bool public reservesMinted = false;

    Counters.Counter public tokenSupply;

    // metadata variables
    string public tokenBaseURI;
    string public unrevealedURI;

    // benefactor variables
    address payable immutable public payee;
    address immutable public reservee = 0x3f4cF2b72CbA8a1696CdfbF29329bA36d0B93268;

    // merkle variables
    bytes32 public root;

    /**
    * @dev Contract Methods
    */

    constructor(
        address _reservee, 
        uint256 _mainsaleStart, 
        uint256 _presaleStart
        ) ERC721("Suckiverse DilDAO", "DILDAO") {
        payee = payable(msg.sender);
        mainsaleStart = _mainsaleStart;
        presaleStart = _presaleStart;
    }

    /************
    * Metadata *
    ************/

    function setTokenBaseURI(string memory _baseURI) external onlyOwner {
        tokenBaseURI = _baseURI;
    }

    function setUnrevealedURI(string memory _unrevealedUri) external onlyOwner {
        unrevealedURI = _unrevealedUri;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        bool revealed = bytes(tokenBaseURI).length > 0;

        if (!revealed) {
            return unrevealedURI;
        }

        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
    }

    /***************
    * Mint Setters *
    ***************/

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setAmountMintable(uint256 _amount) external onlyOwner {
        amountMintable = _amount;
    }

    function setMainsaleStart(uint256 _start) external onlyOwner {
        mainsaleStart = _start;
    }

    function setPresaleStart(uint256 _start) external onlyOwner {
        presaleStart = _start;
    }

    function suckiverse(address _suck) external onlyOwner {
        suck = IERC20(_suck);
    }

    /*******
    * Mint *
    *******/

    function _mintActive() internal view returns (bool) {
        if (block.timestamp > mainsaleStart) {
            return true;
        } else {
            return false;
        }
    }

    function _presaleActive() internal view returns (bool) {
        if (block.timestamp > presaleStart) {
            return true;
        } else {
            return false;
        }
    }

    function tier(address user) internal view returns (uint256) {
        if (suck.totalSupply() / suck.balanceOf(msg.sender) <= 20) {
            return 420;
        } else if (suck.totalSupply() / suck.balanceOf(msg.sender) <= 50 ) {
            return 150;
        } else if (suck.totalSupply() / suck.balanceOf(msg.sender) <= 100) {
            return 69;
        } else if (suck.totalSupply() / suck.balanceOf(msg.sender) <= 200) {
            return 25; 
        } else if (suck.totalSupply() / suck.balanceOf(msg.sender) <= 400) {
            return 12;
        } else if (suck.totalSupply() / suck.balanceOf(msg.sender) <= 1000) {
            return 5;
        } else {
            return 0;
        }
    }
    
    function mint(uint256 _quantity) external {
        require(presaleStart > 0 && mainsaleStart > 0, "Sale start times have not been set");

        if (_mintActive() == true) {
            require(amountMinted[msg.sender] + _quantity <= amountMintable, "Quantity is more than mintable amount per account");
            amountMinted[msg.sender] = _quantity + amountMinted[msg.sender];
        } else if (_presaleActive() == true) {
            require(suck.balanceOf(msg.sender) > 0, "need at least 1 suck token");
            require(amountMinted[msg.sender] + _quantity <= tier(msg.sender), "Quantity is higher than tier amount for this account");
            amountMinted[msg.sender] = _quantity + amountMinted[msg.sender];
        } else {
            revert("sale hasn't started");
        }

        _safeMint(_quantity);
    }

    function _safeMint(uint256 _quantity) internal {
        require(_quantity > 0, "You must mint at least 1");
        require(tokenSupply.current().add(_quantity) <= totalSupply, "This purchase would exceed totalSupply");
        
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 mintIndex = tokenSupply.current();

            if (mintIndex < totalSupply) {
            tokenSupply.increment();
            ERC721._safeMint(msg.sender, mintIndex);
            }
        }

    }

    function mintReserved() external onlyOwner {
        require(!reservesMinted, "Reserves have already been minted.");
        require(tokenSupply.current().add(RESERVED) <= totalSupply, "This mint would exceed totalSupply");
        reservesMinted = true;

        for (uint256 i = 0; i < RESERVED; i++) {
            uint256 mintIndex = tokenSupply.current();

            if (mintIndex < totalSupply) {
                tokenSupply.increment();
                    if (mintIndex > RESERVED - TEAM){
                        ERC721._safeMint(msg.sender, mintIndex);
                    } else {
                        ERC721._safeMint(reservee, mintIndex);
                    }
            }
        }
    }

    /**************
    * Withdrawal *
    **************/

    function withdraw() public {
        uint256 balance = address(this).balance;
        payable(payee).transfer(balance);
    }

}