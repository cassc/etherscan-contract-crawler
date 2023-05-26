// SPDX-License-Identifier: MIT

/// @title DRIP DROP // BY DAVE KRUGMAN
/// @notice ERC-721A contract with owner and admin, ECDSA allowlist, and owner minting
/// @author Transient Labs

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+-+%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%::::%%+::::%%*:::%%-::::%%%%%%%%%+: :*%%%%%%%%%+:::#%%::::#%%*::%%#::::%%%%
%%%%% :: *%= -: *%*- -#%:.:: #%%%%%%%*-   =#%%%%%%%%= -:=%@ -: =%%-:.*%* ::.*%%%
%%%%% +%:-%= %# :%%% %%%.-%% +%%%%%%%+.   -*%%%%%%%%= %# %@ @%. @* %= %* %%= %%%
%%%%% +%% %= %# +%%% %%%:-%% +%%%%%%#=.   :+#%%%%%%%= %%:[email protected] @%::%.-%% +* %%= %%%
%%%%% *%% %=   *%%%% %%%:    %%%%%%%*=    .=*%%%%%%%= %%:[email protected]   .%%.-%% +*    %%%%
%%%%% +%% %= +.=%%%% %%%:.+++%%%%%%#+-     -+#%%%%%%= %%:[email protected] +-.#%.-%% +* +++%%%%
%%%%% +%# %= %::%%%% %%%.-%%%%%%%%%*=:     :=+%%%%%%= %%[email protected] @+ *%:-%% ** %%%%%%%
%%%%% +%:-%= %# %%%% %%%.-%%%%%%%%*+=.     .=+#%%%%%= %# %@ @% +%* %= %* %%%%%%%
%%%%%    @%= %%::%+   #%:-%%%%%%%%*+-      .-=*%%%%%=   #%@ @%# %%+  %%* %%%%%%%
%%%%%####%%%#%%##%%###%%#%%%%%%%%#+=-       -=+#%%%%%###%%%#%%%#%%%##%%%#%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*+=:       :=+*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+==.       .-=+#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*+=-.        -=+*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+==-         :=+*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+==:         .==+*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*+=-.         .-=++#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*+==:.          :==+*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*+==:           :==++#%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*++=-.           .==++*%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%#++==-.           .-==+*#%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%*++==:             :===+*%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%#++===.             :===+*#%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%#++==-.             .-==++*%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%*+===-.             .-===+*#%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%#++===:               :-==++*%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%#*++==-.               .-==+++#%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%*++===-.               .:===++*%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%#*++===:                 .-==++*#%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%*+++==-.                 .:==+++#%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%*++===:.                  :===++*%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%#+++==-:                   .-==+++#%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%*+++==:.             .     .-===++*%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%*++===:.           ......   :===++*%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%#*++===..        .............===++*#%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%#+++==-.......................-==+++*%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%*+++==-.......................-==+++*#%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%*++===:.......................-===++*#%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%*++===:.......................-===++**%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%#*++===:.......................-===+++*%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%#+++===-:...................:::-===+++*%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%#+++===-::...............::::::-===+++*%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%#*+++===-:::.............:::::::====++++#%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%#*++====--::::........:::::::::-====++++#%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%#*++=====--::::::::::::::::::---=====+++#%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%#++=====----::::::::::::::-----========+#%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%#+=======-----:::::::::------===========*%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%#+=======-------------------============#%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%#+=======------------------=============#%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%*========-----------------=============%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%#=========---------------==============%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%#==========------------===============+%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%============--------=================*%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%+==================================-+#%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%#=-===============================-=*%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%+--=============================--+%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%#---===========================---*%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%=---=========================---=%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%#=---=======================----#%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%#+----===================-----*%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%+-----===============-----=#%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%#=------============-----=*%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%=--------=====---------#%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+-----------------=*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+---:::::::---+#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*+=======++*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#######%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

pragma solidity ^0.8.9;

import "ERC721ATLCore.sol";
import "ECDSA.sol";

contract DripDrop is ERC721ATLCore {

    uint256 public mintSupply;
    address private mintValidatorAddress;
    bytes32 public provenanceHash;

    /**
    *   @param _royaltyRecp is the royalty recipient
    *   @param _royaltyPerc is the royalty percentage to set
    *   @param _price is the mint price
    *   @param _supply is the total token supply
    *   @param _merkleRoot is the allowlist merkle root
    *   @param _admin is the admin address
    *   @param _payout is the payout address
    *   @param _provenanceHash is the provenance hash
    */
    constructor (address _royaltyRecp, uint256 _royaltyPerc, uint256 _price,
        uint256 _supply, bytes32 _merkleRoot, address _admin, address _payout,
        bytes32 _provenanceHash)
        ERC721ATLCore("DRIP DROP // BY DAVE KRUGMAN", "DRIPDROP", _royaltyRecp, _royaltyPerc, _price,
        _supply, _merkleRoot, _admin, _payout) 
    {
        provenanceHash = _provenanceHash;
    }

    // disable some of the ERC721ATLCore functions
    function airdrop(address[] calldata addresses) external override adminOrOwner {
        revert("Airdrop Disabled");
    }

    function mint(uint256 numToMint, bytes32[] calldata merkleProof) external override payable isEOA {
        revert("Merkle Mint Disabled");
    }

    /// @notice function to mint using an ECDSA allowlist
    /// @dev requires msg sender to be an EOA
    /// @dev there are some allowlist members that get free mints, in addition to paid mints.
    /// @param _numToMint is the number the caller wants to mint
    /// @param _maxFreeMint is the maximum free tokens the msg sender is allowed to mint
    /// @param _maxMint is the maximum the msg sender is allowed to mint overall
    /// @param _sig is the signature
    function mintDripDrop(uint256 _numToMint, uint256 _maxFreeMint,
        uint256 _maxMint, bytes calldata _sig)
        external payable isEOA 
    {
        require(ERC721A._nextTokenId() + _numToMint - 1 <= mintSupply, "No mint supply left");
        uint256 numMinted = ERC721A._numberMinted(msg.sender);
        if (allowlistSaleOpen) {
            bytes32 msgHash = _generateHash(msg.sender, _maxFreeMint, _maxMint);
            require(ECDSA.recover(msgHash, _sig) == mintValidatorAddress, "Invalid signature supplied to mint");
            require(numMinted + _numToMint <= _maxMint, "Cannot mint more than allowed");
            uint256 numFreeRemaining = _maxFreeMint <= numMinted ? 0 : _maxFreeMint - numMinted;
            uint256 price = _numToMint <= numFreeRemaining ? 0 : (_numToMint - numFreeRemaining)*mintPrice;
            require(msg.value >= price, "Not enough ether attached to the message call");
        } else if (publicSaleOpen) {
            // no need to check signature
            require(numMinted + _numToMint <= mintAllowance, "Cannot mint more than allowed");
            require(msg.value >= mintPrice * _numToMint, "Not enough ether attached to the message call");
        } else {
            revert("Mint not open");
        }

        _mint(msg.sender, _numToMint);
    }

    /// @notice function to set the mint validator address
    /// @dev requires admin or owner
    /// @param _validator is the new validator address
    function setMintValidatorAddress(address _validator) external adminOrOwner {
        mintValidatorAddress = _validator;
    }

    /// @notice function to set mint supply
    /// @dev requires admin or owner
    /// @dev can't be greater than total supply
    function setMintSupply(uint256 _supply) external adminOrOwner {
        require(_supply <= maxSupply, "Mint supply can't be greater than total supply");
        mintSupply = _supply;
    }

    /// @notice funciton to set mint price
    /// @dev requires admin or owner
    function setMintPrice(uint256 _price) external adminOrOwner {
        mintPrice = _price;
    }

    /// @notice function to override getRemainingSupply
    /// @dev function needs to be based on mintSupply
    function getRemainingSupply() external view override returns(uint256) {
        return mintSupply + 1 - ERC721A._nextTokenId();
    }

    /// @notice function to create a signature hash
    /// @param _sender is the message sender
    /// @param _maxFree is the max free tokens to mint
    /// @param _max is the max tokens can mint
    /// @return bytes32 hash of the message
    function _generateHash(address _sender, uint256 _maxFree, uint256 _max) internal pure returns (bytes32) {
        return (
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n84", _sender, _maxFree, _max))
        );
    }
}