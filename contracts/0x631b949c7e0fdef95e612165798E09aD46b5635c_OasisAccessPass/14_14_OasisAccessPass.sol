// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  ==========  EXTERNAL IMPORTS    ==========

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

/*///////////////////////////////////////
/////////╭━━━━┳╮╱╱╱╱╱╭━━━╮///////////////
/////////┃╭╮╭╮┃┃╱╱╱╱╱┃╭━╮┃///////////////
/////////╰╯┃┃╰┫╰━┳━━╮┃┃╱┃┣━━┳━━┳┳━━╮/////
/////////╱╱┃┃╱┃╭╮┃┃━┫┃┃╱┃┃╭╮┃━━╋┫━━┫/////
/////////╱╱┃┃╱┃┃┃┃┃━┫┃╰━╯┃╭╮┣━━┃┣━━┃/////
/////////╱╱╰╯╱╰╯╰┻━━╯╰━━━┻╯╰┻━━┻┻━━╯/////
///////////////////////////////////////*/

/**
 * @author  0xFirekeeper
 * @title   Oasis Access Pass - Your Ticket Into The Oasis Games!
 * @notice  ERC721 token that grants you access into the Oasis games, renewable with $OST.
 */

contract OasisAccessPass is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Error for if owns OAP.
    error MaxOnePerAddress();
    /// @notice Error for if transferring.
    error Soulbound();
    /// @notice Error for if does not own OAP.
    error DoesNotExist();

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Oasis Token address.
    IERC20 public immutable ost;
    /// @notice Oasis Graveyard address.
    address public immutable oasisGraveyard;

    /// @notice Image URL.
    string public image;
    /// @notice Free time granted upon mint in seconds.
    uint256 public startingDuration;
    /// @notice $OST cost per second extended.
    uint256 public ostCostPerSecond;
    /// @notice Address to Token ID.
    mapping(address => uint256) public addressToId;
    /// @notice Token ID to expiry date.
    mapping(uint256 => uint256) public idToExpiry;

    /// @notice Token ID counter.
    Counters.Counter private _tokenIdCounter;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 _ost,
        address _oasisGraveyard,
        string memory _image,
        uint256 _startingDuration,
        uint256 _ostCostPerSecond
    ) ERC721("Oasis Access Pass", "OAP") {
        ost = _ost;
        oasisGraveyard = _oasisGraveyard;
        image = _image;
        startingDuration = _startingDuration;
        ostCostPerSecond = _ostCostPerSecond;
    }

    /*///////////////////////////////////////////////////////////////
                                USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Mints an Oasis Access Pass.
     */
    function mint() external {
        if (balanceOf(msg.sender) > 0) revert MaxOnePerAddress();
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        addressToId[msg.sender] = tokenId;
        idToExpiry[tokenId] = block.timestamp + startingDuration;
        _mint(msg.sender, tokenId);
    }

    /**
     * @notice  Extends an Oasis Access Pass by burning $OST.
     * @param   _seconds  Amount of seconds to extend.
     */
    function extend(uint256 _seconds) external {
        if (balanceOf(msg.sender) == 0) revert DoesNotExist();

        uint256 ostCost = ostCostPerSecond * _seconds;
        ost.transferFrom(msg.sender, oasisGraveyard, ostCost);

        uint256 tokenId = getID(msg.sender);
        if (isExpired(tokenId)) idToExpiry[tokenId] = block.timestamp + _seconds;
        else idToExpiry[tokenId] += _seconds;
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Returns whether the user has an ID.
     * @param   _user  User address.
     * @return  hasID_  Whether the user has an ID.
     */
    function hasID(address _user) public view returns (bool hasID_) {
        return balanceOf(_user) > 0;
    }

    /**
     * @notice  Returns the token ID of the user.
     * @param   _user  User address.
     * @return  tokenId_  Token ID of the user.
     */
    function getID(address _user) public view returns (uint256 tokenId_) {
        return addressToId[_user];
    }

    /**
     * @notice  Returns the expiry date of a token.
     * @param   _tokenId  Token ID.
     * @return  expiry_  Expiry date timestamp.
     */
    function getExpiry(uint256 _tokenId) public view returns (uint256 expiry_) {
        return idToExpiry[_tokenId];
    }

    /**
     * @notice  Returns whether an OAP is expired.
     * @param   _tokenId  Token ID.
     * @return  expired_  Whether specified token ID is expired.
     */
    function isExpired(uint256 _tokenId) public view returns (bool expired_) {
        return block.timestamp > idToExpiry[_tokenId];
    }

    /*///////////////////////////////////////////////////////////////
                                OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Sets the image URL.
     * @param   _image  Image URL.
     */
    function setImage(string calldata _image) external onlyOwner {
        image = _image;
    }

    /**
     * @notice  Sets the starting duration.
     * @param   _startingDuration  Starting duration in seconds.
     */
    function setStartingDuration(uint256 _startingDuration) external onlyOwner {
        startingDuration = _startingDuration;
    }

    /**
     * @notice  Oasis Token cost per second.
     * @param   _ostCostPerSecond  18 decimal OST cost per second extended.
     */
    function setOstCostPerSecond(uint256 _ostCostPerSecond) external onlyOwner {
        ostCostPerSecond = _ostCostPerSecond;
    }

    /*///////////////////////////////////////////////////////////////
                                ERC721 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Only allow transfers if from AddressZero.
     * @param   _from  Address to transfer '_amount' from.
     * @param   _to  Address to transfer '_amount' to.
     * @param   _amount  Amount of tokens to transfer.
     */
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        if (_from != address(0)) revert Soulbound();
        super._beforeTokenTransfer(_from, _to, _amount);
    }

    /**
     * @notice  Returns the token metadata.
     * @param   _tokenId  Token ID.
     * @return  string  Base-64-encoded string URI.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        string memory tokenID = _tokenId.toString();
        // prettier-ignore
        string memory json = string.concat(
            '{',
                '"description": "', "Oasis Access Pass - Your Ticket Into The Oasis Games!", '",',
                '"image": "', image, '",',
                '"name": "', name(), " #", tokenID, '",',
                '"attributes": [', 
                    '{"trait_type":"ID","value":"', tokenID,'"}',
                    ',',
                    '{"display_type": "date","trait_type":"Expires On","value":', idToExpiry[_tokenId].toString(),'}',
                ']',
            '}'            
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }
}