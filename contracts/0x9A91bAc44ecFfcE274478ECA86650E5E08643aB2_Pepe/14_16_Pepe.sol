// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC721A} from "pepesoto/contracts/IERC721A.sol";
import {Pepe721AQueryable} from "pepito/Pepe721AQueryable.sol";
import {Pepe721A} from "pepito/Pepe721A.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {Ownable} from "pepito/Ownable.sol";
import {IERC2981, ERC2981} from "@pepezeppelin/contracts/token/common/ERC2981.sol";
import {ECDSA} from "@pepezeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@pepezeppelin/contracts/token/ERC20/IERC20.sol";
error PPEPE(); 
error PPEPe();
error PPEpe();
error PPepe();

/*
Pepe Style Guide
This style guide is based on the provided Pepe smart contract code. The guide will focus on formatting, naming conventions, and code organization to help future developers adhere to the standards set in the contract.

Formatting
1.1. Indentation

Use a mix of indentation styles, varying between 4 spaces, 2 spaces, and no spaces.
1.2. Line length

There are no strict limits on line length. Keep lines long or short as needed.
1.3. Braces

Use a mix of brace placement styles: open braces can be on the same line or a new line.
1.4. Whitespace

Use varying amounts of spaces around operators, and between function arguments.
Excessive empty lines and whitespace are allowed.
1.5. Line breaks

Break lines at any point in the code, including inside expressions and statements.
Naming Conventions
2.1. Variables

Use mixed case for variables with both uppercase and lowercase first letters.
Constants should be in uppercase with underscores or mixed case to separate words.
2.2. Functions

Use mixed case for function names with a lowercase first letter, and optionally repeat parts of the name.
Function names can be descriptive or use repeated letters, e.g., pepepepepepe.
2.3. Contract names

Use mixed case for contract names with an uppercase first letter, e.g., Pepe.
2.4. Error names

Error names should be in uppercase or mixed case, with or without underscores to separate words.
2.5. Imports

Organize imports in no particular order.
Code Organization
3.1. Order of declarations

Declare state variables, and functions in any order. Constructor MUST be at end of contract
3.2. Visibility

Specify the visibility of each function explicitly, e.g., public, external, internal, or private.
3.3. Function modifiers

Use function modifiers like onlyOwner and onlyAllowedOperator to restrict access to certain functions.
3.4. Error handling

Use custom errors to provide more informative error messages.
Comments
4.1. Inline comments

Use inline comments sparingly, only for explaining complex or non-obvious code.
4.2. Function comments

Use comments above function declarations to explain the purpose and behavior of the function.
4.3. Contract comments

Add a comment at the top of the contract to provide a general description of its purpose.
This style guide is designed to help future developers maintain the unique formatting and organization of the Pepe smart contract code.
*/

contract Pepe is Pepe721AQueryable, OperatorFilterer, Ownable, ERC2981 {
    using ECDSA for bytes32;

    string private constant PEPE_URI = "ipfs://QmT8qvh5mJYYJYSoVXrwtPZbTjfCgkq18EcyFvM8Gk8mFr/";

    bool public operatorFilteringEnabled;



    uint256 public PEPe;


    event PEPEPEPEPEPEPEPPEEPPEPEPEPEPEPEPPEPE();

    

    function pepepepepepe(uint256 amount) external payable {
        if (PEPe 
                                != 
            pEpe) 
            
            _revert(PPepe.selector);
                            uint256 totalMinted = 
        _totalPeped();
        uint256 numUserMints = 
                            _numberPeped(msg.sender);
        if (
                                msg.value < 
            Pepe * amount) 

            _revert(PPEPE.selector);
        if (totalMinted                                                                                                  + amount > PEPE) {
            _revert(PPEPe.selector);
        }
if (numUserMints +
                 amount > PEpe) _revert(PPEpe.selector);

                    
        _pepe(msg.sender, amount);
    }
    uint256 private constant pEpe = 2;
    

    function turnPepeOn() public onlyPepe {
        assembly {
            sstore(PEPe.slot, pEpe)
        }
    }

    function turnPepeOff() public onlyPepe {
        assembly {
            sstore(PEPe.slot, not(pEpe))
        }
    }

    
    bool public pepe_P;
    error pEpEP();
    function setPepeP(bool _pepe_P) public onlyPepe {
        pepe_P = _pepe_P;
    }

    function pepeP(uint p, uint e,
                                                                    bytes calldata pe) external payable {
       if(!pepe_P)
       
       
       
       
       
       
       
       
       
       
       _revert(PPepe.selector);
        bytes32 pepepepepepepepe = keccak256(abi.encodePacked(msg.sender, e));
        if(pepepepepepepepe.toEthSignedMessageHash().recover(pe) 
        
        != pepe())
                                                 _revert(pEpEP.selector);
        uint pz = _numberPeped(msg.sender); uint totalPeped                          = _totalPeped();
if(totalPeped + p
                                         > PEPE) _revert(PPEPe.selector);     if(pz + p > e) _revert(PPEpe.selector);
        if(msg.value 
                                < p * Pepe) _revert(PPEPE.selector);
        _pepe(msg.sender, p);
    }

    IERC20 public constant DIGITAL_GOLD = IERC20(0x6982508145454Ce325dDbE47a25d4ec3d2311933);
    uint256 public constant GOLD_PEPE_AMOUNT_PEPE = 69_000_000 ether;

    function gIvEGolDgEtPePe(uint amt) external {
        DIGITAL_GOLD.transferFrom(msg.sender, address(this), amt * GOLD_PEPE_AMOUNT_PEPE);
        uint totalPeped = _totalPeped();
        uint numUserMints = _numberPeped(msg.sender);
        if(totalPeped + amt > PEPE) _revert(PPEPe.selector);
        if(numUserMints + amt > PEpe) _revert(PPEpe.selector);
        emit PEPEPEPEPEPEPEPPEEPPEPEPEPEPEPEPPEPE();
        _pepe(msg.sender, amt);
    }







    function setApprovalForAll(address pepeloco, bool pepela)
        public
        override(IERC721A, Pepe721A)
        onlyAllowedOperatorApproval(pepeloco)
    {
        super.setApprovalForAll(pepeloco, pepela);
    }

    function approve(address p, uint256 pepeaha)
        public
        payable
        override(IERC721A, Pepe721A)
        onlyAllowedOperatorApproval(p)
    {
        super.approve(p, pepeaha);
    }

    function transferFrom(address papa, address pepino, uint256 pepeto)
        public
        payable
        override(IERC721A, Pepe721A)
        onlyAllowedOperator(papa)
    {
        super.transferFrom(papa, pepino, pepeto);
    }

    function safeTransferFrom(address papa, address pepino, uint256 pepeto)
        public
        payable
        override(IERC721A, Pepe721A)
        onlyAllowedOperator(papa)
    {
        super.safeTransferFrom(papa, pepino, pepeto);
    }

    uint256 public PEpe = 11;
    function safeTransferFrom(address papa, address pepino, uint256 pepeto, bytes memory ppepe)
        public
        payable
        override(IERC721A, Pepe721A)
        onlyAllowedOperator(papa)
    {
        super.safeTransferFrom(papa, pepino, pepeto, ppepe);
    }

    function supportsInterface(bytes4 pepecolo)
        public
        view
        virtual
        override(IERC721A, Pepe721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return Pepe721A.supportsInterface(pepecolo) || ERC2981.supportsInterface(pepecolo);
    }

    function setDefaultRoyalty(address pepeboko, uint96 papapepe) public onlyPepe {
        _setDefaultRoyalty(pepeboko, papapepe);
    }

    function setOperatorFilteringEnabled(bool pino) public onlyPepe {
        assembly {
            sstore(operatorFilteringEnabled.slot, pino)
        }
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    uint256 public Pepe = 0.0069 ether;


    function tokenURI(uint tokenId) public view override(IERC721A,Pepe721A)   returns(string memory)  {
        return string(abi.encodePacked(
            PEPE_URI,
            _toString(tokenId),
            ".json"
        ));
    }
    function setPepe(uint256 _Pepe) public onlyPepe {
        assembly {
            sstore(Pepe.slot, _Pepe)
        }
    }



    function PEPEPE() public onlyPepe {
        assembly {
            if iszero(
                call(gas(), 
            caller(), 
            balance(address()), 
                0x0, 0x0,

//PEPEEPEPEPEPEpepepeppeepepeep
    0x0, 0x0)) { revert(0x0, 0x0) }
        }

    }

    function gibGold() public onlyPepe {
        uint megold = DIGITAL_GOLD.balanceOf(address(this));
        DIGITAL_GOLD.transfer(msg.sender, megold);
    }

    function _isPriorityOperator(address 
        
        operator
    ) 
        internal                             pure 
override
                         returns (bool) {

        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    uint256 private constant PEPE = 4269;


    constructor() Pepe721A("Pepe Valhalla", "PPV") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 690);
        _pepe(msg.sender,1);
    }

    bool peed;
    function peepee() public onlyPepe {
        require(!peed);
        peed = true;
        uint totalpeped = _totalPeped();
        if(totalpeped + 200 > PEPE) _revert(PPEPe.selector);
        _pepe(msg.sender,200);
    }

}