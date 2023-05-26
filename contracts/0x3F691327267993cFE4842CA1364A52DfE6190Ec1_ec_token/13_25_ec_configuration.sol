pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";


contract ec_configuration {

    // jsons/ec/pluto_live.json

    string                   constant _name   = "Pluto2";
    string                   constant _symbol = "PLUTO2";

    struct theKitchenSink {
        uint256             _maxSupply;
        uint256             _mintPointer;
        address payable[]   _wallets;
        uint256 []          _shares;
        uint256             _fullPrice;
        uint256             _discountPrice;
        uint256             _communityPrice;
        bool                 _timedPresale;
        uint256              _presaleStart;
        uint256              _presaleEnd;
        bool                 _timedSale;
        uint256              _saleStart;
        uint256              _saleEnd;
        bool                 _dustMintAvailable;
        uint256              _dustPrice;
        bool                 _lockTillSaleEnd;
        // ETHER CARDS
        uint256              _maxFreeEC;
        uint256              _totalFreeEC;
        // DISCOUNTS
        uint256              _maxDiscount;
        uint256              _totalDiscount;
        // per address limits 
        uint256              _freePerAddress;
        uint256              _discountedPerAddress;
        string               _tokenPreRevealURI;
        address              _signer;

        bool                 _presaleActive;
        bool                 _saleActive;
        bool                 _dustMintActive;


        uint256              _freeClaimed;
        uint256              _discountedClaimed;

        address             EC;
        address             DUST;

        uint256             _maxPerSaleMint;
        uint256             _maxUserMintable;
        uint256             _userMinted;

        uint256             _communityMinted;   // what they have minted in a community contract

        bool                _randomReceived;
        bool                _secondReceived;
        uint256             _randomCL;
        uint256             _randomCL2;
        uint256             _ts1;
        uint256             _ts2;
        


    }

    // 

    uint256                  constant _maxSupply = 10000;

    address payable[]           _wallets = [ 
                                  payable(0xd23B23e61097346b8eA7655480cEb49d82cb9e54) 
                                 , payable(0xBaC204299bEb34fef9299567fF0105ec13B854b0) 
                                 ];
    uint256 []                  _shares = [ 
                                  100 
                                 , 900 
                                
                                ];

    uint256                  constant _fullPrice = 80000000000000000;
    uint256                  constant _discountPrice = 72000000000000000;
    uint256                  constant _communityPrice = 80000000000000000;

    bool                              _timedPresale  = true;
    uint256                           _presaleStart = 1638374400;  // Wed, 01 Dec 2021 16:00
    uint256                           _presaleEnd = 1638979200;      // Wed, 08 Dec 2021 16:00

    bool                              _timedSale = true;
    uint256                           _saleStart = 1638374400;        // Wed, 01 Dec 2021 16:00
    uint256                           _saleEnd = 1638979200;            // Wed, 08 Dec 2021 16:00

    bool                     constant _dustMintAvailable = false;
    uint256                  constant _dustPerAddress = 0;
    uint256                  constant _dustPrice = 1;

    bool                              _lockTillSaleEnd = false;

    // ETHER CARDS
    uint256                  constant _maxFreeEC = 0;
    uint256                           _totalFreeEC;

    // DISCOUNTS
    uint256                  constant _maxDiscount = 10000;
    uint256                           _totalDiscount;

    // per address limits
    uint256                  constant _freePerAddress = 0;
    uint256                  constant _discountedPerAddress = 1000;

    string                            _tokenPreRevealURI = "https://ether-cards.mypinata.cloud/ipfs/QmRoQ34cdk1pfkwjeTGTkRM2qFLU4J5Xns5c4AuPDY7dA8";

    address                  constant public _signer = 0xA55c7770161b6325B64a622821e2db3551Df6C9e;

    // Private Minting

    address             constant _clientVault = 0x2669BAE63BF04F0572e881334809A4A7b46B91Fe;
    uint256             _clientMintPointer = 1;
    uint256             _clientMintPosition = 0;
    uint256             constant _clientMintLimit = 50;

    address             constant _ecVault = 0x7f5C7AFD7D7b8D2997BdE109B1329Fd4f9520F98;
    uint256             _ecMintPointer = 1;
    uint256             _ecMintPosition = 0;
    uint256             constant _ecMintLimit = 150;

    uint256             constant _maxPerSaleMint = 50;

}