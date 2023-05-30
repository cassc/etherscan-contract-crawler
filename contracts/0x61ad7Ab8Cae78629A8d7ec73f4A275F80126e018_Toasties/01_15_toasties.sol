// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "ECDSA.sol";
import "Counters.sol";
import "Strings.sol";
import "ReentrancyGuard.sol";

contract Toasties is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using Strings for uint256;

    /**
    * @dev ERC721 gas optimized contract based on GBD.
    * */

    // mint variables
    uint256 public totalSupply = 7777;
    uint256 public PRICE = 0 ether;
    uint256 public constant RESERVED = 1;
    uint256 public constant TEAM = 0;
    
    uint256 public amountMintable = 20;
    uint256 public mainsaleStart;
    mapping(address => uint256) public amountMinted;

    bool public reservesMinted = false;

    Counters.Counter public tokenSupply;

    // metadata variables
    string public tokenBaseURI = "ipfs://QmTZjLFYm5uHKYb4rsKgFsRZXoQrf1mY6VsRCCKPR3pkbi/";
    string public unrevealedURI;

    // benefactor variables
    address payable immutable public payee;
    address immutable public reservee = 0xd95740e361Fc851E1338A7E2E82255176417d4eD;

    /**
    * @dev Contract Methods
    */

    constructor(
        address _payee,
        uint256 _mainsaleStart
        ) ERC721("Toasties", "TOAST") {
        payee = payable(_payee);
        mainsaleStart = _mainsaleStart;
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
    
    function mint(uint256 _quantity) external payable {
        require(mainsaleStart > 0, "Sale start time has not been set");

        if (_mintActive() == true) {
            require(amountMinted[msg.sender] + _quantity <= amountMintable, "Quantity is more than mintable amount per account");
            amountMinted[msg.sender] = _quantity + amountMinted[msg.sender];
        } else {
            revert("sale hasn't started");
        }

        // require payment
        require(msg.value >= PRICE.mul(_quantity), "The ether value sent is less than the mint price.");
        _safeMint(_quantity);
    }

    function _safeMint(uint256 _quantity) internal {
        require(_quantity > 0, "You must mint at least 1");
        require(tokenSupply.current().add(_quantity) <= totalSupply, "This purchase would exceed totalSupply");
        this.withdraw();
        
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