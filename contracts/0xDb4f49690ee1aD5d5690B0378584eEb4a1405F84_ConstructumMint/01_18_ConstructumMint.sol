// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.17;

import "./Constructum.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConstructumMint {

    uint256 public _price;
    uint256 public _maxSupply;
    uint256 public _reservedMints;
    uint256 public _supply;
    uint256 public _limitPublicMintPerWallet;

    bool public _ALMintOpened;
    bool public _publicMintOpened;

    address public _constructumAddress;
    address public _signer;
    address private _recipient;

    mapping(address => uint256) public _ALTokensMinted;
    mapping(address => bool) public _reserveTokenMinted;
    mapping(address => uint256) public _publicTokenMinted;
    mapping (address => bool) public _isAdmin;

    constructor(){
        _isAdmin[msg.sender] = true;
        _maxSupply = 55;
        _price = 0.08 ether;
        _reservedMints = 3;
        _limitPublicMintPerWallet = 1;
    }

    function toggleAdmin(address newAdmin)external{
        require(_isAdmin[msg.sender]);
        _isAdmin[newAdmin] = !_isAdmin[newAdmin];
    }

    function setRecipient(address recipient) external {
        require(_isAdmin[msg.sender]);
        _recipient = recipient;
    }

    function setSigner (address signer) external{
        require(_isAdmin[msg.sender], "Only Admins can set signer");
        _signer = signer;
    }

    function configDrop(
        uint256 price,
        uint256 maxSupply,
        uint256 reservedMints
    ) external {
        require(_isAdmin[msg.sender]);
        _price = price;
        _maxSupply = maxSupply;
        _reservedMints = reservedMints;
    }

    function setLimitPerWallet(uint256 limitPerWallet)external{
        require(_isAdmin[msg.sender]);
        _limitPublicMintPerWallet = limitPerWallet;
    }

    function setConstructumAddress(address constructumAddress) external{
        require(_isAdmin[msg.sender]);
        _constructumAddress = constructumAddress;
    }

    function toggleMintOpened()external{
        require(_isAdmin[msg.sender]);
        _publicMintOpened = !_publicMintOpened;
    }

    function toggleALMintOpened() external{
        require(_isAdmin[msg.sender], "Only Admins can toggle AL Mint");
        _ALMintOpened = !_ALMintOpened;
    }

    function mintAllowed(uint256 maxQuantity, bool isReserveMint, uint8 v, bytes32 r, bytes32 s)internal view returns(bool){
        return(
            _signer ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            keccak256(
                                abi.encodePacked(
                                    msg.sender,
                                    _constructumAddress,
                                    _ALMintOpened,
                                    _ALTokensMinted[msg.sender] < maxQuantity,
                                    maxQuantity,
                                    isReserveMint
                                )
                            )
                        )
                    )
                , v, r, s)
        );
    }

    function ALMint(
        uint8 v,
        bytes32 r, 
        bytes32 s,
        uint256 maxQuantity,
        bool isReserveMint,
        uint256 innerColor,
        uint256 outerColor,
        uint256 decoration
    ) external payable{
        require(mintAllowed(maxQuantity, isReserveMint, v, r, s), "Mint not allowed");
        if(isReserveMint){
            require(_supply < (_maxSupply),"Max supply reached");
            _reserveTokenMinted[msg.sender] = true;
        }else{
            require(_supply < (_maxSupply - _reservedMints),"Max supply reached");
            require(msg.value >= _price, "Not enough funds");
            _ALTokensMinted[msg.sender] ++;
            bool success = payable(_recipient).send(_price);
            require(success, "Funds could not transfer");
        }
        _supply ++;
         Constructum(_constructumAddress).mint(
            msg.sender, 
            innerColor,
            outerColor,
            decoration
        );
    }


    function mint(
        uint256 innerColor,
        uint256 outerColor,
        uint256 decoration
    ) external payable{
        require(_publicMintOpened, "Mint closed");
        require(msg.value >= _price, "Not enough funds");
        require( _publicTokenMinted[msg.sender] < _limitPublicMintPerWallet);
        require(_supply < (_maxSupply - _reservedMints),"Max supply reached");
        bool success = payable(_recipient).send(_price);
        require(success, "Funds could not transfer");
        _supply ++;
        _publicTokenMinted[msg.sender] ++;
        Constructum(_constructumAddress).mint(
            msg.sender, 
            innerColor,
            outerColor,
            decoration
        );
    }

}