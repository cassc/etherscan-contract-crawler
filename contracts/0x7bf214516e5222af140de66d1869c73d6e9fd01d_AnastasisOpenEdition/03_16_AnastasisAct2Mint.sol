// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./AnastasisAct2.sol";
import "./FundSplit.sol";
import "./IERC721.sol";
import "./IERC20.sol";

contract AnastasisOpenEdition {

    uint256 public _holderPrice = 0.015 ether;
    uint256 public _publicPrice = 0.02 ether;
    uint256 public _ashPrice = 20*10**18;

    address public _ashAddress= 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92;
    address public _fomoverseAddress = 0x74BB71a4210E33256885DEF483fD4227b7f9D88F;
    address public _anastasisAct2Address= 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92;
    address private _fundSplitAddress;
    address private _signer;

    bool public _mintOpened;

    mapping (address => bool) _isAdmin;
    mapping (address => uint256) _mintedQuantity;
    mapping (address => bool) public _biddersHasMinted;

    constructor(){
        _isAdmin[msg.sender] = true;
    }

    function setFundSplitAddress(address fundSplitAddress) external {
        require(_isAdmin[msg.sender]);
        _fundSplitAddress = fundSplitAddress;
    }

    function setAshAddress(address ashAddress) external{
        require(_isAdmin[msg.sender]);
        _ashAddress = ashAddress;
    }

    function setFOMOAddress(address FOMOAddress) external{
        require(_isAdmin[msg.sender]);
        _fomoverseAddress = FOMOAddress;
    }

    function setAnastasisAct2Address(address anastasisAct2Address) external{
        require(_isAdmin[msg.sender]);
        _anastasisAct2Address = anastasisAct2Address;
    }

    function toggleAdmin(address newAdmin)external{
        require(_isAdmin[msg.sender]);
        _isAdmin[newAdmin] = !_isAdmin[newAdmin];
    }
    
    function toggleMintOpened()external{
        require(_isAdmin[msg.sender]);
        _mintOpened = !_mintOpened;
    }

    function setSigner (address signer) external{
        require(_isAdmin[msg.sender], "Only Admins can set signer");
        _signer = signer;
    }

    function mintAllowed( uint8 v, bytes32 r, bytes32 s)internal view returns(bool){
        return(
            _signer ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            keccak256(
                                abi.encodePacked(
                                    msg.sender,
                                    _anastasisAct2Address,
                                    _mintOpened,
                                    _biddersHasMinted[msg.sender] // should be false
                                )
                            )
                        )
                    )
                , v, r, s)
        );
    }

    function mint(bool payInEth, uint256 quantity) external payable{
        require(_mintOpened, "Mint closed");
        require(quantity > 0, "Wrong quantity");
        require(_mintedQuantity[msg.sender] + quantity <= 30, "Cannot mint more than 30 tokens");
        require(quantity <= 10, "Cannot mint more than 10 tokens in one transaction");
        
        bool hasDiscount = false;
        bool success;
        if(
            IERC20(_ashAddress).balanceOf(msg.sender) >= 25*10**18 || 
            IERC721(_fomoverseAddress).balanceOf(msg.sender) >= 1
        ){hasDiscount = true;}
        if(payInEth){
            uint256 price = hasDiscount ? _holderPrice : _publicPrice;
            require(msg.value >= price * quantity, "Not enough funds");
            success = payable(_fundSplitAddress).send(price * quantity);
        }else{
            address payable fundSplitContract = payable(address(_fundSplitAddress));
            success = FundSplit(fundSplitContract).depositAsh(msg.sender, _ashPrice * quantity);
        }
        require(success, "Funds could not transfer");
        Anastasis_Act2(_anastasisAct2Address).mint(msg.sender, quantity);
        _mintedQuantity[msg.sender] += quantity;
    }

    function getFreeMint(
        uint8 v,
        bytes32 r, 
        bytes32 s
    )external{
        require(_mintOpened, "Mint closed");
        require(mintAllowed(v, r, s), "Mint not allowed");
        require(_mintedQuantity[msg.sender] < 30,"Cannot mint more than 30 tokens");
        Anastasis_Act2(_anastasisAct2Address).mint(msg.sender, 1);
        _biddersHasMinted[msg.sender] = true;
        _mintedQuantity[msg.sender] += 1;
    }

}