// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155 }  from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import { IComics77Bit } from "./interfaces/IComics77Bit.sol";

/**
     :++++++++++++++++========   =+++++++++++++++++========:              =====================              .========-    :=========================:
   ::+++++++++++++++++++++++=   .+++++++++++++++++++++++++:              -++++++++++++++++++++++              =+++++++-    ++++++++++++++++++++++++++:
  :++++++++++++++++++++++++=    +++++++++++++++++++++++++.               ++++++++++++++++++++++++.             .-+++++:   :++++++++++++++++++++++++++ 
 .+++++++=:------------+++:    :+++++++=-------------++=                -+++++++++++++++++++++++++:                :-=.   ++++++++++++++++++++++++++. 
 +++++++=       .::-++++=      =+++++++        :-=+++++                 +++++++++++=======+++++++++=        -========-    .::::::::::::::=+::::::::   
.:::----       =+++++++=       -------.      +++++++++.                .+++++++++-         ++++++++-       =+++++++++:               :-++++           
              =++++++++.                   .++++++++=      -++++++     :+++++++++        .=+++++++:        ++++++++++           .:=+++++++:           
            :++++++++=                    -++++++++:   .:.   .:=+:     =++++++++= .=+++++++++++++.        -+++++++++-          .++++++++++            
           =++++++++:                   .++++++++=     -+++-.          +++++++++    .++++++++++++=        ++++++++++           ++++++++++.            
          =++++++++.                   .++++++++-      =++++++:       .++++++++=      =++++++++++++      -+++++++++-           ++++++++++             
        .+++++++++                     =+++++++=                      +++++++++.      .+++++++++++++     ++++++++++           :+++++++++:             
       :++++++++:                    :++++++++=                      .+++++++++         :++++++++++++:  -+++++++++-           -+++++++++              
      .++++++++:                    =++++++++:                       :++++++++-    :::::=+++++++++++++  ++++++++++            +++++++++.              
     :++++++++=                    =++++++++:                          -++++++:   =+++++++++++++++++-  -+++++++++-            +++++++++               
    -++++++++-                   .+++++++++.                            .=++++.  .++++++++++++++++=    ++++++++++            -++++++++=               
   =+++++++=.                   -++++++++-                                 :==   =++++++++++++++-.     +++++++++-            +++++++++:               
                                                                                 -++++++++++++=                                                       
                                                                                  .=+++++++++-                                                        
                                                                                    .=+++++=.                                                         
                                                                                      :++-.                                                           
*/
contract Comics77Bit is IComics77Bit, ERC1155, Ownable {

    /******************************************************************************************************************************/
    /*** State Variables                                                                                                        ***/
    /******************************************************************************************************************************/

    /// @notice The name of the token collection.
    string public name;
    
    /// @notice The symbol of the token collection.
    string public symbol;
    
    /// @notice Mapping from address to minter role.
    mapping(address => bool) public minters;

    /// @notice Mapping from address to burner role.
    mapping(address => bool) public burners;    

    /******************************************************************************************************************************/
    /*** Modifiers                                                                                                              ***/
    /******************************************************************************************************************************/

    /// @notice Throws if called by any account other than a minter.
    modifier onlyMinter() {
        require(minters[msg.sender], "77B:M:NOT_AUTHORIZED");
        _;
    }

    /// @notice Throws if called by any account other than a burner.
    modifier onlyBurner() {
        require(burners[msg.sender], "77B:B:NOT_AUTHORIZED");
        _;
    }

    /******************************************************************************************************************************/
    /*** Constructor                                                                                                            ***/
    /******************************************************************************************************************************/

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) ERC1155(uri_) {
        name = name_;
        symbol = symbol_;

        emit UriSet(uri_);
    }

    /******************************************************************************************************************************/
    /*** Administrative Functions                                                                                               ***/
    /******************************************************************************************************************************/

    function setURI(string memory uri_) public override onlyOwner {
        _setURI(uri_);
        emit UriSet(uri_);
    }

    function setAllowedMinter(address minter_, bool isValid_) external override onlyOwner {
        minters[minter_] = isValid_;
        emit AllowedMinterSet(minter_, isValid_);
    }

    function setAllowedBurner(address burner_, bool isValid_) external override onlyOwner {
        burners[burner_] = isValid_;
        emit AllowedBurnerSet(burner_, isValid_);
    }

    /******************************************************************************************************************************/
    /*** Minter Functions                                                                                                       ***/
    /******************************************************************************************************************************/

    function mint(
        address[] memory recipients_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    ) external override onlyMinter {
        uint256 length = recipients_.length;
        for (uint256 i; i < length;) {
            _mint(recipients_[i], ids_[i], amounts_[i], "");
            unchecked { ++i; }
        }
    }

    function mintBatch(
        address[] memory recipients_,
        uint256[][] memory ids_,
        uint256[][] memory amounts_
    ) external override onlyMinter {
        uint256 length = recipients_.length;
        for (uint256 i; i < length;) {
            _mintBatch(recipients_[i], ids_[i], amounts_[i], "");
            unchecked { ++i; }
        }
    }

    /******************************************************************************************************************************/
    /*** Burner Functions                                                                                                       ***/
    /******************************************************************************************************************************/

    function burn(
        address account_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    ) external override onlyBurner {
        _burnBatch(account_, ids_, amounts_);
    }

    function burnBatch(
        address[] memory accounts_,
        uint256[][] memory ids_,
        uint256[][] memory amounts_
    ) external override onlyBurner {
        uint256 length = accounts_.length;
        for (uint256 i; i < length;) {
            _burnBatch(accounts_[i], ids_[i], amounts_[i]);
            unchecked { ++i; }
        }
    }
}