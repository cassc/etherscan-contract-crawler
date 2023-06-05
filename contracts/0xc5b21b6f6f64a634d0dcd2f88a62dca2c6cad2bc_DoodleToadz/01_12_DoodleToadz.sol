// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./common/ERC721Ext.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}



contract DoodleToadz is ERC721Ext, Ownable {
    using ECDSA for bytes32;

    uint256 public constant MAX_ELEMENTS = 5556;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant PRESALE_PRICE = 0.042 ether;
    uint256 public constant PRESALE_LIMIT = 6;
    address public whiteListSigningAddress = address(6387432542);
    address public constant wdAddress = 0x94B7fa83257d120E765324D4f7c2509b56d11Ee5;

    address proxyRegistryAddress;

    enum Status {CLOSED, PRESALE, SALE}
    Status public state = Status.CLOSED;

    uint256 private tokenSupply = 1;

    string public baseTokenURI;


    constructor(string memory baseURI, address _proxyRegistryAddress) ERC721Ext("DoodleToadz", "DTODZ"){
        setBaseURI(baseURI);
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    modifier saleIsOpen {
       require (state != Status.CLOSED, "sales closed");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }


    function totalSupply() public view returns (uint256) {
        return tokenSupply - 1;
    }


    function airdropTo(address[] calldata _wallets) external onlyOwner {
        uint256 _tokenSupply = tokenSupply;
        uint256 num = _wallets.length;
        require(totalSupply() + num < MAX_ELEMENTS, "exceed limit");


        for(uint256 i = 0; i < num; i++) {
            _mint(_wallets[i], _tokenSupply);
            // solhint-disable-next-line
            unchecked {
                _tokenSupply++;
            }

        }
        tokenSupply = _tokenSupply;
    }

    function mint(uint256 _numToMint, bytes calldata _signature) external payable saleIsOpen {

        uint256 _tokenSupply = tokenSupply;
        require(_numToMint > 0 && _numToMint < 21, "max limit to mint"); //20 per mint
        require(totalSupply() + _numToMint < MAX_ELEMENTS, "sold out");
        require(msg.value == getPrice(_numToMint), "sended value must equal price");
        require(msg.sender == tx.origin, "no contract calls");
 

        if(state == Status.PRESALE) {
            require((_numToMint + numMinted(msg.sender)) < PRESALE_LIMIT, "minting more than allowed");

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


        for(uint8 i = 0; i < _numToMint; i++){
            uint256 tokenIdToMint = _tokenSupply;
            require(tokenIdToMint > 0 && tokenIdToMint < MAX_ELEMENTS, "sold out");

            _mint(msg.sender, tokenIdToMint);
            // solhint-disable-next-line
            unchecked {
                _tokenSupply++;
            }
        }
        tokenSupply = _tokenSupply;

    }

    function getPrice(uint256 _count) public view returns (uint256) {
        if(state == Status.PRESALE){
            return PRESALE_PRICE * _count;
        }
        return PRICE * _count;
    }


    function setWhiteListSigningAddress(address _signingAddress) external onlyOwner {
        whiteListSigningAddress = _signingAddress;
    }


    function setSaleState(uint newState) external onlyOwner {
        state = Status(newState);
    }


    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        (bool success, ) = wdAddress.call{value: balance}("");
        require(success, "Transfer failed");
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