pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";


contract pixiedust {

    // jsons/toddlerpillars.json

    string                   constant _name   = "Toddlerpillars";
    string                   constant _symbol = "TDPL";

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

    uint256                  constant _maxSupply = 9999;

    address payable[]           _wallets = [ 
                                  payable(0x7F17cD2B6627166F2c69884AD8DA14fAb3fff522) 
                                 , payable(0xb108Cd8C67d0ad0690A119BBcc0708289A4Ee9c3) 
                                 , payable(0x422D9914eE2A933a040815F9A619D27252373EbD) 
                                 ];
    uint256 []                  _shares = [ 
                                  150 
                                 , 250 
                                 , 600 
                                
                                ];

    uint256                  constant _fullPrice = 40000000000000000;
    uint256                  constant _discountPrice = 40000000000000000;
    uint256                  constant _communityPrice = 40000000000000000;

    bool                              _timedPresale  = true;
    uint256                           _presaleStart = 1637254800;  // Thu, 18 Nov 2021 17:00
    uint256                           _presaleEnd = 1637341200;      // Fri, 19 Nov 2021 17:00

    bool                              _timedSale = true;
    uint256                           _saleStart = 1637341200;        // Fri, 19 Nov 2021 17:00
    uint256                           _saleEnd = 1638550800;            // Fri, 03 Dec 2021 17:00

    bool                     constant _dustMintAvailable = false;
    uint256                  constant _dustPerAddress = 0;
    uint256                  constant _dustPrice = 1;

    // ETHER CARDS
    uint256                  constant _maxFreeEC = 0;
    uint256                           _totalFreeEC;

    // DISCOUNTS
    uint256                  constant _maxDiscount = 9999;
    uint256                           _totalDiscount;

    // per address limits
    uint256                  constant _freePerAddress = 0;
    uint256                  constant _discountedPerAddress = 6;

    string                            _tokenPreRevealURI = "https://ether-cards.mypinata.cloud/ipfs/QmeKvyYvMThpuDUQ7po4AWxr5SUpfyNKecDmsgS4VqZmNu";

    address                  constant public _signer = 0xA55c7770161b6325B64a622821e2db3551Df6C9e;

    // Private Minting

    address             constant _clientVault = 0x422D9914eE2A933a040815F9A619D27252373EbD;
    uint256             _clientMintPointer = 1;
    uint256             _clientMintPosition = 0;
    uint256             constant _clientMintLimit = 550;

    address             constant _ecVault = 0x9dFF1113CF4186deC4feb774632356D22f07eB9e;
    uint256             _ecMintPointer = 1;
    uint256             _ecMintPosition = 0;
    uint256             constant _ecMintLimit = 100;

    uint256             constant _maxPerSaleMint = 50;

}