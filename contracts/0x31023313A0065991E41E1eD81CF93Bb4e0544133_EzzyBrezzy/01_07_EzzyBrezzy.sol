// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./common/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

struct MintInfo {
    uint256 unitPrice;
    uint256 undiscountedPrice;
    uint256 priceToPay;
    bool dropActive;
    uint16 totalMints;
    uint16 mintsToPay;
}

contract EzzyBrezzy is ERC721A, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    string public constant COL_NAME = "Ezzy Brezzy";
    string public constant TICKER = "EZBZ";

    uint256 public MAX_ELEMENTS = 1667;  //must be +1
    uint256 public PRICE = 0.049 ether;
    uint256 public constant SALE_LIMIT = 4;  //must be +1

    address public whiteListSigningAddress = address(0xc429C9A7Db096B4e5795D280A203f8dBC284c9d7);


    address public constant wdAddress = address(0x08678c1609ee1023f1F9F3951E7620daF8e2D0f9);


    enum Status {CLOSED, PRESALE, SALE}
    Status public state = Status.CLOSED;
    string public baseTokenURI;

    address proxyRegistryAddress;
 
    constructor(string memory baseURI, address _proxyRegistryAddress) ERC721A(COL_NAME, TICKER){
        setBaseURI(baseURI);
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    modifier saleIsOpen {
       require (state != Status.CLOSED, "sales closed");
        _;
    }


    function setWhiteListSigningAddress(address _signingAddress) external onlyOwner {
        whiteListSigningAddress = _signingAddress;
    }

    function setSaleState(uint newState) external onlyOwner {
        state = Status(newState);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

     function setPrice(uint256 newPrice) public onlyOwner {
        PRICE = newPrice;
    }

     function setMaxElements(uint256 newMax) public onlyOwner {
        MAX_ELEMENTS = newMax;
    }
    //compat
    function isDropActive() public view returns (bool) {
        return state != Status.CLOSED;
    }

    //compat

    function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

    function tokenURI(uint256 tokenId) public override view returns (string memory)
        {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

            return bytes(_baseURI()).length > 0 
                ? string(abi.encodePacked(_baseURI(), tokenId.toString(), (".json")))
                : "";
        }

    function mintedCount(address addressToCheck) external view returns (uint) {
        return _numberMinted(addressToCheck);
    }

    function getMintInfo(address buyer, uint16 quantity) public view returns (MintInfo memory) {
        uint16 freeMintsAllowed = 0;

        uint16 quantityToPay = quantity;
 
        if (_numberMinted(buyer) == 0) {
            quantityToPay = quantity - freeMintsAllowed;
        }

        return MintInfo(
        /* unitPrice */ PRICE,
        /* undiscountedPrice */ PRICE * quantity,
        /* priceToPay */ PRICE * quantityToPay,
        /* dropActive */ isDropActive(),
        /* totalMints */ quantity,
        /* mintsToPay */ quantityToPay
        );
    }

    function airdrop(address to, uint16 quantity) external onlyOwner {
        require(_totalMinted() + quantity < MAX_ELEMENTS, "Maximum amount of mints reached");
        _mint(to, quantity);
    }

    function mint(uint16 _numToMint, bytes calldata _signature) external payable saleIsOpen {
        MintInfo memory info = getMintInfo(_msgSender(), _numToMint);
        require(_numToMint > 0 && _numToMint < SALE_LIMIT, "max limit to mint");
        require(_totalMinted() + _numToMint < MAX_ELEMENTS, "Maximum amount of nfts reached");
        require(_msgSender() == tx.origin, "no contract calls");
        require((_numToMint + _numberMinted(_msgSender())) < SALE_LIMIT, "minting more than allowed");
        require(msg.value == info.priceToPay, "value must equal price");

        if(state == Status.PRESALE) {
            require(
                whiteListSigningAddress ==
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            bytes32(uint256(uint160(msg.sender)))
                        )
                    ).recover(_signature),
                "you are not whitelisted"
            );
        }

        // solhint-disable-next-line
        _safeMint(_msgSender(), _numToMint);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        (bool success, ) = wdAddress.call{value:  balance}("");
        require(success, "Transfer failed.");
    }

    //Whitelist opensea proxy
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

}