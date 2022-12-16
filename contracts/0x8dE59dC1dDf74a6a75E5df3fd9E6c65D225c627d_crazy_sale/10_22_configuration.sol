pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";


contract configuration {

    // jsons/ec/pluto.json

    string                   constant _name   = "Tokyo Degenerates";
    string                   constant _symbol = "TDGN";

    struct theKitchenSink {
        uint256             _maxSupply;
        
        uint256             _mintPointer;
        address payable[]   _wallets;
        uint256 []          _shares;
        uint256             _fullPrice;
        uint256             _presalePrice;
        uint256              _presaleStart;
        uint256              _presaleEnd;
        bool                 _timedSale;
        uint256              _saleStart;
        uint256              _saleEnd;
        uint256              _ensSalePrice;
        uint256              _ensPresalePrice;
        bool                 _lockTillSaleEnd;
        // per address limits 
        uint256              _salePerAddress;
        uint256              _discountedPerAddress;
        string               _tokenPreRevealURI;

        bool                 _presaleActive;
        bool                 _saleActive;
        bool                 _dustMintActive;



        address             ENS;

        uint256             _maxPerSaleMint;
        uint256             _maxUserMintable;
        uint256             _userMinted;

        bool                _secondReceived;

        uint256             _ts1;
        uint256             _ts2;

    }

    // 

    uint256                  constant _maxPresaleSupply = 1000;
    uint256                  constant _maxSupply = 10000;

    address payable[]           _wallets = [ 

                                    payable(0x3E5F533A865C4e4efd4338fF4Fc36EA3D749FE8C),
                                    payable(0x9f97c580ad628B3458a8Aad3BD94F1aCB44Fc830),
                                    payable(0x93d42b0Ade77E1F6001Ddc9B6375254986AB0875),
                                    payable(0x0F199A126fDc51e82267e674e36732c94b5152b4)
                                 ];
    uint256 []                  _shares = [ 
                                  960,
                                  10,
                                  10,
                                  20 
                                ];

    uint256                  constant _fullPrice = 80000000000000000;
    uint256                  constant _discountPrice = 50000000000000000;
    uint256                  constant _clientMint = 100;

    bool                              _timedPresale  = false;
    uint256                           _presaleStart = 1638363600;  // Wed, 01 Dec 2021 13:00
    uint256                           _presaleEnd = 1638368100;      // Wed, 01 Dec 2021 14:15

    bool                              _timedSale = false;
    uint256                           _saleStart = 1638363600;        // Wed, 01 Dec 2021 13:00
    uint256                           _saleEnd = 1638368100;            // Wed, 01 Dec 2021 14:15

    uint256                  constant _ensPresalePrice = 5e18;
    uint256                  constant _ensSalePrice = 8e18;

    bool                              _lockTillSaleEnd = false;

    // DISCOUNTS
    uint256                  constant _maxDiscount = 10000;
    uint256                           _totalDiscount;

    // per address limits
    uint256                  constant _discountedPerAddress = 1000;

    string                            _tokenPreRevealURI = "https://api.tokyodegenerates.com/";

    
    // Private Minting


    uint256             constant _maxPerSaleMint = 10;

    uint256             constant _presalePerAddress = 10;
    uint256             constant _salePerAddress = 10;

    address             constant _presigner = 0x419B3f5982DA6AD4D590c44B071409f3982ce810;


}