// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/ERC721A.sol";
import "erc721a/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/ICroakens.sol";
import "./interfaces/ISwampverse.sol";

contract Creatures is ERC721A, ERC721ABurnable, Ownable {
    using Strings for uint256;

    uint256 MAX_SUPPLY = 2400;
    uint256 ERC20_BURN_AMOUNT = 450 * (10**18);
    uint256 ERC721_BURN_AMOUNT = 2;

    string public BEGINNING_URI = "";
    string public ENDING_URI = "";

    address public blackHole = 0x000000000000000000000000000000000000dEaD;
    address public croakens_burn_address = 0x77295a06440b829c004549ba85c4D2ADD3B49463;

    bool public mintingAllowed = false;

    ICroakens public croakens;
    ISwampverse public swampverse;

    constructor(ICroakens _croakens, ISwampverse _swampverse)
        ERC721A("Swampverse: Creatures", "Creatures")
    {
        croakens = _croakens;
        swampverse = _swampverse;
    }

    /**
        @notice mint a creature in exchange of 2 swampverse tokens
        and 450 croakens burn

        @param _ids => array of swampverse ids to be burned
     */
    function mintCreature(uint256[] memory _ids) public {
        require(mintingAllowed, "Creatures.mintCreature: MINTING_NOT_ALLOWED");
        require(
            _totalMinted() + 1 <= MAX_SUPPLY,
            "Creatures.mintCreature: TOKEN_LIMIT_ERROR"
        );
        require(
            _ids.length == ERC721_BURN_AMOUNT,
            "Creatures.mintCreature: WRONG_IDS_LENGTH"
        );
        croakens.transferFrom(
            msg.sender,
            croakens_burn_address,
            ERC20_BURN_AMOUNT
        );

        for (uint256 x = 0; x < _ids.length; x++) {
            swampverse.transferFrom(msg.sender, blackHole, _ids[x]);
        }
        _safeMint(msg.sender, 1);
    }

    /**
        @param _mode: 
        1 - replace beinning of URI
        2 - replce ending of URI
        anything else - will result in revert()

        @param _new_uri: corresponding value
     */
    function setURI(uint256 _mode, string memory _new_uri) public onlyOwner {
        if (_mode == 1) BEGINNING_URI = _new_uri;
        else if (_mode == 2) ENDING_URI = _new_uri;
        else revert("Creatures.setURI: WRONG_MODE");
    }

    /**
        @param _mode:
        1 - change max_supply 
        2 - change Croakens burn amount
        3 - change swampverse burn amount
        anythign else - will result in revert()

        @param _value: corresponding value
     */
    function setUintInfo(uint256 _mode, uint256 _value) public onlyOwner {
        if (_mode == 1) MAX_SUPPLY = _value;
        else if (_mode == 2) ERC20_BURN_AMOUNT = _value * (10**18);
        else if (_mode == 3) ERC721_BURN_AMOUNT = _value;
        else revert("Creatures.setUintInfo: WRONG_MODE");
    }

    /**
        @notice change burn address

        @param _mode;
        1 - change swampverse burn address
        2 - change croakens burn address
        anything else - will result in revert()

        @dev can't set 0x0 due to previous contract implementation
        restrictions from openzeppelin ERC721/ERC20 contract.
     */
    function changeBurnAddress(uint8 _mode, address _value) public onlyOwner {
        require(
            _value != address(0),
            "Creatures.changeBurnAddress: zero_address_transfer_is_restricted"
        );
        if (_mode == 1) blackHole = _value;
        else if (_mode == 2) croakens_burn_address = _value;
        else revert("Creatures.changeBurnAddress: WRONG_MODE");
    }

    /**
        @notice set croakens and swampverse addresses
        
        @param _mode:
        1 - set croakens address
        2 - set swampverse address
        anythign else - will result in revert()
     */
    function setAddresses(uint8 _mode, address _address) public onlyOwner {
        if (_mode == 1) croakens = ICroakens(_address);
        else if (_mode == 2) swampverse = ISwampverse(_address);
        else revert("Creatures.setAddresses: WRONG_MODE");
    }

    /**
        @notice allow minting

        @param _value => true or false
     */
    function toggleMinting(bool _value) public onlyOwner {
        mintingAllowed = _value;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(BEGINNING_URI, tokenId.toString(), ENDING_URI)
            );
    }
}