// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "gwei-slim-nft-contracts/contracts/base/ERC721Base.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721Delegated} from "gwei-slim-nft-contracts/contracts/base/ERC721Delegated.sol";
import "@0xdievardump/signed-allowances/contracts/SignedAllowance.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

//Memories of an Autómaton
//@creator: nyx // @opusnyx
//@author: secondstate // @sec0ndstate
//
//
//  .............................................................
//  .............................................................
//  .............................................................
//  .............................................................
//  .............................................................
//  .............................................................
//  ._____.______.......________......________......________.....
//  |\..._.\.._...\....|\...__..\....|\...__..\....|\...__..\....
//  \.\..\\\__\.\..\...\.\..\|\..\...\.\..\|\..\...\.\..\|\..\...
//  .\.\..\\|__|.\..\...\.\..\\\..\...\.\...__..\...\.\...__..\..
//  ..\.\..\....\.\..\...\.\..\\\..\...\.\..\.\..\...\.\..\.\..\.
//  ...\.\__\....\.\__\...\.\_______\...\.\__\.\__\...\.\__\.\__\
//  ....\|__|.....\|__|....\|_______|....\|__|\|__|....\|__|\|__|
//  .............................................................
//  .............................................................
//  .............................................................
//  .............................................................
//  .............................................................
//  .............................................................

contract MOAA is ERC721Delegated, SignedAllowance {

    // uint256 internal _currentPMIndex;
    uint256 internal _currentMemoriaIndex;
    uint256 internal _currentAutomatonIndex;
    uint256 internal _saleState;

    constructor(
        address baseFactory,
        address allowanceSigner_
    ) 
     ERC721Delegated(
            baseFactory,
            "Memories of an Automaton",
            "MOAA",
            ConfigSettings({
                royaltyBps: 1000,
                uriBase: "",
                uriExtension: "",
                hasTransferHook: false
            })
        )
    {
            // _currentPMIndex = 0; // 0 is reserved for PuppetMaster - but we do not keep track
            _currentAutomatonIndex = 1; // 1 is the first token id for Automaton
            _currentMemoriaIndex = 101; //101 is the first token id for Memoria
            _saleState = 1; //1 = closed - only admin can mint, 2 = public sale - no checks for WL, 3 = private sale - checks for WL
            _setAllowancesSigner(allowanceSigner_);
    }

    struct UserMinted {
        bool mintedFirst;
        bool mintedSecond;
    }


    struct ConfigStorage {
        string puppetMasterUrl;
        string automatonUrl;
        string memoriaUrl;
        uint256 AutomatonPrice;
        uint256 MemoriaPrice;
        address operator;
    }
    ConfigStorage confStorage;


    mapping(address => UserMinted) private _userMinted;


    address private ash = 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92;
    address private payout = 0x62799023aD27358DF30516742216DFCa60d427c8;


////////////////////////////////////////
/////////////// SETTERS /////////////////
////////////////////////////////////////

    /// @notice sets allowance signer, this can be used to revoke all unused allowances already out there
    /// @param newSigner the new signer
    function setAllowancesSigner(address newSigner) external onlyOperator {
        _setAllowancesSigner(newSigner);
    }

    function changeSaleState(uint256 newState) external onlyOperator {
        _saleState = newState;
    }

        function setOperator(address newOperator) external onlyOperator {
        confStorage.operator = newOperator;
    }


    function setUrls(string memory _PMUrl, string memory _MemoriaUrl, string memory _AutomatonUrl) external onlyOperator {
        confStorage.puppetMasterUrl = _PMUrl;
        confStorage.memoriaUrl = _MemoriaUrl;
        confStorage.automatonUrl = _AutomatonUrl;
    }


    function setPrice(uint64 _AutomatonPrice, uint64 _MemoriaPrice) external onlyOperator {
        confStorage.AutomatonPrice = _AutomatonPrice;
        confStorage.MemoriaPrice = _MemoriaPrice;
    }


////////////////////////////////////////
/////////////// GETTERS /////////////////
////////////////////////////////////////

    function getSaleState() public view returns (uint256) {
        return _saleState;
    }


////////////////////////////////////////
/////////////// MODIFIERS //////////////
////////////////////////////////////////

    modifier onlyOperator() {
     require(msg.sender == ERC721Delegated._owner() || msg.sender == confStorage.operator, 'Not Authorized');
        _;
    }


////////////////////////////////////////
/////////////// MINTING /////////////////
////////////////////////////////////////
 

    function adminMint(address to, uint256 _selectedToken,uint256 tokenId) public onlyOperator {
        require(_selectedToken == 1 || _selectedToken == 2 || _selectedToken == 0, "Selector must be 1 Automaton 2 for memoria, 0 for PM");
        if (_selectedToken == 0 && tokenId == 0) {
            tokenId = tokenId;
        } else if (_selectedToken == 1 && tokenId == 0) {
            tokenId = _currentAutomatonIndex;
            while(_exists(tokenId)) {
            unchecked {
                tokenId++;
            }
      }
            require(_currentAutomatonIndex < 101, "Exceeds max supply of Automaton.");
            _currentAutomatonIndex = tokenId;
        } else if (_selectedToken == 2 && tokenId == 0) {
            tokenId = _currentMemoriaIndex;
            while(_exists(tokenId)) {
            unchecked {
                tokenId++;
            }
        }
            require(_currentMemoriaIndex < 401, "Exceeds max supply of Memoria.");
            _currentMemoriaIndex = tokenId;
        }
        _mint(to, tokenId);
    }


    /// @notice This function allows `nonce` mint per allowance.
    /// @param _selectedToken the tokenId to mint
    /// @param nonce the nonce, which is also the number of mint allowed for this signature
    /// @param signature the signature by the allowance wallet
    function publicPurchase(uint256 _selectedToken,uint256 nonce, bytes memory signature) external {
        require(_selectedToken == 1 || _selectedToken == 2, "Selector must be 1 Automaton or 2 for Memoria");
        uint256 nonceTier = nonce >> 128;
        UserMinted storage alreadyMinted = _userMinted[msg.sender];
        require(_saleState == 2 || _saleState == 3, "Sale is not open to public/private purchases.");
        uint256 tokenId;
        if (_selectedToken == 1) {
            require(_currentAutomatonIndex < 101, "Exceeds max supply of Automaton.");
            require(IERC20(ash).transferFrom(msg.sender, payout, confStorage.AutomatonPrice * 10 ** 18), "$ASH transfer failed"); 
            if (_saleState == 3) { // check for private sale first
                validateSignature(msg.sender, nonce, signature);
                require (nonceTier == 1 || nonceTier == 3, "Nonce tier must be 1 or 3"); // 1 for Automaton only, 3 for Automaton and Memoria
                require(alreadyMinted.mintedFirst == false, "Already minted Automaton allowance.");
                alreadyMinted.mintedFirst = true;
            }
            tokenId = _currentAutomatonIndex;
            while(_exists(tokenId)) {
            unchecked {
                tokenId++;
            }
      }
            _currentAutomatonIndex = tokenId;

        } else if (_selectedToken == 2) {
            require(_currentMemoriaIndex < 401, "Exceeds max supply of Memoria.");
            require(IERC20(ash).transferFrom(msg.sender, payout, confStorage.MemoriaPrice * 10 ** 18), "$ASH transfer failed"); 
            if (_saleState == 3) { // check for private sale first
                require (nonceTier == 2 || nonceTier == 3, "Nonce tier must be 2 or 3"); // 2 for Memoria only, 3 for Automaton and Memoria
                require(alreadyMinted.mintedSecond == false, "Already minted Memoria allowance.");
                alreadyMinted.mintedSecond = true;
            }
            tokenId = _currentMemoriaIndex;
            while(_exists(tokenId)) {
            unchecked {
                tokenId++;
            }
            }
            _currentMemoriaIndex = tokenId;

        }
            _mint(msg.sender, tokenId);
    }



    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Unknown token");
        string memory MemoriaUrl = string(abi.encodePacked(confStorage.memoriaUrl, Strings.toHexString(uint256(uint160((ERC721Base(address(this)).ownerOf(tokenId)))), 20)));
        string memory AutomatonUrl = string(abi.encodePacked(confStorage.automatonUrl, Strings.toHexString(uint256(uint160((ERC721Base(address(this)).ownerOf(tokenId)))), 20)));
        string memory PMUrl = string(abi.encodePacked(confStorage.puppetMasterUrl, Strings.toHexString(uint256(uint160((ERC721Base(address(this)).ownerOf(tokenId)))), 20)));

        string memory automatonImage = string(abi.encodePacked("https://arweave.net/-5BT4N6nFxExBM-QkrXk44aoxPmUxARFDs5joJcml2s"));
        string memory memoriaImage = string(abi.encodePacked("https://arweave.net/yHDh1K0sE0STZqmMesomaD1p7mkd4_CrWrwTrKsjIME"));
        string memory json;
        if(tokenId == 0) {
            json = string(
            abi.encodePacked( 
                '{"name": "Puppet Master #0/0",',
                '"description": "2501",',
                '"created_by": "nyx x secondstate",',
                '"image": "', automatonImage, '",'
                '"image_url": "', automatonImage, '",',
                '"animation_url": "', PMUrl, '",',
                '"attributes":[',
                '{"trait_type":"Archillect","value":"TV"},{"trait_type":"Artist","value":"Nyx"},{"trait_type":"Artist","value":"secondstate"}',
                "]}"
            )
        );  // tokenId must be between the 1 and 100 range 
        } else if (tokenId > 0 && tokenId < 101) {
            json = string(
            abi.encodePacked( 
                '{"name": "Aut\xC3\xB3maton #', Strings.toString(tokenId), '/100",',
                '"description": "She whispered...",',
                '"created_by": "nyx x secondstate",',
                '"image": "', automatonImage, '",'
                '"image_url": "', automatonImage, '",',
                '"animation_url": "', AutomatonUrl, '",',
                '"attributes":[',
                '{"trait_type":"Artist","value":"Nyx"},{"trait_type":"Artist","value":"secondstate"},{"trait_type":"Extrinsic","value":"DannyWithThreeBrains"}',
                "]}"
            )
        );// tokenId must be between the 101 and 400 range
        } else if (tokenId > 100 && tokenId < 401) {
            json = string(
            abi.encodePacked( 
                '{"name": "Memoria #', Strings.toString(tokenId - 100), '/300",',
                '"description": "Awake but dreaming...",',
                '"created_by": "nyx x secondstate",',
                '"image": "', memoriaImage, '",'
                '"image_url": "', memoriaImage, '",',
                '"animation_url": "', MemoriaUrl, '",',
                '"attributes":[',
                '{"trait_type":"Artist","value":"Nyx"},{"trait_type":"Artist","value":"secondstate"},{"trait_type":"Intrinsic","value":"DannyWithThreeBrains"}',
                "]}"
            )
        );
        }
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }
        }