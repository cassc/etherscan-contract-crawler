// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import "./base/ERC721aNFT.sol";
import "./ext/MultipleWalletWithdrawable.sol";
import "./ext/PriceUpdatable.sol";
import "./ext/WithStateControl.sol";
import "./ext/WithSignatureControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


//        ____              __          __ 
//       / __ \____  ____ _/ /_  ____  / /_
//      / /_/ / __ \/ __ `/ __ \/ __ \/ __/
//     / _, _/ /_/ / /_/ / /_/ / /_/ / /_  
//    /_/ |_|\____/\__, /_.___/\____/\__/  
//                /____/                   
//               __ __ _                 __              
//              / //_/(_____  ____ _____/ ____  ____ ___ 
//             / ,<  / / __ \/ __ `/ __  / __ \/ __ `__ \
//            / /| |/ / / / / /_/ / /_/ / /_/ / / / / / /
//           /_/ |_/_/_/ /_/\__, /\__,_/\____/_/ /_/ /_/ 
//                         /____/                        
//
//                          V 2.0
//

contract RogbotKingdom is ERC721aNFT, MultipleWalletWithdrawable, PriceUpdatable, WithStateControl, WithSignatureControl, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public constant MAX_SUPPLY = 10000;   
    mapping(ProjectState => uint256) private _mintLimit;
    mapping(ProjectState => uint256) private _stageSupply;

    constructor(string memory _tokenURI) ERC721A("RogbotKingdom", "RBKD") {
        _baseTokenURI = _tokenURI;
        state = ProjectState.Prepare;
        signerAddress = 0xc2CCBA0B95D4dd4E7515E1522206E6A5Dff6CfeD;
        _mintLimit[ProjectState.PioneerSale] = 4;
        _mintLimit[ProjectState.WhitelistSale] = 4;
        _mintLimit[ProjectState.PublicSale] = 4;

        _stageSupply[ProjectState.PioneerSale] = 555;
        _stageSupply[ProjectState.WhitelistSale] = 5555;
        _stageSupply[ProjectState.PublicSale] = 10000;
    }

    
 
    // airdrop NFT
    function airdrop(address[] calldata _address, uint256[] calldata _nums)
        external
        onlyOwner
    {
        
        uint256 sum = 0;
        for (uint i = 0; i < _nums.length; i++) {
            sum = sum + _nums[i];
        }
        
        require(
            sum  <= 1000,
            "Maximum 1000 tokens"
        );

        require(
            totalSupply() + sum <= MAX_SUPPLY,
            "Exceeds maximum supply"
        );

        for (uint256 i = 0; i < _address.length; i++) {
            _baseMint(_address[i], _nums[i]);
        }
    }

    // mint multiple token
    function mint(
        uint256 _num,
        bytes memory _ticket,
        bytes memory _signature
    ) public payable nonReentrant {

        // check if sale is stared 
        require(
            (ProjectState.PublicSale == state || ProjectState.WhitelistSale == state || ProjectState.PioneerSale == state ),
            "Sale not started"
        );

        // only EOA can call this function
        require(msg.sender == tx.origin, "Only EOA can call this function");

        // check max supply
        require(totalSupply() + _num <= MAX_SUPPLY, "Exceeds maximum supply");

        // check max supply
        require(totalSupply() + _num <= _stageSupply[state], "Exceeds current stage maximum supply");

        // minting amt cannot be over the limit of the current state
        require(
            (_num > 0 && _num <= _mintLimit[state]),
            "Incorrect minting amount"
        );

        // each ticket cannot be used to mint over the allowed amt 
        if (!_bypassSignatureChecking) {
            require(_ticketUsed[_ticket] + _num <= _mintLimit[state] , "Minting amount exceed limit");
        }

        // validate ticket
        require(
                isSignedBySigner(
                    msg.sender,
                    _ticket,
                    _signature,
                    signerAddress
                ),
                "Ticket is invalid"
            );

        // check eth amt 
        require(msg.value >= (price * _num), "Not enough ETH was sent");    

        _ticketUsed[_ticket] += _num;

        // transfer the fund to the project team
        if ( msg.value > 0 ) {
            for (uint256 i = 0 ; i < _wallets.length; i++) {
                payable(_wallets[i]).transfer(msg.value.mul(_ratio[i]).div(100));
            }
        }
        
        _baseMint(_num);
 
    }


    function updateMintingLimit(ProjectState _state, uint256 _limit)
        external
        onlyOwner
    {
        _mintLimit[_state] = _limit;
    }

    function updateStageSupplyLimit(ProjectState _state, uint256 _limit)
        external
        onlyOwner
    {
        _stageSupply[_state] = _limit;
    }

    function mintingLimit(ProjectState _state) external view returns (uint256) {
        return _mintLimit[_state];
    }

    function stageSupplyLimit(ProjectState _state) external view returns (uint256) {
         return _stageSupply[_state];
    }
    

}